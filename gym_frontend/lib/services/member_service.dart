import 'dart:convert';
import 'logger_service.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'cache_service.dart';

class MemberService {
  // Singleton CacheService — déjà initialisé dans main.dart
  static final CacheService _cache = CacheService();

  // ── Récupérer un membre par ID ──
  static Future<Map<String, dynamic>?> getMemberById(
    int id, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedMember(id);
      if (cached != null) return cached;
    }

    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/members/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _cache.cacheMember(id, data);
        return data;
      }
      return null;
    } catch (_) {
      return _cache.getCachedMember(id, checkExpiry: false);
    }
  }

  // ── Récupérer les séances d'un membre ──
  static Future<List<dynamic>> getMemberSessions(
    int memberId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedSessions(memberId);
      if (cached != null) return cached;
    }

    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/sessions/member/$memberId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _cache.cacheSessions(memberId, data);
        return data;
      }
      return [];
    } catch (_) {
      return await _cache.getCachedSessions(memberId, checkExpiry: false) ?? [];
    }
  }

  // ── Récupérer le profil d'un membre ──
  static Future<Map<String, dynamic>?> getMemberProfile(
    int id, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCachedProfile(id);
      if (cached != null) return cached;
    }

    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/members/$id/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _cache.cacheProfile(id, data);
        return data;
      }
      return null;
    } catch (_) {
      return _cache.getCachedProfile(id, checkExpiry: false);
    }
  }

  // ── Créer une séance ──
  static Future<Map<String, dynamic>> createSession(
    int memberId,
    Map<String, dynamic> sessionData,
  ) async {
    AppLogger.d("📝 [DEBUG] createSession - memberId=$memberId");
    AppLogger.d("📝 [DEBUG] sessionData=$sessionData");

    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/sessions/member/$memberId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(sessionData),
          )
          .timeout(const Duration(seconds: 15));

      AppLogger.d("📡 [DEBUG] createSession response status: ${response.statusCode}");
      AppLogger.d("📡 [DEBUG] createSession response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final session = jsonDecode(response.body);
        await _cache.invalidateMember(memberId);
        return {'success': true, 'session': session};
      }
      return {'success': false, 'message': 'Erreur lors de la création'};
    } catch (e) {
      AppLogger.d("❌ [DEBUG] createSession error: $e");
      return {'success': false, 'message': 'Serveur inaccessible'};
    }
  }

  // ── Récupérer la prédiction IA ──
  static Future<Map<String, dynamic>?> getAIPrediction(
    int memberId,
    int sessionId, {
    bool forceRefresh = false,
  }) async {
    AppLogger.d(
      "🔍 [DEBUG] getAIPrediction appelé: memberId=$memberId, sessionId=$sessionId",
    );

    if (!forceRefresh) {
      final cached = await _cache.getCachedPrediction(memberId, sessionId);
      if (cached != null) {
        AppLogger.d("📦 [DEBUG] Utilisation cache pour prediction");
        return cached;
      }
    }

    try {
      final token = await AuthService.getToken();
      AppLogger.d(
        "🔑 [DEBUG] Token récupéré: ${token?.substring(0, token!.length > 20 ? 20 : token.length)}...",
      );

      final url = '${ApiConfig.baseUrl}/api/ai/predict/$memberId/$sessionId';
      AppLogger.d("🌐 [DEBUG] Appel URL: $url");

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      AppLogger.d("📡 [DEBUG] Status code: ${response.statusCode}");
      AppLogger.d("📡 [DEBUG] Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _cache.cachePrediction(memberId, sessionId, data);
        AppLogger.d("✅ [DEBUG] Prédiction reçue avec succès");
        return data;
      }
      AppLogger.d("❌ [DEBUG] Status code non 200: ${response.statusCode}");
      return null;
    } catch (e) {
      AppLogger.d("❌ [DEBUG] Erreur getAIPrediction: $e");
      return _cache.getCachedPrediction(
        memberId,
        sessionId,
        checkExpiry: false,
      );
    }
  }

  // ── Mettre à jour le profil ──
  static Future<bool> updateMemberProfile(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/members/$id/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await _cache.invalidateMember(id);
        await _cache.invalidateCoachCache();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
