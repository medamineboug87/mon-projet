import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class AdminService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Stats globales ──
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/stats'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Tous les coachs ──
  static Future<List<dynamic>> getAllCoaches() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/coaches'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Coach par ID ──
  static Future<Map<String, dynamic>?> getCoachById(int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/coaches/$coachId'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Tous les membres ──
  static Future<List<dynamic>> getAllMembers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/members'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/coaches'),
        headers: await _headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'experience': experience,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['error'] ?? 'Erreur'};
    } catch (_) {
      return {'success': false, 'message': 'Serveur inaccessible'};
    }
  }

  // ════════════════════════════════════════════════════════
  // ── MODIFIER UN COACH ──
  // ════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> updateCoach({
    required int coachId,
    required String fullName,
    required String email,
    required String phone,
    required int experience,
  }) async {
    try {
      // Basic validations on the client side too
      if (fullName.trim().isEmpty) {
        return {'success': false, 'message': 'Le nom complet est requis'};
      }
      if (email.trim().isEmpty || !email.contains('@')) {
        return {'success': false, 'message': 'Email invalide'};
      }
      if (experience < 0) {
        return {
          'success': false,
          'message': "L'expérience ne peut pas être négative",
        };
      }

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/admin/coaches/$coachId'),
            headers: await _headers(),
            body: jsonEncode({
              'fullName': fullName.trim(),
              'email': email.trim().toLowerCase(),
              'phone': phone.trim(),
              'experience': experience,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Coach mis à jour',
        };
      }
      try {
        final err = jsonDecode(response.body);
        return {
          'success': false,
          'message': err['error'] ?? 'Erreur de mise à jour',
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Serveur inaccessible'};
    }
  }

  // ════════════════════════════════════════════════════════
  // ── ACTIVER / DÉSACTIVER UN COACH ──
  // ════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> toggleCoachActive(int coachId) async {
    try {
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/admin/coaches/$coachId/toggle-active',
            ),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'active': data['active'],
          'message': data['message'],
        };
      }
      try {
        final err = jsonDecode(response.body);
        return {'success': false, 'message': err['error'] ?? 'Erreur'};
      } catch (_) {
        return {'success': false, 'message': 'Erreur serveur'};
      }
    } catch (_) {
      return {'success': false, 'message': 'Serveur inaccessible'};
    }
  }

  // ════════════════════════════════════════════════════════
  // ── HISTORIQUE DES MODIFICATIONS ──
  // ════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>?> getCoachHistory(int coachId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/admin/coaches/$coachId/history'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Supprimer un coach ──
  static Future<bool> deleteCoach(int coachId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/coaches/$coachId'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Supprimer un membre ──
  static Future<bool> deleteMember(int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/admin/members/$memberId'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
