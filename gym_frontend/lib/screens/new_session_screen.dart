import 'package:flutter/material.dart';
import '../services/member_service.dart';
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

// ─────────────────────────────────────────────
// DESIGN TOKENS

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
  int _painLevel = 0; // 0-10 : 0=aucune douleur, 10=très intense
  bool _warmupDone = true; // échauffement effectué avant la séance

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

  // ── Muscle zones ──
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
  // SUBMIT
  // ─────────────────────────────────────────────

  Future<void> _submitSession() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMuscles.isEmpty && !_hasCardio) {
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

    setState(() => _isLoading = true);

    final cardioDur = _hasCardio ? (int.tryParse(_cardioDurCtrl.text) ?? 0) : 0;

    final sessionData = {
      "date": DateTime.now().toIso8601String().split('T')[0],
      "duration": int.tryParse(_durationCtrl.text) ?? 0,
      "intensity": 5,
      "weightLifted": double.tryParse(_weightCtrl.text) ?? 0.0,
      "targetMuscles": _selectedMuscles.join(', '),
      // ── Cardio fields ──
      "hasCardio": _hasCardio,
      "cardioDurationMinutes": cardioDur,
      "cardioType": _hasCardio ? _cardioType : "",
      "cardioIntensity": _hasCardio ? _cardioIntensity : 0,
      // ── Ressenti post-séance (Niveau 2 IA) ──
      "painLevel": _painLevel,
      "warmupDone": _warmupDone,
    };

    try {
      final result = await MemberService.createSession(
        widget.memberId,
        sessionData,
      );

      if (result['success'] == true) {
        final sessionId = result['session']['id'];
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
              content: Text('Séance enregistrée !'),
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
            const SizedBox(height: 14),

            // ── Poids ──
            _SectionTitle('🏋 Poids soulevé (kg)', _kBlue),
            const SizedBox(height: 8),
            _buildField(
              _weightCtrl,
              'Poids total soulevé',
              Icons.fitness_center_rounded,
              isNumber: true,
            ),
            const SizedBox(height: 20),

            // ═══════════════════════════════════════
            // CARDIO SECTION
            // ═══════════════════════════════════════
            _buildCardioSection(),
            const SizedBox(height: 20),

            // ═══════════════════════════════════════
            // BODY MAP
            // ═══════════════════════════════════════
            _SectionTitle('💪 Muscles ciblés', _kOrange),
            const SizedBox(height: 4),
            const Text(
              'Appuyez sur un muscle pour le sélectionner',
              style: TextStyle(color: _kTextSub, fontSize: 11),
            ),
            const SizedBox(height: 12),

            // Toggle avant/arrière
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

            // Muscles sélectionnés (chips) avec bouton "Voir exercices"
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
                        onDeleted: () =>
                            setState(() => _selectedMuscles.remove(m)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              // ⭐ NOUVEAU BOUTON : Voir les exercices du muscle sélectionné
              if (_selectedMuscles.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedMuscles.map((muscle) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExerciseScreen(
                                muscleName: muscle,
                                lastWorkedHours: 72,
                              ),
                            ),
                          );
                        },
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
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 10),
            ],

            // SVG Body Map (sélection uniquement, pas de navigation)
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
                          // ✅ Appui simple → sélectionner/désélectionner
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

            // Badges muscles (sélection uniquement)
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
                      color: isSelected
                          ? _kGreen.withValues(alpha: 0.15)
                          : _kSurf2,
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
            const SizedBox(height: 24),

            // ═══════════════════════════════════════
            // RESSENTI POST-SÉANCE (Niveau 2 IA)
            // ═══════════════════════════════════════
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
  // CARDIO SECTION WIDGET
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
          // Toggle header
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

          // Cardio details (visible si activé)
          if (_hasCardio) ...[
            const Divider(color: _kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Type de cardio ──
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

                  // ── Durée cardio ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Durée (minutes)',
                              style: TextStyle(
                                color: _kTextSub,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildField(
                              _cardioDurCtrl,
                              'Ex: 30',
                              Icons.timer_outlined,
                              isNumber: true,
                              required: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Intensité cardio ──
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
                      overlayColor: (_cardioColors[_cardioType] ?? _kGreen)
                          .withValues(alpha: 0.12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Légère',
                        style: TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                      const Text(
                        'Modérée',
                        style: TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                      const Text(
                        'Intense',
                        style: TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                    ],
                  ),

                  // ── Warning HIIT ──
                  if (_cardioType == 'HIIT' && _cardioIntensity >= 8) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _kRed.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: _kRed,
                            size: 14,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'HIIT haute intensité — l\'IA analysera le risque de surcharge accru',
                              style: TextStyle(color: _kRed, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RESSENTI POST-SÉANCE WIDGET (Niveau 2 IA)
  // ─────────────────────────────────────────────

  Widget _buildRessentSection() {
    // Couleur dynamique selon le niveau de douleur
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
          // ── Header ──
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ressenti post-séance',
                        style: TextStyle(
                          color: _kText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Ces informations améliorent les prédictions de l\'IA',
                        style: const TextStyle(color: _kTextSub, fontSize: 11),
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
                // ─────────────────────────────────
                // ÉCHAUFFEMENT
                // ─────────────────────────────────
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

                // Alerte si pas d'échauffement
                if (!_warmupDone) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _kOrange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _kOrange,
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sans échauffement, le risque de blessure augmente de 40% — l\'IA en tiendra compte.',
                            style: TextStyle(color: _kOrange, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ─────────────────────────────────
                // DOULEUR RESSENTIE
                // ─────────────────────────────────
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
                    // Badge niveau de douleur
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

                // Slider douleur
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: painColor,
                    inactiveTrackColor: _kBorder,
                    thumbColor: painColor,
                    overlayColor: painColor.withValues(alpha: 0.12),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Aucune',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                    Text(
                      'Légère',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                    Text(
                      'Modérée',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                    Text(
                      'Intense',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                  ],
                ),

                // Alerte douleur élevée
                if (_painLevel >= 7) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kRed.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.medical_services_rounded,
                          color: _kRed,
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Douleur intense détectée — l\'IA augmentera le niveau de risque de blessure. Consultez un professionnel si la douleur persiste.',
                            style: TextStyle(color: _kRed, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Émojis visuels niveau douleur
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PainEmoji(0, '😊', 'Aucune', _painLevel),
                    _PainEmoji(3, '😐', 'Légère', _painLevel),
                    _PainEmoji(6, '😣', 'Modérée', _painLevel),
                    _PainEmoji(8, '😖', 'Forte', _painLevel),
                    _PainEmoji(10, '😱', 'Intense', _painLevel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PREDICTION WIDGET — enrichi
  // ─────────────────────────────────────────────

  Widget _buildPrediction() {
    final fatigue = _prediction!['fatigue'];
    final injury = _prediction!['injury'];
    final overload = _prediction!['overload'];

    final fatigueLbl = fatigue?['label'] ?? 'N/A';
    final injuryLbl = injury?['label'] ?? 'N/A';
    final riskLevel = overload?['riskLevel'] ?? 'NORMAL';
    final riskMuscles =
        (overload?['highRiskMuscles'] as List?)?.cast<String>() ?? [];
    final warnings = (overload?['warnings'] as List?)?.cast<String>() ?? [];
    final recs = (overload?['recommendations'] as List?)?.cast<String>() ?? [];
    final hasCardioIA =
        fatigue?['hasCardio'] == true || injury?['hasCardio'] == true;

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
          // Header
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
              if (hasCardioIA) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, color: _kPurple, size: 11),
                      SizedBox(width: 4),
                      Text(
                        'CARDIO INCLUS',
                        style: TextStyle(
                          color: _kPurple,
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
          // ── Résumé ressenti pris en compte ──
          if (_painLevel > 0 || !_warmupDone) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (_painLevel > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (_painLevel >= 7
                                  ? _kRed
                                  : _painLevel >= 4
                                  ? _kOrange
                                  : _kGreen)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medical_services_rounded,
                          color: _painLevel >= 7
                              ? _kRed
                              : _painLevel >= 4
                              ? _kOrange
                              : _kGreen,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'DOULEUR $_painLevel/10 PRISE EN COMPTE',
                          style: TextStyle(
                            color: _painLevel >= 7
                                ? _kRed
                                : _painLevel >= 4
                                ? _kOrange
                                : _kGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_warmupDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: _kOrange,
                          size: 10,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'SANS ÉCHAUFFEMENT',
                          style: TextStyle(
                            color: _kOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Fatigue + Blessure
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

          // Charge hebdo
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
                        '${overload?['sessionCount'] ?? 0} séances • '
                        '${overload?['totalMinutes'] ?? 0} min muscu'
                        '${(overload?['totalCardioMinutes'] ?? 0) > 0 ? ' + ${overload!['totalCardioMinutes']} min cardio' : ''}',
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

          // Muscles à risque
          if (riskMuscles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _kOrange,
                        size: 13,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Muscles à risque ciblés',
                        style: TextStyle(
                          color: _kOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: riskMuscles
                        .map(
                          (m) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _kOrange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              m,
                              style: const TextStyle(
                                color: _kOrange,
                                fontSize: 10,
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

          // Warnings + recommandations
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
                              color: Colors.white60,
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
  // HELPERS
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
}

// ─────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
    );
  }
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

// ── Widget emoji douleur cliquable ──
class _PainEmoji extends StatelessWidget {
  final int targetLevel;
  final String emoji;
  final String label;
  final int currentLevel;

  const _PainEmoji(this.targetLevel, this.emoji, this.label, this.currentLevel);

  bool get _isActive {
    if (targetLevel == 0) return currentLevel == 0;
    if (targetLevel == 10) return currentLevel >= 9;
    return (currentLevel - targetLevel).abs() <= 1;
  }

  @override
  Widget build(BuildContext context) {
    final active = _isActive;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active
                ? (targetLevel >= 7
                          ? _kRed
                          : targetLevel >= 4
                          ? _kOrange
                          : _kGreen)
                      .withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(
                    color:
                        (targetLevel >= 7
                                ? _kRed
                                : targetLevel >= 4
                                ? _kOrange
                                : _kGreen)
                            .withValues(alpha: 0.4),
                  )
                : null,
          ),
          child: Text(emoji, style: TextStyle(fontSize: active ? 22 : 18)),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: active ? _kText : _kTextSub,
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _PredCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
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
      canvas.drawLine(Offset(cx - 52, 166), Offset(cx + 52, 166), detail);
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
