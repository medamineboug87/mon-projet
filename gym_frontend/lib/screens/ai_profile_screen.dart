// lib/screens/ai_profile_screen.dart
//
// Résout les Limites 4, 10 et 11 côté Flutter :
//   - Limite 4  : avgSleepHours + stressLevel → endpoint /ai-profile
//   - Limite 10 : profil médical complet (blessures, douleurs chroniques, antécédents)
//   - Limite 11 : objectif personnel principal + niveau déclaré

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

// ─── Design tokens (cohérents avec le reste du projet) ───
const Color _kBg      = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2   = Color(0xFFEEF1F8);
const Color _kGreen   = Color(0xFF00897B);
const Color _kGreenL  = Color(0xFFE0F2F1);
const Color _kBlue    = Color(0xFF1976D2);
const Color _kBlueL   = Color(0xFFE3F2FD);
const Color _kOrange  = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed     = Color(0xFFE53935);
const Color _kRedL    = Color(0xFFFFEBEE);
const Color _kPurple  = Color(0xFF7B1FA2);
const Color _kPurpleL = Color(0xFFF3E5F5);
const Color _kText    = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder  = Color(0xFFDDE2EE);

// ─── Données statiques ───

const List<Map<String, String>> _kGoals = [
  {'value': 'WEIGHT_LOSS',     'label': 'Perte de poids',              'emoji': '🏃'},
  {'value': 'MUSCLE_GAIN',     'label': 'Prise de masse musculaire',   'emoji': '💪'},
  {'value': 'ENDURANCE',       'label': 'Endurance cardiovasculaire',  'emoji': '🚴'},
  {'value': 'TONING',          'label': 'Tonification',                'emoji': '✨'},
  {'value': 'GENERAL_FITNESS', 'label': 'Bien-être général',           'emoji': '💚'},
  {'value': 'REHABILITATION',  'label': 'Rééducation',                 'emoji': '🩺'},
  {'value': 'PERFORMANCE',     'label': 'Performance sportive',        'emoji': '🏆'},
];

const List<Map<String, String>> _kLevels = [
  {'value': 'BEGINNER',     'label': 'Débutant',       'sub': '< 1 an d\'expérience'},
  {'value': 'INTERMEDIATE', 'label': 'Intermédiaire',  'sub': '1 à 3 ans'},
  {'value': 'ADVANCED',     'label': 'Avancé',         'sub': '3 à 5 ans'},
  {'value': 'ATHLETE',      'label': 'Athlète',        'sub': '5+ ans / compétiteur'},
];

const List<Map<String, String>> _kPainZones = [
  {'value': 'NONE',           'label': 'Aucune'},
  {'value': 'NECK',           'label': 'Nuque / Cou'},
  {'value': 'LOWER_BACK',     'label': 'Bas du dos'},
  {'value': 'UPPER_BACK',     'label': 'Haut du dos'},
  {'value': 'LEFT_SHOULDER',  'label': 'Épaule gauche'},
  {'value': 'RIGHT_SHOULDER', 'label': 'Épaule droite'},
  {'value': 'LEFT_KNEE',      'label': 'Genou gauche'},
  {'value': 'RIGHT_KNEE',     'label': 'Genou droit'},
  {'value': 'LEFT_ANKLE',     'label': 'Cheville gauche'},
  {'value': 'RIGHT_ANKLE',    'label': 'Cheville droite'},
  {'value': 'LEFT_HIP',       'label': 'Hanche gauche'},
  {'value': 'RIGHT_HIP',      'label': 'Hanche droite'},
  {'value': 'LEFT_ELBOW',     'label': 'Coude gauche'},
  {'value': 'RIGHT_ELBOW',    'label': 'Coude droit'},
  {'value': 'WRISTS',         'label': 'Poignets'},
];

// ════════════════════════════════════════════════════════════
// MAIN SCREEN
// ════════════════════════════════════════════════════════════

class AIProfileScreen extends StatefulWidget {
  final int memberId;

  const AIProfileScreen({super.key, required this.memberId});

  @override
  State<AIProfileScreen> createState() => _AIProfileScreenState();
}

class _AIProfileScreenState extends State<AIProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _isLoading = true;
  bool _isSaving  = false;
  Map<String, dynamic>? _profile;

  // ── Limite 11 : Objectif & Niveau ──
  String _primaryGoal   = 'GENERAL_FITNESS';
  String _fitnessLevel  = 'BEGINNER';
  int    _yearsExperience = 0;

  // ── Limite 4 : Sommeil & Stress ──
  double _avgSleepHours = 7.0;
  int    _stressLevel   = 5;
  String _outsideActivity = '';
  String _dietType      = 'Omnivore';
  double _waterIntake   = 1.5;

  // ── Limite 10 : Profil médical ──
  final _medicalCtrl        = TextEditingController();
  final _allergiesCtrl      = TextEditingController();
  final _medicationsCtrl    = TextEditingController();
  final _injuryHistoryCtrl  = TextEditingController();
  final _currentInjuriesCtrl = TextEditingController();
  final _surgicalHistoryCtrl = TextEditingController();
  final _restrictionsCtrl   = TextEditingController();
  bool   _hasMedicalFollowUp = false;
  final _medFollowUpDetailCtrl = TextEditingController();
  Set<String> _selectedPainZones = {'NONE'};
  int    _chronicPainIntensity = 0;

  static const List<String> _dietOptions = [
    'Omnivore', 'Végétarien', 'Vegan', 'Keto / Low-carb',
    'Méditerranéen', 'Sans gluten', 'Halal', 'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _medicalCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _injuryHistoryCtrl.dispose();
    _currentInjuriesCtrl.dispose();
    _surgicalHistoryCtrl.dispose();
    _restrictionsCtrl.dispose();
    _medFollowUpDetailCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // API
  // ─────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/members/${widget.memberId}/ai-profile'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        _applyProfile(data);
        setState(() {
          _profile  = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyProfile(Map<String, dynamic> data) {
    // Objectif & Niveau (Limite 11)
    _primaryGoal    = data['primaryGoal']      ?? 'GENERAL_FITNESS';
    _fitnessLevel   = data['selfDeclaredLevel'] ?? 'BEGINNER';
    _yearsExperience = data['yearsOfExperience'] ?? 0;

    // Sommeil & Stress (Limite 4)
    _avgSleepHours  = (data['avgSleepHours'] as num?)?.toDouble() ?? 7.0;
    _stressLevel    = data['stressLevel'] ?? 5;
    _outsideActivity = data['outsideGymActivity'] ?? '';
    _dietType       = data['dietType'] ?? 'Omnivore';
    _waterIntake    = (data['dailyWaterIntake'] as num?)?.toDouble() ?? 1.5;

    // Profil médical (Limite 10)
    _medicalCtrl.text         = data['medicalConditions']        ?? '';
    _allergiesCtrl.text       = data['allergiesContraindications'] ?? '';
    _medicationsCtrl.text     = data['currentMedications']       ?? '';
    _injuryHistoryCtrl.text   = data['injuryHistory']            ?? '';
    _currentInjuriesCtrl.text = data['currentInjuries']          ?? '';
    _surgicalHistoryCtrl.text = data['surgicalHistory']          ?? '';
    _restrictionsCtrl.text    = data['exerciseRestrictions']     ?? '';
    _hasMedicalFollowUp       = data['hasMedicalFollowUp']       ?? false;
    _medFollowUpDetailCtrl.text = data['medicalFollowUpDetail']  ?? '';
    _chronicPainIntensity     = data['chronicPainIntensity']     ?? 0;

    final zones = data['chronicPainZones'];
    if (zones != null && zones.toString().isNotEmpty) {
      _selectedPainZones = zones.toString().split(',').map((s) => s.trim()).toSet();
    } else {
      _selectedPainZones = {'NONE'};
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final painZones = _selectedPainZones.contains('NONE')
        ? 'NONE'
        : _selectedPainZones.where((z) => z != 'NONE').join(',');

    final body = {
      // Limite 11
      'primaryGoal':           _primaryGoal,
      'selfDeclaredLevel':     _fitnessLevel,
      'yearsOfExperience':     _yearsExperience,
      // Limite 4
      'avgSleepHours':         _avgSleepHours,
      'stressLevel':           _stressLevel,
      'outsideGymActivity':    _outsideActivity,
      'dietType':              _dietType,
      'dailyWaterIntake':      _waterIntake,
      // Limite 10
      'medicalConditions':       _medicalCtrl.text.trim(),
      'allergiesContraindications': _allergiesCtrl.text.trim(),
      'currentMedications':    _medicationsCtrl.text.trim(),
      'injuryHistory':         _injuryHistoryCtrl.text.trim(),
      'currentInjuries':       _currentInjuriesCtrl.text.trim(),
      'surgicalHistory':       _surgicalHistoryCtrl.text.trim(),
      'exerciseRestrictions':  _restrictionsCtrl.text.trim(),
      'hasMedicalFollowUp':    _hasMedicalFollowUp,
      'medicalFollowUpDetail': _medFollowUpDetailCtrl.text.trim(),
      'chronicPainZones':      painZones,
      'chronicPainIntensity':  _chronicPainIntensity,
    };

    try {
      final r = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/members/${widget.memberId}/ai-profile'),
        headers: await _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (r.statusCode == 200) {
        _snack('Profil IA sauvegardé !', _kGreen);
        await _loadProfile();
      } else {
        _snack('Erreur lors de la sauvegarde', _kRed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        _snack('Erreur réseau', _kRed);
      }
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
          'Profil IA personnalisé',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              const Divider(height: 1, color: _kBorder),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: _kGreen,
                labelColor: _kGreen,
                unselectedLabelColor: _kTextSub,
                tabs: const [
                  Tab(icon: Icon(Icons.flag_rounded,       size: 18), text: 'Objectif'),
                  Tab(icon: Icon(Icons.nightlight_rounded, size: 18), text: 'Vie & Récup.'),
                  Tab(icon: Icon(Icons.medical_services_rounded, size: 18), text: 'Médical'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save_rounded, color: _kGreen, size: 18),
                      label: const Text(
                        'Sauvegarder',
                        style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : Column(
              children: [
                // Bandeau de complétude
                _buildCompletenessBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildGoalTab(),
                      _buildLifestyleTab(),
                      _buildMedicalTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    label: Text(
                      _isSaving ? 'Sauvegarde en cours...' : 'Sauvegarder le profil IA',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────
  // BANDEAU DE COMPLÉTUDE
  // ─────────────────────────────────────────────

  Widget _buildCompletenessBar() {
    // Calculer le score de complétude
    int score = 0;
    if (_primaryGoal.isNotEmpty) score++;
    if (_fitnessLevel.isNotEmpty) score++;
    if (_avgSleepHours > 0) score++;
    if (_stressLevel > 0) score++;
    if (!_selectedPainZones.isEmpty) score++;
    final pct = score / 5;

    Color barColor = pct >= 0.8 ? _kGreen : pct >= 0.5 ? _kOrange : _kRed;

    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: barColor, size: 14),
              const SizedBox(width: 6),
              Text(
                'Complétude du profil IA : ${(pct * 100).toInt()}%',
                style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                pct >= 0.8 ? '✅ Prédictions optimales' : '⚠️ Complétez pour de meilleures prédictions',
                style: TextStyle(color: barColor, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _kBorder,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1 — OBJECTIF & NIVEAU (Limite 11)
  // ═══════════════════════════════════════════════════════════

  Widget _buildGoalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          icon: Icons.flag_rounded,
          color: _kGreen,
          title: 'Objectif principal',
          subtitle: 'Oriente toutes les recommandations IA',
          child: Column(
            children: _kGoals.map((goal) {
              final isSelected = _primaryGoal == goal['value'];
              return _buildGoalTile(
                value:    goal['value']!,
                label:    goal['label']!,
                emoji:    goal['emoji']!,
                selected: isSelected,
                onTap:    () => setState(() => _primaryGoal = goal['value']!),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        _SectionCard(
          icon: Icons.bar_chart_rounded,
          color: _kBlue,
          title: 'Niveau déclaré',
          subtitle: 'Ajuste les multiplicateurs de risque IA',
          child: Column(
            children: _kLevels.map((lvl) {
              final isSelected = _fitnessLevel == lvl['value'];
              return _buildLevelTile(
                value:    lvl['value']!,
                label:    lvl['label']!,
                sub:      lvl['sub']!,
                selected: isSelected,
                onTap:    () => setState(() => _fitnessLevel = lvl['value']!),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        _SectionCard(
          icon: Icons.workspace_premium_rounded,
          color: _kOrange,
          title: 'Années d\'expérience sportive',
          subtitle: 'Complète la détection automatique par séances',
          child: _buildYearsSelector(),
        ),

        const SizedBox(height: 8),
        _buildImpactCard(
          title: 'Impact sur les prédictions',
          items: [
            _ImpactItem('Objectif WEIGHT_LOSS', 'Recommandations cardio accrues, charges modérées', _kGreen),
            _ImpactItem('Objectif REHABILITATION', 'Multiplicateur de risque × 0.7, alertes spécifiques', _kOrange),
            _ImpactItem('Objectif PERFORMANCE', 'Multiplicateur de risque × 1.3, volume élevé accepté', _kRed),
            _ImpactItem('Niveau BEGINNER', 'Temps de récupération × 2, seuils de fatigue bas', _kBlue),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalTile({
    required String value, required String label, required String emoji,
    required bool selected, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kGreen.withOpacity(0.10) : _kSurf2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kGreen.withOpacity(0.5) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? _kGreen : _kText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelTile({
    required String value, required String label, required String sub,
    required bool selected, required VoidCallback onTap,
  }) {
    Color levelColor;
    switch (value) {
      case 'BEGINNER':     levelColor = _kGreen; break;
      case 'INTERMEDIATE': levelColor = _kBlue;  break;
      case 'ADVANCED':     levelColor = _kOrange; break;
      default:             levelColor = _kRed;
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? levelColor.withOpacity(0.10) : _kSurf2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? levelColor.withOpacity(0.5) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: levelColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    color: selected ? levelColor : _kText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 14,
                  )),
                  Text(sub, style: const TextStyle(color: _kTextSub, fontSize: 11)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: levelColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildYearsSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleBtn(
          icon: Icons.remove_rounded,
          color: _kRed,
          onTap: () => setState(() => _yearsExperience = (_yearsExperience - 1).clamp(0, 40)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Text(
                '$_yearsExperience',
                style: const TextStyle(color: _kText, fontSize: 44, fontWeight: FontWeight.w900),
              ),
              const Text('années', style: TextStyle(color: _kTextSub, fontSize: 12)),
            ],
          ),
        ),
        _CircleBtn(
          icon: Icons.add_rounded,
          color: _kGreen,
          onTap: () => setState(() => _yearsExperience = (_yearsExperience + 1).clamp(0, 40)),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2 — STYLE DE VIE & RÉCUPÉRATION (Limite 4)
  // ═══════════════════════════════════════════════════════════

  Widget _buildLifestyleTab() {
    Color sleepColor = _avgSleepHours >= 7 ? _kGreen : _avgSleepHours >= 6 ? _kOrange : _kRed;
    Color stressColor = _stressLevel <= 4 ? _kGreen : _stressLevel <= 7 ? _kOrange : _kRed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Sommeil ──
        _SectionCard(
          icon: Icons.nightlight_rounded,
          color: _kBlue,
          title: 'Sommeil moyen par nuit',
          subtitle: 'Impact direct sur la récupération musculaire',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_avgSleepHours.toStringAsFixed(1)} h',
                    style: TextStyle(color: sleepColor, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sleepColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _avgSleepHours >= 7 ? '✅ Suffisant' : _avgSleepHours >= 6 ? '⚠️ Limite' : '🔴 Insuffisant',
                      style: TextStyle(color: sleepColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: sleepColor,
                  inactiveTrackColor: _kBorder,
                  thumbColor: sleepColor,
                  trackHeight: 5,
                ),
                child: Slider(
                  value: _avgSleepHours,
                  min: 3, max: 12, divisions: 18,
                  onChanged: (v) => setState(() => _avgSleepHours = double.parse(v.toStringAsFixed(1))),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('3h', style: TextStyle(color: _kTextSub, fontSize: 10)),
                  Text('Recommandé : 7-9h', style: TextStyle(color: _kTextSub, fontSize: 10)),
                  Text('12h', style: TextStyle(color: _kTextSub, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              _buildImpactRow(
                _avgSleepHours < 6
                    ? '🔴 Récupération × 1.45 — risque accru de blessure'
                    : _avgSleepHours < 7
                    ? '⚠️ Récupération × 1.15 — légèrement ralentie'
                    : '✅ Récupération optimale',
                sleepColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Stress ──
        _SectionCard(
          icon: Icons.psychology_alt_rounded,
          color: _kOrange,
          title: 'Niveau de stress chronique',
          subtitle: 'Le cortisol élevé ralentit la récupération musculaire',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_stressLevel / 10',
                    style: TextStyle(color: stressColor, fontSize: 32, fontWeight: FontWeight.w900),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: stressColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _stressLevel <= 4 ? '✅ Maîtrisé' : _stressLevel <= 7 ? '⚠️ Modéré' : '🔴 Élevé',
                      style: TextStyle(color: stressColor, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: stressColor,
                  inactiveTrackColor: _kBorder,
                  thumbColor: stressColor,
                  trackHeight: 5,
                ),
                child: Slider(
                  value: _stressLevel.toDouble(),
                  min: 0, max: 10, divisions: 10,
                  onChanged: (v) => setState(() => _stressLevel = v.round()),
                ),
              ),
              _buildImpactRow(
                _stressLevel >= 8
                    ? '🔴 Récupération × 1.25 — envisagez du yoga/méditation'
                    : _stressLevel >= 6
                    ? '⚠️ Récupération × 1.10 — surveillez la surcharge'
                    : '✅ Pas d\'impact sur la récupération',
                stressColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Hydratation ──
        _SectionCard(
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF0288D1),
          title: 'Hydratation quotidienne',
          subtitle: 'Recommandé : 2 à 3L par jour',
          child: Column(
            children: [
              Text(
                '${_waterIntake.toStringAsFixed(1)} L / jour',
                style: const TextStyle(color: Color(0xFF0288D1), fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: const SliderThemeData(
                  activeTrackColor: Color(0xFF0288D1),
                  inactiveTrackColor: _kBorder,
                  thumbColor: Color(0xFF0288D1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _waterIntake,
                  min: 0.5, max: 5, divisions: 18,
                  onChanged: (v) => setState(() => _waterIntake = double.parse(v.toStringAsFixed(1))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Alimentation ──
        _SectionCard(
          icon: Icons.restaurant_rounded,
          color: _kPurple,
          title: 'Type d\'alimentation',
          subtitle: 'Informe les recommandations nutritionnelles',
          child: DropdownButtonFormField<String>(
            value: _dietOptions.contains(_dietType) ? _dietType : 'Omnivore',
            dropdownColor: _kSurface,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: _kSurf2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder),
              ),
            ),
            items: _dietOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _dietType = v ?? 'Omnivore'),
          ),
        ),
        const SizedBox(height: 14),

        // ── Activité hors salle ──
        _SectionCard(
          icon: Icons.directions_walk_rounded,
          color: _kGreen,
          title: 'Activité physique hors salle',
          subtitle: 'Ex : marche, vélo domicile-travail, jardinage',
          child: _buildTextField(
            hint: 'Ex: marche 20 min/jour, vélo le week-end...',
            onChanged: (v) => _outsideActivity = v,
            initialValue: _outsideActivity,
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3 — PROFIL MÉDICAL (Limite 10)
  // ═══════════════════════════════════════════════════════════

  Widget _buildMedicalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Alerte
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kBlueL,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBlue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _kBlue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ces informations restent privées et ne sont utilisées que pour personnaliser les recommandations IA et les alertes coach.',
                  style: TextStyle(color: _kBlue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Zones de douleur chronique ──
        _SectionCard(
          icon: Icons.location_on_rounded,
          color: _kRed,
          title: 'Zones de douleur chronique',
          subtitle: 'Augmente le multiplicateur de risque IA pour ces zones',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kPainZones.map((zone) {
                  final isSelected = _selectedPainZones.contains(zone['value']);
                  final isNone = zone['value'] == 'NONE';
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isNone) {
                        _selectedPainZones = {'NONE'};
                      } else {
                        _selectedPainZones.remove('NONE');
                        if (isSelected)
                          _selectedPainZones.remove(zone['value']);
                        else
                          _selectedPainZones.add(zone['value']!);
                        if (_selectedPainZones.isEmpty)
                          _selectedPainZones = {'NONE'};
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isNone ? _kGreen : _kRed).withOpacity(0.12)
                            : _kSurf2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? (isNone ? _kGreen : _kRed).withOpacity(0.5) : _kBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        zone['label']!,
                        style: TextStyle(
                          color: isSelected ? (isNone ? _kGreen : _kRed) : _kTextSub,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (!_selectedPainZones.contains('NONE')) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Intensité de la douleur', style: TextStyle(color: _kTextSub, fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(
                      '$_chronicPainIntensity/10',
                      style: TextStyle(
                        color: _chronicPainIntensity >= 7 ? _kRed : _chronicPainIntensity >= 4 ? _kOrange : _kGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _chronicPainIntensity >= 7 ? _kRed : _chronicPainIntensity >= 4 ? _kOrange : _kGreen,
                    inactiveTrackColor: _kBorder,
                    thumbColor: _chronicPainIntensity >= 7 ? _kRed : _kOrange,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _chronicPainIntensity.toDouble(),
                    min: 0, max: 10, divisions: 10,
                    onChanged: (v) => setState(() => _chronicPainIntensity = v.round()),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Blessures actuelles ──
        _SectionCard(
          icon: Icons.healing_rounded,
          color: _kRed,
          title: 'Blessures actuelles / en rééducation',
          subtitle: 'Déclenche des alertes spécifiques pour le coach',
          child: _buildTextFieldController(
            ctrl: _currentInjuriesCtrl,
            hint: 'Ex: entorse cheville gauche en cours, douleur épaule droite...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Antécédents ──
        _SectionCard(
          icon: Icons.history_rounded,
          color: _kOrange,
          title: 'Antécédents de blessures',
          subtitle: 'Historique des blessures passées importantes',
          child: _buildTextFieldController(
            ctrl: _injuryHistoryCtrl,
            hint: 'Ex: déchirure LCA genou droit 2019, fracture coude 2021...',
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 14),

        // ── Antécédents chirurgicaux ──
        _SectionCard(
          icon: Icons.local_hospital_rounded,
          color: _kPurple,
          title: 'Antécédents chirurgicaux',
          subtitle: 'Opérations pouvant affecter la mobilité ou la charge',
          child: _buildTextFieldController(
            ctrl: _surgicalHistoryCtrl,
            hint: 'Ex: opération ménisque 2020, prothèse de hanche gauche...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Conditions médicales ──
        _SectionCard(
          icon: Icons.medical_services_rounded,
          color: _kBlue,
          title: 'Conditions médicales générales',
          subtitle: 'Pathologies pouvant influencer l\'effort physique',
          child: _buildTextFieldController(
            ctrl: _medicalCtrl,
            hint: 'Ex: diabète type 2, hypertension, asthme d\'effort...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Allergies ──
        _SectionCard(
          icon: Icons.warning_amber_rounded,
          color: _kOrange,
          title: 'Allergies & Contre-indications',
          subtitle: 'Allergies ou contre-indications à prendre en compte',
          child: _buildTextFieldController(
            ctrl: _allergiesCtrl,
            hint: 'Ex: allergie latex, contre-indication à la plongeon...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Médicaments ──
        _SectionCard(
          icon: Icons.medication_rounded,
          color: _kPurple,
          title: 'Médicaments en cours (optionnel)',
          subtitle: 'Certains médicaments affectent la fréquence cardiaque ou la récupération',
          child: _buildTextFieldController(
            ctrl: _medicationsCtrl,
            hint: 'Ex: bêtabloquants, anticoagulants, corticoïdes...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Suivi médical ──
        _SectionCard(
          icon: Icons.person_search_rounded,
          color: _kGreen,
          title: 'Suivi médical actif',
          subtitle: 'Kinésithérapeute, cardiologue, médecin du sport...',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Suivi médical en cours ?',
                            style: TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(
                          _hasMedicalFollowUp ? '✅ Oui — précisez ci-dessous' : 'Non',
                          style: TextStyle(color: _hasMedicalFollowUp ? _kGreen : _kTextSub, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _hasMedicalFollowUp,
                    onChanged: (v) => setState(() => _hasMedicalFollowUp = v),
                    activeColor: _kGreen,
                  ),
                ],
              ),
              if (_hasMedicalFollowUp) ...[
                const SizedBox(height: 10),
                _buildTextFieldController(
                  ctrl: _medFollowUpDetailCtrl,
                  hint: 'Ex: kiné 2×/semaine (genou), cardiologue mensuel...',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Restrictions d'exercices ──
        _SectionCard(
          icon: Icons.block_rounded,
          color: _kRed,
          title: 'Exercices à éviter',
          subtitle: 'L\'IA et le coach seront alertés si ces exercices sont pratiqués',
          child: _buildTextFieldController(
            ctrl: _restrictionsCtrl,
            hint: 'Ex: squat lourd (genou), développé nuque (épaule), burpees (dos)...',
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS HELPERS
  // ─────────────────────────────────────────────

  Widget _buildTextField({
    required String hint,
    required Function(String) onChanged,
    required String initialValue,
    int maxLines = 2,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      style: const TextStyle(color: _kText, fontSize: 13),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSub, fontSize: 12),
        filled: true,
        fillColor: _kSurf2,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTextFieldController({
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 2,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSub, fontSize: 12),
        filled: true,
        fillColor: _kSurf2,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImpactRow(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: color, size: 13),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildImpactCard({required String title, required List<_ImpactItem> items}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: _kGreen, size: 14),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6, margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '${item.label} : ', style: TextStyle(color: item.color, fontSize: 11, fontWeight: FontWeight.w700)),
                        TextSpan(text: item.desc, style: const TextStyle(color: _kTextSub, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS RÉUTILISABLES
// ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w800)),
                      Text(subtitle, style: const TextStyle(color: _kTextSub, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}

class _ImpactItem {
  final String label;
  final String desc;
  final Color color;
  _ImpactItem(this.label, this.desc, this.color);
}
