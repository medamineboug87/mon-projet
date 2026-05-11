import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class MessageService {
  // ── Headers helper ──
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ════════════════════════════════════════════════════════
  // MEMBRE ↔ COACH
  // ════════════════════════════════════════════════════════

  static Future<String?> getCoachUsername() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/coach-username'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['username'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getMemberUsername(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/member-username/$memberId'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['username'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getCoachUsernameById(int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/coach-username/$coachId'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['username'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> getMemberMessages(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/member/$memberId'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> sendMessage({
    required String senderUsername,
    required String receiverUsername,
    required int memberId,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages/send'),
        headers: await _headers(),
        body: jsonEncode({
          'senderUsername': senderUsername,
          'receiverUsername': receiverUsername,
          'memberId': memberId,
          'content': content,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Compteur global (toutes sources) ──
  static Future<int> countUnread(String username) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/unread/$username'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['unreadCount'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Compteur messages non lus du COACH uniquement ──
  static Future<int> countUnreadFromCoach(String username) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/unread/coach/$username'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['unreadCount'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Compteur messages non lus de l'ADMIN uniquement ──
  static Future<int> countUnreadFromAdmin(String username) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/unread/admin/$username'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['unreadCount'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markAsRead(int memberId, String username) async {
    try {
      await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/messages/member/$memberId/read/$username',
        ),
        headers: await _headers(),
      );
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════
  // MEMBRE → ADMIN
  // ════════════════════════════════════════════════════════

  static Future<bool> sendMessageToAdmin(String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages/member/send-to-admin'),
        headers: await _headers(),
        body: jsonEncode({'content': content}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getMemberAdminConversation() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/member/admin-conversation'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> markAdminMessagesAsRead() async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages/admin/read'),
        headers: await _headers(),
      );
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════
  // ADMIN → UTILISATEUR / BROADCAST
  // ════════════════════════════════════════════════════════

  static Future<bool> sendAdminMessageToUser({
    required String receiverUsername,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages/admin/send'),
        headers: await _headers(),
        body: jsonEncode({
          'receiverUsername': receiverUsername,
          'content': content,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> adminBroadcast({
    required String target,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/messages/admin/broadcast'),
        headers: await _headers(),
        body: jsonEncode({'target': target, 'content': content}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<dynamic>> getAdminConversationWithUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/admin/conversation/$userId'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getBroadcastHistory() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/messages/admin/broadcast/history'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (_) {
      return [];
    }
  }
}
