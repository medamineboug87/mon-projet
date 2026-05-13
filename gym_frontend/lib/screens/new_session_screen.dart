import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/member_service.dart';
import '../services/auth_service.dart';
import '../widgets/session/session_mode_toggle.dart';
import '../widgets/session/session_body_map.dart';
import '../widgets/session/session_cardio_section.dart';
import '../widgets/session/session_ressent_section.dart';
import '../widgets/session/session_prediction_card.dart';
import '../widgets/exercise_section/exercise_entry_model.dart';
import '../widgets/exercise_section/exercise_list.dart';
import '../widgets/exercise_section/exercise_form_dialog.dart';
import '../widgets/exercise_section/exercise_picker_sheet.dart';
import '../config/api_config.dart';
import '../models/muscle_zone.dart';

// ─── Design tokens ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class NewSessionScreen extends StatefulWidget {
  final int memberId;
  const NewSessionScreen({super.key, required this.memberId});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _cardioDurCtrl = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _prediction;

  // Body map
  bool _showFront = true;
  Set<String> _selectedMuscles = {};

  // Cardio
  bool _hasCardio = false;
  String _cardioType = 'Course';
  int _cardioIntensity = 5;

  // Ressenti
  int _painLevel = 0;
  bool _warmupDone = true;

  // Exercices détaillés
  bool _useDetailedExercises = false;
  List<ExerciseEntry> _exercises = [];

  // Muscles zones pour le body map
  final List<MuscleZone> _frontMuscles = const [
    MuscleZone('Pectoraux', Rect.fromLTWH(115, 108, 120, 58)),
    MuscleZone('Épaules', Rect.fromLTWH(72, 98, 206, 36)),
    MuscleZone('Biceps', Rect.fromLTWH(62, 134, 44, 72)),
    MuscleZone('Biceps D.', Rect.fromLTWH(244, 134, 44, 72)),
    MuscleZone('Abdominaux', Rect.fromLTWH(130, 168, 90, 98)),
    MuscleZone('Quadriceps', Rect.fromLTWH(115, 298, 52, 106)),
    MuscleZone('Quadriceps D.', Rect.fromLTWH(183, 298, 52, 106)),
    MuscleZone('Mollets', Rect.fromLTWH(115, 410, 52, 82)),
    MuscleZone('Mollets D.', Rect.fromLTWH(183, 410, 52, 82)),
  ];

  final List<MuscleZone> _backMuscles = const [
    MuscleZone('Trapèzes', Rect.fromLTWH(118, 92, 114, 48)),
    MuscleZone('Dorsaux', Rect.fromLTWH(100, 128, 150, 90)),
    MuscleZone('Triceps', Rect.fromLTWH(62, 134, 44, 72)),
    MuscleZone('Triceps D.', Rect.fromLTWH(244, 134, 44, 72)),
    MuscleZone('Lombaires', Rect.fromLTWH(135, 222, 80, 58)),
    MuscleZone('Fessiers', Rect.fromLTWH(115, 278, 120, 52)),
    MuscleZone('Ischio-jambiers', Rect.fromLTWH(115, 298, 52, 106)),
    MuscleZone('Ischio D.', Rect.fromLTWH(183, 298, 52, 106)),
  ];

  @override
  void dispose() {
    _durationCtrl.dispose();
    _weightCtrl.dispose();
    _cardioDurCtrl.dispose();
    super.dispose();
  }

  double get _effectiveWeightFromExercises {
    if (_exercises.isEmpty) return 0;
    return _exercises.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
  }

  Set<String> get _musclesFromExercises {
    return _exercises
        .where((e) => e.muscleName.isNotEmpty)
        .map((e) => e.muscleName)
        .toSet();
  }

  Future<void> _submitSession() async {
    if (!_formKey.currentState!.validate()) return;

    final musclesUsed = _useDetailedExercises
        ? _musclesFromExercises
        : _selectedMuscles;

    if (musclesUsed.isEmpty && !_hasCardio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sélectionnez au moins un muscle ou activez le cardio !',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_useDetailedExercises && _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ajoutez au moins un exercice ou désactivez la saisie détaillée.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_useDetailedExercises && _exercises.any((e) => !e.isValid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les exercices doivent avoir un nom.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cardioDur = _hasCardio ? (int.tryParse(_cardioDurCtrl.text) ?? 0) : 0;
    final double globalWeight = _useDetailedExercises && _exercises.isNotEmpty
        ? _effectiveWeightFromExercises
        : (double.tryParse(_weightCtrl.text) ?? 0.0);
    final targetMuscles = _useDetailedExercises
        ? _musclesFromExercises.join(', ')
        : _selectedMuscles.join(', ');

    final sessionData = {
      "date": DateTime.now().toIso8601String().split('T')[0],
      "duration": int.tryParse(_durationCtrl.text) ?? 0,
      "intensity": 5,
      "weightLifted": globalWeight,
      "targetMuscles": targetMuscles,
      "hasCardio": _hasCardio,
      "cardioDurationMinutes": cardioDur,
      "cardioType": _hasCardio ? _cardioType : "",
      "cardioIntensity": _hasCardio ? _cardioIntensity : 0,
      "painLevel": _painLevel,
      "warmupDone": _warmupDone,
    };

    try {
      final result = await MemberService.createSession(
        widget.memberId,
        sessionData,
      );

      if (result['success'] == true) {
        final sessionId = result['session']['id'] as int;

        if (_useDetailedExercises && _exercises.isNotEmpty) {
          await _saveDetailedExercises(sessionId);
        }

        final prediction = await MemberService.getAIPrediction(
          widget.memberId,
          sessionId,
        );
        setState(() {
          _prediction = prediction;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Séance enregistrée avec exercices détaillés !'),
              backgroundColor: _kGreen,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réseau: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDetailedExercises(int sessionId) async {
    try {
      final token = await AuthService.getToken();
      final exercisesJson = _exercises
          .asMap()
          .entries
          .map((e) => {...e.value.toJson(), 'exerciseOrder': e.key + 1})
          .toList();

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/sessions/$sessionId/exercises/bulk',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(exercisesJson),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('⚠️ Erreur sauvegarde exercices: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur réseau exercices: $e');
    }
  }

  void _showAddExerciseDialog() {
    String? selectedMuscle;
    if (_useDetailedExercises && _exercises.isNotEmpty) {
      selectedMuscle = _exercises.last.muscleName;
    } else if (_selectedMuscles.isNotEmpty) {
      selectedMuscle = _selectedMuscles.first;
    }

    if (selectedMuscle == null || selectedMuscle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez d\'abord sélectionner un muscle sur le body map',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExercisePickerSheet(
        muscleName: selectedMuscle,
        onSelect: (exercise) {
          setState(() {
            _exercises.add(
              ExerciseEntry(
                exerciseName: exercise['name'] ?? '',
                muscleName: exercise['muscleName'] ?? '',
                weightKg: 0.0,
                setsCompleted: 3,
                repsCompleted: '10',
                rpe: null,
                failureReached: false,
                restSeconds: 90,
                notes: '',
              ),
            );
          });
          _showEditExerciseDialog(_exercises.length - 1, _exercises.last);
        },
      ),
    );
  }

  void _showEditExerciseDialog(int index, ExerciseEntry entry) {
    final clone = ExerciseEntry(
      exerciseName: entry.exerciseName,
      muscleName: entry.muscleName,
      weightKg: entry.weightKg,
      setsCompleted: entry.setsCompleted,
      repsCompleted: entry.repsCompleted,
      rpe: entry.rpe,
      failureReached: entry.failureReached,
      restSeconds: entry.restSeconds,
      notes: entry.notes,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExerciseFormDialog(
        entry: clone,
        isEdit: true,
        onSave: (saved) => setState(() => _exercises[index] = saved),
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Nouvelle séance',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _kSurf2,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDurationField(),
            const SizedBox(height: 20),
            SessionModeToggle(
              useDetailedExercises: _useDetailedExercises,
              exerciseCount: _exercises.length,
              onToggle: (v) => setState(() => _useDetailedExercises = v),
            ),
            const SizedBox(height: 16),
            if (_useDetailedExercises) ...[
              ExerciseList(
                exercises: _exercises,
                selectedMuscles: _selectedMuscles,
                onAddExercise: _showAddExerciseDialog,
                onEditExercise: _showEditExerciseDialog,
                onRemoveExercise: _removeExercise,
              ),
              const SizedBox(height: 16),
            ] else ...[
              _buildWeightField(),
              const SizedBox(height: 20),
              SessionBodyMap(
                selectedMuscles: _selectedMuscles,
                onMusclesChanged: (muscles) =>
                    setState(() => _selectedMuscles = muscles),
                showFront: _showFront,
                frontMuscles: _frontMuscles,
                backMuscles: _backMuscles,
                onViewChanged: (front) => setState(() => _showFront = front),
              ),
              const SizedBox(height: 20),
            ],
            SessionCardioSection(
              hasCardio: _hasCardio,
              cardioType: _cardioType,
              cardioIntensity: _cardioIntensity,
              durationCtrl: _cardioDurCtrl,
              onCardioChanged: (has, type, intensity) => setState(() {
                _hasCardio = has;
                _cardioType = type;
                _cardioIntensity = intensity;
              }),
            ),
            const SizedBox(height: 20),
            SessionRessentSection(
              painLevel: _painLevel,
              warmupDone: _warmupDone,
              onPainChanged: (v) => setState(() => _painLevel = v),
              onWarmupChanged: (v) => setState(() => _warmupDone = v),
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            if (_prediction != null) ...[
              const SizedBox(height: 20),
              SessionPredictionCard(prediction: _prediction!),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⏱ Durée muscu (minutes)',
          style: TextStyle(
            color: _kGreen,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _kText),
          validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
          decoration: InputDecoration(
            labelText: 'Durée entraînement',
            labelStyle: const TextStyle(color: _kTextSub),
            prefixIcon: const Icon(
              Icons.timer_rounded,
              color: _kGreen,
              size: 20,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏋 Poids soulevé (kg)',
          style: TextStyle(
            color: _kBlue,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _kText),
          validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
          decoration: InputDecoration(
            labelText: 'Poids total soulevé',
            labelStyle: const TextStyle(color: _kTextSub),
            prefixIcon: const Icon(
              Icons.fitness_center_rounded,
              color: _kGreen,
              size: 20,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitSession,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: _kText, strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_rounded, color: _kText),
        label: Text(
          _isLoading ? 'Enregistrement...' : 'Enregistrer la séance',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _kText,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
