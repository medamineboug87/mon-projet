import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import '../providers/prediction_provider.dart';

// ─── Design tokens light ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class SessionsHistoryScreen extends ConsumerWidget {
  final int memberId;

  const SessionsHistoryScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écouter les providers
    final sessionsAsync = ref.watch(sessionsProvider(memberId));
    final predictionsAsync = ref.watch(sessionsPredictionsProvider(memberId));

    if (sessionsAsync.isLoading) {
      return _buildLoadingScreen();
    }

    if (sessionsAsync.hasError) {
      return _buildErrorScreen(context, ref, sessionsAsync.error);
    }

    final sessions = sessionsAsync.valueOrNull ?? [];
    final predictions = predictionsAsync.valueOrNull ?? {};

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text(
          'Historique des séances',
          style: TextStyle(color: _kText),
        ),
        backgroundColor: const Color(0xFFEEF1F8),
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kText),
            onPressed: () => _refreshData(ref),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Text('Aucune séance', style: TextStyle(color: _kTextSub)),
            )
          : RefreshIndicator(
              onRefresh: () => _refreshData(ref),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final prediction = predictions[session['id']];
                  return _buildSessionTile(session, prediction);
                },
              ),
            ),
    );
  }

  // ✅ Correction #1: Écran de chargement sans Scaffold supplémentaire
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text(
          'Historique des séances',
          style: TextStyle(color: _kText),
        ),
        backgroundColor: const Color(0xFFEEF1F8),
      ),
      body: const Center(child: CircularProgressIndicator(color: Colors.green)),
    );
  }

  // ✅ Correction #2: Écran d'erreur SANS Scaffold double (retourne directement le Scaffold principal)
  // ⚠️ Cette méthode retourne un Widget, pas un Scaffold. Appelée dans le build principal.
  Widget _buildErrorScreen(BuildContext context, WidgetRef ref, Object? error) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text(
          'Historique des séances',
          style: TextStyle(color: _kText),
        ),
        backgroundColor: const Color(0xFFEEF1F8),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Impossible de charger l\'historique',
                style: TextStyle(color: _kText, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: _kTextSub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _refreshData(ref),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData(WidgetRef ref) async {
    ref.invalidate(sessionsProvider(memberId));
    ref.invalidate(sessionsPredictionsProvider(memberId));
  }

  Widget _buildSessionTile(
    Map<String, dynamic> session,
    Map<String, dynamic>? prediction,
  ) {
    final fatigue = prediction?['fatigue'];
    final injury = prediction?['injury'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.fitness_center, color: _kGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['date'] ?? 'N/A',
                    style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session['duration']}min • ${session['weightLifted']}kg',
                    style: const TextStyle(color: _kTextSub, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        iconColor: Colors.green,
        collapsedIconColor: _kTextSub,
        backgroundColor: const Color(0xFFEEF1F8),
        collapsedBackgroundColor: const Color(0xFFEEF1F8),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Durée', '${session['duration']} minutes'),
                _buildDetailRow(
                  'Poids soulevé',
                  '${session['weightLifted']} kg',
                ),
                if (session['targetMuscles'] != null &&
                    session['targetMuscles'].toString().isNotEmpty)
                  _buildDetailRow('Muscles ciblés', session['targetMuscles']),
                const Divider(color: _kBorder, height: 24),
                if (prediction != null) ...[
                  const Text(
                    'Résultats IA',
                    style: TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPredictionRow(
                    'Fatigue',
                    fatigue?['label'] ?? 'N/A',
                    (fatigue?['confidence'] ?? 0.0).toDouble(),
                  ),
                  const SizedBox(height: 8),
                  _buildPredictionRow(
                    'Risque de blessure',
                    injury?['label'] ?? 'N/A',
                    (injury?['confidence'] ?? 0.0).toDouble(),
                  ),
                ] else
                  const Text(
                    'Pas de prédiction IA',
                    style: TextStyle(color: _kTextSub),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(color: _kText, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(String label, String result, double confidence) {
    final isWarning = label == 'Fatigue'
        ? result.toLowerCase().contains('fatigué')
        : result.toLowerCase().contains('élevé');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning ? Colors.orange : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _kTextSub, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                result,
                style: TextStyle(
                  color: isWarning ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: _kText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
