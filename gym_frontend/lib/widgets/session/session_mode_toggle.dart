import 'package:flutter/material.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class SessionModeToggle extends StatelessWidget {
  final bool useDetailedExercises;
  final int exerciseCount;
  final ValueChanged<bool> onToggle;

  const SessionModeToggle({
    super.key,
    required this.useDetailedExercises,
    required this.exerciseCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: useDetailedExercises ? _kGreen.withValues(alpha: 0.5) : _kBorder,
          width: useDetailedExercises ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.list_alt_rounded, color: _kGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saisie exercices détaillée', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w800)),
                      Text(
                        useDetailedExercises
                            ? '$exerciseCount exercice(s) • Prédiction IA plus précise'
                            : 'Activez pour saisir poids réel par exercice',
                        style: TextStyle(color: useDetailedExercises ? _kGreen : _kTextSub, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(value: useDetailedExercises, onChanged: onToggle, activeColor: _kGreen),
              ],
            ),
          ),
          if (!useDetailedExercises)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: _kBlue, size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La saisie détaillée permet à l\'IA d\'analyser la charge réelle par muscle (RPE, volume, échec musculaire).',
                        style: TextStyle(color: _kBlue, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}