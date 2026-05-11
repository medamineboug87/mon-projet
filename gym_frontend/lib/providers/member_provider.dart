import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/member_service.dart';

final memberProvider = FutureProvider.family<Map<String, dynamic>?, int>((
  ref,
  memberId,
) async {
  return await MemberService.getMemberById(memberId);
});

final memberProfileProvider = FutureProvider.family<Map<String, dynamic>?, int>(
  (ref, memberId) async {
    return await MemberService.getMemberProfile(memberId);
  },
);
