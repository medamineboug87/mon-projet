import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/plan_service.dart';
import 'member_home_screen.dart';

// ─── Design tokens light ───

const Color _kOrange = Color(0xFFF57C00);
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Plans chargés depuis l'API ──
  List<SubscriptionPlanModel> _plans = [];
  bool _plansLoading = true;

  // Étape 1 — Infos personnelles
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'MALE';

  // Étape 2 — Abonnement
  String? _selectedPlan;

  // Étape 3 — Compte
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  // Étape 4 — Paiement : 'card' | 'cash' | null
  String? _paymentMethod;

  // Étape 5 — Formulaire carte
  final _cardNameCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  // ── Charger les plans depuis l'API (standard + custom) ──
  Future<void> _loadPlans() async {
    setState(() => _plansLoading = true);
    try {
      final plans = await PlanService.getActivePlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _plansLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _plans = PlanService.getStandardPlans();
          _plansLoading = false;
        });
      }
    }
  }

  // ── Helper : trouver le plan sélectionné ──
  SubscriptionPlanModel? get _selectedPlanModel => _selectedPlan == null
      ? null
      : _plans.where((p) => p.name == _selectedPlan).firstOrNull;

  // ── Validations par étape ──
  bool _validateStep1() {
    if (_fullNameController.text.trim().isEmpty)
      return _err('Entrez votre nom complet');
    if (_ageController.text.trim().isEmpty) return _err('Entrez votre âge');
    if (_weightController.text.trim().isEmpty)
      return _err('Entrez votre poids');
    if (_heightController.text.trim().isEmpty)
      return _err('Entrez votre taille');
    if (!_emailController.text.contains('@')) return _err('Email invalide');

    String phone = _phoneController.text.trim();
    if (phone.length < 8) return _err('Numéro de téléphone invalide');

    String firstDigit = phone[0];
    if (!['2', '4', '5', '9'].contains(firstDigit)) {
      return _err('Le numéro doit commencer par 2, 4, 5 ou 9');
    }

    return true;
  }

  bool _validateStep2() {
    if (_selectedPlan == null) return _err('Choisissez un abonnement');
    return true;
  }

  bool _validateStep3() {
    if (_usernameController.text.trim().isEmpty)
      return _err("Entrez un nom d'utilisateur");
    if (_passwordController.text.length < 6)
      return _err('Mot de passe minimum 6 caractères');
    if (_passwordController.text != _confirmPasswordController.text)
      return _err('Les mots de passe ne correspondent pas');
    return true;
  }

  bool _validateStep4() {
    if (_paymentMethod == null) return _err('Choisissez un mode de paiement');
    return true;
  }

  bool _validateCardForm() {
    if (_cardNameCtrl.text.trim().isEmpty) return _err('Nom du porteur requis');
    if (_cardNumberCtrl.text.replaceAll(' ', '').length < 16)
      return _err('Numéro de carte invalide');
    if (_cardExpiryCtrl.text.length < 5)
      return _err("Date d'expiration invalide");
    if (_cardCvvCtrl.text.length < 3) return _err('CVV invalide');
    return true;
  }

  bool _err(String msg) {
    setState(() => _errorMessage = msg);
    return false;
  }

  // ── Navigation ──
  Future<void> _nextStep() async {
    setState(() => _errorMessage = null);
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;
    if (_currentStep == 3 && !_validateStep4()) return;

    if (_currentStep == 3 && _paymentMethod == 'card') {
      setState(() => _currentStep = 4);
      return;
    }

    if (_currentStep == 4 && !_validateCardForm()) return;

    if (_currentStep >= 3) {
      await _completeRegistration();
    } else {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    setState(() {
      _errorMessage = null;
      if (_currentStep == 4) {
        _currentStep = 3;
      } else if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  // ── Finaliser l'inscription ──
  Future<void> _completeRegistration() async {
    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register-complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': _fullNameController.text.trim(),
              'age': int.parse(_ageController.text),
              'gender': _gender,
              'weight': double.parse(_weightController.text),
              'height': double.parse(_heightController.text),
              'email': _emailController.text.trim(),
              'phone': '+216${_phoneController.text.trim()}',
              'username': _usernameController.text.trim(),
              'password': _passwordController.text,
              'subscriptionType': _selectedPlan,
              'subscriptionPrice': _selectedPlanModel?.price ?? 0,
              'subscriptionDuration': _selectedPlanModel?.duration ?? 1,
              'paymentRef': _paymentMethod == 'card'
                  ? 'CARD_${DateTime.now().millisecondsSinceEpoch}'
                  : '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthService.saveSession(
          token: data['token'],
          role: 'MEMBER',
          memberId: data['memberId'],
          username: data['username'],
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (_paymentMethod == 'cash') {
          _showCashInstructions(data['memberId']);
        } else {
          await _activateCardSubscription(data['memberId']);
        }
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? "Erreur lors de l'inscription";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Serveur inaccessible';
        _isLoading = false;
      });
    }
  }

  // ── FIX #7 : Activation carte avec gestion d'erreur explicite ──
  Future<void> _activateCardSubscription(int memberId) async {
    final plan = _selectedPlanModel;
    final token = await AuthService.getToken();

    bool activationSuccess = false;
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/payments/simulate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'memberId': memberId,
              'subscriptionType': _selectedPlan,
              'amount': plan?.price ?? 0,
            }),
          )
          .timeout(const Duration(seconds: 15));
      activationSuccess = response.statusCode == 200;
    } catch (_) {
      activationSuccess = false;
    }

    if (!mounted) return;

    if (!activationSuccess) {
      // Informer l'utilisateur que l'activation automatique a échoué
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _kSurface,
          title: const Text(
            '⚠️ Activation en attente',
            style: TextStyle(color: _kText),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre compte a été créé avec succès.',
                style: TextStyle(color: _kText),
              ),
              SizedBox(height: 12),
              Text(
                "L'activation automatique n'a pas pu être effectuée.",
                style: TextStyle(color: _kOrange, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '📋 Pour activer votre abonnement :',
                style: TextStyle(color: _kText, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                '1. Présentez-vous à la réception',
                style: TextStyle(color: _kText, fontSize: 13),
              ),
              Text(
                '2. L\'admin activera votre abonnement',
                style: TextStyle(color: _kText, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemberHomeScreen(memberId: memberId),
                  ),
                );
              },
              child: const Text(
                'OK, compris !',
                style: TextStyle(color: _kOrange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MemberHomeScreen(memberId: memberId)),
      );
    }
  }

  void _showCashInstructions(int memberId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text('💵 Compte créé !', style: TextStyle(color: _kText)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre compte a été créé avec succès.',
              style: TextStyle(color: _kText),
            ),
            SizedBox(height: 12),
            Text(
              '📋 Pour activer votre abonnement :',
              style: TextStyle(color: _kOrange, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. Présentez-vous à la réception',
              style: TextStyle(color: _kText, fontSize: 13),
            ),
            Text(
              '2. Payez le montant en espèces',
              style: TextStyle(color: _kText, fontSize: 13),
            ),
            Text(
              "3. L'admin activera votre compte",
              style: TextStyle(color: _kText, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberHomeScreen(memberId: memberId),
                ),
              );
            },
            child: const Text(
              'OK, compris !',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stepLabels = ['Profil', 'Abonnement', 'Compte', 'Paiement'];
    final indicatorStep = _currentStep > 3 ? 3 : _currentStep;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Créer un compte',
          style: TextStyle(color: Color(0xFF1A2340)),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
      ),
      body: Stack(
        children: [
          const _SportBackground(),
          Column(
            children: [
              _buildStepIndicator(stepLabels, indicatorStep),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: _kGreen),
                            SizedBox(height: 16),
                            Text(
                              'Traitement en cours...',
                              style: TextStyle(color: _kTextSub),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStepContent(),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                if (_currentStep > 0) ...[
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _prevStep,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _kGreen,
                                        side: const BorderSide(color: _kGreen),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      child: const Text(
                                        'Retour',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: Text(
                                      _currentStep >= 3 &&
                                              !(_currentStep == 3 &&
                                                  _paymentMethod == 'card')
                                          ? "S'inscrire"
                                          : 'Continuer',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(List<String> steps, int activeStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.transparent,
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == activeStep;
          final isDone = index < activeStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone || isActive ? _kGreen : _kBorder,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          color: isActive || isDone ? _kText : _kTextSub,
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? _kGreen : _kBorder,
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      0 => _buildStep1(),
      1 => _buildStep2(),
      2 => _buildStep3(),
      3 => _buildStep4Payment(),
      4 => _buildStep5CardForm(),
      _ => const SizedBox(),
    };
  }

  // ── Étape 1 : Infos personnelles ──
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vos informations personnelles',
          style: TextStyle(
            color: _kText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildField(_fullNameController, 'Nom complet', Icons.person),
        const SizedBox(height: 16),
        _buildField(_ageController, 'Âge', Icons.cake, isNumber: true),
        const SizedBox(height: 16),
        _buildField(
          _weightController,
          'Poids (kg)',
          Icons.monitor_weight,
          isNumber: true,
        ),
        const SizedBox(height: 16),
        _buildField(
          _heightController,
          'Taille (cm)',
          Icons.height,
          isNumber: true,
        ),
        const SizedBox(height: 16),
        _buildField(
          _emailController,
          'Email',
          Icons.email,
          hint: 'ahmed@gmail.com',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: _kText),
          decoration: InputDecoration(
            labelText: 'Téléphone',
            labelStyle: const TextStyle(color: _kTextSub),
            prefixIcon: const Icon(Icons.phone, color: _kGreen),
            prefixText: '+216 ',
            prefixStyle: const TextStyle(color: _kText, fontSize: 16),
            hintText: '20 123 456',
            hintStyle: const TextStyle(color: _kBorder),
            filled: true,
            fillColor: const Color(0xFFEEF1F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Genre', style: TextStyle(color: _kTextSub, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = 'MALE'),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _gender == 'MALE'
                        ? _kGreen
                        : const Color(0xFFEEF1F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == 'MALE' ? _kGreen : _kBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Homme',
                      style: TextStyle(
                        color: _gender == 'MALE' ? Colors.white : _kText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = 'FEMALE'),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _gender == 'FEMALE'
                        ? _kGreen
                        : const Color(0xFFEEF1F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gender == 'FEMALE' ? _kGreen : _kBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Femme',
                      style: TextStyle(
                        color: _gender == 'FEMALE' ? Colors.white : _kText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Étape 2 : Abonnement — DYNAMIQUE depuis API ──
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez votre abonnement',
          style: TextStyle(
            color: _kText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        if (_plansLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _kGreen),
            ),
          )
        else if (_plans.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Impossible de charger les plans. Vérifiez votre connexion.',
                    style: TextStyle(color: _kText),
                  ),
                ),
                TextButton(
                  onPressed: _loadPlans,
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        else
          ..._plans.map((plan) {
            final isSelected = _selectedPlan == plan.name;
            final planColor = _hexToColor(plan.color);
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = plan.name),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? planColor : _kBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: planColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          plan.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.displayName,
                            style: TextStyle(
                              color: planColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (plan.description != null &&
                              plan.description!.isNotEmpty)
                            Text(
                              plan.description!,
                              style: const TextStyle(
                                color: _kTextSub,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            plan.durationLabel,
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 11,
                            ),
                          ),
                          if (plan.isCustom)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: planColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Offre spéciale',
                                style: TextStyle(
                                  color: planColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${plan.price.toStringAsFixed(0)} DT',
                          style: const TextStyle(
                            color: _kText,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: planColor, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Étape 3 : Création compte ──
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créez votre compte',
          style: TextStyle(
            color: _kText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildField(_usernameController, "Nom d'utilisateur", Icons.person),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: _kText),
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            labelStyle: const TextStyle(color: _kTextSub),
            prefixIcon: const Icon(Icons.lock, color: _kGreen),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _kTextSub,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFEEF1F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildField(
          _confirmPasswordController,
          'Confirmer mot de passe',
          Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        if (_selectedPlanModel != null) _buildOrderSummary(),
      ],
    );
  }

  Widget _buildOrderSummary() {
    final plan = _selectedPlanModel!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGreen.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Abonnement :', style: TextStyle(color: _kTextSub)),
              Row(
                children: [
                  Text(plan.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    plan.displayName,
                    style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Durée :', style: TextStyle(color: _kTextSub)),
              Text(plan.durationLabel, style: const TextStyle(color: _kText)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prix :', style: TextStyle(color: _kTextSub)),
              Text(
                '${plan.price.toStringAsFixed(0)} DT',
                style: const TextStyle(
                  color: _kGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Étape 4 : Choix méthode de paiement ──
  Widget _buildStep4Payment() {
    final plan = _selectedPlanModel;
    final price = plan?.price.toStringAsFixed(0) ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode de paiement',
          style: TextStyle(
            color: _kText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(plan?.emoji ?? '⭐', style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan?.displayName ?? _selectedPlan ?? '',
                      style: const TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plan?.durationLabel ?? '',
                      style: const TextStyle(color: _kTextSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '$price DT',
                style: const TextStyle(
                  color: _kGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildPaymentChoice(
          method: 'card',
          emoji: '💳',
          title: 'Payer par carte',
          subtitle: 'Visa / Mastercard',
          color: _kGreen,
        ),
        const SizedBox(height: 12),

        _buildPaymentChoice(
          method: 'cash',
          emoji: '💵',
          title: 'Payer en espèces',
          subtitle: "À la réception — activation par l'admin",
          color: _kOrange,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kGreen.withValues(alpha: 0.15)),
          ),
          child: const Row(
            children: [
              Icon(Icons.security, color: _kGreen, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paiement 100% sécurisé • Données cryptées SSL',
                  style: TextStyle(color: _kTextSub, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChoice({
    required String method,
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFFEEF1F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : _kBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _kTextSub, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  // ── Étape 5 : Formulaire carte ──
  Widget _buildStep5CardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations carte bancaire',
          style: TextStyle(
            color: _kText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildCardField(_cardNameCtrl, 'Nom du porteur', Icons.person),
        const SizedBox(height: 14),
        _buildCardField(
          _cardNumberCtrl,
          'Numéro de carte',
          Icons.credit_card,
          hint: '•••• •••• •••• ••••',
          keyboardType: TextInputType.number,
          maxLength: 19,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildCardField(
                _cardExpiryCtrl,
                'MM/AA',
                Icons.calendar_today,
                hint: '12/27',
                keyboardType: TextInputType.number,
                maxLength: 5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardField(
                _cardCvvCtrl,
                'CVV',
                Icons.lock,
                hint: '•••',
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscure: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_selectedPlanModel != null) _buildOrderSummary(),
      ],
    );
  }

  Widget _buildCardField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      style: const TextStyle(color: _kText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kTextSub),
        hintStyle: const TextStyle(color: _kBorder),
        prefixIcon: Icon(icon, color: _kGreen, size: 20),
        filled: true,
        fillColor: const Color(0xFFEEF1F8),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isPassword = false,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kTextSub),
        hintStyle: const TextStyle(color: _kBorder),
        prefixIcon: Icon(icon, color: _kGreen),
        filled: true,
        fillColor: const Color(0xFFEEF1F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGreen, width: 2),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return _kGreen;
    }
  }
}

// ─────────────────────────────────────────────
// BACKGROUND SPORTIF
// ─────────────────────────────────────────────
class _SportBackground extends StatelessWidget {
  const _SportBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: CustomPaint(painter: _SportBgPainter()));
  }
}

class _SportBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFE8F5E9), Color(0xFFF4F6FA), Color(0xFFE3F2FD)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final orb1 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF00897B).withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(size.width + 30, -20), radius: 220),
          );
    canvas.drawCircle(Offset(size.width + 30, -20), 220, orb1);

    final orb2 = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF1976D2).withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(-40, size.height + 10), radius: 180),
          );
    canvas.drawCircle(Offset(-40, size.height + 10), 180, orb2);

    final grid = Paint()
      ..color = const Color(0xFF00897B).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    _drawDumbbell(canvas, const Offset(32, 80), 0.06);
    _drawDumbbell(canvas, Offset(size.width - 40, size.height - 120), 0.05);
    _drawHex(canvas, Offset(size.width - 55, 55), 48);
    _drawHeartbeat(
      canvas,
      Offset(28, size.height - 140),
      size.width * 0.25,
      0.06,
    );
  }

  void _drawDumbbell(Canvas canvas, Offset center, double opacity) {
    final p = Paint()
      ..color = const Color(0xFF00897B).withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(center.dx - 22, center.dy),
      Offset(center.dx + 22, center.dy),
      p,
    );
    final plate = Paint()
      ..color = const Color(0xFF00897B).withValues(alpha: opacity + 0.02)
      ..style = PaintingStyle.fill;
    for (final dx in [-22.0, 22.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + dx, center.dy),
            width: 10,
            height: 22,
          ),
          const Radius.circular(3),
        ),
        plate,
      );
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r) {
    final p = Paint()
      ..color = const Color(0xFF1976D2).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = math.pi / 180 * (60 * i - 30);
      final pt = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
    final p2 = Paint()
      ..color = const Color(0xFF1976D2).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, r * 0.6, p2);
  }

  void _drawHeartbeat(
    Canvas canvas,
    Offset origin,
    double width,
    double opacity,
  ) {
    final p = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final seg = width / 7;
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + seg, origin.dy)
      ..lineTo(origin.dx + 1.8 * seg, origin.dy - 28)
      ..lineTo(origin.dx + 2.6 * seg, origin.dy + 18)
      ..lineTo(origin.dx + 3.4 * seg, origin.dy - 14)
      ..lineTo(origin.dx + 4.0 * seg, origin.dy)
      ..lineTo(origin.dx + width, origin.dy);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
