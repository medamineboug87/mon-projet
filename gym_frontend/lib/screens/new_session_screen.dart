// lib/screens/new_session_screen.dart
// Flow repensé : 3 étapes fluides sans navigation parasites

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/member_service.dart';
import '../services/auth_service.dart';
import '../services/member_profile_service.dart';
import '../widgets/session/session_prediction_card.dart';
import '../widgets/exercise_section/exercise_entry_model.dart';
import '../widgets/exercise_section/exercise_form_dialog.dart';
import '../widgets/exercise_section/exercise_picker_sheet.dart';
import '../config/api_config.dart';
import 'unified_profile_screen.dart';

// ─── Design tokens ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

// ─── Muscles disponibles ───
const List<Map<String, dynamic>> _kMuscleGroups = [
  {
    'group': 'Haut du corps',
    'muscles': [
      {'name': 'Pectoraux', 'emoji': '💪', 'color': 0xFF1976D2},
      {'name': 'Dorsaux', 'emoji': '🏋️', 'color': 0xFF00897B},
      {'name': 'Épaules', 'emoji': '🔺', 'color': 0xFF7B1FA2},
      {'name': 'Biceps', 'emoji': '💪', 'color': 0xFFF57C00},
      {'name': 'Triceps', 'emoji': '💪', 'color': 0xFFE53935},
      {'name': 'Trapèzes', 'emoji': '🔝', 'color': 0xFF0288D1},
      {'name': 'Abdominaux', 'emoji': '⬡', 'color': 0xFF388E3C},
      {'name': 'Lombaires', 'emoji': '🔙', 'color': 0xFF6D4C41},
    ],
  },
  {
    'group': 'Bas du corps',
    'muscles': [
      {'name': 'Quadriceps', 'emoji': '🦵', 'color': 0xFF1976D2},
      {'name': 'Ischio-jambiers', 'emoji': '🦵', 'color': 0xFF7B1FA2},
      {'name': 'Fessiers', 'emoji': '🍑', 'color': 0xFFF57C00},
      {'name': 'Mollets', 'emoji': '🦶', 'color': 0xFF00897B},
    ],
  },
];

// ─── Types cardio ───
const List<Map<String, dynamic>> _kCardioTypes = [
  {'name': 'Course', 'emoji': '🏃', 'color': 0xFF00897B},
  {'name': 'Vélo', 'emoji': '🚴', 'color': 0xFF1976D2},
  {'name': 'HIIT', 'emoji': '⚡', 'color': 0xFFE53935},
  {'name': 'Natation', 'emoji': '🏊', 'color': 0xFF0288D1},
  {'name': 'Elliptique', 'emoji': '🔄', 'color': 0xFF7B1FA2},
  {'name': 'Rameur', 'emoji': '🚣', 'color': 0xFFF57C00},
  {'name': 'Marche', 'emoji': '🚶', 'color': 0xFF388E3C},
  {'name': 'Corde', 'emoji': '🪢', 'color': 0xFFE53935},
];

class NewSessionScreen extends StatefulWidget {
  final int memberId;
  const NewSessionScreen({super.key, required this.memberId});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen>
    with TickerProviderStateMixin {
  // ── Stepper ──
  int _step = 0; // 0=muscles, 1=détails, 2=résultat
  late AnimationController _stepAnim;
  late Animation<double> _fadeAnim;

  // ── Étape 1 : muscles ──
  final Set<String> _selectedMuscles = {};
  bool _hasCardio = false;
  String _cardioType = 'Course';

  // ── Étape 2 : détails ──
  final _durationCtrl = TextEditingController();
  final _cardioDurCtrl = TextEditingController();
  int _cardioIntensity = 5;
  int _painLevel = 0;
  bool _warmupDone = true;
  List<ExerciseEntry> _exercises = [];

  // ── Résultat ──
  bool _isLoading = false;
  Map<String, dynamic>? _prediction;

  // ── Profil ──
  bool _profileComplete = false;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut);
    _stepAnim.forward();
    _checkProfile();
  }

  @override
  void dispose() {
    _stepAnim.dispose();
    _durationCtrl.dispose();
    _cardioDurCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkProfile() async {
    final profile = await MemberProfileService.getProfile(widget.memberId);
    if (mounted)
      setState(() => _profileComplete = profile?['isComplete'] == true);
  }

  void _goToStep(int step) {
    _stepAnim.reverse().then((_) {
      setState(() => _step = step);
      _stepAnim.forward();
    });
  }

  bool get _canProceed => _selectedMuscles.isNotEmpty || _hasCardio;

  // ── Exercices ──
  void _showPickerForMuscle(String muscle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExercisePickerSheet(
        muscleName: muscle,
        onSelect: (exercise) {
          setState(() {
            _exercises.add(
              ExerciseEntry(
                exerciseName: exercise['name'] ?? '',
                muscleName: exercise['muscleName'] ?? muscle,
                weightKg: 0.0,
                setsCompleted: 3,
                repsCompleted: '10',
              ),
            );
          });
          _showEditExercise(_exercises.length - 1);
        },
      ),
    );
  }

  void _showEditExercise(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseFormDialog(
        entry: _exercises[index],
        isEdit: true,
        onSave: (saved) => setState(() => _exercises[index] = saved),
      ),
    );
  }

  // ── Soumission ──
  Future<void> _submit() async {
    if (_durationCtrl.text.trim().isEmpty) {
      _snack('Entrez la durée de la séance');
      return;
    }

    setState(() => _isLoading = true);

    final targetMuscles = _exercises.isNotEmpty
        ? _exercises.map((e) => e.muscleName).toSet().join(', ')
        : _selectedMuscles.join(', ');

    final maxWeight = _exercises.isNotEmpty
        ? _exercises.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final sessionData = {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'duration': int.tryParse(_durationCtrl.text) ?? 0,
      'intensity': 5,
      'weightLifted': maxWeight,
      'targetMuscles': targetMuscles,
      'hasCardio': _hasCardio,
      'cardioDurationMinutes': _hasCardio
          ? (int.tryParse(_cardioDurCtrl.text) ?? 0)
          : 0,
      'cardioType': _hasCardio ? _cardioType : '',
      'cardioIntensity': _hasCardio ? _cardioIntensity : 0,
      'painLevel': _painLevel,
      'warmupDone': _warmupDone,
    };

    final result = await MemberService.createSession(
      widget.memberId,
      sessionData,
    );

    if (result['success'] == true) {
      final sessionId = result['session']['id'] as int;
      // FIX #14 : _saveExercises gère maintenant les erreurs et notifie l'utilisateur
      if (_exercises.isNotEmpty) await _saveExercises(sessionId);
      final prediction = await MemberService.getAIPrediction(
        widget.memberId,
        sessionId,
      );
      setState(() {
        _prediction = prediction;
        _isLoading = false;
      });
      _goToStep(2);
    } else {
      setState(() => _isLoading = false);
      _snack(result['message'] ?? 'Erreur lors de l\'enregistrement');
    }
  }

  // FIX #14 : erreur de sauvegarde des exercices explicitement remontée à l'utilisateur
  Future<void> _saveExercises(int sessionId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/sessions/$sessionId/exercises/bulk',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(
              _exercises
                  .asMap()
                  .entries
                  .map((e) => {...e.value.toJson(), 'exerciseOrder': e.key + 1})
                  .toList(),
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && mounted) {
        _snack(
          'Exercices non sauvegardés (erreur ${response.statusCode}). La séance a été enregistrée.',
        );
      }
    } catch (e) {
      if (mounted) {
        _snack(
          'Exercices non sauvegardés : vérifiez votre connexion. La séance a été enregistrée.',
        );
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _kOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _step == 0
            ? _buildStep0()
            : _step == 1
            ? _buildStep1()
            : _buildStep2(),
      ),
      bottomNavigationBar: _step < 2 ? _buildBottomBar() : null,
    );
  }

  AppBar _buildAppBar() {
    final titles = ['Muscles ciblés', 'Détails de la séance', 'Analyse IA'];
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titles[_step],
            style: const TextStyle(
              color: _kText,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (_step < 2)
            Text(
              'Étape ${_step + 1} sur 2',
              style: const TextStyle(color: _kTextSub, fontSize: 11),
            ),
        ],
      ),
      backgroundColor: _kSurface,
      iconTheme: const IconThemeData(color: _kText),
      elevation: 0,
      bottom: _step < 2
          ? PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: _StepProgressBar(step: _step, total: 2),
            )
          : null,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_step == 1) ...[
            OutlinedButton(
              onPressed: () => _goToStep(0),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kTextSub,
                side: const BorderSide(color: _kBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _step == 0
                  ? (_canProceed ? () => _goToStep(1) : null)
                  : (_isLoading ? null : _submit),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                disabledBackgroundColor: _kBorder,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _step == 0 ? 'Continuer' : 'Enregistrer la séance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // ÉTAPE 0 — MUSCLES
  // ══════════════════════════════════════════════════

  Widget _buildStep0() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_profileComplete)
          _WarningBanner(
            message:
                'Complétez votre profil IA pour des prédictions plus précises.',
            actionLabel: 'Compléter',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UnifiedProfileScreen(memberId: widget.memberId),
              ),
            ).then((_) => _checkProfile()),
          ),

        ..._kMuscleGroups.map(
          (group) => _MuscleGroupSection(
            groupName: group['group'] as String,
            muscles: (group['muscles'] as List).cast<Map<String, dynamic>>(),
            selectedMuscles: _selectedMuscles,
            onToggle: (muscle) => setState(() {
              _selectedMuscles.contains(muscle)
                  ? _selectedMuscles.remove(muscle)
                  : _selectedMuscles.add(muscle);
            }),
          ),
        ),

        const SizedBox(height: 8),

        _CardioToggleCard(
          hasCardio: _hasCardio,
          cardioType: _cardioType,
          onToggle: (v) => setState(() => _hasCardio = v),
          onSelectType: (type) => setState(() => _cardioType = type),
        ),

        if (_selectedMuscles.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SelectionSummary(muscles: _selectedMuscles),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // ÉTAPE 1 — DÉTAILS
  // ══════════════════════════════════════════════════

  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          icon: Icons.timer_rounded,
          color: _kGreen,
          title: 'Durée de la séance',
          child: _InputField(
            controller: _durationCtrl,
            hint: 'Ex : 60',
            suffix: 'min',
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 14),

        if (_selectedMuscles.isNotEmpty) ...[
          _ExercisesSection(
            muscles: _selectedMuscles,
            exercises: _exercises,
            onAddForMuscle: _showPickerForMuscle,
            onEdit: _showEditExercise,
            onRemove: (i) => setState(() => _exercises.removeAt(i)),
          ),
          const SizedBox(height: 14),
        ],

        if (_hasCardio) ...[
          _SectionCard(
            icon: Icons.favorite_rounded,
            color: _kPurple,
            title: 'Cardio — $_cardioType',
            child: Column(
              children: [
                _InputField(
                  controller: _cardioDurCtrl,
                  hint: 'Ex : 20',
                  suffix: 'min',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _IntensitySlider(
                  label: 'Intensité cardio',
                  value: _cardioIntensity,
                  min: 1,
                  max: 10,
                  onChanged: (v) => setState(() => _cardioIntensity = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        _SectionCard(
          icon: Icons.sentiment_satisfied_alt_rounded,
          color: _kOrange,
          title: 'Ressenti post-séance',
          child: Column(
            children: [
              _WarmupRow(
                value: _warmupDone,
                onChanged: (v) => setState(() => _warmupDone = v),
              ),
              const SizedBox(height: 16),
              _IntensitySlider(
                label: 'Douleur ressentie',
                value: _painLevel,
                min: 0,
                max: 10,
                onChanged: (v) => setState(() => _painLevel = v),
                colorFn: (v) => v == 0
                    ? _kGreen
                    : v <= 3
                    ? const Color(0xFF69F0AE)
                    : v <= 6
                    ? _kOrange
                    : _kRed,
                labelFn: (v) => v == 0
                    ? 'Aucune'
                    : v <= 3
                    ? 'Légère'
                    : v <= 6
                    ? 'Modérée'
                    : 'Intense',
              ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // ÉTAPE 2 — RÉSULTAT
  // ══════════════════════════════════════════════════

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGreen, Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Séance enregistrée !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_selectedMuscles.join(' • ')}${_hasCardio ? ' • $_cardioType' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_prediction != null) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Analyse IA',
                style: TextStyle(
                  color: _kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SessionPredictionCard(prediction: _prediction!),
            const SizedBox(height: 20),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: const Text(
                'Retour au tableau de bord',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// SOUS-WIDGETS
// ══════════════════════════════════════════════════

class _StepProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const _StepProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 2 : 0),
            decoration: BoxDecoration(
              color: active ? _kGreen : _kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _MuscleGroupSection extends StatelessWidget {
  final String groupName;
  final List<Map<String, dynamic>> muscles;
  final Set<String> selectedMuscles;
  final void Function(String) onToggle;

  const _MuscleGroupSection({
    required this.groupName,
    required this.muscles,
    required this.selectedMuscles,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Text(
            groupName.toUpperCase(),
            style: const TextStyle(
              color: _kTextSub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
          children: muscles.map((m) {
            final name = m['name'] as String;
            final isSelected = selectedMuscles.contains(name);
            final color = Color(m['color'] as int);
            return _MuscleChip(
              name: name,
              emoji: m['emoji'] as String,
              color: color,
              isSelected: isSelected,
              onTap: () => onToggle(name),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _MuscleChip({
    required this.name,
    required this.emoji,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : _kBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? color : _kTextSub,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardioToggleCard extends StatelessWidget {
  final bool hasCardio;
  final String cardioType;
  final void Function(bool) onToggle;
  final void Function(String) onSelectType;

  const _CardioToggleCard({
    required this.hasCardio,
    required this.cardioType,
    required this.onToggle,
    required this.onSelectType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCardio
              ? const Color(0xFF7B1FA2).withValues(alpha: 0.4)
              : _kBorder,
          width: hasCardio ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFF7B1FA2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cardio',
                        style: TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        hasCardio ? cardioType : 'Pas de cardio cette séance',
                        style: TextStyle(
                          color: hasCardio
                              ? const Color(0xFF7B1FA2)
                              : _kTextSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: hasCardio,
                  onChanged: onToggle,
                  activeColor: const Color(0xFF7B1FA2),
                ),
              ],
            ),
          ),
          if (hasCardio) ...[
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.9,
                children: _kCardioTypes.map((c) {
                  final name = c['name'] as String;
                  final isSelected = cardioType == name;
                  final color = Color(c['color'] as int);
                  return GestureDetector(
                    onTap: () => onSelectType(name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : _kSurf2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.5)
                              : _kBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            c['emoji'] as String,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? color : _kTextSub,
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  final Set<String> muscles;
  const _SelectionSummary({required this.muscles});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGreenL,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _kGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${muscles.length} muscle${muscles.length > 1 ? 's' : ''} sélectionné${muscles.length > 1 ? 's' : ''} : ${muscles.join(', ')}',
              style: const TextStyle(
                color: _kGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisesSection extends StatelessWidget {
  final Set<String> muscles;
  final List<ExerciseEntry> exercises;
  final void Function(String) onAddForMuscle;
  final void Function(int) onEdit;
  final void Function(int) onRemove;

  const _ExercisesSection({
    required this.muscles,
    required this.exercises,
    required this.onAddForMuscle,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center_rounded,
                  color: _kGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Exercices',
                    style: TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${exercises.length} ajouté${exercises.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: _kTextSub, fontSize: 12),
                ),
              ],
            ),
          ),

          if (exercises.isNotEmpty) ...[
            ...exercises.asMap().entries.map(
              (entry) => _ExerciseRow(
                index: entry.key,
                exercise: entry.value,
                onEdit: () => onEdit(entry.key),
                onRemove: () => onRemove(entry.key),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajouter un exercice pour :',
                  style: TextStyle(
                    color: _kTextSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: muscles
                      .map(
                        (muscle) => GestureDetector(
                          onTap: () => onAddForMuscle(muscle),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _kGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  color: _kGreen,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  muscle,
                                  style: const TextStyle(
                                    color: _kGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final ExerciseEntry exercise;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _ExerciseRow({
    required this.index,
    required this.exercise,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: _kGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName.isEmpty
                      ? 'Exercice ${index + 1}'
                      : exercise.exerciseName,
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${exercise.setsCompleted} × ${exercise.repsCompleted}'
                  '${exercise.weightKg > 0 ? '  •  ${exercise.weightKg}kg' : ''}',
                  style: const TextStyle(color: _kTextSub, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: _kBlue, size: 18),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _kRed, size: 18),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.suffix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: _kText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kBorder, fontSize: 22),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _kTextSub, fontSize: 16),
        filled: true,
        fillColor: _kSurf2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _IntensitySlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;
  final Color Function(int)? colorFn;
  final String Function(int)? labelFn;

  const _IntensitySlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.colorFn,
    this.labelFn,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFn?.call(value) ?? _kGreen;
    final valLabel = labelFn?.call(value) ?? '$value/$max';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _kTextSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$value/$max  $valLabel',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: _kBorder,
            thumbColor: color,
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

class _WarmupRow extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _WarmupRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Échauffement effectué',
                style: TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                value
                    ? '✅ Risque de blessure réduit'
                    : '⚠️ Sans échauffement = risque accru',
                style: TextStyle(
                  color: value ? _kGreen : _kOrange,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: _kGreen),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  const _WarningBanner({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: _kOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _kOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _kOrange, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: _kOrange),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
