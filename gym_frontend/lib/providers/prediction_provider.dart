import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/member_service.dart';
import 'session_provider.dart';

/// Dernière prédiction IA pour un membre (basée sur sa dernière séance).
/// Retourne null si aucune séance ou si le service IA est indisponible.
final lastPredictionProvider = FutureProvider.family<Map<String, dynamic>?, int>((
  ref,
  memberId,
) async {
  // ✅ ref.watch (pas ref.read) : se recharge si sessionsProvider change
  final sessions = await ref.watch(sessionsProvider(memberId).future);
  if (sessions.isEmpty) return null;

  final lastSession = sessions.last;
  final prediction = await MemberService.getAIPrediction(
    memberId,
    lastSession['id'],
  );

  // Ne pas retourner une réponse d'erreur du service IA comme prédiction valide
  if (prediction != null && prediction.containsKey('error')) return null;
  return prediction;
});

/// Analyse de surcharge hebdomadaire (overload) extraite de la dernière prédiction.
final overloadAnalysisProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, memberId) async {
      // ✅ ref.watch : réactif aux changements de lastPredictionProvider
      final prediction = await ref.watch(
        lastPredictionProvider(memberId).future,
      );
      return prediction?['overload'];
    });

/// Toutes les prédictions IA pour toutes les séances d'un membre.
/// Les séances sans prédiction (service IA down) sont simplement ignorées.
final sessionsPredictionsProvider =
    FutureProvider.family<Map<int, Map<String, dynamic>>, int>((
      ref,
      memberId,
    ) async {
      // ✅ ref.watch : se recharge si la liste des séances change
      final sessions = await ref.watch(sessionsProvider(memberId).future);
      final predictions = <int, Map<String, dynamic>>{};

      // Paralléliser les appels pour ne pas attendre séquentiellement
      await Future.wait(
        sessions.map((session) async {
          try {
            final prediction = await MemberService.getAIPrediction(
              memberId,
              session['id'],
            );
            if (prediction != null && !prediction.containsKey('error')) {
              predictions[session['id'] as int] = prediction;
            }
          } catch (_) {
            // Service IA indisponible pour cette séance — on ignore
          }
        }),
      );

      return predictions;
    });
