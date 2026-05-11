import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/member_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import 'exercise_screen_updated.dart';
import '../widgets/index.dart';

// ─── Design tokens light ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kGreenDark = Color(0xFF00695C);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kOrange = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kPurpleL = Color(0xFFF3E5F5);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

// ─── Modèle d'exercice saisi par le membre ───
class _ExerciseEntry {
  String exerciseName;
  String muscleName;
  double weightKg;
  int setsCompleted;
  String repsCompleted;
  int? rpe;
  bool failureReached;
  int restSeconds;
  String notes;

  _ExerciseEntry({
    this.exerciseName = '',
    this.muscleName = '',
    this.weightKg = 0.0,
    this.setsCompleted = 3,
    this.repsCompleted = '10',
    this.rpe,
    this.failureReached = false,
    this.restSeconds = 90,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'muscleName': muscleName,
    'weightKg': weightKg,
    'setsCompleted': setsCompleted,
    'repsCompleted': repsCompleted,
    'rpe': rpe,
    'failureReached': failureReached,
    'restSeconds': restSeconds,
    'notes': notes.isNotEmpty ? notes : null,
  };

  double get totalVolume =>
      weightKg *
      setsCompleted *
      (double.tryParse(repsCompleted.split(RegExp(r'[-,]'))[0]) ?? 10);

  String get chargeLevel {
    // Seuils simplifiés pour affichage
    if (weightKg == 0) return 'N/A';
    if (weightKg < 20) return 'Légère';
    if (weightKg < 50) return 'Modérée';
    if (weightKg < 80) return 'Élevée';
    return 'Très élevée';
  }

  Color get chargeLevelColor {
    switch (chargeLevel) {
      case 'Légère':
        return _kGreen;
      case 'Modérée':
        return _kBlue;
      case 'Élevée':
        return _kOrange;
      case 'Très élevée':
        return _kRed;
      default:
        return _kTextSub;
    }
  }

  bool get isValid => exerciseName.trim().isNotEmpty;
}

// ─── Noms de muscles disponibles ───
const List<String> _kMuscleOptions = [
  'Pectoraux',
  'Dorsaux',
  'Épaules',
  'Biceps',
  'Biceps droit',
  'Triceps',
  'Triceps droit',
  'Abdominaux',
  'Quadriceps',
  'Quadriceps droit',
  'Ischio-jambiers',
  'Ischio-jambiers droits',
  'Fessiers',
  'Mollets',
  'Mollets droits',
  'Lombaires',
  'Trapèzes',
];

class NewSessionScreen extends StatefulWidget {
  final int memberId;
  const NewSessionScreen({super.key, required this.memberId});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _durationCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _cardioDurCtrl = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _prediction;

  // ── Body map ──
  bool _showFront = true;
  Set<String> _selectedMuscles = {};

  // ── Cardio ──
  bool _hasCardio = false;
  String _cardioType = 'Course';
  int _cardioIntensity = 5;

  // ── Ressenti post-séance (Niveau 2 IA) ──
  int _painLevel = 0;
  bool _warmupDone = true;

  // ── NOUVEAU : Exercices avec poids réel (Niveau 3 IA) ──
  bool _useDetailedExercises = false;
  List<_ExerciseEntry> _exercises = [];

  static const List<String> _cardioTypes = [
    'Course',
    'Vélo',
    'HIIT',
    'Natation',
    'Elliptique',
    'Rameur',
    'Marche',
    'Corde',
  ];

  static const Map<String, IconData> _cardioIcons = {
    'Course': Icons.directions_run_rounded,
    'Vélo': Icons.pedal_bike_rounded,
    'HIIT': Icons.flash_on_rounded,
    'Natation': Icons.pool_rounded,
    'Elliptique': Icons.loop_rounded,
    'Rameur': Icons.rowing_rounded,
    'Marche': Icons.directions_walk_rounded,
    'Corde': Icons.cable_rounded,
  };

  static const Map<String, Color> _cardioColors = {
    'Course': _kGreen,
    'Vélo': _kBlue,
    'HIIT': _kRed,
    'Natation': _kBlue,
    'Elliptique': Color(0xFFCE93D8),
    'Rameur': _kOrange,
    'Marche': Color(0xFF69F0AE),
    'Corde': _kRed,
  };

  static const _svgW = 350.0;
  static const _svgH = 520.0;

  final List<_MuscleZone> _frontMuscles = const [
    _MuscleZone('Pectoraux', Rect.fromLTWH(115, 108, 120, 58)),
    _MuscleZone('Épaules', Rect.fromLTWH(72, 98, 206, 36)),
    _MuscleZone('Biceps', Rect.fromLTWH(62, 134, 44, 72)),
    _MuscleZone('Biceps D.', Rect.fromLTWH(244, 134, 44, 72)),
    _MuscleZone('Abdominaux', Rect.fromLTWH(130, 168, 90, 98)),
    _MuscleZone('Quadriceps', Rect.fromLTWH(115, 298, 52, 106)),
    _MuscleZone('Quadriceps D.', Rect.fromLTWH(183, 298, 52, 106)),
    _MuscleZone('Mollets', Rect.fromLTWH(115, 410, 52, 82)),
    _MuscleZone('Mollets D.', Rect.fromLTWH(183, 410, 52, 82)),
  ];

  final List<_MuscleZone> _backMuscles = const [
    _MuscleZone('Trapèzes', Rect.fromLTWH(118, 92, 114, 48)),
    _MuscleZone('Dorsaux', Rect.fromLTWH(100, 128, 150, 90)),
    _MuscleZone('Triceps', Rect.fromLTWH(62, 134, 44, 72)),
    _MuscleZone('Triceps D.', Rect.fromLTWH(244, 134, 44, 72)),
    _MuscleZone('Lombaires', Rect.fromLTWH(135, 222, 80, 58)),
    _MuscleZone('Fessiers', Rect.fromLTWH(115, 278, 120, 52)),
    _MuscleZone('Ischio-jambiers', Rect.fromLTWH(115, 298, 52, 106)),
    _MuscleZone('Ischio D.', Rect.fromLTWH(183, 298, 52, 106)),
  ];

  List<_MuscleZone> get _currentMuscles =>
      _showFront ? _frontMuscles : _backMuscles;

  @override
  void dispose() {
    _durationCtrl.dispose();
    _weightCtrl.dispose();
    _cardioDurCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Ajouter un exercice depuis les muscles sélectionnés
  // ─────────────────────────────────────────────
  void _addExercise({String? muscleName}) {
    setState(() {
      _exercises.add(
        _ExerciseEntry(
          muscleName:
              muscleName ??
              (_selectedMuscles.isNotEmpty ? _selectedMuscles.first : ''),
        ),
      );
    });
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  // Calcul du poids effectif maximal parmi les exercices
  double get _effectiveWeightFromExercises {
    if (_exercises.isEmpty) return 0;
    return _exercises.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
  }

  // Extraction des muscles depuis les exercices
  Set<String> get _musclesFromExercises {
    return _exercises
        .where((e) => e.muscleName.isNotEmpty)
        .map((e) => e.muscleName)
        .toSet();
  }

  // ─────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────
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

    // Calculer le poids global : depuis les exercices détaillés ou le champ manuel
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

        // ── NIVEAU 3 : Envoyer les exercices détaillés si activé ──
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

  // Envoi bulk des exercices au backend
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
      } else {
        debugPrint(
          '✅ ${_exercises.length} exercices sauvegardés pour la séance $sessionId',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur réseau exercices: $e');
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
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
            // ── Durée muscu ──
            _SectionTitle('⏱ Durée muscu (minutes)', _kGreen),
            const SizedBox(height: 8),
            _buildField(
              _durationCtrl,
              'Durée entraînement',
              Icons.timer_rounded,
              isNumber: true,
            ),
            const SizedBox(height: 20),

            // ══════════════════════════════════════════════
            // NOUVEAU : TOGGLE SAISIE EXERCICES DÉTAILLÉS
            // ══════════════════════════════════════════════
            _buildExercisesModeToggle(),
            const SizedBox(height: 16),

            // ── Si mode détaillé : section exercices ──
            if (_useDetailedExercises) ...[
              _buildDetailedExercisesSection(),
              const SizedBox(height: 16),
            ] else ...[
              // ── Mode simple : champ poids global ──
              _SectionTitle('🏋 Poids soulevé (kg)', _kBlue),
              const SizedBox(height: 8),
              _buildField(
                _weightCtrl,
                'Poids total soulevé',
                Icons.fitness_center_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 20),

              // ── Body Map (mode simple uniquement) ──
              _buildBodyMapSection(),
              const SizedBox(height: 20),
            ],

            // ── Cardio ──
            _buildCardioSection(),
            const SizedBox(height: 20),

            // ── Ressenti post-séance ──
            _buildRessentSection(),
            const SizedBox(height: 24),

            // ── Bouton enregistrer ──
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitSession,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: _kText,
                          strokeWidth: 2,
                        ),
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
            ),

            // ── Résultat IA ──
            if (_prediction != null) ...[
              const SizedBox(height: 20),
              _buildPrediction(),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOGGLE MODE EXERCICES
  // ─────────────────────────────────────────────
  Widget _buildExercisesModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _useDetailedExercises
              ? _kGreen.withValues(alpha: 0.5)
              : _kBorder,
          width: _useDetailedExercises ? 1.5 : 1,
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
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.list_alt_rounded,
                    color: _kGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saisie exercices détaillée',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _useDetailedExercises
                            ? '${_exercises.length} exercice(s) • Prédiction IA plus précise'
                            : 'Activez pour saisir poids réel par exercice',
                        style: TextStyle(
                          color: _useDetailedExercises ? _kGreen : _kTextSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useDetailedExercises,
                  onChanged: (v) => setState(() => _useDetailedExercises = v),
                  activeColor: _kGreen,
                ),
              ],
            ),
          ),
          if (!_useDetailedExercises)
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

  // ─────────────────────────────────────────────
  // SECTION EXERCICES DÉTAILLÉS
  // ─────────────────────────────────────────────
  Widget _buildDetailedExercisesSection() {
    final totalVolume = _exercises.fold(0.0, (sum, e) => sum + e.totalVolume);
    final maxWeight = _exercises.isEmpty
        ? 0.0
        : _exercises.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
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
                const Text(
                  'Exercices de la séance',
                  style: TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_exercises.isNotEmpty) ...[
                  _MiniStatBadge(
                    '${maxWeight.toStringAsFixed(0)}kg max',
                    _kBlue,
                  ),
                  const SizedBox(width: 6),
                  _MiniStatBadge(
                    '${totalVolume.toStringAsFixed(0)} vol.',
                    _kOrange,
                  ),
                ],
              ],
            ),
          ),

          // Liste des exercices
          if (_exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _kGreenL,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: _kGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucun exercice ajouté',
                      style: TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ajoutez vos exercices avec le poids utilisé',
                      style: TextStyle(color: _kTextSub, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_exercises.asMap().entries.map(
              (entry) => _buildExerciseCard(entry.key, entry.value),
            )),

          // Bouton ajouter un exercice
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () => _showAddExerciseDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _kGreen.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: _kGreen, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ajouter un exercice',
                      style: TextStyle(
                        color: _kGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Résumé muscles travaillés
          if (_musclesFromExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Muscles travaillés',
                    style: TextStyle(
                      color: _kTextSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: _musclesFromExercises
                        .map(
                          (m) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreenL,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _kGreen.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              m,
                              style: const TextStyle(
                                color: _kGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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

  // ─────────────────────────────────────────────
  // CARTE D'UN EXERCICE
  // ─────────────────────────────────────────────
  Widget _buildExerciseCard(int index, _ExerciseEntry exercise) {
    final hasHighLoad = exercise.weightKg >= 80;
    final hasFailure = exercise.failureReached;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasHighLoad || hasFailure
              ? _kOrange.withValues(alpha: 0.4)
              : _kBorder,
          width: hasHighLoad || hasFailure ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header carte exercice
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: _kGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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
                      if (exercise.muscleName.isNotEmpty)
                        Text(
                          exercise.muscleName,
                          style: const TextStyle(
                            color: _kTextSub,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                // Badges charge
                if (exercise.weightKg > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: exercise.chargeLevelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exercise.chargeLevel,
                      style: TextStyle(
                        color: exercise.chargeLevelColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Bouton éditer
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: _kBlue, size: 18),
                  onPressed: () => _showEditExerciseDialog(index, exercise),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Bouton supprimer
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: _kRed,
                    size: 18,
                  ),
                  onPressed: () => _removeExercise(index),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Stats de l'exercice
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                _ExerciseStatChip(
                  '${exercise.weightKg.toStringAsFixed(1)} kg',
                  Icons.fitness_center_rounded,
                  _kBlue,
                ),
                const SizedBox(width: 6),
                _ExerciseStatChip(
                  '${exercise.setsCompleted} séries',
                  Icons.repeat_rounded,
                  _kGreen,
                ),
                const SizedBox(width: 6),
                _ExerciseStatChip(
                  '${exercise.repsCompleted} reps',
                  Icons.numbers_rounded,
                  _kOrange,
                ),
                if (exercise.rpe != null) ...[
                  const SizedBox(width: 6),
                  _ExerciseStatChip(
                    'RPE ${exercise.rpe}',
                    Icons.speed_rounded,
                    exercise.rpe! >= 9
                        ? _kRed
                        : exercise.rpe! >= 7
                        ? _kOrange
                        : _kGreen,
                  ),
                ],
                if (exercise.failureReached) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kRedL,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _kRed,
                          size: 10,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Échec',
                          style: TextStyle(
                            color: _kRed,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Volume total
          if (exercise.totalVolume > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 12,
                    color: _kTextSub,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Volume total : ${exercise.totalVolume.toStringAsFixed(0)} kg',
                    style: const TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DIALOG AJOUT EXERCICE
  // ─────────────────────────────────────────────
  void _showAddExerciseDialog() {
    final entry = _ExerciseEntry(
      muscleName: _selectedMuscles.isNotEmpty ? _selectedMuscles.first : '',
    );
    _showExerciseFormDialog(
      entry,
      onSave: (saved) {
        setState(() => _exercises.add(saved));
      },
    );
  }

  void _showEditExerciseDialog(int index, _ExerciseEntry entry) {
    // Clone pour édition
    final clone = _ExerciseEntry(
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
    _showExerciseFormDialog(
      clone,
      onSave: (saved) {
        setState(() => _exercises[index] = saved);
      },
      isEdit: true,
    );
  }

  void _showExerciseFormDialog(
    _ExerciseEntry entry, {
    required Function(_ExerciseEntry) onSave,
    bool isEdit = false,
  }) {
    final nameCtrl = TextEditingController(text: entry.exerciseName);
    final weightCtrl = TextEditingController(
      text: entry.weightKg > 0 ? entry.weightKg.toString() : '',
    );
    final repsCtrl = TextEditingController(text: entry.repsCompleted);
    final notesCtrl = TextEditingController(text: entry.notes);

    int sets = entry.setsCompleted;
    int? rpe = entry.rpe;
    bool failure = entry.failureReached;
    int rest = entry.restSeconds;
    String muscle = entry.muscleName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _kGreenL,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: _kGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Modifier l\'exercice' : 'Ajouter un exercice',
                      style: const TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _kTextSub),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, color: _kBorder),

              // Formulaire scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de l'exercice
                      const _FormLabel('Nom de l\'exercice *'),
                      const SizedBox(height: 6),
                      _sheetField(
                        nameCtrl,
                        'Ex: Développé couché, Squat...',
                        Icons.fitness_center_rounded,
                      ),
                      const SizedBox(height: 14),

                      // Muscle ciblé
                      const _FormLabel('Muscle ciblé'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value:
                            muscle.isNotEmpty &&
                                _kMuscleOptions.contains(muscle)
                            ? muscle
                            : null,
                        decoration: _sheetFieldDecoration(
                          'Sélectionner...',
                          Icons.person_rounded,
                        ),
                        dropdownColor: _kSurface,
                        style: const TextStyle(color: _kText, fontSize: 13),
                        items: _kMuscleOptions
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (v) => setSheet(() => muscle = v ?? ''),
                      ),
                      const SizedBox(height: 14),

                      // Poids
                      const _FormLabel('Poids utilisé (kg)'),
                      const SizedBox(height: 6),
                      _sheetField(
                        weightCtrl,
                        'Ex: 60.0',
                        Icons.monitor_weight_rounded,
                        isNumber: true,
                      ),
                      const SizedBox(height: 14),

                      // Séries et Répétitions
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FormLabel('Séries'),
                                const SizedBox(height: 6),
                                _SetsSelector(
                                  value: sets,
                                  onChanged: (v) => setSheet(() => sets = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FormLabel('Répétitions'),
                                const SizedBox(height: 6),
                                _sheetField(
                                  repsCtrl,
                                  'Ex: 10 ou 8-12',
                                  Icons.numbers_rounded,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // RPE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _FormLabel('RPE (effort ressenti 1-10)'),
                          if (rpe != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (rpe! >= 9
                                            ? _kRed
                                            : rpe! >= 7
                                            ? _kOrange
                                            : _kGreen)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$rpe/10',
                                style: TextStyle(
                                  color: rpe! >= 9
                                      ? _kRed
                                      : rpe! >= 7
                                      ? _kOrange
                                      : _kGreen,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: rpe == null
                              ? _kBorder
                              : (rpe! >= 9
                                    ? _kRed
                                    : rpe! >= 7
                                    ? _kOrange
                                    : _kGreen),
                          inactiveTrackColor: _kBorder,
                          thumbColor: rpe == null
                              ? _kBorder
                              : (rpe! >= 9
                                    ? _kRed
                                    : rpe! >= 7
                                    ? _kOrange
                                    : _kGreen),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 9,
                          ),
                        ),
                        child: Slider(
                          value: rpe?.toDouble() ?? 0,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          onChanged: (v) => setSheet(
                            () => rpe = v.round() == 0 ? null : v.round(),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Non évalué',
                            style: TextStyle(color: _kTextSub, fontSize: 9),
                          ),
                          Text(
                            'Modéré',
                            style: TextStyle(color: _kTextSub, fontSize: 9),
                          ),
                          Text(
                            'Maximal',
                            style: TextStyle(color: _kTextSub, fontSize: 9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Repos entre séries
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _FormLabel('Repos entre séries'),
                          Text(
                            '${rest}s',
                            style: const TextStyle(
                              color: _kGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _RestSelector(
                        value: rest,
                        onChanged: (v) => setSheet(() => rest = v),
                      ),
                      const SizedBox(height: 14),

                      // Échec musculaire
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: failure ? _kRedL : _kSurf2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: failure
                                ? _kRed.withValues(alpha: 0.4)
                                : _kBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Échec musculaire atteint',
                                    style: TextStyle(
                                      color: _kText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    failure
                                        ? '⚠️ Récupération accrue nécessaire'
                                        : 'Charge non maximale',
                                    style: TextStyle(
                                      color: failure ? _kRed : _kTextSub,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: failure,
                              onChanged: (v) => setSheet(() => failure = v),
                              activeColor: _kRed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      const _FormLabel('Notes (optionnel)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: _kText, fontSize: 13),
                        decoration: _sheetFieldDecoration(
                          'Observations, sensations, points techniques...',
                          Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bouton sauvegarder
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Le nom de l\'exercice est requis',
                                  ),
                                  backgroundColor: _kRed,
                                ),
                              );
                              return;
                            }
                            final saved = _ExerciseEntry(
                              exerciseName: nameCtrl.text.trim(),
                              muscleName: muscle,
                              weightKg: double.tryParse(weightCtrl.text) ?? 0.0,
                              setsCompleted: sets,
                              repsCompleted: repsCtrl.text.trim().isEmpty
                                  ? '10'
                                  : repsCtrl.text.trim(),
                              rpe: rpe,
                              failureReached: failure,
                              restSeconds: rest,
                              notes: notesCtrl.text.trim(),
                            );
                            Navigator.pop(ctx);
                            onSave(saved);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Text(
                            isEdit ? 'Mettre à jour' : 'Ajouter l\'exercice',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BODY MAP SECTION (mode simple)
  // ─────────────────────────────────────────────
  Widget _buildBodyMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('💪 Muscles ciblés', _kOrange),
        const SizedBox(height: 4),
        const Text(
          'Appuyez sur un muscle pour le sélectionner',
          style: TextStyle(color: _kTextSub, fontSize: 11),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _kSurf2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _toggleBtn(
                  'Face avant',
                  _showFront,
                  () => setState(() => _showFront = true),
                ),
              ),
              Expanded(
                child: _toggleBtn(
                  'Vue arrière',
                  !_showFront,
                  () => setState(() => _showFront = false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedMuscles.isNotEmpty) ...[
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: _selectedMuscles
                .map(
                  (m) => Chip(
                    label: Text(
                      m,
                      style: const TextStyle(color: _kText, fontSize: 12),
                    ),
                    backgroundColor: _kGreen.withValues(alpha: 0.18),
                    side: const BorderSide(color: _kGreen, width: 0.8),
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 14,
                      color: _kTextSub,
                    ),
                    onDeleted: () => setState(() => _selectedMuscles.remove(m)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMuscles
                .map(
                  (muscle) => ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseScreen(
                          muscleName: muscle,
                          lastWorkedHours: 72,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.fitness_center, size: 16),
                    label: Text('Voir exercices : $muscle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: _kSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
        Center(
          child: SizedBox(
            width: _svgW,
            height: _svgH,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(_svgW, _svgH),
                  painter: _BodyPainter(
                    showFront: _showFront,
                    selectedMuscles: _selectedMuscles,
                    muscles: _currentMuscles,
                  ),
                ),
                ..._currentMuscles.map((zone) {
                  final isSelected = _selectedMuscles.contains(zone.name);
                  return Positioned(
                    left: zone.rect.left,
                    top: zone.rect.top,
                    width: zone.rect.width,
                    height: zone.rect.height,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected)
                          _selectedMuscles.remove(zone.name);
                        else
                          _selectedMuscles.add(zone.name);
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _kGreen.withValues(alpha: 0.35)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected
                              ? Border.all(color: _kGreen, width: 1.5)
                              : null,
                        ),
                        child: isSelected
                            ? Center(
                                child: Text(
                                  zone.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _kText,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 6,
          children: _currentMuscles.map((zone) {
            final isSelected = _selectedMuscles.contains(zone.name);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected)
                  _selectedMuscles.remove(zone.name);
                else
                  _selectedMuscles.add(zone.name);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _kGreen.withValues(alpha: 0.15) : _kSurf2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _kGreen.withValues(alpha: 0.5)
                        : _kBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  zone.name,
                  style: TextStyle(
                    color: isSelected ? _kGreen : _kTextSub,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
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

  // ─────────────────────────────────────────────
  // CARDIO SECTION
  // ─────────────────────────────────────────────
  Widget _buildCardioSection() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _hasCardio
              ? (_cardioColors[_cardioType] ?? _kGreen).withValues(alpha: 0.4)
              : _kBorder,
          width: _hasCardio ? 1.5 : 1,
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
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: _kPurple,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _hasCardio
                            ? '$_cardioType • ${_cardioDurCtrl.text.isEmpty ? "?" : _cardioDurCtrl.text} min'
                            : 'Aucun cardio cette séance',
                        style: TextStyle(
                          color: _hasCardio
                              ? (_cardioColors[_cardioType] ?? _kGreen)
                              : _kTextSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _hasCardio,
                  onChanged: (v) => setState(() => _hasCardio = v),
                  activeColor: _kPurple,
                ),
              ],
            ),
          ),
          if (_hasCardio) ...[
            const Divider(color: _kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Type de cardio',
                    style: TextStyle(
                      color: _kTextSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                    children: _cardioTypes.map((type) {
                      final isSelected = _cardioType == type;
                      final color = _cardioColors[type] ?? _kGreen;
                      return GestureDetector(
                        onTap: () => setState(() => _cardioType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : _kText.withValues(alpha: 0.04),
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
                              Icon(
                                _cardioIcons[type] ??
                                    Icons.directions_run_rounded,
                                color: isSelected ? color : _kBorder,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? color : _kTextSub,
                                  fontSize: 9,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    _cardioDurCtrl,
                    'Durée (minutes)',
                    Icons.timer_outlined,
                    isNumber: true,
                    required: false,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Intensité cardio',
                        style: TextStyle(
                          color: _kTextSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _IntensityBadge(
                        intensity: _cardioIntensity,
                        cardioType: _cardioType,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _cardioColors[_cardioType] ?? _kGreen,
                      inactiveTrackColor: _kBorder,
                      thumbColor: _cardioColors[_cardioType] ?? _kGreen,
                      trackHeight: 5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _cardioIntensity.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      onChanged: (v) =>
                          setState(() => _cardioIntensity = v.round()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESSENTI POST-SÉANCE
  // ─────────────────────────────────────────────
  Widget _buildRessentSection() {
    Color painColor;
    String painLabel;
    if (_painLevel == 0) {
      painColor = _kGreen;
      painLabel = 'Aucune douleur';
    } else if (_painLevel <= 3) {
      painColor = const Color(0xFF69F0AE);
      painLabel = 'Légère';
    } else if (_painLevel <= 6) {
      painColor = _kOrange;
      painLabel = 'Modérée';
    } else {
      painColor = _kRed;
      painLabel = 'Intense';
    }

    return Container(
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _painLevel >= 7
              ? _kRed.withValues(alpha: 0.4)
              : !_warmupDone
              ? _kOrange.withValues(alpha: 0.4)
              : _kBorder,
          width: (_painLevel >= 7 || !_warmupDone) ? 1.5 : 1,
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF26C6DA).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: Color(0xFF26C6DA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ressenti post-séance',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Ces informations améliorent les prédictions IA',
                        style: TextStyle(color: _kTextSub, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: _kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Échauffement effectué',
                            style: TextStyle(
                              color: _kText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _warmupDone
                                ? '✅ Risque de blessure réduit'
                                : '⚠️ Sans échauffement = risque accru',
                            style: TextStyle(
                              color: _warmupDone ? _kGreen : _kOrange,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _warmupDone,
                      onChanged: (v) => setState(() => _warmupDone = v),
                      activeColor: _kGreen,
                      inactiveThumbColor: _kOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Douleur ressentie',
                      style: TextStyle(
                        color: _kTextSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: painColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: painColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_painLevel/10',
                            style: TextStyle(
                              color: painColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '• $painLabel',
                            style: TextStyle(
                              color: painColor.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: painColor,
                    inactiveTrackColor: _kBorder,
                    thumbColor: painColor,
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: _painLevel.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (v) => setState(() => _painLevel = v.round()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PREDICTION WIDGET
  // ─────────────────────────────────────────────
  Widget _buildPrediction() {
    final fatigue = _prediction!['fatigue'];
    final injury = _prediction!['injury'];
    final overload = _prediction!['overload'];
    final fatigueLbl = fatigue?['label'] ?? 'N/A';
    final injuryLbl = injury?['label'] ?? 'N/A';
    final riskLevel = overload?['riskLevel'] ?? 'NORMAL';
    final warnings = (overload?['warnings'] as List?)?.cast<String>() ?? [];
    final recs = (overload?['recommendations'] as List?)?.cast<String>() ?? [];
    final exerciseCount = fatigue?['exerciseCount'] ?? 0;
    final muscleRiskSource = fatigue?['muscleRiskSource'] ?? '';
    final effectiveWeight = fatigue?['effectiveWeightUsed'] ?? 0;

    Color riskColor = switch (riskLevel) {
      'CRITIQUE' => _kRed,
      'ÉLEVÉ' => _kOrange,
      'MODÉRÉ' => const Color(0xFFFFD740),
      _ => _kGreen,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _kGreen, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'ANALYSE IA',
                      style: TextStyle(
                        color: _kGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (exerciseCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.list_alt_rounded,
                        color: _kBlue,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$exerciseCount EXERCICES RÉELS',
                        style: const TextStyle(
                          color: _kBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (effectiveWeight > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kGreenL,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Charge effective analysée : ${effectiveWeight}kg${muscleRiskSource == 'EXERCICES_RÉELS' ? ' (données réelles)' : ''}',
                style: const TextStyle(
                  color: _kGreenDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PredCard(
                  icon: Icons.battery_alert_rounded,
                  label: 'Fatigue',
                  value: fatigueLbl,
                  confidence: (fatigue?['confidence'] as num?)?.toDouble() ?? 0,
                  isWarning: fatigueLbl.toLowerCase().contains('fatigué'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PredCard(
                  icon: Icons.healing_rounded,
                  label: 'Blessure',
                  value: injuryLbl,
                  confidence: (injury?['confidence'] as num?)?.toDouble() ?? 0,
                  isWarning: injuryLbl.toLowerCase().contains('élevé'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: riskColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_rounded, color: riskColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Charge hebdomadaire',
                        style: TextStyle(color: _kTextSub, fontSize: 11),
                      ),
                      Text(
                        '${overload?['sessionCount'] ?? 0} séances • ${overload?['totalMinutes'] ?? 0} min',
                        style: const TextStyle(color: _kText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    riskLevel,
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...warnings
                .take(3)
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, color: _kRed, size: 6),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            w,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (recs.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...recs
                .take(2)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_rounded,
                          color: _kGreen,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS UI
  // ─────────────────────────────────────────────
  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? _kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? _kText : _kTextSub,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText),
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSub),
        prefixIcon: Icon(icon, color: _kGreen, size: 20),
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
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: _sheetFieldDecoration(hint, icon),
    );
  }

  InputDecoration _sheetFieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kTextSub, fontSize: 12),
      prefixIcon: Icon(icon, color: _kGreen, size: 18),
      filled: true,
      fillColor: _kSurf2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS PARTAGÉS
// ─────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _kTextSub,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
  );
}

class _MiniStatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniStatBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _ExerciseStatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _ExerciseStatChip(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _IntensityBadge extends StatelessWidget {
  final int intensity;
  final String cardioType;
  const _IntensityBadge({required this.intensity, required this.cardioType});
  Color _color() {
    if (intensity >= 8) return _kRed;
    if (intensity >= 6) return _kOrange;
    if (intensity >= 4) return const Color(0xFFFFD740);
    return _kGreen;
  }

  String _label() {
    if (intensity >= 8) return 'Intense';
    if (intensity >= 6) return 'Modérée';
    if (intensity >= 4) return 'Légère';
    return 'Très légère';
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$intensity/10',
            style: TextStyle(
              color: c,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '• ${_label()}',
            style: TextStyle(color: c.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Sélecteur de séries (- / nombre / +)
class _SetsSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _SetsSelector({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _kSurf2,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kBorder),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 18, color: _kRed),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          constraints: const BoxConstraints(),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 18, color: _kGreen),
          onPressed: value < 20 ? () => onChanged(value + 1) : null,
          constraints: const BoxConstraints(),
        ),
      ],
    ),
  );
}

// Sélecteur de temps de repos
class _RestSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RestSelector({required this.value, required this.onChanged});

  static const List<int> _options = [30, 60, 90, 120, 180, 240, 300];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 6,
    children: _options.map((seconds) {
      final isSelected = value == seconds;
      final label = seconds >= 60
          ? '${seconds ~/ 60}min${seconds % 60 > 0 ? '${seconds % 60}s' : ''}'
          : '${seconds}s';
      return GestureDetector(
        onTap: () => onChanged(seconds),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? _kGreen.withValues(alpha: 0.15) : _kSurf2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _kGreen.withValues(alpha: 0.5) : _kBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _kGreen : _kTextSub,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _PredCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final double confidence;
  final bool isWarning;
  const _PredCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.confidence,
    required this.isWarning,
  });
  @override
  Widget build(BuildContext context) {
    final color = isWarning ? _kRed : _kGreen;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(color: _kTextSub, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: _kBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}% confiance',
            style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MUSCLE ZONE MODEL + BODY PAINTER
// ─────────────────────────────────────────────
class _MuscleZone {
  final String name;
  final Rect rect;
  const _MuscleZone(this.name, this.rect);
}

class _BodyPainter extends CustomPainter {
  final bool showFront;
  final Set<String> selectedMuscles;
  final List<_MuscleZone> muscles;
  const _BodyPainter({
    required this.showFront,
    required this.selectedMuscles,
    required this.muscles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..color = const Color(0xFF2C3E6B)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFF4A6FA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cx = size.width / 2;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 44), width: 62, height: 72),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 44), width: 62, height: 72),
      outline,
    );
    canvas.drawRect(Rect.fromLTWH(cx - 16, 78, 32, 22), body);

    final torso = Path()
      ..moveTo(cx - 72, 100)
      ..lineTo(cx + 72, 100)
      ..lineTo(cx + 56, 282)
      ..lineTo(cx - 56, 282)
      ..close();
    canvas.drawPath(torso, body);
    canvas.drawPath(torso, outline);

    for (final dx in [-82.0, 82.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + dx, 114), width: 42, height: 32),
        body,
      );
    }

    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 70, 106),
      Offset(cx - 98, 222),
      22,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 98, 222),
      Offset(cx - 100, 316),
      16,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 70, 106),
      Offset(cx + 98, 222),
      22,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 98, 222),
      Offset(cx + 100, 316),
      16,
    );

    final pelvis = Path()
      ..moveTo(cx - 56, 280)
      ..lineTo(cx + 56, 280)
      ..lineTo(cx + 62, 306)
      ..lineTo(cx - 62, 306)
      ..close();
    canvas.drawPath(pelvis, body);
    canvas.drawPath(pelvis, outline);

    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 34, 304),
      Offset(cx - 36, 420),
      28,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 34, 304),
      Offset(cx + 36, 420),
      28,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx - 36, 418),
      Offset(cx - 38, 508),
      22,
    );
    _drawLimb(
      canvas,
      body,
      outline,
      Offset(cx + 36, 418),
      Offset(cx + 38, 508),
      22,
    );

    final detail = Paint()
      ..color = Color(0xFF4A6FA5).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (showFront) {
      canvas.drawLine(Offset(cx, 100), Offset(cx, 280), detail);
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(cx - 28, 178 + i * 30.0),
          Offset(cx + 28, 178 + i * 30.0),
          detail,
        );
      }
    } else {
      for (int i = 0; i < 9; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx, 108 + i * 18.0),
            width: 12,
            height: 10,
          ),
          detail,
        );
      }
    }
  }

  void _drawLimb(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    Offset top,
    Offset bottom,
    double halfW,
  ) {
    final path = Path()
      ..moveTo(top.dx - halfW, top.dy)
      ..lineTo(top.dx + halfW, top.dy)
      ..lineTo(bottom.dx + halfW * 0.85, bottom.dy)
      ..lineTo(bottom.dx - halfW * 0.85, bottom.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.selectedMuscles != selectedMuscles || old.showFront != showFront;
}
