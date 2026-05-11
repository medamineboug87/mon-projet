import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class PaymentService {
  static const Map<String, Map<String, dynamic>> plans = {
    'BASIC': {'name': 'BASIC', 'price': 60.0, 'duration': '1 mois'},
    'STANDARD': {'name': 'STANDARD', 'price': 150.0, 'duration': '3 mois'},
    'PREMIUM': {'name': 'PREMIUM', 'price': 300.0, 'duration': '6 mois'},
    'ANNUAL': {'name': 'ANNUAL', 'price': 490.0, 'duration': '12 mois'},
  };

  // ✅ Paiement en ligne simulé (Mastercard/Visa/D17)
  static Future<Map<String, dynamic>?> simulateOnlinePayment({
    required int memberId,
    required String subscriptionType,
    required double amount,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/payments/simulate"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "memberId": memberId,
          "subscriptionType": subscriptionType,
          "amount": amount,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ✅ Paiement en espèces
  static Future<Map<String, dynamic>?> cashPayment({
    required int memberId,
    required String subscriptionType,
  }) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/payments/cash"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "memberId": memberId,
          "subscriptionType": subscriptionType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
