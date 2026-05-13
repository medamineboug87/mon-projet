import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/member_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../providers/member_provider.dart';

// ─── Design tokens light ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kOrange = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);
const Color _kSurf2 = Color(0xFFEEF1F8);

class ProfileScreen extends ConsumerStatefulWidget {
  final int memberId;

  const ProfileScreen({super.key, required this.memberId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // Sommeil & Stress — appartiennent au profil IA (/ai-profile)
  double _avgSleepHours = 7.0;
  int _stressLevel = 5;

  double _originalSleepHours = 7.0;
  int _originalStressLevel = 5;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    // Charger le profil membre (nom, age, poids, taille)
    final profile = await MemberService.getMemberProfile(widget.memberId);
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile['fullName'] ?? '';
        _ageController.text = profile['age']?.toString() ?? '';
        _weightController.text = profile['weight']?.toString() ?? '';
        _heightController.text = profile['height']?.toString() ?? '';
      });
    }

    // Charger le profil IA séparément pour avgSleepHours et stressLevel
    await _loadAIProfile();
  }

  Future<void> _loadAIProfile() async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/members/${widget.memberId}/ai-profile',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _avgSleepHours = (data['avgSleepHours'] as num?)?.toDouble() ?? 7.0;
          _stressLevel = data['stressLevel'] as int? ?? 5;
          _originalSleepHours = _avgSleepHours;
          _originalStressLevel = _stressLevel;
        });
      }
    } catch (_) {
      // Silencieux — on garde les valeurs par défaut
    }
  }

  Future<void> _saveProfile() async {
    // ── 1. Sauvegarder les données membre : nom, age, poids, taille ──
    // Endpoint : PUT /members/{id}/profile
    final memberData = {
      "fullName": _nameController.text,
      "age": int.tryParse(_ageController.text) ?? 0,
      "weight": double.tryParse(_weightController.text) ?? 0,
      "height": double.tryParse(_heightController.text) ?? 0,
    };

    final memberSuccess = await MemberService.updateMemberProfile(
      widget.memberId,
      memberData,
    );

    // ── 2. Sauvegarder les données IA : sommeil et stress ──
    // Endpoint : PUT /members/{id}/ai-profile
    bool aiSuccess = false;
    try {
      final token = await AuthService.getToken();
      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/members/${widget.memberId}/ai-profile',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'avgSleepHours': _avgSleepHours,
              'stressLevel': _stressLevel,
            }),
          )
          .timeout(const Duration(seconds: 10));

      aiSuccess = response.statusCode == 200;
    } catch (_) {
      // On ne bloque pas si le profil IA échoue
    }

    if (!mounted) return;

    if (memberSuccess) {
      ref.invalidate(memberProvider(widget.memberId));
      ref.invalidate(memberProfileProvider(widget.memberId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aiSuccess
                ? 'Profil mis à jour !'
                : 'Profil mis à jour (données IA non sauvegardées)',
          ),
          backgroundColor: aiSuccess ? _kGreen : _kOrange,
        ),
      );
      setState(() {
        _isEditing = false;
        _originalSleepHours = _avgSleepHours;
        _originalStressLevel = _stressLevel;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour'),
          backgroundColor: _kRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(memberProfileProvider(widget.memberId));

    if (profileAsync.isLoading) {
      return Scaffold(
        backgroundColor: _kSurface,
        appBar: AppBar(
          title: const Text('Mon Profil', style: TextStyle(color: _kText)),
          backgroundColor: _kSurf2,
        ),
        body: const Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }

    if (profileAsync.hasError) {
      return _buildErrorScreen(profileAsync.error);
    }

    final profile = profileAsync.valueOrNull;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(color: _kText)),
        backgroundColor: _kSurf2,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: _kBorder),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: _kText),
            onPressed: () {
              if (_isEditing) {
                setState(() {
                  _avgSleepHours = _originalSleepHours;
                  _stressLevel = _originalStressLevel;
                });
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isEditing
            ? _buildEditForm(profile)
            : _buildProfileView(profile),
      ),
    );
  }

  Widget _buildErrorScreen(Object? error) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(color: _kText)),
        backgroundColor: _kSurf2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: _kRed),
              const SizedBox(height: 24),
              const Text(
                'Impossible de charger le profil',
                style: TextStyle(color: _kText, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: _kTextSub),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(Map<String, dynamic>? profile) {
    final bmi = profile?['bmi'];
    final bmiCategory = profile?['bmiCategory'] ?? '';

    Color bmiColor = _kGreen;
    if (bmiCategory == 'Surpoids' || bmiCategory == 'Insuffisance pondérale') {
      bmiColor = _kOrange;
    } else if (bmiCategory == 'Obésité') {
      bmiColor = _kRed;
    }

    Color sleepColor = _avgSleepHours >= 7 ? _kGreen : _kOrange;
    Color stressColor = _stressLevel <= 4
        ? _kGreen
        : (_stressLevel <= 6 ? _kOrange : _kRed);

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: _kGreen, width: 3),
          ),
          child: const Icon(Icons.person, size: 60, color: _kGreen),
        ),
        const SizedBox(height: 16),
        Text(
          profile?['fullName'] ?? 'N/A',
          style: const TextStyle(
            color: _kText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile?['gender'] ?? '',
          style: const TextStyle(color: _kTextSub),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatCard(
              'Age',
              '${profile?['age'] ?? 'N/A'}',
              'ans',
              Icons.cake,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Poids',
              '${profile?['weight'] ?? 'N/A'}',
              'kg',
              Icons.monitor_weight,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Taille',
              '${profile?['height'] ?? 'N/A'}',
              'cm',
              Icons.height,
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Sommeil et Stress (lus depuis le profil IA)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurf2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.nightlight_round, color: _kBlue, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${_avgSleepHours.toStringAsFixed(1)}h',
                      style: TextStyle(
                        color: sleepColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Sommeil/nuit',
                      style: TextStyle(color: _kTextSub, fontSize: 11),
                    ),
                    if (_avgSleepHours < 7)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kOrangeL,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚠️ Insuffisant',
                          style: TextStyle(
                            color: _kOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: _kBorder),
              Expanded(
                child: Column(
                  children: [
                    const Icon(
                      Icons.psychology_alt_rounded,
                      color: _kOrange,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_stressLevel}/10',
                      style: TextStyle(
                        color: stressColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Stress',
                      style: TextStyle(color: _kTextSub, fontSize: 11),
                    ),
                    if (_stressLevel >= 7)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kRedL,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🔴 Élevé',
                          style: TextStyle(
                            color: _kRed,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (bmi != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kSurf2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bmiColor, width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'Indice de Masse Corporelle (BMI)',
                  style: TextStyle(color: _kTextSub, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  bmi.toString(),
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  bmiCategory,
                  style: TextStyle(
                    color: bmiColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (bmi as num).clamp(10, 40) / 40,
                    backgroundColor: _kBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(bmiColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Insuffisant',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                    Text(
                      'Normal',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                    Text(
                      'Surpoids',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                    Text(
                      'Obésité',
                      style: TextStyle(color: _kTextSub, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Membre depuis : ${profile?['registrationDate'] ?? 'N/A'}',
          style: const TextStyle(color: _kTextSub),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text(
              'Modifier mon profil',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(Map<String, dynamic>? profile) {
    Color sleepColor = _avgSleepHours >= 7 ? _kGreen : _kOrange;
    Color stressColor = _stressLevel <= 4
        ? _kGreen
        : (_stressLevel <= 6 ? _kOrange : _kRed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Données membre → /members/{id}/profile ──
        _buildSectionHeader(
          'Informations personnelles',
          Icons.person_rounded,
          _kBlue,
        ),
        const SizedBox(height: 12),
        _buildEditField('Nom complet', _nameController, Icons.person),
        const SizedBox(height: 16),
        _buildEditField('Age', _ageController, Icons.cake, isNumber: true),
        const SizedBox(height: 16),
        _buildEditField(
          'Poids (kg)',
          _weightController,
          Icons.monitor_weight,
          isNumber: true,
        ),
        const SizedBox(height: 16),
        _buildEditField(
          'Taille (cm)',
          _heightController,
          Icons.height,
          isNumber: true,
        ),
        const SizedBox(height: 28),

        // ── Données IA → /members/{id}/ai-profile ──
        _buildSectionHeader(
          'Récupération & Bien-être',
          Icons.auto_awesome_rounded,
          _kGreen,
        ),
        const SizedBox(height: 4),
        const Text(
          'Ces données améliorent les prédictions IA',
          style: TextStyle(color: _kTextSub, fontSize: 11),
        ),
        const SizedBox(height: 16),

        // Sommeil
        const Text(
          '💤 Heures de sommeil (moyenne par nuit)',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.nightlight_round, color: _kBlue, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: sleepColor,
                  inactiveTrackColor: _kBorder,
                  thumbColor: sleepColor,
                  overlayColor: sleepColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _avgSleepHours,
                  min: 0,
                  max: 12,
                  divisions: 24,
                  label: '${_avgSleepHours.toStringAsFixed(1)} heures',
                  onChanged: (v) => setState(() => _avgSleepHours = v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: sleepColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_avgSleepHours.toStringAsFixed(1)}h',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sleepColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _avgSleepHours >= 7
              ? '✅ Sommeil suffisant pour une bonne récupération'
              : '⚠️ Sommeil insuffisant → récupération ralentie',
          style: TextStyle(color: sleepColor, fontSize: 11),
        ),
        const SizedBox(height: 24),

        // Stress
        const Text(
          '🧘 Niveau de stress',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.psychology_alt_rounded, color: _kOrange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: stressColor,
                  inactiveTrackColor: _kBorder,
                  thumbColor: stressColor,
                  overlayColor: stressColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _stressLevel.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '${_stressLevel}/10',
                  onChanged: (v) => setState(() => _stressLevel = v.round()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: stressColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_stressLevel/10',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: stressColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _stressLevel <= 4
              ? '✅ Stress maîtrisé → bonne récupération'
              : (_stressLevel <= 6
                    ? '⚠️ Stress modéré → surveiller la récupération'
                    : '🔴 Stress élevé → risque de blessure accru'),
          style: TextStyle(color: stressColor, fontSize: 11),
        ),
        const SizedBox(height: 32),

        // Boutons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _avgSleepHours = _originalSleepHours;
                    _stressLevel = _originalStressLevel;
                    _isEditing = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: _kTextSub),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save, color: Colors.white, size: 18),
                label: const Text(
                  'Sauvegarder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _kSurf2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kGreen, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(unit, style: const TextStyle(color: _kTextSub, fontSize: 11)),
            Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSub),
        prefixIcon: Icon(icon, color: _kGreen),
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
