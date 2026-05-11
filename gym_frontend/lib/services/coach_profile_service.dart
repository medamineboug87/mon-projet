import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class CoachProfileService {
  // Récupérer profil coach par coachId
  static Future<Map<String, dynamic>?> getCoachProfile(int coachId) async {
    try {
      final token = await AuthService.getToken();
      AppLogger.d('📡 GET /coaches/profile/$coachId');

      final response = await http
          .get(
            Uri.parse("${ApiConfig.baseUrl}/coaches/profile/$coachId"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      AppLogger.d('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.i('✅ Profil coach chargé: ${data['fullName']}');
        return data;
      }
      AppLogger.w('❌ Erreur ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      AppLogger.e('❌ Erreur getCoachProfile', e);
      return null;
    }
  }

  // Modifier profil coach
  static Future<bool> updateCoachProfile(
    int coachId,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await AuthService.getToken();
      AppLogger.d('📡 PUT /coaches/profile/$coachId');

      final response = await http
          .put(
            Uri.parse("${ApiConfig.baseUrl}/coaches/profile/$coachId"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      AppLogger.d('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.i('✅ Profil coach mis à jour');
        return true;
      }
      AppLogger.w('❌ Erreur ${response.statusCode}: ${response.body}');
      return false;
    } catch (e) {
      AppLogger.e('❌ Erreur updateCoachProfile', e);
      return false;
    }
  }
}
