// lib/services/member_profile_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class MemberProfileService {
  static Future<Map<String, dynamic>?> getProfile(int memberId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/members/$memberId/ai-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Erreur chargement profil IA: $e');
      return null;
    }
  }

  static Future<bool> isProfileComplete(int memberId) async {
    final profile = await getProfile(memberId);
    if (profile == null) return false;
    return profile['isComplete'] == true;
  }
}