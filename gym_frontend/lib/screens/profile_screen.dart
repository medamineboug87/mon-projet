
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/member_service.dart';
import '../providers/member_provider.dart';

// ─── Design tokens light ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen   = Color(0xFF00897B);
const Color _kText    = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder  = Color(0xFFDDE2EE);


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
    final profile = await MemberService.getMemberProfile(widget.memberId);
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile['fullName'] ?? '';
        _ageController.text = profile['age']?.toString() ?? '';
        _weightController.text = profile['weight']?.toString() ?? '';
        _heightController.text = profile['height']?.toString() ?? '';
      });
    }
  }

  Future<void> _saveProfile() async {
    final updated = {
      "fullName": _nameController.text,
      "age": int.tryParse(_ageController.text) ?? 0,
      "weight": double.tryParse(_weightController.text) ?? 0,
      "height": double.tryParse(_heightController.text) ?? 0,
    };

    final success = await MemberService.updateMemberProfile(
      widget.memberId,
      updated,
    );

    if (success && mounted) {
      // Invalider le cache
      ref.invalidate(memberProvider(widget.memberId));
      ref.invalidate(memberProfileProvider(widget.memberId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour !'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(memberProfileProvider(widget.memberId));

    if (profileAsync.isLoading) {
      return Scaffold(
        backgroundColor: _kSurface,
        appBar: AppBar(
          title: const Text(
            'Mon Profil',
            style: TextStyle(color: _kText),
          ),
          backgroundColor: const Color(0xFFEEF1F8),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
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
        backgroundColor: const Color(0xFFEEF1F8),
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: _kText,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
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
        backgroundColor: const Color(0xFFEEF1F8),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
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
                onPressed: () => _loadProfile(),
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

    Color bmiColor = Colors.green;
    if (bmiCategory == 'Surpoids' || bmiCategory == 'Insuffisance pondérale') {
      bmiColor = Colors.orange;
    } else if (bmiCategory == 'Obésité') {
      bmiColor = Colors.red;
    }

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

        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard(
              'Age',
              '${profile?['age'] ?? 'N/A'}',
              'ans',
              Icons.cake,
            ),
            _buildStatCard(
              'Poids',
              '${profile?['weight'] ?? 'N/A'}',
              'kg',
              Icons.monitor_weight,
            ),
            _buildStatCard(
              'Taille',
              '${profile?['height'] ?? 'N/A'}',
              'cm',
              Icons.height,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // BMI Card
        if (bmi != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF1F8),
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
            icon: const Icon(Icons.edit, color: _kText),
            label: const Text(
              'Modifier mon profil',
              style: TextStyle(fontSize: 16, color: _kText),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
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
    return Column(
      children: [
        const SizedBox(height: 20),
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
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save, color: _kText),
            label: const Text(
              'Sauvegarder',
              style: TextStyle(fontSize: 16, color: _kText),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kGreen, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _kText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(color: _kTextSub, fontSize: 12),
          ),
          Text(
            label,
            style: const TextStyle(color: _kTextSub, fontSize: 11),
          ),
        ],
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
        fillColor: const Color(0xFFEEF1F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
