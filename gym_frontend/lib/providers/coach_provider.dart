import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/coach_service.dart';

final allMembersProvider = FutureProvider<List<dynamic>>((ref) async {
  return await CoachService.getAllMembers();
});

/// Récupère les dernières prédictions IA de tous les membres.
/// Si le service IA est down pour un membre, on ignore silencieusement.
final allMembersPredictionsProvider =
    FutureProvider<Map<int, Map<String, dynamic>>>((ref) async {
      final members = await ref.watch(allMembersProvider.future);
      final predictions = <int, Map<String, dynamic>>{};

      await Future.wait(
        members.map((member) async {
          try {
            final pred = await CoachService.getLastSessionPrediction(
              member['id'],
            );
            if (pred != null && !pred.containsKey('error')) {
              predictions[member['id'] as int] = pred;
            }
          } catch (_) {
            // Service IA indisponible pour ce membre — on passe
          }
        }),
      );

      return predictions;
    });

final memberSessionsForCoachProvider =
    FutureProvider.family<List<dynamic>, int>((ref, memberId) async {
      return await CoachService.getMemberSessions(memberId);
    });

final memberLastPredictionForCoachProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, memberId) async {
      try {
        final pred = await CoachService.getLastSessionPrediction(memberId);
        if (pred != null && pred.containsKey('error')) return null;
        return pred;
      } catch (_) {
        return null;
      }
    });
