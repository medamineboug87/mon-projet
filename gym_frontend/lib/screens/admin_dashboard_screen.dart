import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../providers/message_provider.dart';
import 'login_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_exercises_screen.dart';
import 'admin_subscriptions_screen.dart';
import 'admin_plans_screen.dart';

// ─── Design tokens ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00C853);
const Color _kGreenL = Color(0xFFE8F5E9);
const Color _kGreenDark = Color(0xFF00963E);
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

enum _AdminSection {
  stats,
  coaches,
  members,
  payments,
  messages,
  exercises,
  subscriptions,
  plans,
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  _AdminSection _current = _AdminSection.stats;

  Map<String, dynamic>? _stats;
  List<dynamic> _coaches = [];
  List<dynamic> _members = [];
  List<dynamic> _pendingPayments = [];

  // ✅ Stats abonnements (version 2)
  Map<String, dynamic> _subscriptionStats = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      AdminService.getStats().then((v) {
        if (mounted) setState(() => _stats = v);
      }),
      AdminService.getAllCoaches().then((v) {
        if (mounted) setState(() => _coaches = v);
      }),
      AdminService.getAllMembers().then((v) {
        if (mounted) setState(() => _members = v);
      }),
      _fetchPendingPayments(),
      _fetchSubscriptionStats(), // ✅ Version 2
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchPendingPayments() async {
    try {
      final token = await AuthService.getToken();
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/cash/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200 && mounted) {
        setState(() => _pendingPayments = jsonDecode(r.body));
      }
    } catch (_) {}
  }

  // ✅ Version 2 : stats abonnements
  Future<void> _fetchSubscriptionStats() async {
    try {
      final token = await AuthService.getToken();
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200 && mounted) {
        setState(() => _subscriptionStats = jsonDecode(r.body));
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
  }

  // ═══════════════════════════════════════════════════════════════
  // MODIFIER UN COACH — Version 1
  // ═══════════════════════════════════════════════════════════════
  void _showEditCoachDialog(Map<String, dynamic> coach) {
    final int coachId = (coach['id'] as num).toInt();
    final nameCtrl = TextEditingController(
      text: coach['fullName']?.toString() ?? '',
    );
    final emailCtrl = TextEditingController(
      text: coach['email']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: coach['phone']?.toString() ?? '',
    );
    final experienceCtrl = TextEditingController(
      text: coach['experience']?.toString() ?? '0',
    );
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(
                  title: 'Modifier le coach',
                  subtitle: coach['fullName']?.toString() ?? '',
                  icon: Icons.edit_rounded,
                  color: _kBlue,
                  onClose: () => Navigator.pop(ctx),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorMsg != null) ...[
                          _ErrorBanner(message: errorMsg!),
                          const SizedBox(height: 12),
                        ],
                        _FieldLabel('Nom complet *'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: nameCtrl,
                          hint: 'Ex : Ahmed Ben Ali',
                          icon: Icons.person_rounded,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel('Email *'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: emailCtrl,
                          hint: 'coach@email.com',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel('Téléphone'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: phoneCtrl,
                          hint: '+216 XX XXX XXX',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel("Années d'expérience *"),
                        const SizedBox(height: 8),
                        _ExperienceStepper(
                          controller: experienceCtrl,
                          onChanged: (_) => setD(() {}),
                        ),
                        const SizedBox(height: 8),
                        if (coach['username'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _kSurf2,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_circle_rounded,
                                  size: 16,
                                  color: _kTextSub,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Username :',
                                  style: TextStyle(
                                    color: _kTextSub,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  coach['username'].toString(),
                                  style: const TextStyle(
                                    color: _kText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kSurf2,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: const Text(
                                    'lecture seule',
                                    style: TextStyle(
                                      color: _kTextSub,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _DialogFooter(
                  isLoading: isLoading,
                  confirmLabel: 'Enregistrer',
                  confirmColor: _kBlue,
                  confirmIcon: Icons.save_rounded,
                  onCancel: () => Navigator.pop(ctx),
                  onConfirm: () async {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final expText = experienceCtrl.text.trim();

                    if (name.isEmpty) {
                      setD(() => errorMsg = 'Le nom complet est requis');
                      return;
                    }
                    if (email.isEmpty || !email.contains('@')) {
                      setD(() => errorMsg = 'Veuillez entrer un email valide');
                      return;
                    }
                    final exp = int.tryParse(expText);
                    if (exp == null || exp < 0) {
                      setD(
                        () => errorMsg = "L'expérience doit être un nombre ≥ 0",
                      );
                      return;
                    }

                    setD(() {
                      isLoading = true;
                      errorMsg = null;
                    });

                    final result = await AdminService.updateCoach(
                      coachId: coachId,
                      fullName: name,
                      email: email,
                      phone: phoneCtrl.text.trim(),
                      experience: exp,
                    );

                    setD(() => isLoading = false);

                    if (result['success'] == true) {
                      Navigator.pop(ctx);
                      await _loadData();
                      _snack(
                        result['message'] ?? 'Coach mis à jour !',
                        _kGreen,
                      );
                    } else {
                      setD(
                        () => errorMsg =
                            result['message'] ??
                            'Erreur lors de la mise à jour',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIVER / DÉSACTIVER — Version 1
  // ═══════════════════════════════════════════════════════════════
  Future<void> _toggleCoachActive(Map<String, dynamic> coach) async {
    final int coachId = (coach['id'] as num).toInt();
    final bool isCurrentlyActive = coach['active'] == true;
    final String name = coach['fullName']?.toString() ?? 'Ce coach';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCurrentlyActive ? _kRedL : _kGreenL,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCurrentlyActive
                    ? Icons.person_off_rounded
                    : Icons.person_rounded,
                color: isCurrentlyActive ? _kRed : _kGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isCurrentlyActive ? 'Désactiver le coach' : 'Activer le coach',
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coach : $name',
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isCurrentlyActive
                  ? 'Le coach sera marqué comme inactif. Il ne pourra plus être assigné à de nouvelles séances.'
                  : 'Le coach sera réactivé et disponible pour les membres.',
              style: const TextStyle(color: _kTextSub, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyActive ? _kRed : _kGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              isCurrentlyActive ? 'Désactiver' : 'Activer',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await AdminService.toggleCoachActive(coachId);
    if (result['success'] == true) {
      await _loadData();
      _snack(
        result['message'] ?? 'Statut mis à jour',
        result['active'] == true ? _kGreen : _kOrange,
      );
    } else {
      _snack(result['message'] ?? 'Erreur', _kRed);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HISTORIQUE DES MODIFICATIONS — Version 1
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showCoachHistory(Map<String, dynamic> coach) async {
    final int coachId = (coach['id'] as num).toInt();
    final String name = coach['fullName']?.toString() ?? 'Coach';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: _kBlue)),
    );

    final data = await AdminService.getCoachHistory(coachId);
    if (!mounted) return;
    Navigator.pop(context);

    final List history = (data?['history'] as List?) ?? [];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: Column(
            children: [
              _DialogHeader(
                title: 'Historique — $name',
                subtitle: '${history.length} entrée(s)',
                icon: Icons.history_rounded,
                color: _kPurple,
                onClose: () => Navigator.pop(ctx),
              ),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _kSurf2,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.history_rounded,
                                size: 28,
                                color: _kTextSub,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Aucun historique disponible',
                              style: TextStyle(color: _kTextSub, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final entry = history[i] as Map<String, dynamic>;
                          final action = entry['action']?.toString() ?? '';
                          final detail = entry['detail']?.toString() ?? '';
                          final timestamp =
                              entry['timestamp']?.toString() ?? '';
                          final performedBy =
                              entry['performedBy']?.toString() ?? 'admin';

                          Color actionColor = switch (action) {
                            'CREATION' => _kGreen,
                            'MODIFICATION' => _kBlue,
                            'ACTIVATION' => _kGreen,
                            'DÉSACTIVATION' => _kOrange,
                            _ => _kTextSub,
                          };
                          IconData actionIcon = switch (action) {
                            'CREATION' => Icons.add_circle_rounded,
                            'MODIFICATION' => Icons.edit_rounded,
                            'ACTIVATION' => Icons.check_circle_rounded,
                            'DÉSACTIVATION' => Icons.cancel_rounded,
                            _ => Icons.info_rounded,
                          };

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: actionColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: actionColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: actionColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    actionIcon,
                                    color: actionColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: actionColor.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              action,
                                              style: TextStyle(
                                                color: actionColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatHistoryDate(timestamp),
                                            style: const TextStyle(
                                              color: _kTextSub,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (detail.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          detail,
                                          style: const TextStyle(
                                            color: _kText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        'Par : $performedBy',
                                        style: const TextStyle(
                                          color: _kTextSub,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kTextSub,
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatHistoryDate(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE COACH dialog — Version 1 améliorée
  // ═══════════════════════════════════════════════════════════════
  void _showCreateCoachDialog() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final experienceCtrl = TextEditingController(text: '0');
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogHeader(
                  title: 'Ajouter un coach',
                  subtitle: 'Nouveau compte coach',
                  icon: Icons.person_add_rounded,
                  color: _kGreen,
                  onClose: () => Navigator.pop(ctx),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorMsg != null) ...[
                          _ErrorBanner(message: errorMsg!),
                          const SizedBox(height: 12),
                        ],
                        _FieldLabel('Nom complet *'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: nameCtrl,
                          hint: 'Ahmed Ben Ali',
                          icon: Icons.person_rounded,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 12),
                        _FieldLabel('Username *'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: usernameCtrl,
                          hint: 'coach_ahmed',
                          icon: Icons.account_circle_rounded,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 12),
                        _FieldLabel('Email *'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: emailCtrl,
                          hint: 'ahmed@gym.com',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 12),
                        _FieldLabel('Téléphone'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: phoneCtrl,
                          hint: '+216 XX XXX XXX',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 12),
                        _FieldLabel('Mot de passe *'),
                        const SizedBox(height: 6),
                        _EditField(
                          controller: passwordCtrl,
                          hint: '••••••••',
                          icon: Icons.lock_rounded,
                          obscure: true,
                          onChanged: (_) => setD(() => errorMsg = null),
                        ),
                        const SizedBox(height: 12),
                        _FieldLabel("Années d'expérience *"),
                        const SizedBox(height: 6),
                        _ExperienceStepper(
                          controller: experienceCtrl,
                          onChanged: (_) => setD(() {}),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _DialogFooter(
                  isLoading: isLoading,
                  confirmLabel: 'Créer le coach',
                  confirmColor: _kGreen,
                  confirmIcon: Icons.add_rounded,
                  onCancel: () => Navigator.pop(ctx),
                  onConfirm: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      setD(() => errorMsg = 'Nom complet requis');
                      return;
                    }
                    if (usernameCtrl.text.trim().isEmpty) {
                      setD(() => errorMsg = 'Username requis');
                      return;
                    }
                    final email = emailCtrl.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      setD(() => errorMsg = 'Email invalide');
                      return;
                    }
                    if (passwordCtrl.text.length < 8) {
                      setD(
                        () => errorMsg = 'Mot de passe : 8 caractères minimum',
                      );
                      return;
                    }
                    final exp = int.tryParse(experienceCtrl.text) ?? 0;

                    setD(() {
                      isLoading = true;
                      errorMsg = null;
                    });

                    final r = await AdminService.createCoach(
                      username: usernameCtrl.text.trim(),
                      fullName: nameCtrl.text.trim(),
                      email: email,
                      phone: phoneCtrl.text.trim(),
                      password: passwordCtrl.text.trim(),
                      experience: exp,
                    );

                    setD(() => isLoading = false);

                    if (r['success'] == true) {
                      Navigator.pop(ctx);
                      await _loadData();
                      _snack('Coach ajouté avec succès !', _kGreen);
                    } else {
                      setD(() => errorMsg = r['message'] ?? 'Erreur');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCoach(Map<String, dynamic> coach) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer le coach',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Confirmer la suppression de ${coach['fullName']} ?\nCette action est irréversible.',
          style: const TextStyle(color: _kTextSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await AdminService.deleteCoach(
      (coach['id'] as num).toInt(),
    );
    if (success && mounted) {
      await _loadData();
      _snack('Coach supprimé', _kOrange);
    }
  }

  void _confirmDeleteMember(Map<String, dynamic> member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer le membre',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Confirmer la suppression de ${member['fullName']} ?',
          style: const TextStyle(color: _kTextSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: _kRed, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await AdminService.deleteMember(
      (member['id'] as num).toInt(),
    );
    if (success && mounted) {
      await _loadData();
      _snack('Membre supprimé', _kGreen);
    }
  }

  Future<void> _confirmCashPayment(int subId) async {
    try {
      final token = await AuthService.getToken();
      final r = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/cash/confirm/$subId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        await _loadData();
        _snack('Paiement confirmé !', _kGreen);
      } else {
        _snack('Erreur', _kRed);
      }
    } catch (_) {
      _snack('Erreur réseau', _kRed);
    }
  }

  Future<void> _rejectCashPayment(int subId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Rejeter la demande',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Confirmer le rejet de $name ?\nLe compte sera supprimé.',
          style: const TextStyle(color: _kTextSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Rejeter',
              style: TextStyle(color: _kRed, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final token = await AuthService.getToken();
      final r = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/payments/cash/reject/$subId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) {
        await _loadData();
        _snack('Demande rejetée et compte supprimé', _kRed);
      } else {
        final body = jsonDecode(r.body);
        _snack(body['error'] ?? 'Erreur lors du rejet', _kRed);
      }
    } catch (_) {
      _snack('Erreur réseau', _kRed);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _sectionLabel(_AdminSection s) => switch (s) {
    _AdminSection.stats => 'Tableau de bord',
    _AdminSection.coaches => 'Coachs',
    _AdminSection.members => 'Membres',
    _AdminSection.payments => 'Paiements',
    _AdminSection.messages => 'Messagerie',
    _AdminSection.exercises => 'Exercices',
    _AdminSection.subscriptions => 'Abonnements',
    _AdminSection.plans => 'Plans',
  };

  Widget _buildSection() => switch (_current) {
    _AdminSection.stats => _buildStats(),
    _AdminSection.coaches => _buildCoaches(),
    _AdminSection.members => _buildMembers(),
    _AdminSection.payments => _buildPendingPayments(),
    _AdminSection.messages => const AdminMessagesScreen(),
    _AdminSection.exercises => const AdminExercisesScreen(),
    _AdminSection.subscriptions => const AdminSubscriptionsScreen(),
    _AdminSection.plans => const AdminPlansScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pendingPayments.length;
    final unreadCount = ref.watch(adminUnreadCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: _kGreen,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin',
                    style: TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                  Text(
                    _sectionLabel(_current),
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: _kGreen,
                  strokeWidth: 2,
                ),
              ),
            PopupMenuButton<_AdminSection>(
              icon: const Icon(Icons.menu_rounded, color: _kTextSub),
              onSelected: (s) => setState(() => _current = s),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _AdminSection.stats,
                  child: Row(
                    children: [
                      Icon(Icons.dashboard_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Tableau de bord'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _AdminSection.coaches,
                  child: Row(
                    children: [
                      Icon(Icons.sports_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Coachs'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _AdminSection.members,
                  child: Row(
                    children: [
                      Icon(Icons.people_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Membres'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _AdminSection.payments,
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded, size: 20),
                      const SizedBox(width: 12),
                      const Text('Paiements'),
                      if (pendingCount > 0) ...[
                        const Spacer(),
                        _Badge(count: pendingCount, color: _kOrange),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _AdminSection.messages,
                  child: Row(
                    children: [
                      const Icon(Icons.forum_rounded, size: 20),
                      const SizedBox(width: 12),
                      const Text('Messagerie'),
                      if (unreadCount > 0) ...[
                        const Spacer(),
                        _Badge(count: unreadCount, color: _kRed),
                      ],
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _AdminSection.exercises,
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Exercices'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _AdminSection.subscriptions,
                  child: Row(
                    children: [
                      Icon(Icons.card_membership_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Abonnements'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _AdminSection.plans,
                  child: Row(
                    children: [
                      Icon(Icons.local_offer_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Plans'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
              onPressed: _loadData,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: _kTextSub),
              onPressed: _logout,
            ),
          ],
        ),
        backgroundColor: _kSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _buildSection(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  section: _AdminSection.stats,
                  icon: Icons.dashboard_rounded,
                  label: 'Stats',
                  badge: 0,
                  badgeColor: _kGreen,
                  current: _current,
                  onTap: (s) => setState(() => _current = s),
                ),
                _BottomNavItem(
                  section: _AdminSection.coaches,
                  icon: Icons.sports_rounded,
                  label: 'Coachs',
                  badge: 0,
                  badgeColor: _kGreen,
                  current: _current,
                  onTap: (s) => setState(() => _current = s),
                ),
                _BottomNavItem(
                  section: _AdminSection.members,
                  icon: Icons.people_rounded,
                  label: 'Membres',
                  badge: 0,
                  badgeColor: _kGreen,
                  current: _current,
                  onTap: (s) => setState(() => _current = s),
                ),
                _BottomNavItem(
                  section: _AdminSection.payments,
                  icon: Icons.payments_rounded,
                  label: 'Paiements',
                  badge: pendingCount,
                  badgeColor: _kOrange,
                  current: _current,
                  onTap: (s) => setState(() => _current = s),
                ),
                _BottomNavItem(
                  section: _AdminSection.messages,
                  icon: Icons.forum_rounded,
                  label: 'Msgs',
                  badge: unreadCount,
                  badgeColor: _kRed,
                  current: _current,
                  onTap: (s) => setState(() => _current = s),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _current == _AdminSection.coaches
          ? FloatingActionButton(
              onPressed: _showCreateCoachDialog,
              backgroundColor: _kGreen,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COACHES LIST — Version 1 améliorée
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCoaches() {
    final activeCount = _coaches.where((c) => c['active'] == true).length;
    final inactiveCount = _coaches.length - activeCount;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kGreen,
      child: _coaches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kSurf2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.sports_rounded,
                      size: 30,
                      color: _kTextSub,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun coach',
                    style: TextStyle(color: _kTextSub, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      _SummaryChip(
                        label:
                            '$activeCount actif${activeCount > 1 ? 's' : ''}',
                        color: _kGreen,
                        bg: _kGreenL,
                      ),
                      const SizedBox(width: 8),
                      if (inactiveCount > 0)
                        _SummaryChip(
                          label:
                              '$inactiveCount inactif${inactiveCount > 1 ? 's' : ''}',
                          color: _kOrange,
                          bg: _kOrangeL,
                        ),
                      const Spacer(),
                      Text(
                        '${_coaches.length} coach${_coaches.length > 1 ? 's' : ''} au total',
                        style: const TextStyle(color: _kTextSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ..._coaches.map((coach) => _buildCoachCard(coach)),
              ],
            ),
    );
  }

  Widget _buildCoachCard(Map<String, dynamic> coach) {
    final name = coach['fullName']?.toString() ?? 'N/A';
    final bool isActive = coach['active'] == true;
    final int exp = (coach['experience'] as num?)?.toInt() ?? 0;
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _kBorder : _kOrange.withOpacity(0.3),
          width: isActive ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _kBlue.withOpacity(0.12)
                            : _kOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? _kBlue.withOpacity(0.25)
                              : _kOrange.withOpacity(0.25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: isActive ? _kBlue : _kOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isActive ? _kGreen : _kOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kSurface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isActive ? _kText : _kTextSub,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _kOrangeL,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _kOrange.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'Inactif',
                                style: TextStyle(
                                  color: _kOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        coach['email']?.toString() ?? '',
                        style: const TextStyle(color: _kTextSub, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: _kOrange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "$exp an${exp > 1 ? 's' : ''} d'expérience",
                            style: const TextStyle(color: _kBlue, fontSize: 11),
                          ),
                          if (coach['phone'] != null &&
                              coach['phone'].toString().isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.phone_rounded,
                              size: 11,
                              color: _kTextSub,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              coach['phone'].toString(),
                              style: const TextStyle(
                                color: _kTextSub,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: Icons.edit_rounded,
                    label: 'Modifier',
                    color: _kBlue,
                    onTap: () => _showEditCoachDialog(coach),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: isActive
                        ? Icons.person_off_rounded
                        : Icons.person_rounded,
                    label: isActive ? 'Désactiver' : 'Activer',
                    color: isActive ? _kOrange : _kGreen,
                    onTap: () => _toggleCoachActive(coach),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    color: _kPurple,
                    onTap: () => _showCoachHistory(coach),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmDeleteCoach(coach),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _kRedL,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kRed.withOpacity(0.2)),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: _kRed,
                        size: 16,
                      ),
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

  // ═══════════════════════════════════════════════════════════════
  // STATS COMPLÈTES — Version 2 (dashboard complet avec abonnements)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStats() {
    final total = _stats?['totalMembers'] ?? 0;
    final coaches = _stats?['totalCoaches'] ?? 0;
    final males = _stats?['maleMembers'] ?? 0;
    final females = _stats?['femaleMembers'] ?? 0;

    // Stats abonnements (version 2)
    final subTotal = (_subscriptionStats['total'] as num?)?.toInt() ?? 0;
    final subActive = (_subscriptionStats['active'] as num?)?.toInt() ?? 0;
    final subPending = (_subscriptionStats['pending'] as num?)?.toInt() ?? 0;
    final subSuspended =
        (_subscriptionStats['suspended'] as num?)?.toInt() ?? 0;
    final subCancelled =
        (_subscriptionStats['cancelled'] as num?)?.toInt() ?? 0;
    final revenue =
        (_subscriptionStats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final basicCount = (_subscriptionStats['basicCount'] as num?)?.toInt() ?? 0;
    final standardCount =
        (_subscriptionStats['standardCount'] as num?)?.toInt() ?? 0;
    final premiumCount =
        (_subscriptionStats['premiumCount'] as num?)?.toInt() ?? 0;
    final annualCount =
        (_subscriptionStats['annualCount'] as num?)?.toInt() ?? 0;

    final byType = _subscriptionStats['byType'] as Map<String, dynamic>? ?? {};
    final customEntries = byType.entries
        .where(
          (e) => !['BASIC', 'STANDARD', 'PREMIUM', 'ANNUAL'].contains(e.key),
        )
        .where((e) => (e.value as num).toInt() > 0)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
        children: [
          // ══════════════════════════════════
          // SECTION 1 — MEMBRES & COACHS
          // ══════════════════════════════════
          _sectionHeader('MEMBRES & COACHS', Icons.people_rounded, _kGreen),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kGreenL,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kGreen.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: _kGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: _kGreen,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'Membres inscrits',
                      style: TextStyle(color: _kTextSub, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$coaches',
                      style: const TextStyle(
                        color: _kBlue,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'Coach(s)',
                      style: TextStyle(color: _kTextSub, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _miniStatCard(
                  'Hommes',
                  males,
                  Icons.male_rounded,
                  _kBlue,
                  _kBlueL,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStatCard(
                  'Femmes',
                  females,
                  Icons.female_rounded,
                  _kOrange,
                  _kOrangeL,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RÉPARTITION MEMBRES',
                  style: TextStyle(
                    color: _kTextSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildGenderBar('Hommes', males, total, _kBlue),
                const SizedBox(height: 10),
                _buildGenderBar('Femmes', females, total, _kOrange),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ══════════════════════════════════
          // SECTION 2 — REVENUS
          // ══════════════════════════════════
          _sectionHeader(
            'REVENUS & ABONNEMENTS',
            Icons.attach_money_rounded,
            _kGreen,
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGreen, _kGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kGreen.withOpacity(0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenus abonnements actifs',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        '${revenue.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$subTotal abonnements',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (subPending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _kOrange.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$subPending en attente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: [
              _subStatusCard(
                'Actifs',
                subActive,
                Icons.check_circle_rounded,
                _kGreen,
                _kGreenL,
              ),
              _subStatusCard(
                'En attente',
                subPending,
                Icons.hourglass_top_rounded,
                _kOrange,
                _kOrangeL,
              ),
              _subStatusCard(
                'Suspendus',
                subSuspended,
                Icons.pause_circle_rounded,
                _kBlue,
                _kBlueL,
              ),
              _subStatusCard(
                'Annulés',
                subCancelled,
                Icons.cancel_rounded,
                _kRed,
                _kRedL,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ══════════════════════════════════
          // SECTION 3 — RÉPARTITION PAR PLAN
          // ══════════════════════════════════
          _sectionHeader(
            'RÉPARTITION PAR PLAN',
            Icons.local_offer_rounded,
            _kBlue,
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: [
                _planBar('BASIC', basicCount, subTotal, _kBlue),
                const SizedBox(height: 12),
                _planBar('STANDARD', standardCount, subTotal, _kPurple),
                const SizedBox(height: 12),
                _planBar('PREMIUM', premiumCount, subTotal, _kGreen),
                const SizedBox(height: 12),
                _planBar('ANNUAL', annualCount, subTotal, _kOrange),
                if (customEntries.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: _kBorder, height: 1),
                  ),
                  ...customEntries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _planBar(
                        e.key,
                        (e.value as num).toInt(),
                        subTotal,
                        _kPurple,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ══════════════════════════════════
          // SECTION 4 — PAIEMENTS EN ATTENTE (aperçu)
          // ══════════════════════════════════
          if (_pendingPayments.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _sectionHeader(
                    'PAIEMENTS EN ATTENTE',
                    Icons.hourglass_top_rounded,
                    _kOrange,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _current = _AdminSection.payments),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(color: _kOrange, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._pendingPayments.take(3).map((sub) {
              final name = sub['member']?['fullName'] ?? 'Membre inconnu';
              final subId = sub['id'] as int;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kOrangeL,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kOrange.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: _kOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${sub['type']} • ${sub['price']} DT • espèces',
                            style: const TextStyle(
                              color: _kOrange,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _confirmCashPayment(subId),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _kGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _rejectCashPayment(subId, name),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _kRedL,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _kRed.withOpacity(0.3)),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _kRed,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (_pendingPayments.length > 3)
              GestureDetector(
                onTap: () => setState(() => _current = _AdminSection.payments),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _kOrange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kOrange.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      '+ ${_pendingPayments.length - 3} autre(s) en attente — Voir tout',
                      style: const TextStyle(
                        color: _kOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],

          // ══════════════════════════════════
          // SECTION 5 — ACTIONS RAPIDES
          // ══════════════════════════════════
          _sectionHeader('ACTIONS RAPIDES', Icons.flash_on_rounded, _kTextSub),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _quickAction(
                  icon: Icons.payments_rounded,
                  label: 'Paiements\nen attente',
                  badge: _pendingPayments.length,
                  color: _kOrange,
                  bg: _kOrangeL,
                  onTap: () =>
                      setState(() => _current = _AdminSection.payments),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickAction(
                  icon: Icons.card_membership_rounded,
                  label: 'Gérer\nAbonnements',
                  badge: 0,
                  color: _kGreen,
                  bg: _kGreenL,
                  onTap: () =>
                      setState(() => _current = _AdminSection.subscriptions),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickAction(
                  icon: Icons.local_offer_rounded,
                  label: 'Plans\npersonnalisés',
                  badge: 0,
                  color: _kBlue,
                  bg: _kBlueL,
                  onTap: () => setState(() => _current = _AdminSection.plans),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers visuels pour les stats (version 2) ──

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _kTextSub,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGenderBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Icon(
              label == 'Hommes' ? Icons.male_rounded : Icons.female_rounded,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: _kTextSub, fontSize: 12)),
            const Spacer(),
            Text(
              '$count (${(pct * 100).toStringAsFixed(0)}%)',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: _kSurf2,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _subStatusCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: _kTextSub, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planBar(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(color: _kTextSub, fontSize: 12),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _kSurf2,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            '$count  ${(pct * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required int badge,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 26),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: bg, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MEMBRES (version simplifiée mais fonctionnelle) ──
  Widget _buildMembers() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kGreen,
      child: _members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kSurf2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.people_rounded,
                      size: 30,
                      color: _kTextSub,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun membre',
                    style: TextStyle(color: _kTextSub, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final member = _members[i];
                final name = member['fullName']?.toString() ?? 'N/A';
                final initials = name
                    .trim()
                    .split(' ')
                    .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
                    .take(2)
                    .join();
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: _kGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: _kText,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${member['age']} ans • ${member['gender'] ?? ''}',
                              style: const TextStyle(
                                color: _kTextSub,
                                fontSize: 11,
                              ),
                            ),
                            if (member['registrationDate'] != null)
                              Text(
                                'Depuis ${member['registrationDate']}',
                                style: const TextStyle(
                                  color: _kTextSub,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDeleteMember(member),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _kRedL,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: _kRed,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ── Paiements en attente (version complète) ──
  Widget _buildPendingPayments() {
    if (_pendingPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kSurf2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 30,
                color: _kTextSub,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aucun paiement en attente',
              style: TextStyle(color: _kTextSub, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _pendingPayments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final sub = _pendingPayments[i];
          final name = sub['member']?['fullName'] ?? 'Membre inconnu';
          final subId = sub['id'] as int;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kOrangeL,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kOrange.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _kOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.payments_rounded,
                          color: _kOrange,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: _kText,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${sub['type']} • ${sub['price']} DT • espèces',
                            style: const TextStyle(
                              color: _kOrange,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Depuis : ${sub['startDate']}',
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _confirmCashPayment(subId),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: _kGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Confirmer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _rejectCashPayment(subId, name),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: _kRedL,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kRed.withOpacity(0.35)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, color: _kRed, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Rejeter',
                                style: TextStyle(
                                  color: _kRed,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED WIDGETS (Version 1 + Version 2 combinées)
// ═══════════════════════════════════════════════════════════════

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(color: _kTextSub, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _kTextSub, size: 20),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  final bool isLoading;
  final String confirmLabel;
  final Color confirmColor;
  final IconData confirmIcon;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DialogFooter({
    required this.isLoading,
    required this.confirmLabel,
    required this.confirmColor,
    required this.confirmIcon,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kTextSub,
                side: const BorderSide(color: _kBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                disabledBackgroundColor: confirmColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(confirmIcon, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          confirmLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final void Function(String)? onChanged;

  const _EditField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(color: _kText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTextSub, fontSize: 13),
        prefixIcon: Icon(icon, color: _kBlue, size: 18),
        filled: true,
        fillColor: _kSurf2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _kBlue, width: 1.5),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _kTextSub,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ),
  );
}

class _ExperienceStepper extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const _ExperienceStepper({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (ctx, setL) {
        int value = int.tryParse(controller.text) ?? 0;

        void update(int newVal) {
          if (newVal < 0) return;
          controller.text = newVal.toString();
          onChanged(newVal.toString());
          setL(() {});
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kSurf2,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => update(value - 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: value > 0
                        ? _kRed.withOpacity(0.1)
                        : _kBorder.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: value > 0 ? _kRed.withOpacity(0.3) : _kBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: value > 0 ? _kRed : _kTextSub,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    onChanged(v);
                    setL(() {});
                  },
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              Text(
                'an${value > 1 ? 's' : ''}',
                style: const TextStyle(color: _kTextSub, fontSize: 12),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => update(value + 1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kGreen.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: _kGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _kRedL,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kRed.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: _kRed, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: _kRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: TextStyle(color: color, fontSize: 11),
    ),
  );
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _SummaryChip({
    required this.label,
    required this.color,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _BottomNavItem extends StatelessWidget {
  final _AdminSection section;
  final IconData icon;
  final String label;
  final int badge;
  final Color badgeColor;
  final _AdminSection current;
  final void Function(_AdminSection) onTap;

  const _BottomNavItem({
    required this.section,
    required this.icon,
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == section;
    final color = isActive ? _kGreen : _kTextSub;
    return GestureDetector(
      onTap: () => onTap(section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? _kGreen.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: color),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kSurface, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
