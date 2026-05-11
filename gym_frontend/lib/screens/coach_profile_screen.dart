import 'package:flutter/material.dart';
import '../services/coach_profile_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

// ─── Design tokens light ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenDark = Color(0xFF00695C);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class CoachProfileScreen extends StatefulWidget {
  final int coachId;

  const CoachProfileScreen({super.key, required this.coachId});

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profile = await CoachProfileService.getCoachProfile(widget.coachId);

    if (profile != null && mounted) {
      setState(() {
        _profile = profile;
        _nameController.text = profile['fullName'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Impossible de charger le profil';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success =
        await CoachProfileService.updateCoachProfile(widget.coachId, {
          "fullName": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "phone": _phoneController.text.trim(),
        });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour !'),
          backgroundColor: _kGreen,
        ),
      );
      setState(() => _isEditing = false);
      _loadProfile();
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise à jour';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          title: const Text('Mon Profil', style: TextStyle(color: _kText)),
          backgroundColor: _kSurface,
        ),
        body: const Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          title: const Text('Mon Profil', style: TextStyle(color: _kText)),
          backgroundColor: _kSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: _kText),
              onPressed: _logout,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: _kRed),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: _kText, fontSize: 16),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(color: _kText)),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: _kText),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _kText),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isEditing ? _buildEditForm() : _buildProfileView(),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Avatar
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kGreen, _kGreenDark]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.sports, size: 55, color: _kText),
        ),
        const SizedBox(height: 20),

        // Nom
        Text(
          _profile?['fullName'] ?? 'N/A',
          style: const TextStyle(
            color: _kText,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Badge Coach
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kGreen, _kGreenDark]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏋️ Coach Certifié',
            style: TextStyle(
              color: _kText,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Statistiques d'expérience
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Expérience',
                '${_profile?['experience'] ?? 0}',
                'ans',
                Icons.star,
                const Color(0xFFFFD740),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Infos
        _buildInfoCard('Email', _profile?['email'] ?? 'N/A', Icons.email),
        const SizedBox(height: 12),
        _buildInfoCard('Téléphone', _profile?['phone'] ?? 'N/A', Icons.phone),
        const SizedBox(height: 12),
        _buildInfoCard(
          'Username',
          _profile?['username'] ?? 'N/A',
          Icons.account_circle,
        ),
        const SizedBox(height: 32),

        // Bouton modifier
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kGreen, _kGreenDark]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isEditing = true),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, color: _kText, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Modifier mon profil',
                      style: TextStyle(
                        color: _kText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Modifier le profil',
          style: TextStyle(
            color: _kText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        _buildEditField(_nameController, 'Nom complet', Icons.person),
        const SizedBox(height: 16),
        _buildEditField(_emailController, 'Email', Icons.email),
        const SizedBox(height: 16),
        _buildEditField(_phoneController, 'Téléphone', Icons.phone),
        const SizedBox(height: 32),

        // Bouton sauvegarder
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kGreen, _kGreenDark]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saveProfile,
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, color: _kText, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Sauvegarder',
                      style: TextStyle(
                        color: _kText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton annuler
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isEditing = false),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Text(
                  'Annuler',
                  style: TextStyle(color: _kTextSub, fontSize: 16),
                ),
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
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _kTextSub, fontSize: 13),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _kTextSub, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _kText,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kSurface.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: _kText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _kTextSub, fontSize: 14),
          prefixIcon: Icon(icon, color: _kGreen, size: 22),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kGreen, width: 1.5),
          ),
        ),
      ),
    );
  }
}
