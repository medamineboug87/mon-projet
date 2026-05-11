import 'package:flutter/material.dart';
import '../services/payment_service.dart';

// ─── Design tokens light ───
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenDark = Color(0xFF00695C);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class PaymentScreen extends StatefulWidget {
  final int memberId;
  final String subscriptionType;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.memberId,
    required this.subscriptionType,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // 0 = choix méthode, 1 = formulaire carte, 2 = processing, 3 = succès, 4 = espèces pending
  int _step = 0;
  bool _isProcessing = false;

  // Contrôleurs carte
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: _kRed));
  }

  // ── Validation basique du formulaire carte ──
  bool _validateCardForm() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Nom du porteur requis');
      return false;
    }
    final rawNumber = _cardNumberCtrl.text.replaceAll(' ', '');
    if (rawNumber.length < 16) {
      _showError('Numéro de carte invalide (16 chiffres requis)');
      return false;
    }
    if (_expiryCtrl.text.length < 5) {
      _showError('Date d\'expiration invalide (MM/AA)');
      return false;
    }
    if (_cvvCtrl.text.length < 3) {
      _showError('CVV invalide');
      return false;
    }
    return true;
  }

  // ── Paiement en ligne (simulation côté backend) ──
  Future<void> _payOnline() async {
    if (!_validateCardForm()) return;

    setState(() => _isProcessing = true);

    final result = await PaymentService.simulateOnlinePayment(
      memberId: widget.memberId,
      subscriptionType: widget.subscriptionType,
      amount: widget.amount,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      setState(() => _step = 3);
    } else {
      _showError('Erreur de paiement. Veuillez réessayer.');
    }
  }

  // ── Paiement en espèces (PENDING) ──
  Future<void> _payByCash() async {
    setState(() => _isProcessing = true);

    final result = await PaymentService.cashPayment(
      memberId: widget.memberId,
      subscriptionType: widget.subscriptionType,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result != null && result['status'] == 'PENDING') {
      setState(() => _step = 4);
    } else {
      _showError('Erreur. Veuillez réessayer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Paiement', style: TextStyle(color: _kText)),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        leading: (_step == 1)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: _kText),
                onPressed: () => setState(() {
                  _step = 0;
                }),
              )
            : null,
      ),
      body: _isProcessing
          ? _buildProcessingScreen()
          : switch (_step) {
              1 => _buildCardForm(),
              3 => _buildSuccessScreen(),
              4 => _buildCashPendingScreen(),
              _ => _buildMethodSelection(),
            },
    );
  }

  // ─────────────────────────────────────────────
  // ÉTAPE 0 : Choix méthode
  // ─────────────────────────────────────────────
  Widget _buildMethodSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé commande
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                const Icon(Icons.card_membership, color: _kText, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abonnement ${widget.subscriptionType}',
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${widget.amount.toStringAsFixed(0)} DT',
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'Choisissez votre mode de paiement',
            style: TextStyle(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // ── Carte bancaire ──
          _buildPaymentOption(
            emoji: '💳',
            title: 'Paiement par carte',
            subtitle: 'Visa / Mastercard',
            color: _kGreen,
            onTap: () => setState(() {
              _step = 1;
            }),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: Divider(color: _kText.withValues(alpha: 0.1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ou',
                  style: TextStyle(color: _kText.withValues(alpha: 0.3)),
                ),
              ),
              Expanded(child: Divider(color: _kText.withValues(alpha: 0.1))),
            ],
          ),
          const SizedBox(height: 20),

          // ── Espèces ──
          _buildPaymentOption(
            emoji: '💵',
            title: 'Payer en espèces',
            subtitle: 'À la réception — activation après confirmation admin',
            color: _kOrange,
            onTap: _payByCash,
          ),
          const SizedBox(height: 24),

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
      ),
    );
  }

  Widget _buildPaymentOption({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
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
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ÉTAPE 1 : Formulaire carte
  // ─────────────────────────────────────────────
  Widget _buildCardForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Text('💳', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Text(
                  'Informations carte bancaire',
                  style: TextStyle(
                    color: _kGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildCardField(
            controller: _nameCtrl,
            label: 'Nom du porteur',
            hint: 'Ahmed Ben Ali',
            icon: Icons.person,
          ),
          const SizedBox(height: 14),
          _buildCardField(
            controller: _cardNumberCtrl,
            label: 'Numéro de carte',
            hint: '•••• •••• •••• ••••',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            maxLength: 19,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCardField(
                  controller: _expiryCtrl,
                  label: 'MM/AA',
                  hint: '12/27',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCardField(
                  controller: _cvvCtrl,
                  label: 'CVV',
                  hint: '•••',
                  icon: Icons.lock,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscure: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total à payer', style: TextStyle(color: _kText)),
                Text(
                  '${widget.amount.toStringAsFixed(0)} DT',
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

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _payOnline,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Payer ${widget.amount.toStringAsFixed(0)} DT',
                style: const TextStyle(
                  color: _kText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: _kTextSub, size: 14),
                SizedBox(width: 4),
                Text(
                  'Transaction sécurisée',
                  style: TextStyle(color: _kTextSub, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      style: const TextStyle(color: _kText, fontSize: 16),
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
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Processing
  // ─────────────────────────────────────────────
  Widget _buildProcessingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _kGreen, strokeWidth: 3),
          SizedBox(height: 24),
          Text(
            'Traitement en cours...',
            style: TextStyle(color: _kText, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Veuillez patienter',
            style: TextStyle(color: _kTextSub, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ÉTAPE 3 : Succès paiement en ligne
  // ─────────────────────────────────────────────
  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kGreen, _kGreenDark]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: _kText, size: 55),
            ),
            const SizedBox(height: 28),
            const Text(
              'Paiement réussi !',
              style: TextStyle(
                color: _kText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Abonnement ${widget.subscriptionType} activé',
              style: const TextStyle(color: _kText, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.amount.toStringAsFixed(0)} DT',
              style: const TextStyle(
                color: _kGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Retour au Dashboard',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ÉTAPE 4 : Espèces en attente (PENDING)
  // ─────────────────────────────────────────────
  Widget _buildCashPendingScreen() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _kOrange, width: 2),
            ),
            child: const Icon(Icons.hourglass_top, color: _kOrange, size: 50),
          ),
          const SizedBox(height: 24),
          const Text(
            'Demande enregistrée !',
            style: TextStyle(
              color: _kText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Votre compte est en attente d\'activation.',
            style: TextStyle(color: _kText, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 Instructions :',
                  style: TextStyle(
                    color: _kOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '1. Présentez-vous à la réception',
                  style: TextStyle(color: _kText, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  '2. Payez le montant en espèces',
                  style: TextStyle(color: _kText, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  '3. L\'admin activera votre compte',
                  style: TextStyle(color: _kText, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'OK, compris !',
                style: TextStyle(
                  color: _kText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
