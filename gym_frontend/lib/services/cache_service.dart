import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _prefixMember = 'member_';
  static const String _prefixSessions = 'sessions_';
  static const String _prefixProfile = 'profile_';
  static const String _prefixPrediction = 'prediction_';
  static const String _prefixMembers = 'all_members';
  static const String _lastRefreshKey = 'last_refresh_';

  static const Duration cacheDuration = Duration(hours: 1);

  SharedPreferences? _prefs;
  // Completer utilisé pour bloquer les appels concurrents pendant l'init
  Completer<void>? _initCompleter;

  static final CacheService _instance = CacheService._internal();
  CacheService._internal();
  factory CacheService() => _instance;

  /// Thread-safe : si deux appels arrivent simultanément,
  /// le second attend la fin du premier via le Completer.
  Future<void> init() async {
    // Déjà initialisé → rien à faire
    if (_prefs != null) return;

    // Init en cours → attendre qu'elle se termine
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    // Premier appelant : créer le Completer et lancer l'init
    _initCompleter = Completer<void>();
    try {
      _prefs = await SharedPreferences.getInstance();
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Permettre une nouvelle tentative
      rethrow;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    await init();
    return _prefs!;
  }

  // ============================================================
  // MÉTHODES GÉNÉRIQUES
  // ============================================================

  Future<void> set(String key, dynamic value) async {
    final prefs = await _getPrefs();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List || value is Map) {
      await prefs.setString(key, jsonEncode(value));
    }
  }

  Future<dynamic> get(String key) async {
    final prefs = await _getPrefs();
    return prefs.get(key);
  }

  Future<List<dynamic>?> getList(String key) async {
    final prefs = await _getPrefs();
    final String? data = prefs.getString(key);
    if (data == null) return null;
    return jsonDecode(data) as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getMap(String key) async {
    final prefs = await _getPrefs();
    final String? data = prefs.getString(key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> remove(String key) async {
    final prefs = await _getPrefs();
    await prefs.remove(key);
  }

  Future<bool> isExpired(String key) async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getInt('${_lastRefreshKey}$key');
    if (timestamp == null) return true;
    final lastRefresh = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(lastRefresh) > cacheDuration;
  }

  Future<void> updateTimestamp(String key) async {
    final prefs = await _getPrefs();
    await prefs.setInt(
      '${_lastRefreshKey}$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Vide tout le cache et remet le service dans un état réinitialisable.
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    _prefs = null;
    _initCompleter = null;
  }

  // ============================================================
  // MEMBER
  // ============================================================

  Future<void> cacheMember(int memberId, Map<String, dynamic> member) async {
    final key = '$_prefixMember$memberId';
    await set(key, member);
    await updateTimestamp(key);
  }

  Future<Map<String, dynamic>?> getCachedMember(
    int memberId, {
    bool checkExpiry = true,
  }) async {
    final key = '$_prefixMember$memberId';
    if (checkExpiry && await isExpired(key)) return null;
    return getMap(key);
  }

  // ============================================================
  // SESSIONS
  // ============================================================

  Future<void> cacheSessions(int memberId, List<dynamic> sessions) async {
    final key = '$_prefixSessions$memberId';
    await set(key, sessions);
    await updateTimestamp(key);
  }

  Future<List<dynamic>?> getCachedSessions(
    int memberId, {
    bool checkExpiry = true,
  }) async {
    final key = '$_prefixSessions$memberId';
    if (checkExpiry && await isExpired(key)) return null;
    return getList(key);
  }

  // ============================================================
  // PROFILE
  // ============================================================

  Future<void> cacheProfile(int memberId, Map<String, dynamic> profile) async {
    final key = '$_prefixProfile$memberId';
    await set(key, profile);
    await updateTimestamp(key);
  }

  Future<Map<String, dynamic>?> getCachedProfile(
    int memberId, {
    bool checkExpiry = true,
  }) async {
    final key = '$_prefixProfile$memberId';
    if (checkExpiry && await isExpired(key)) return null;
    return getMap(key);
  }

  // ============================================================
  // PREDICTION
  // ============================================================

  Future<void> cachePrediction(
    int memberId,
    int sessionId,
    Map<String, dynamic> prediction,
  ) async {
    final key = '$_prefixPrediction${memberId}_$sessionId';
    await set(key, prediction);
    await updateTimestamp(key);
  }

  Future<Map<String, dynamic>?> getCachedPrediction(
    int memberId,
    int sessionId, {
    bool checkExpiry = true,
  }) async {
    final key = '$_prefixPrediction${memberId}_$sessionId';
    if (checkExpiry && await isExpired(key)) return null;
    return getMap(key);
  }

  // ============================================================
  // ALL MEMBERS (coach)
  // ============================================================

  Future<void> cacheAllMembers(List<dynamic> members) async {
    await set(_prefixMembers, members);
    await updateTimestamp(_prefixMembers);
  }

  Future<List<dynamic>?> getCachedAllMembers({bool checkExpiry = true}) async {
    if (checkExpiry && await isExpired(_prefixMembers)) return null;
    return getList(_prefixMembers);
  }

  // ============================================================
  // INVALIDATION
  // ============================================================

  Future<void> invalidateMember(int memberId) async {
    await Future.wait([
      remove('$_prefixMember$memberId'),
      remove('$_prefixSessions$memberId'),
      remove('$_prefixProfile$memberId'),
      remove('${_lastRefreshKey}$_prefixMember$memberId'),
      remove('${_lastRefreshKey}$_prefixSessions$memberId'),
      remove('${_lastRefreshKey}$_prefixProfile$memberId'),
    ]);
  }

  Future<void> invalidatePredictions(int memberId, int sessionId) async {
    final key = '$_prefixPrediction${memberId}_$sessionId';
    await Future.wait([
      remove(key),
      remove('${_lastRefreshKey}$key'),
    ]);
  }

  Future<void> invalidateCoachCache() async {
    await Future.wait([
      remove(_prefixMembers),
      remove('${_lastRefreshKey}$_prefixMembers'),
    ]);
  }
}