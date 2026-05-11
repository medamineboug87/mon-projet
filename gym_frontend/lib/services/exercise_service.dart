import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ExerciseService {
  // ── GET exercices par muscle ──
  // FIX : utiliser Uri.encodeComponent pour gérer les accents français
  // (Épaules, Abdominaux, Ischio-jambiers, etc.)
  static Future<List<dynamic>> getExercisesByMuscle(String muscleName) async {
    try {
      final token = await AuthService.getToken();

      // Encoder correctement le nom du muscle (accents, tirets, espaces)
      final encodedMuscle = Uri.encodeComponent(muscleName);

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/exercises/muscle/$encodedMuscle'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // S'assurer que c'est bien une liste
        if (data is List) return data;
        return [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getAllExercises() async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/exercises'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
