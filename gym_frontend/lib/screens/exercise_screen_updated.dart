import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/exercise_service.dart';

final Map<String, Map<String, dynamic>> muscleMetadata = {
  'Pectoraux': {'recovery': 48, 'difficulty': 'Intermédiaire'},
  'Biceps': {'recovery': 24, 'difficulty': 'Débutant'},
  'Biceps droit': {'recovery': 24, 'difficulty': 'Débutant'},
  'Épaules': {'recovery': 24, 'difficulty': 'Intermédiaire'},
  'Abdominaux': {'recovery': 24, 'difficulty': 'Débutant'},
  'Quadriceps': {'recovery': 72, 'difficulty': 'Avancé'},
  'Quadriceps droit': {'recovery': 72, 'difficulty': 'Avancé'},
  'Mollets': {'recovery': 24, 'difficulty': 'Débutant'},
  'Mollets droits': {'recovery': 24, 'difficulty': 'Débutant'},
  'Dorsaux': {'recovery': 48, 'difficulty': 'Intermédiaire'},
  'Triceps': {'recovery': 24, 'difficulty': 'Débutant'},
  'Triceps droit': {'recovery': 24, 'difficulty': 'Débutant'},
  'Trapèzes': {'recovery': 24, 'difficulty': 'Intermédiaire'},
  'Lombaires': {'recovery': 48, 'difficulty': 'Avancé'},
  'Ischio-jambiers': {'recovery': 72, 'difficulty': 'Intermédiaire'},
  'Ischio-jambiers droits': {'recovery': 72, 'difficulty': 'Intermédiaire'},
  'Fessiers': {'recovery': 48, 'difficulty': 'Intermédiaire'},
};

const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenLight = Color(0xFFE0F2F1);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class ExerciseScreen extends StatefulWidget {
  final String muscleName;
  final int lastWorkedHours;

  const ExerciseScreen({
    super.key,
    required this.muscleName,
    this.lastWorkedHours = 72,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  int _activeExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    final data = await ExerciseService.getExercisesByMuscle(widget.muscleName);

    if (mounted) {
      setState(() {
        if (data.isNotEmpty) {
          _exercises = data
              .map<Map<String, dynamic>>(
                (e) => {
                  'name': e['name'] ?? '',
                  'sets': e['sets'] ?? '3',
                  'reps': e['reps'] ?? '10-12',
                  'secondary': e['secondaryMuscles'] ?? '',
                  'description': e['description'] ?? '',
                  'difficulty': e['difficulty'] ?? 'Intermédiaire',
                  'recoveryHours': e['recoveryHours'] ?? 48,
                  'videoUrl': e['videoUrl'] ?? '',
                },
              )
              .toList();
        }
        _isLoading = false;
      });
      if (_exercises.isNotEmpty) _startAnimationLoop();
    }
  }

  void _startAnimationLoop() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _exercises.isEmpty) return;
      setState(() {
        _activeExerciseIndex = (_activeExerciseIndex + 1) % _exercises.length;
      });
      if (mounted) _startAnimationLoop();
    });
  }

  Future<void> _launchVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la vidéo'),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = muscleMetadata[widget.muscleName];
    final int recovery = _exercises.isNotEmpty
        ? (_exercises.first['recoveryHours'] as int? ?? 48)
        : (meta?['recovery'] as int? ?? 48);
    final String difficulty = _exercises.isNotEmpty
        ? (_exercises.first['difficulty'] ?? 'Intermédiaire')
        : (meta?['difficulty'] ?? 'Intermédiaire');
    final isRecoveryAlert = widget.lastWorkedHours < 48;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          widget.muscleName,
          style: const TextStyle(color: _kText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kText),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRecoveryAlert)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kRed.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: _kRed,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ce muscle n\'est pas encore récupéré !',
                                style: TextStyle(
                                  color: _kRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildHeader(widget.muscleName, recovery, difficulty),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Exercices recommandés',
                          style: TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _kGreenLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_exercises.length} exercice${_exercises.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: _kGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_exercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _kBorder),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 48,
                                color: _kBorder,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aucun exercice disponible.\nL\'admin n\'a pas encore configuré ce muscle.',
                                style: TextStyle(color: _kTextSub),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._exercises.asMap().entries.map(
                        (entry) => _buildExerciseCard(
                          entry.value,
                          entry.key == _activeExerciseIndex,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String muscle, int recovery, String difficulty) {
    Color diffColor;
    Color diffBg;
    if (difficulty == 'Avancé') {
      diffColor = _kRed;
      diffBg = const Color(0xFFFFEBEE);
    } else if (difficulty == 'Intermédiaire') {
      diffColor = _kOrange;
      diffBg = const Color(0xFFFFF3E0);
    } else {
      diffColor = _kGreen;
      diffBg = _kGreenLight;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kGreenLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.fitness_center, size: 36, color: _kGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscle,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: _kTextSub,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$recovery-72h de récupération',
                      style: const TextStyle(color: _kTextSub, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: diffBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, bool active) {
    final hasVideo = (exercise['videoUrl'] ?? '').isNotEmpty;
    final hasDesc = (exercise['description'] ?? '').isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: active ? 6.0 : 0.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? _kGreen.withValues(alpha: 0.6) : _kBorder,
              width: active ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? _kGreen.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: active ? 20 : 8,
                offset: Offset(0, active ? 8 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Corps ──
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: Offset(value, 0),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: _kGreenLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: _kGreen,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise['name'] as String,
                                style: const TextStyle(
                                  color: _kText,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    Icons.repeat,
                                    'Sets',
                                    exercise['sets'] as String,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    Icons.numbers,
                                    'Reps',
                                    exercise['reps'] as String,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreenLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '▶ Actif',
                              style: TextStyle(
                                color: _kGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if ((exercise['secondary'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.account_tree,
                            size: 13,
                            color: _kTextSub,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Secondaires : ${exercise['secondary']}',
                              style: const TextStyle(
                                color: _kTextSub,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Description / Technique ──
                    if (hasDesc) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kSurf2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: 15,
                                  color: _kGreen,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Technique',
                                  style: TextStyle(
                                    color: _kGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exercise['description'] as String,
                              style: const TextStyle(
                                color: _kText,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Bandeau Vidéo cliquable ──
              if (hasVideo)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFFF0C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _launchVideo(exercise['videoUrl'] as String),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _kOrange,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kOrange.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
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
                                      fontWeight: FontWeight.bold,
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
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kSurf2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _kGreen),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: _kText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
