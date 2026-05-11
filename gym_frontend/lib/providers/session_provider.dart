import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/member_service.dart';

final sessionsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  memberId,
) async {
  return await MemberService.getMemberSessions(memberId);
});

final recentSessionsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  memberId,
) async {
  final sessions = await MemberService.getMemberSessions(memberId);
  return sessions.reversed.take(5).toList();
});
