// lib/widgets/exercise_section/exercise_form_dialog.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'exercise_entry_model.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Design tokens ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class ExerciseFormDialog extends StatefulWidget {
  final ExerciseEntry entry;
  final bool isEdit;
  final Function(ExerciseEntry) onSave;

  const ExerciseFormDialog({
    super.key,
    required this.entry,
    required this.isEdit,
    required this.onSave,
  });

  @override
  State<ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<ExerciseFormDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _rpeCtrl;
  late TextEditingController _restCtrl;
  late TextEditingController _notesCtrl;

  // ✅ NOUVEAU : pour la description et la vidéo (lecture seule)
  String _description = '';
  String _videoUrl = '';
  bool _isLoadingDetails = false;

  // Muscle (non modifiable en édition)
  String _muscleName = '';
  bool _failureReached = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.entry.exerciseName);
    _weightCtrl = TextEditingController(
      text: widget.entry.weightKg > 0 ? widget.entry.weightKg.toString() : '',
    );
    _setsCtrl = TextEditingController(
      text: widget.entry.setsCompleted.toString(),
    );
    _repsCtrl = TextEditingController(text: widget.entry.repsCompleted);
    _rpeCtrl = TextEditingController(
      text: widget.entry.rpe != null ? widget.entry.rpe.toString() : '',
    );
    _restCtrl = TextEditingController(
      text: widget.entry.restSeconds != null
          ? widget.entry.restSeconds.toString()
          : '90',
    );
    _notesCtrl = TextEditingController(text: widget.entry.notes ?? '');
    _muscleName = widget.entry.muscleName;
    _failureReached = widget.entry.failureReached ?? false;

    // ✅ NOUVEAU : charger les détails de l'exercice depuis l'API
    _loadExerciseDetails();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _rpeCtrl.dispose();
    _restCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// ✅ Charge la description et la vidéo depuis l'API
  Future<void> _loadExerciseDetails() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _isLoadingDetails = true);

    try {
      final token = await AuthService.getToken();
      final encodedName = Uri.encodeComponent(_nameCtrl.text.trim());
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/exercises/name/$encodedName'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _description = data['description'] ?? '';
          _videoUrl = data['videoUrl'] ?? '';
          _isLoadingDetails = false;
        });
      } else {
        setState(() => _isLoadingDetails = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  void _save() {
    final updatedEntry = ExerciseEntry(
      exerciseName: _nameCtrl.text.trim(),
      muscleName: _muscleName,
      weightKg: double.tryParse(_weightCtrl.text) ?? 0,
      setsCompleted: int.tryParse(_setsCtrl.text) ?? 3,
      repsCompleted: _repsCtrl.text.trim().isEmpty ? '10' : _repsCtrl.text,
      rpe: int.tryParse(_rpeCtrl.text),
      restSeconds: int.tryParse(_restCtrl.text) ?? 90,
      notes: _notesCtrl.text.trim().isEmpty ? '' : _notesCtrl.text,
      failureReached: _failureReached,
    );
    widget.onSave(updatedEntry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isEdit ? Icons.edit_rounded : Icons.add_rounded,
                    color: _kGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.isEdit
                        ? 'Modifier l\'exercice'
                        : 'Ajouter un exercice',
                    style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kTextSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),

          // Formulaire
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nom de l'exercice ──
                  _buildField(
                    _nameCtrl,
                    'Nom de l\'exercice *',
                    Icons.fitness_center_rounded,
                    enabled: !widget.isEdit, // ← non modifiable en édition
                  ),
                  const SizedBox(height: 14),

                  // ── Muscle cible (lecture seule en édition) ──
                  if (widget.isEdit) ...[
                    const Text(
                      'Muscle cible',
                      style: TextStyle(color: _kTextSub, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _kSurf2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fitness_center_rounded,
                            color: _kGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _muscleName,
                            style: const TextStyle(
                              color: _kText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Poids, séries, répétitions ──
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          _weightCtrl,
                          'Poids (kg)',
                          Icons.monitor_weight_rounded,
                          isNumber: true,
                          hint: 'Ex: 60.0',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          _setsCtrl,
                          'Séries',
                          Icons.repeat_rounded,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          _repsCtrl,
                          'Répétitions',
                          Icons.numbers_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── RPE ──
                  _buildField(
                    _rpeCtrl,
                    'RPE (effort ressenti 1-10)',
                    Icons.speed_rounded,
                    isNumber: true,
                    hint: 'Optionnel',
                  ),
                  const SizedBox(height: 14),

                  // ── Repos entre séries ──
                  _buildRestSelector(),
                  const SizedBox(height: 14),

                  // ── Échec musculaire ──
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Échec musculaire atteint',
                          style: TextStyle(
                            color: _kText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: _failureReached,
                        onChanged: (v) => setState(() => _failureReached = v),
                        activeColor: _kOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Notes ──
                  _buildField(
                    _notesCtrl,
                    'Notes (optionnel)',
                    Icons.note_alt_rounded,
                    maxLines: 2,
                    hint: 'Observations, sensations, points techniques...',
                  ),
                  const SizedBox(height: 20),

                  // ✅ NOUVEAU : Description et vidéo (lecture seule)
                  if (_isLoadingDetails)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: _kGreen,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  else if (_description.isNotEmpty || _videoUrl.isNotEmpty) ...[
                    const Divider(color: _kBorder),
                    const SizedBox(height: 12),
                    const Text(
                      '📖 Détails de l\'exercice',
                      style: TextStyle(
                        color: _kText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_description.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kSurf2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: 14,
                                  color: _kGreen,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Technique / Description',
                                  style: TextStyle(
                                    color: _kGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _description,
                              style: const TextStyle(
                                color: _kTextSub,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_videoUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final uri = Uri.tryParse(_videoUrl);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _kOrange.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _kOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vidéo de démonstration',
                                      style: TextStyle(
                                        color: _kOrange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Appuyez pour regarder',
                                      style: TextStyle(
                                        color: _kTextSub,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new,
                                color: _kOrange,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // ── Boutons ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _kBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(color: _kTextSub),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text(
                            'Mettre à jour',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool enabled = true,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 12),
        hintStyle: const TextStyle(color: _kBorder, fontSize: 12),
        prefixIcon: Icon(icon, color: _kGreen, size: 18),
        filled: true,
        fillColor: enabled ? _kSurf2 : _kSurf2.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRestSelector() {
    final restOptions = [30, 60, 90, 120, 180, 240, 300];
    int currentRest = int.tryParse(_restCtrl.text) ?? 90;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repos entre séries',
          style: TextStyle(color: _kTextSub, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: restOptions.map((seconds) {
            final isSelected = currentRest == seconds;
            final minutes = seconds ~/ 60;
            final remainingSeconds = seconds % 60;
            String label;
            if (minutes > 0 && remainingSeconds > 0) {
              label = '${minutes}min${remainingSeconds}s';
            } else if (minutes > 0) {
              label = '${minutes}min';
            } else {
              label = '${seconds}s';
            }
            return GestureDetector(
              onTap: () => setState(() => _restCtrl.text = seconds.toString()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _kGreen.withValues(alpha: 0.12) : _kSurf2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _kGreen : _kBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? _kGreen : _kTextSub,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
