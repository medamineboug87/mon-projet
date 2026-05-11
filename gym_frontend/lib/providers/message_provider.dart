import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

// ── Conversation membre ↔ coach ──
final messagesProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  memberId,
) async {
  return await MessageService.getMemberMessages(memberId);
});

// ── Compteur générique non-lus par username ──
final unreadCountProvider = FutureProvider.family<int, String>((
  ref,
  username,
) async {
  return await MessageService.countUnread(username);
});

// ── Conversation membre ↔ admin ──
final memberAdminConversationProvider = FutureProvider<List<dynamic>>((
  ref,
) async {
  return await MessageService.getMemberAdminConversation();
});

// ── Membre : messages non lus du COACH uniquement ──
final memberUnreadFromCoachProvider = FutureProvider<int>((ref) async {
  final username = await AuthService.getUsername();
  if (username == null) return 0;
  return await MessageService.countUnreadFromCoach(username);
});

// ── Membre : messages non lus de l'ADMIN uniquement ──
final memberUnreadFromAdminProvider = FutureProvider<int>((ref) async {
  final username = await AuthService.getUsername();
  if (username == null) return 0;
  return await MessageService.countUnreadFromAdmin(username);
});

// ── Coach : messages non lus de l'ADMIN uniquement ──
final coachUnreadFromAdminProvider = FutureProvider<int>((ref) async {
  final username = await AuthService.getUsername();
  if (username == null) return 0;
  return await MessageService.countUnreadFromAdmin(username);
});

// ── Admin : total messages non lus ──
final adminUnreadCountProvider = FutureProvider<int>((ref) async {
  final username = await AuthService.getUsername();
  if (username == null) return 0;
  return await MessageService.countUnread(username);
});
