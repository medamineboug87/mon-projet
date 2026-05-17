import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class CoachAIFeedbackService {
  // Récupérer les statistiques globales de précision
  static Future<Map<String, dynamic>?> getGlobalAccuracyStats() async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/ai/feedback/accuracy'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Récupérer les statistiques de précision par membre
  // ✅ FIX #29 : Paralléliser les appels HTTP avec Future.wait
  static Future<List<Map<String, dynamic>>> getMembersAccuracyStats() async {
    try {
      final token = await AuthService.getToken();

      final membersResponse = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/members'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (membersResponse.statusCode != 200) return [];

      final allMembers = jsonDecode(membersResponse.body) as List;

      // ✅ FIX #29 : Paralléliser avec Future.wait
      final statsResults = await Future.wait(
        allMembers.map((member) async {
          final memberId = member['id'];
          final memberName = member['fullName'];

          try {
            final response = await http
                .get(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/api/ai/feedback/accuracy/member/$memberId',
                  ),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                )
                .timeout(const Duration(seconds: 5));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              return {'memberId': memberId, 'memberName': memberName, ...data};
            }
          } catch (_) {
            // Ignorer l'erreur et retourner les valeurs par défaut
          }

          // Valeur par défaut en cas d'erreur
          return {
            'memberId': memberId,
            'memberName': memberName,
            'fatigue': {'accuracyValue': 0.0, 'accuracy': '0.0%'},
            'injury': {'accuracyValue': 0.0, 'accuracy': '0.0%'},
            'averageRating': null,
            'correctionsCount': 0,
          };
        }).toList(),
      );

      final List<Map<String, dynamic>> stats = List<Map<String, dynamic>>.from(
        statsResults,
      );

      // Trier par nombre de corrections décroissant
      stats.sort(
        (a, b) =>
            (b['correctionsCount'] ?? 0).compareTo(a['correctionsCount'] ?? 0),
      );
      return stats;
    } catch (e) {
      return [];
    }
  }

  // Récupérer les feedbacks récents par membre
  static Future<Map<int, List<Map<String, dynamic>>>>
  getRecentFeedbacksByMember() async {
    try {
      final token = await AuthService.getToken();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/ai/feedback/corrections?size=50',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return {};

      final data = jsonDecode(response.body);
      final feedbacks = data['data'] as List? ?? [];

      final Map<int, List<Map<String, dynamic>>> result = {};

      for (final fb in feedbacks) {
        final memberId = fb['memberId'];
        if (memberId != null) {
          result.putIfAbsent(memberId, () => []);
          result[memberId]!.add(fb);
        }
      }

      // Trier les feedbacks de chaque membre par date décroissante
      for (final entry in result.entries) {
        entry.value.sort((a, b) {
          final dateA = a['createdAt'] != null
              ? DateTime.tryParse(a['createdAt'].toString())
              : null;
          final dateB = b['createdAt'] != null
              ? DateTime.tryParse(b['createdAt'].toString())
              : null;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
      }

      return result;
    } catch (e) {
      return {};
    }
  }
}
