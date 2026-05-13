import 'package:flutter/material.dart';
import 'exercise_entry_model.dart';
import 'exercise_card.dart';

// ─── Design tokens ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class ExerciseList extends StatelessWidget {
  final List<ExerciseEntry> exercises;
  final Set<String> selectedMuscles;
  final VoidCallback onAddExercise;
  final Function(int, ExerciseEntry) onEditExercise;
  final Function(int) onRemoveExercise;

  const ExerciseList({
    super.key,
    required this.exercises,
    required this.selectedMuscles,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onRemoveExercise,
  });

  Set<String> get _musclesFromExercises {
    return exercises
        .where((e) => e.muscleName.isNotEmpty)
        .map((e) => e.muscleName)
        .toSet();
  }

  double get _totalVolume => exercises.fold(0.0, (sum, e) => sum + e.totalVolume);
  double get _maxWeight => exercises.isEmpty ? 0.0 : exercises.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    final hasMuscleSelected = exercises.isNotEmpty
        ? exercises.last.muscleName.isNotEmpty
        : selectedMuscles.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (exercises.isEmpty)
            _buildEmptyState()
          else
            ...exercises.asMap().entries.map(
              (entry) => ExerciseCard(
                index: entry.key,
                exercise: entry.value,
                onEdit: () => onEditExercise(entry.key, entry.value),
                onDelete: () => onRemoveExercise(entry.key),
              ),
            ),
          _buildAddButton(hasMuscleSelected),
          if (_musclesFromExercises.isNotEmpty) _buildMusclesChips(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center_rounded, color: _kGreen, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Exercices de la séance',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const Spacer(),
          if (exercises.isNotEmpty) ...[
            _MiniStatBadge('${_maxWeight.toStringAsFixed(0)}kg max', _kBlue),
            const SizedBox(width: 6),
            _MiniStatBadge('${_totalVolume.toStringAsFixed(0)} vol.', _kOrange),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: _kGreen, size: 48),
            SizedBox(height: 12),
            Text('Aucun exercice ajouté', style: TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 13)),
            SizedBox(height: 4),
            Text('Ajoutez vos exercices avec le poids utilisé', style: TextStyle(color: _kTextSub, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(bool hasMuscleSelected) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: hasMuscleSelected ? onAddExercise : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hasMuscleSelected ? _kGreen.withValues(alpha: 0.08) : _kBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasMuscleSelected ? _kGreen.withValues(alpha: 0.3) : _kBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: hasMuscleSelected ? _kGreen : _kTextSub, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ajouter un exercice',
                style: TextStyle(
                  color: hasMuscleSelected ? _kGreen : _kTextSub,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMusclesChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Muscles travaillés', style: TextStyle(color: _kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: _musclesFromExercises
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGreenL,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                      ),
                      child: Text(m, style: const TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MiniStatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniStatBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}