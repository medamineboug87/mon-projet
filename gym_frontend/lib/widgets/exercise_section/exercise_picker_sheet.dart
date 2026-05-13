// lib/widgets/exercise_picker_sheet.dart

import 'package:flutter/material.dart';
import '../../services/exercise_library_service.dart';

class ExercisePickerSheet extends StatefulWidget {
  final String? muscleName;
  final Function(Map<String, dynamic>) onSelect;

  const ExercisePickerSheet({
    super.key,
    this.muscleName,
    required this.onSelect,
  });

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    List<Map<String, dynamic>> exercises;
    if (widget.muscleName != null && widget.muscleName!.isNotEmpty) {
      exercises = await ExerciseLibraryService.getExercisesByMuscle(
        widget.muscleName!,
      );
    } else {
      exercises = await ExerciseLibraryService.getAllExercises();
    }
    setState(() {
      _exercises = exercises;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredExercises {
    if (_searchQuery.isEmpty) return _exercises;
    return _exercises
        .where(
          (e) =>
              e['name']?.toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ==
                  true ||
              e['muscleName']?.toString().toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ==
                  true,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE2EE),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.fitness_center, color: Color(0xFF00897B)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Choisir un exercice',
                    style: TextStyle(
                      color: Color(0xFF1A2340),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B7A99)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Color(0xFF1A2340)),
              decoration: InputDecoration(
                hintText: 'Rechercher un exercice...',
                hintStyle: const TextStyle(color: Color(0xFF6B7A99)),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF6B7A99),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF4F6FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00897B)),
                  )
                : _filteredExercises.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun exercice trouvé',
                      style: TextStyle(color: Color(0xFF6B7A99)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (ctx, i) => _ExerciseCard(
                      exercise: _filteredExercises[i],
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(_filteredExercises[i]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasVideo = (exercise['videoUrl'] as String?)?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF00897B),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] ?? 'Exercice',
                        style: const TextStyle(
                          color: Color(0xFF1A2340),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            exercise['muscleName'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF6B7A99),
                              fontSize: 11,
                            ),
                          ),
                          if (hasVideo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE53935,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle,
                                    size: 10,
                                    color: Color(0xFFE53935),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Vidéo',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFFE53935),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (exercise['description'] != null &&
                          exercise['description'].toString().isNotEmpty)
                        Text(
                          exercise['description'],
                          style: const TextStyle(
                            color: Color(0xFF6B7A99),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF6B7A99),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
