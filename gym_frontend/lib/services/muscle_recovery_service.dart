// lib/services/muscle_recovery_service.dart
// Service Flutter pour l'API de récupération musculaire

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class MuscleRecoveryService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/ai/recovery/{memberId}
  /// Retourne le statut de récupération musculaire complet
  static Future<Map<String, dynamic>> getRecoveryStatus(int memberId) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/ai/recovery/$memberId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 404) {
        throw Exception('Aucune donnée de récupération disponible.');
      }

      throw Exception('Erreur serveur (${response.statusCode})');
    } on http.ClientException {
      throw Exception('Connexion impossible. Vérifiez votre réseau.');
    }
  }
}
