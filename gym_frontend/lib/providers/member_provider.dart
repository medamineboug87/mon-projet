// lib/providers/member_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/member_service.dart';
import '../services/auth_service.dart';

final memberProvider = FutureProvider.family<Map<String, dynamic>?, int>((
  ref,
  memberId,
) async {
  if (memberId == 0) return null;
  return await MemberService.getMemberById(memberId);
});

final memberProfileProvider = FutureProvider.family<Map<String, dynamic>?, int>(
  (ref, memberId) async {
    if (memberId == 0) return null;
    return await MemberService.getMemberProfile(memberId);
  },
);

// ✅ FIX : lit le memberId depuis AuthService (SharedPreferences)
final memberIdProvider = FutureProvider<int>((ref) async {
  return await AuthService.getMemberId();
});
