// lib/screens/admin_dashboard_screen.dart
// ✅ CORRIGÉ : version mobile-first

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

const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00C853);
const Color _kGreenL = Color(0xFFE8F5E9);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kOrange = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      AdminService.getStats(),
      AdminService.getAllCoaches(),
      AdminService.getAllMembers(),
      _fetchPendingPayments(),
    ]);
    if (mounted)
      setState(() {
        _stats = results[0] as Map<String, dynamic>?;
        _coaches = results[1] as List<dynamic>;
        _members = results[2] as List<dynamic>;
        _pendingPayments = results[3] as List<dynamic>;
        _isLoading = false;
      });
  }

  Future<List<dynamic>> _fetchPendingPayments() async {
    try {
      final token = await AuthService.getToken();
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/cash/pending'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
    return [];
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
      } else
        _snack('Erreur', _kRed);
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

  void _showCreateCoachDialog() {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final experienceCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Ajouter un coach',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TextFieldWithLabel(
                  nameCtrl,
                  'Nom complet',
                  Icons.person_rounded,
                ),
                const SizedBox(height: 10),
                _TextFieldWithLabel(
                  usernameCtrl,
                  'Username',
                  Icons.account_circle_rounded,
                ),
                const SizedBox(height: 10),
                _TextFieldWithLabel(emailCtrl, 'Email', Icons.email_rounded),
                const SizedBox(height: 10),
                _TextFieldWithLabel(
                  phoneCtrl,
                  'Téléphone',
                  Icons.phone_rounded,
                ),
                const SizedBox(height: 10),
                _TextFieldWithLabel(
                  passwordCtrl,
                  'Mot de passe',
                  Icons.lock_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                _TextFieldWithLabel(
                  experienceCtrl,
                  "Années d'expérience",
                  Icons.star_rounded,
                  isNumber: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
            ),
            _ActionButton(
              label: 'Ajouter',
              isLoading: loading,
              color: _kGreen,
              onTap: () async {
                setD(() => loading = true);
                final r = await AdminService.createCoach(
                  username: usernameCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                  experience: int.tryParse(experienceCtrl.text) ?? 0,
                );
                setD(() => loading = false);
                if (r['success'] == true) {
                  Navigator.pop(ctx);
                  await _loadData();
                  _snack('Coach ajouté !', _kGreen);
                } else
                  _snack(r['message'] ?? 'Erreur', _kRed);
              },
            ),
          ],
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
          'Confirmer la suppression de ${coach['fullName']} ?',
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
    final success = await AdminService.deleteCoach(coach['id']);
    if (success && mounted) {
      await _loadData();
      _snack('Coach supprimé', _kGreen);
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
    final success = await AdminService.deleteMember(member['id']);
    if (success && mounted) {
      await _loadData();
      _snack('Membre supprimé', _kGreen);
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
    _AdminSection.plans => "Plans",
  };

  IconData _sectionIcon(_AdminSection s) => switch (s) {
    _AdminSection.stats => Icons.dashboard_rounded,
    _AdminSection.coaches => Icons.sports_rounded,
    _AdminSection.members => Icons.people_rounded,
    _AdminSection.payments => Icons.payments_rounded,
    _AdminSection.messages => Icons.forum_rounded,
    _AdminSection.exercises => Icons.fitness_center_rounded,
    _AdminSection.subscriptions => Icons.card_membership_rounded,
    _AdminSection.plans => Icons.local_offer_rounded,
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
                color: _kGreen.withValues(alpha: 0.12),
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
              onSelected: (section) {
                setState(() => _current = section);
              },
              itemBuilder: (context) => [
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
                      Icon(Icons.payments_rounded, size: 20),
                      const SizedBox(width: 12),
                      const Text('Paiements'),
                      if (pendingCount > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _kOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pendingCount > 99 ? '99+' : '$pendingCount',
                            style: const TextStyle(
                              color: _kOrange,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _AdminSection.messages,
                  child: Row(
                    children: [
                      Icon(Icons.forum_rounded, size: 20),
                      const SizedBox(width: 12),
                      const Text('Messagerie'),
                      if (unreadCount > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _kRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(color: _kRed, fontSize: 11),
                          ),
                        ),
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
              color: Colors.black.withValues(alpha: 0.06),
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
                _buildBottomNavItem(
                  _AdminSection.stats,
                  Icons.dashboard_rounded,
                  'Stats',
                  0,
                  _kGreen,
                ),
                _buildBottomNavItem(
                  _AdminSection.coaches,
                  Icons.sports_rounded,
                  'Coachs',
                  0,
                  _kGreen,
                ),
                _buildBottomNavItem(
                  _AdminSection.members,
                  Icons.people_rounded,
                  'Membres',
                  0,
                  _kGreen,
                ),
                _buildBottomNavItem(
                  _AdminSection.payments,
                  Icons.payments_rounded,
                  'Paiements',
                  pendingCount,
                  _kOrange,
                ),
                _buildBottomNavItem(
                  _AdminSection.messages,
                  Icons.forum_rounded,
                  'Msgs',
                  unreadCount,
                  _kRed,
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

  Widget _buildBottomNavItem(
    _AdminSection section,
    IconData icon,
    String label,
    int badge,
    Color badgeColor,
  ) {
    final isActive = _current == section;
    final color = isActive ? _kGreen : _kTextSub;
    return GestureDetector(
      onTap: () => setState(() => _current = section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? _kGreen.withValues(alpha: 0.12)
              : Colors.transparent,
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
                        vertical: 2,
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
                          fontSize: 9,
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

  // ── STATS ──
  Widget _buildStats() {
    final total = _stats?['totalMembers'] ?? 0;
    final coaches = _stats?['totalCoaches'] ?? 0;
    final males = _stats?['maleMembers'] ?? 0;
    final females = _stats?['femaleMembers'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kGreen,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kGreenL,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.15),
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
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'Membres actifs',
                      style: TextStyle(color: _kTextSub, fontSize: 12),
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
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kBlueL,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sports_rounded,
                          color: _kBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$coaches',
                        style: const TextStyle(
                          color: _kBlue,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'Coachs',
                        style: TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kOrangeL,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: _kOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_pendingPayments.length}',
                        style: const TextStyle(
                          color: _kOrange,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'En attente',
                        style: TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kBlueL,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.male_rounded,
                          color: _kBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$males',
                        style: const TextStyle(
                          color: _kBlue,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'Hommes',
                        style: TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kOrangeL,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kOrange.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.female_rounded,
                          color: _kOrange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$females',
                        style: const TextStyle(
                          color: _kOrange,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'Femmes',
                        style: TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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

  Widget _buildCoaches() {
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
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _coaches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final coach = _coaches[i];
                final name = coach['fullName'] ?? 'N/A';
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
                          color: _kBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: _kBlue,
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
                              coach['email'] ?? '',
                              style: const TextStyle(
                                color: _kTextSub,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              "${coach['experience']} ans d'expérience",
                              style: const TextStyle(
                                color: _kBlue,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kRedL,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: _kRed,
                            size: 16,
                          ),
                          onPressed: () => _confirmDeleteCoach(coach),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

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
                final name = member['fullName'] ?? 'N/A';
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
                          color: _kGreen.withValues(alpha: 0.12),
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _kRedL,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: _kRed,
                            size: 16,
                          ),
                          onPressed: () => _confirmDeleteMember(member),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPendingPayments() {
    if (_pendingPayments.isEmpty)
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
              border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _kOrange.withValues(alpha: 0.15),
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
                            'Depuis: ${sub['startDate']}',
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
                            border: Border.all(
                              color: _kRed.withValues(alpha: 0.35),
                            ),
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

// ─────────────────────────────────────────────
// WIDGETS UTILITAIRES
// ─────────────────────────────────────────────

class _TextFieldWithLabel extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool isNumber;

  const _TextFieldWithLabel(
    this.controller,
    this.label,
    this.icon, {
    this.isPassword = false,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: isPassword,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: _kText, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextSub, fontSize: 12),
      prefixIcon: Icon(icon, color: _kGreen, size: 18),
      filled: true,
      fillColor: _kSurf2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kGreen, width: 1.5),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
    ),
  );
}
