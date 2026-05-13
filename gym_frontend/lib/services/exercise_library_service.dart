// lib/services/exercise_library_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ExerciseLibraryService {
  static Future<List<Map<String, dynamic>>> getExercisesByMuscle(
    String muscleName,
  ) async {
    try {
      final token = await AuthService.getToken();
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Erreur chargement exercices: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllExercises() async {
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
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Erreur chargement tous les exercices: $e');
      return [];
    }
  }
}
