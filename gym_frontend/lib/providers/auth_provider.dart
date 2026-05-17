import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/coach_provider.dart'; // ✅ allMembersProvider & allMembersPredictionsProvider

// Provider pour le token
final tokenProvider = StateProvider<String?>((ref) => null);

// Provider pour savoir si l'utilisateur est connecté
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  return await AuthService.isLoggedIn();
});

// Provider pour le rôle
final roleProvider = FutureProvider<String?>((ref) async {
  return await AuthService.getRole();
});

// Provider pour le memberId
final memberIdProvider = FutureProvider<int>((ref) async {
  return await AuthService.getMemberId();
});

// Provider pour le username
final usernameProvider = FutureProvider<String?>((ref) async {
  return await AuthService.getUsername();
});

// Provider pour le coachId
final coachIdProvider = FutureProvider<int>((ref) async {
  return await AuthService.getCoachId();
});

// Action pour le login
final loginProvider =
    FutureProvider.family<
      Map<String, dynamic>,
      ({String identifier, String password})
    >((ref, input) async {
      return await AuthService.login(input.identifier, input.password);
    });

// ✅ FIX #12 & #21 : LogoutNotifier avec type correct
class LogoutNotifier extends AsyncNotifier<dynamic> {
  @override
  Future<dynamic> build() async => null;

  Future<void> logout() async {
    await AuthService.logout();

    // Invalider tous les providers d'authentification
    ref.invalidate(isLoggedInProvider);
    ref.invalidate(roleProvider);
    ref.invalidate(memberIdProvider);
    ref.invalidate(coachIdProvider);
    ref.invalidate(usernameProvider);
    ref.invalidate(tokenProvider);

    // Invalider les données métier
    ref.invalidate(allMembersProvider);
    ref.invalidate(allMembersPredictionsProvider);
  }
}

// ✅ Correction du type : dynamic au lieu de void
final logoutProvider = AsyncNotifierProvider<LogoutNotifier, dynamic>(
  LogoutNotifier.new,
);
