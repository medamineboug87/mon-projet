import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'cache_service.dart';
import 'member_service.dart';

class CoachService {
  static final CacheService _cache = CacheService();

  // ── Récupérer tous les membres ──
  static Future<List<dynamic>> getAllMembers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      // ✅ FIX : await ajouté (getCachedAllMembers est maintenant async)
      final cached = await _cache.getCachedAllMembers();
      if (cached != null) return cached;
    }

    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse("${ApiConfig.baseUrl}/members"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _cache.cacheAllMembers(data);
        return data;
      }
      return [];
    } catch (e) {
      // ✅ FIX : await ajouté
      return await _cache.getCachedAllMembers(checkExpiry: false) ?? [];
    }
  }

  // ── Récupérer les séances d'un membre (délègue à MemberService) ──
  static Future<List<dynamic>> getMemberSessions(
    int memberId, {
    bool forceRefresh = false,
  }) async {
    return await MemberService.getMemberSessions(
      memberId,
      forceRefresh: forceRefresh,
    );
  }

  // ── Récupérer la dernière prédiction IA d'un membre ──
  static Future<Map<String, dynamic>?> getLastSessionPrediction(
    int memberId, {
    bool forceRefresh = false,
  }) async {
    final sessions = await getMemberSessions(
      memberId,
      forceRefresh: forceRefresh,
    );
    if (sessions.isEmpty) return null;

    final lastSession = sessions.last;
    return await MemberService.getAIPrediction(
      memberId,
      lastSession['id'],
      forceRefresh: forceRefresh,
    );
  }
}
