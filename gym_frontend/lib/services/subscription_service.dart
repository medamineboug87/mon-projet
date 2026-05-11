import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class SubscriptionService {
  // Récupérer abonnement actif
  static Future<Map<String, dynamic>?> getActiveSubscription(
    int memberId,
  ) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/subscriptions/member/$memberId/active"),
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

  // Renouveler abonnement
  static Future<bool> renewSubscription(int subscriptionId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/subscriptions/$subscriptionId/renew"),
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

  // Annuler abonnement
  static Future<bool> cancelSubscription(int subscriptionId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/subscriptions/$subscriptionId/cancel"),
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
