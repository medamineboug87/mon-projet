import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

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

  // Récupérer l'historique des abonnements d'un membre
  static Future<List<dynamic>> getMemberSubscriptions(int memberId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/subscriptions/member/$memberId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Ton backend retourne directement une List<Subscription>
        if (data is List) {
          return data;
        }
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Erreur dans getMemberSubscriptions: $e');
      return [];
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
