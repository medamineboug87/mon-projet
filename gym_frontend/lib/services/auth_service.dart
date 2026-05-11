import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'logger_service.dart';

class AuthService {
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // ── Retry HTTP (uniquement sur erreurs serveur 5xx) ──
  static Future<http.Response> _retryHttpRequest(
    Future<http.Response> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final response = await request();
        // ✅ Ne pas retry sur 4xx (client error) — seulement 5xx
        if (response.statusCode < 500) return response;
        AppLogger.w(
          'Tentative ${attempts + 1} échouée avec status ${response.statusCode}',
        );
      } catch (e) {
        AppLogger.e('Erreur réseau lors de la tentative ${attempts + 1}', e);
      }
      attempts++;
      if (attempts < maxRetries) await Future.delayed(delay);
    }
    throw Exception('Échec après $maxRetries tentatives');
  }

  // ── LOGIN ──
  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    AppLogger.i('Tentative de connexion pour $identifier');
    try {
      final response = await _retryHttpRequest(
        () => http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'identifier': identifier, 'password': password}),
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'] ?? 'MEMBER';
        final memberId = data['memberId'] ?? 0;
        final coachId = data['coachId'] ?? 0;
        final username = data['username'] ?? '';

        final prefs = await _getPrefs();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setInt('memberId', memberId);
        await prefs.setInt('coachId', coachId);
        await prefs.setString('username', username);

        AppLogger.i('Connexion réussie pour $username (rôle: $role)');
        return {
          'success': true,
          'token': token,
          'role': role,
          'memberId': memberId,
          'coachId': coachId,
          'username': username,
        };
      }

      // ✅ FIX : gérer le cas 403 PENDING spécifiquement
      if (response.statusCode == 403) {
        try {
          final data = jsonDecode(response.body);
          final error = data['error'] ?? '';
          final message = data['message'] ?? 'Accès refusé';
          AppLogger.w('Login bloqué (403): $message');
          return {
            'success': false,
            'error': error, // "PENDING" → utilisé par login_screen
            'message': message,
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'FORBIDDEN',
            'message': 'Accès refusé',
          };
        }
      }

      AppLogger.w('Échec de connexion: status ${response.statusCode}');
      return {'success': false, 'message': 'Identifiants incorrects'};
    } catch (e) {
      AppLogger.e('Erreur lors de la connexion', e);
      return {
        'success': false,
        'message': 'Serveur inaccessible. Vérifiez votre connexion.',
      };
    }
  }

  // ── SAVE SESSION ──
  static Future<void> saveSession({
    required String token,
    required String role,
    required int memberId,
    required String username,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setInt('memberId', memberId);
    await prefs.setString('username', username);
  }

  // ── LOGOUT ──
  static Future<void> logout() async {
    AppLogger.i('Déconnexion de l\'utilisateur');
    final prefs = await _getPrefs();
    await prefs.clear();
    AppLogger.i('Session effacée');
  }

  // ── GETTERS ──
  static Future<bool> isLoggedIn() async =>
      (await _getPrefs()).getString('token') != null;
  static Future<String?> getToken() async =>
      (await _getPrefs()).getString('token');
  static Future<String?> getRole() async =>
      (await _getPrefs()).getString('role');
  static Future<int> getMemberId() async =>
      (await _getPrefs()).getInt('memberId') ?? 0;
  static Future<int> getCoachId() async =>
      (await _getPrefs()).getInt('coachId') ?? 0;
  static Future<String?> getUsername() async =>
      (await _getPrefs()).getString('username');
}
