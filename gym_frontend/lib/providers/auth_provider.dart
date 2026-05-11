import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

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

// ✅ FIX #12 : logoutProvider correctement implémenté
// Appelé via ref.read(logoutProvider.notifier).logout()
class LogoutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> logout() async {
    await AuthService.logout();
    // Invalider tous les providers d'état
    ref.invalidate(isLoggedInProvider);
    ref.invalidate(roleProvider);
    ref.invalidate(memberIdProvider);
    ref.invalidate(coachIdProvider);
    ref.invalidate(usernameProvider);
    ref.invalidate(tokenProvider);
  }
}

final logoutProvider = AsyncNotifierProvider<LogoutNotifier, void>(
  LogoutNotifier.new,
);
