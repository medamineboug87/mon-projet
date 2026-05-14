// lib/screens/unified_profile_screen.dart
//
// Remplace ProfileScreen + AIProfileScreen par un seul écran à 3 onglets :
//   Onglet 1 — "Mes infos"    → nom (lecture seule), âge/poids/taille/email/téléphone
//   Onglet 2 — "Objectif"     → goal, niveau, expérience, alimentation, hydratation
//   Onglet 3 — "Santé"        → sommeil, stress, douleurs, médical

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/member_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../providers/member_provider.dart';

// ─── Design tokens (cohérents avec le reste de l'app) ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kGreenD = Color(0xFF00695C);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

// ─── Données statiques ───
const List<Map<String, String>> _kGoals = [
  {'value': 'WEIGHT_LOSS', 'label': 'Perte de poids', 'emoji': '🏃'},
  {'value': 'MUSCLE_GAIN', 'label': 'Prise de masse', 'emoji': '💪'},
  {'value': 'ENDURANCE', 'label': 'Endurance', 'emoji': '🚴'},
  {'value': 'TONING', 'label': 'Tonification', 'emoji': '✨'},
  {'value': 'GENERAL_FITNESS', 'label': 'Bien-être général', 'emoji': '💚'},
  {'value': 'REHABILITATION', 'label': 'Rééducation', 'emoji': '🩺'},
  {'value': 'PERFORMANCE', 'label': 'Performance sportive', 'emoji': '🏆'},
];

const List<Map<String, String>> _kLevels = [
  {'value': 'BEGINNER', 'label': 'Débutant', 'sub': '< 1 an'},
  {'value': 'INTERMEDIATE', 'label': 'Intermédiaire', 'sub': '1 à 3 ans'},
  {'value': 'ADVANCED', 'label': 'Avancé', 'sub': '3 à 5 ans'},
  {'value': 'ATHLETE', 'label': 'Athlète', 'sub': '5+ ans'},
];

const List<Map<String, String>> _kPainZones = [
  {'value': 'NONE', 'label': 'Aucune'},
  {'value': 'NECK', 'label': 'Nuque / Cou'},
  {'value': 'LOWER_BACK', 'label': 'Bas du dos'},
  {'value': 'UPPER_BACK', 'label': 'Haut du dos'},
  {'value': 'LEFT_SHOULDER', 'label': 'Épaule gauche'},
  {'value': 'RIGHT_SHOULDER', 'label': 'Épaule droite'},
  {'value': 'LEFT_KNEE', 'label': 'Genou gauche'},
  {'value': 'RIGHT_KNEE', 'label': 'Genou droit'},
  {'value': 'LEFT_ANKLE', 'label': 'Cheville gauche'},
  {'value': 'RIGHT_ANKLE', 'label': 'Cheville droite'},
  {'value': 'LEFT_HIP', 'label': 'Hanche gauche'},
  {'value': 'RIGHT_HIP', 'label': 'Hanche droite'},
  {'value': 'WRISTS', 'label': 'Poignets'},
];

const List<String> _kDietOptions = [
  'Omnivore',
  'Végétarien',
  'Vegan',
  'Keto / Low-carb',
  'Méditerranéen',
  'Sans gluten',
  'Halal',
  'Autre',
];

// ════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL
// ════════════════════════════════════════════════════════════

class UnifiedProfileScreen extends ConsumerStatefulWidget {
  final int memberId;
  const UnifiedProfileScreen({super.key, required this.memberId});

  @override
  ConsumerState<UnifiedProfileScreen> createState() =>
      _UnifiedProfileScreenState();
}

class _UnifiedProfileScreenState extends ConsumerState<UnifiedProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _isLoading = true;
  bool _isSaving = false;

  // ── Onglet 1 : données membres (âge, poids, taille, email, téléphone) ──
  // Nom et genre : lecture seule
  String _fullName = '';
  String _gender = '';
  String _registrationDate = '';

  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // ── Onglet 2 : objectif & niveau ──
  String _primaryGoal = 'GENERAL_FITNESS';
  String _fitnessLevel = 'BEGINNER';
  int _yearsExperience = 0;
  String _dietType = 'Omnivore';
  String _outsideActivity = '';
  double _waterIntake = 1.5;

  // ── Onglet 3 : santé & récup ──
  double _avgSleepHours = 7.0;
  int _stressLevel = 5;
  Set<String> _painZones = {'NONE'};
  int _chronicPainIntensity = 0;
  final _medicalCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _injuryHistoryCtrl = TextEditingController();
  final _currentInjuriesCtrl = TextEditingController();
  final _restrictionsCtrl = TextEditingController();
  bool _hasMedicalFollowUp = false;
  final _followUpDetailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _medicalCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _injuryHistoryCtrl.dispose();
    _currentInjuriesCtrl.dispose();
    _restrictionsCtrl.dispose();
    _followUpDetailCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // CHARGEMENT
  // ─────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadMemberProfile(), _loadAIProfile()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMemberProfile() async {
    final data = await MemberService.getMemberProfile(widget.memberId);
    if (data != null && mounted) {
      setState(() {
        _fullName = data['fullName'] ?? '';
        _gender = data['gender'] ?? '';
        _registrationDate = data['registrationDate'] ?? '';
        _ageCtrl.text = data['age']?.toString() ?? '';
        _weightCtrl.text = data['weight']?.toString() ?? '';
        _heightCtrl.text = data['height']?.toString() ?? '';
        _emailCtrl.text = data['email'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
      });
    }
  }

  Future<void> _loadAIProfile() async {
    try {
      final r = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/members/${widget.memberId}/ai-profile',
            ),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        setState(() {
          _primaryGoal = data['primaryGoal'] ?? 'GENERAL_FITNESS';
          _fitnessLevel = data['selfDeclaredLevel'] ?? 'BEGINNER';
          _yearsExperience = data['yearsOfExperience'] ?? 0;
          _dietType = data['dietType'] ?? 'Omnivore';
          _outsideActivity = data['outsideGymActivity'] ?? '';
          _waterIntake = (data['dailyWaterIntake'] as num?)?.toDouble() ?? 1.5;
          _avgSleepHours = (data['avgSleepHours'] as num?)?.toDouble() ?? 7.0;
          _stressLevel = data['stressLevel'] ?? 5;
          _chronicPainIntensity = data['chronicPainIntensity'] ?? 0;
          _hasMedicalFollowUp = data['hasMedicalFollowUp'] ?? false;
          _medicalCtrl.text = data['medicalConditions'] ?? '';
          _allergiesCtrl.text = data['allergiesContraindications'] ?? '';
          _medicationsCtrl.text = data['currentMedications'] ?? '';
          _injuryHistoryCtrl.text = data['injuryHistory'] ?? '';
          _currentInjuriesCtrl.text = data['currentInjuries'] ?? '';
          _restrictionsCtrl.text = data['exerciseRestrictions'] ?? '';
          _followUpDetailCtrl.text = data['medicalFollowUpDetail'] ?? '';
          final zones = data['chronicPainZones']?.toString() ?? '';
          _painZones = zones.isEmpty
              ? {'NONE'}
              : zones.split(',').map((s) => s.trim()).toSet();
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // SAUVEGARDE
  // ─────────────────────────────────────────────

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    final painZones = _painZones.contains('NONE')
        ? 'NONE'
        : _painZones.where((z) => z != 'NONE').join(',');

    await Future.wait([
      MemberService.updateMemberProfile(widget.memberId, {
        'age': int.tryParse(_ageCtrl.text) ?? 0,
        'weight': double.tryParse(_weightCtrl.text) ?? 0,
        'height': double.tryParse(_heightCtrl.text) ?? 0,
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      }),
      http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/members/${widget.memberId}/ai-profile',
            ),
            headers: await _headers(),
            body: jsonEncode({
              'primaryGoal': _primaryGoal,
              'selfDeclaredLevel': _fitnessLevel,
              'yearsOfExperience': _yearsExperience,
              'dietType': _dietType,
              'outsideGymActivity': _outsideActivity,
              'dailyWaterIntake': _waterIntake,
              'avgSleepHours': _avgSleepHours,
              'stressLevel': _stressLevel,
              'chronicPainZones': painZones,
              'chronicPainIntensity': _chronicPainIntensity,
              'hasMedicalFollowUp': _hasMedicalFollowUp,
              'medicalConditions': _medicalCtrl.text.trim(),
              'allergiesContraindications': _allergiesCtrl.text.trim(),
              'currentMedications': _medicationsCtrl.text.trim(),
              'injuryHistory': _injuryHistoryCtrl.text.trim(),
              'currentInjuries': _currentInjuriesCtrl.text.trim(),
              'exerciseRestrictions': _restrictionsCtrl.text.trim(),
              'medicalFollowUpDetail': _followUpDetailCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15)),
    ]);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ref.invalidate(memberProvider(widget.memberId));
    ref.invalidate(memberProfileProvider(widget.memberId));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Profil mis à jour !',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          'Mon profil',
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
                indicatorWeight: 2,
                labelColor: _kGreen,
                unselectedLabelColor: _kTextSub,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.person_rounded, size: 18),
                    text: 'Mes infos',
                  ),
                  Tab(
                    icon: Icon(Icons.flag_rounded, size: 18),
                    text: 'Objectif',
                  ),
                  Tab(
                    icon: Icon(Icons.favorite_rounded, size: 18),
                    text: 'Santé',
                  ),
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: _kGreen,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _saveAll,
                      icon: const Icon(
                        Icons.save_rounded,
                        color: _kGreen,
                        size: 18,
                      ),
                      label: const Text(
                        'Sauvegarder',
                        style: TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : TabBarView(
              controller: _tabCtrl,
              children: [_buildInfoTab(), _buildGoalTab(), _buildHealthTab()],
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAll,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isSaving ? 'Sauvegarde...' : 'Sauvegarder le profil',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ONGLET 1 — MES INFOS
  // ════════════════════════════════════════════════════════════

  Widget _buildInfoTab() {
    final initials = _fullName.trim().isEmpty
        ? '?'
        : _fullName
              .trim()
              .split(' ')
              .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
              .take(2)
              .join();

    final genderLabel = _gender == 'MALE'
        ? 'Homme'
        : _gender == 'FEMALE'
        ? 'Femme'
        : _gender;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // ── Avatar + identité (lecture seule) ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kGreen, _kGreenD],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName.isEmpty ? '—' : _fullName,
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (genderLabel.isNotEmpty)
                      _infoChip(
                        genderLabel == 'Homme'
                            ? Icons.male_rounded
                            : Icons.female_rounded,
                        genderLabel,
                      ),
                    if (_registrationDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _infoChip(
                        Icons.calendar_today_rounded,
                        'Membre depuis $_registrationDate',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Champs éditables ──
        Container(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Informations modifiables', Icons.edit_rounded),
              const Divider(height: 1, color: _kBorder),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Âge / Poids / Taille sur une ligne
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            _ageCtrl,
                            'Âge',
                            Icons.cake_rounded,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            _weightCtrl,
                            'Poids (kg)',
                            Icons.monitor_weight_rounded,
                            isNumber: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            _heightCtrl,
                            'Taille (cm)',
                            Icons.height_rounded,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _emailCtrl,
                      'Email',
                      Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _phoneCtrl,
                      'Téléphone',
                      Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // ONGLET 2 — OBJECTIF & NIVEAU
  // ════════════════════════════════════════════════════════════

  Widget _buildGoalTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // Objectif principal
        _card(
          icon: Icons.flag_rounded,
          title: 'Objectif principal',
          child: Column(
            children: _kGoals.map((g) {
              final selected = _primaryGoal == g['value'];
              return _selectRow(
                emoji: g['emoji']!,
                label: g['label']!,
                selected: selected,
                onTap: () => setState(() => _primaryGoal = g['value']!),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Niveau
        _card(
          icon: Icons.bar_chart_rounded,
          title: 'Mon niveau',
          child: Column(
            children: _kLevels.map((l) {
              final selected = _fitnessLevel == l['value'];
              return _levelRow(
                label: l['label']!,
                sub: l['sub']!,
                value: l['value']!,
                selected: selected,
                onTap: () => setState(() => _fitnessLevel = l['value']!),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Années d'expérience
        _card(
          icon: Icons.workspace_premium_rounded,
          title: "Années d'expérience",
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleBtn(
                Icons.remove_rounded,
                _kRed,
                () => setState(
                  () => _yearsExperience = (_yearsExperience - 1).clamp(0, 40),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      '$_yearsExperience',
                      style: const TextStyle(
                        color: _kGreen,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    const Text(
                      'années',
                      style: TextStyle(color: _kTextSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _circleBtn(
                Icons.add_rounded,
                _kGreen,
                () => setState(
                  () => _yearsExperience = (_yearsExperience + 1).clamp(0, 40),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Alimentation
        _card(
          icon: Icons.restaurant_rounded,
          title: 'Alimentation',
          child: DropdownButtonFormField<String>(
            value: _kDietOptions.contains(_dietType) ? _dietType : 'Omnivore',
            dropdownColor: _kSurface,
            style: const TextStyle(color: _kText, fontSize: 13),
            decoration: _inputDeco(
              'Type d\'alimentation',
              Icons.restaurant_rounded,
            ),
            items: _kDietOptions
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _dietType = v ?? 'Omnivore'),
          ),
        ),
        const SizedBox(height: 14),

        // Hydratation
        _card(
          icon: Icons.water_drop_rounded,
          title: 'Hydratation quotidienne',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_waterIntake.toStringAsFixed(1)} L / jour',
                    style: const TextStyle(
                      color: _kGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  _statusPill(
                    _waterIntake >= 2 ? '✅ Bon' : '⚠️ Insuffisant',
                    _waterIntake >= 2 ? _kGreen : _kOrange,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _greenSlider(
                value: _waterIntake,
                min: 0.5,
                max: 5,
                divisions: 18,
                onChanged: (v) => setState(
                  () => _waterIntake = double.parse(v.toStringAsFixed(1)),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0.5L',
                    style: TextStyle(color: _kTextSub, fontSize: 10),
                  ),
                  Text(
                    'Recommandé : 2-3L',
                    style: TextStyle(color: _kTextSub, fontSize: 10),
                  ),
                  Text('5L', style: TextStyle(color: _kTextSub, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // ONGLET 3 — SANTÉ & RÉCUP
  // ════════════════════════════════════════════════════════════

  Widget _buildHealthTab() {
    Color sleepColor = _avgSleepHours >= 7 ? _kGreen : _kOrange;
    Color stressColor = _stressLevel <= 4
        ? _kGreen
        : _stressLevel <= 7
        ? _kOrange
        : _kRed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // ── Sommeil ──
        _card(
          icon: Icons.nightlight_rounded,
          title: 'Sommeil moyen par nuit',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_avgSleepHours.toStringAsFixed(1)} h',
                    style: TextStyle(
                      color: sleepColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _statusPill(
                    _avgSleepHours >= 7
                        ? '✅ Suffisant'
                        : _avgSleepHours >= 6
                        ? '⚠️ Limite'
                        : '🔴 Insuffisant',
                    sleepColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: sleepColor,
                  inactiveTrackColor: _kBorder,
                  thumbColor: sleepColor,
                  trackHeight: 5,
                ),
                child: Slider(
                  value: _avgSleepHours,
                  min: 3,
                  max: 12,
                  divisions: 18,
                  onChanged: (v) => setState(
                    () => _avgSleepHours = double.parse(v.toStringAsFixed(1)),
                  ),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('3h', style: TextStyle(color: _kTextSub, fontSize: 10)),
                  Text(
                    'Recommandé : 7-9h',
                    style: TextStyle(color: _kTextSub, fontSize: 10),
                  ),
                  Text('12h', style: TextStyle(color: _kTextSub, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Stress ──
        _card(
          icon: Icons.psychology_alt_rounded,
          title: 'Niveau de stress',
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_stressLevel / 10',
                    style: TextStyle(
                      color: stressColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _statusPill(
                    _stressLevel <= 4
                        ? '✅ Maîtrisé'
                        : _stressLevel <= 7
                        ? '⚠️ Modéré'
                        : '🔴 Élevé',
                    stressColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: stressColor,
                  inactiveTrackColor: _kBorder,
                  thumbColor: stressColor,
                  trackHeight: 5,
                ),
                child: Slider(
                  value: _stressLevel.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (v) => setState(() => _stressLevel = v.round()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Zones de douleur ──
        _card(
          icon: Icons.location_on_rounded,
          title: 'Zones de douleur chronique',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kPainZones.map((zone) {
                  final isSelected = _painZones.contains(zone['value']);
                  final isNone = zone['value'] == 'NONE';
                  final color = isNone ? _kGreen : _kRed;
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isNone) {
                        _painZones = {'NONE'};
                      } else {
                        _painZones.remove('NONE');
                        if (isSelected)
                          _painZones.remove(zone['value']);
                        else
                          _painZones.add(zone['value']!);
                        if (_painZones.isEmpty) _painZones = {'NONE'};
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : _kSurf2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.5)
                              : _kBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        zone['label']!,
                        style: TextStyle(
                          color: isSelected ? color : _kTextSub,
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
              if (!_painZones.contains('NONE')) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Intensité',
                      style: TextStyle(
                        color: _kTextSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$_chronicPainIntensity/10',
                      style: TextStyle(
                        color: _chronicPainIntensity >= 7
                            ? _kRed
                            : _chronicPainIntensity >= 4
                            ? _kOrange
                            : _kGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _chronicPainIntensity >= 7
                        ? _kRed
                        : _chronicPainIntensity >= 4
                        ? _kOrange
                        : _kGreen,
                    inactiveTrackColor: _kBorder,
                    thumbColor: _chronicPainIntensity >= 7 ? _kRed : _kOrange,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _chronicPainIntensity.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    onChanged: (v) =>
                        setState(() => _chronicPainIntensity = v.round()),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Blessures actuelles ──
        _card(
          icon: Icons.healing_rounded,
          title: 'Blessures actuelles',
          child: _textArea(
            _currentInjuriesCtrl,
            'Ex : entorse cheville gauche, douleur épaule droite...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Antécédents ──
        _card(
          icon: Icons.history_rounded,
          title: 'Antécédents de blessures',
          child: _textArea(
            _injuryHistoryCtrl,
            'Ex : déchirure LCA 2019, fracture coude 2021...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Exercices à éviter ──
        _card(
          icon: Icons.block_rounded,
          title: 'Exercices à éviter',
          child: _textArea(
            _restrictionsCtrl,
            'Ex : squat lourd (genou), développé nuque...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Conditions médicales ──
        _card(
          icon: Icons.medical_services_rounded,
          title: 'Conditions médicales',
          child: _textArea(
            _medicalCtrl,
            'Ex : diabète, hypertension, asthme...',
          ),
        ),
        const SizedBox(height: 14),

        // ── Suivi médical ──
        _card(
          icon: Icons.person_search_rounded,
          title: 'Suivi médical actif',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suivi en cours ?',
                          style: TextStyle(
                            color: _kText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _hasMedicalFollowUp
                              ? '✅ Oui — précisez ci-dessous'
                              : 'Non',
                          style: TextStyle(
                            color: _hasMedicalFollowUp ? _kGreen : _kTextSub,
                            fontSize: 11,
                          ),
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
                _textArea(
                  _followUpDetailCtrl,
                  'Ex : kiné 2×/semaine (genou), cardiologue mensuel...',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS HELPERS
  // ─────────────────────────────────────────────

  /// Carte section unifiée — une seule couleur verte pour l'icône
  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon),
          const Divider(height: 1, color: _kBorder),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _kGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: _kText,
              fontWeight: FontWeight.w800,
              fontSize: 13,
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
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType:
          keyboardType ??
          (isNumber ? TextInputType.number : TextInputType.text),
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: _inputDeco(label, icon),
    );
  }

  Widget _textArea(
    TextEditingController ctrl,
    String hint, {
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

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextSub, fontSize: 12),
      prefixIcon: Icon(icon, color: _kGreen, size: 18),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _kTextSub),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _kTextSub, fontSize: 12)),
      ],
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _greenSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: const SliderThemeData(
        activeTrackColor: _kGreen,
        inactiveTrackColor: _kBorder,
        thumbColor: _kGreen,
        trackHeight: 4,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  /// Ligne de sélection (objectif) avec emoji
  Widget _selectRow({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kGreen.withValues(alpha: 0.09) : _kSurf2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kGreen.withValues(alpha: 0.5) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
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

  /// Ligne de sélection (niveau) avec point coloré
  Widget _levelRow({
    required String label,
    required String sub,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = switch (value) {
      'BEGINNER' => _kGreen,
      'INTERMEDIATE' => const Color(0xFF0288D1),
      'ADVANCED' => _kOrange,
      _ => _kRed,
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kGreen.withValues(alpha: 0.09) : _kSurf2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _kGreen.withValues(alpha: 0.5) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? _kGreen : _kText,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
          ],
        ),
      ),
    );
  }
}
