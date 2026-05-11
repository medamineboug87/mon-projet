import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  // ── Stats globales ──
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/stats"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Tous les coachs ──
  static Future<List<dynamic>> getAllCoaches() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/coaches"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Tous les membres ──
  static Future<List<dynamic>> getAllMembers() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/members"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Créer un coach ──
  static Future<Map<String, dynamic>> createCoach({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String phone,
    required int experience,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/admin/coaches"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
          "fullName": fullName,
          "email": email,
          "phone": phone,
          "experience": experience,
        }),
      );
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      final error = jsonDecode(response.body);
      return {"success": false, "message": error['error'] ?? 'Erreur'};
    } catch (e) {
      return {"success": false, "message": "Serveur inaccessible"};
    }
  }

  // ── Supprimer un coach ──
  static Future<bool> deleteCoach(int coachId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/admin/coaches/$coachId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Supprimer un membre ──
  static Future<bool> deleteMember(int memberId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/admin/members/$memberId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
