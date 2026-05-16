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

  @override
  void dispose() {
    super.dispose();
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

  // FIX 2.1 : utilise DELETE /payments/cash/reject/{subId} qui fait la cascade complète
  // (plus besoin d'appeler AdminService.deleteMember séparément)
  Future<void> _rejectCashPayment(int subId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _LightDialog(
        title: 'Rejeter la demande',
        message: 'Confirmer le rejet de $name ?\nLe compte sera supprimé.',
        confirmLabel: 'Rejeter',
        confirmColor: _kRed,
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
                _LightField(nameCtrl, 'Nom complet', Icons.person_rounded),
                const SizedBox(height: 10),
                _LightField(
                  usernameCtrl,
                  'Username',
                  Icons.account_circle_rounded,
                ),
                const SizedBox(height: 10),
                _LightField(emailCtrl, 'Email', Icons.email_rounded),
                const SizedBox(height: 10),
                _LightField(phoneCtrl, 'Téléphone', Icons.phone_rounded),
                const SizedBox(height: 10),
                _LightField(
                  passwordCtrl,
                  'Mot de passe',
                  Icons.lock_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                _LightField(
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
            _GreenBtn(
              label: 'Ajouter',
              isLoading: loading,
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
      builder: (ctx) => _LightDialog(
        title: 'Supprimer le coach',
        message: 'Confirmer la suppression de ${coach['fullName']} ?',
        confirmLabel: 'Supprimer',
        confirmColor: _kRed,
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
      builder: (ctx) => _LightDialog(
        title: 'Supprimer le membre',
        message: 'Confirmer la suppression de ${member['fullName']} ?',
        confirmLabel: 'Supprimer',
        confirmColor: _kRed,
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
    _AdminSection.payments => 'Paiements en attente',
    _AdminSection.messages => 'Messagerie',
    _AdminSection.exercises => 'Exercices',
    _AdminSection.subscriptions => 'Abonnements',
    _AdminSection.plans => "Plans d'abonnement",
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
      body: SafeArea(
        child: Column(
          children: [
            _AdminTopBar(
              title: _sectionLabel(_current),
              pendingCount: pendingCount,
              onRefresh: _loadData,
              onLogout: _logout,
            ),
            Expanded(
              child: Row(
                children: [
                  _SideDrawer(
                    current: _current,
                    pendingCount: pendingCount,
                    unreadCount: unreadCount,
                    onSelect: (s) => setState(() => _current = s),
                    onAddCoach: _current == _AdminSection.coaches
                        ? _showCreateCoachDialog
                        : null,
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: _kGreen),
                          )
                        : _buildSection(),
                  ),
                ],
              ),
            ),
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
          _HeroCard(
            value: '$total',
            label: 'Membres actifs',
            color: _kGreen,
            bg: _kGreenL,
            icon: Icons.people_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$coaches',
                  label: 'Coachs',
                  color: _kBlue,
                  bg: _kBlueL,
                  icon: Icons.sports_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: '${_pendingPayments.length}',
                  label: 'En attente',
                  color: _kOrange,
                  bg: _kOrangeL,
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$males',
                  label: 'Hommes',
                  color: _kBlue,
                  bg: _kBlueL,
                  icon: Icons.male_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: '$females',
                  label: 'Femmes',
                  color: _kOrange,
                  bg: _kOrangeL,
                  icon: Icons.female_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GlassSection(
            title: 'RÉPARTITION MEMBRES',
            child: Column(
              children: [
                _GenderBar(
                  label: 'Hommes',
                  count: males,
                  total: total,
                  color: _kBlue,
                ),
                const SizedBox(height: 10),
                _GenderBar(
                  label: 'Femmes',
                  count: females,
                  total: total,
                  color: _kOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoaches() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kGreen,
      child: _coaches.isEmpty
          ? _EmptyState(icon: Icons.sports_rounded, label: 'Aucun coach')
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _coaches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _CoachCard(
                coach: _coaches[i],
                onDelete: () => _confirmDeleteCoach(_coaches[i]),
              ),
            ),
    );
  }

  Widget _buildMembers() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kGreen,
      child: _members.isEmpty
          ? _EmptyState(icon: Icons.people_rounded, label: 'Aucun membre')
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _MemberCard(
                member: _members[i],
                onDelete: () => _confirmDeleteMember(_members[i]),
              ),
            ),
    );
  }

  Widget _buildPendingPayments() {
    if (_pendingPayments.isEmpty)
      return _EmptyState(
        icon: Icons.check_circle_rounded,
        label: 'Aucun paiement en attente',
        color: _kGreen,
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
          return _PendingCard(
            memberName: name,
            subType: sub['type'] ?? '',
            price: sub['price']?.toString() ?? '',
            startDate: sub['startDate'] ?? '',
            onConfirm: () => _confirmCashPayment(subId),
            // FIX 2.1 : plus de memberId nécessaire — le reject gère la cascade
            onReject: () => _rejectCashPayment(subId, name),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────
class _AdminTopBar extends StatelessWidget {
  final String title;
  final int pendingCount;
  final VoidCallback onRefresh, onLogout;

  const _AdminTopBar({
    required this.title,
    required this.pendingCount,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: _kGreen,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin',
                  style: TextStyle(color: _kTextSub, fontSize: 11),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          if (pendingCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _kOrangeL,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kOrange.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded, size: 11, color: _kOrange),
                  const SizedBox(width: 4),
                  Text(
                    '$pendingCount',
                    style: const TextStyle(
                      color: _kOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub, size: 20),
            onPressed: onRefresh,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _kTextSub, size: 18),
            onPressed: onLogout,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SIDE DRAWER
// ─────────────────────────────────────────────
class _SideDrawer extends StatelessWidget {
  final _AdminSection current;
  final int pendingCount, unreadCount;
  final ValueChanged<_AdminSection> onSelect;
  final VoidCallback? onAddCoach;

  const _SideDrawer({
    required this.current,
    required this.pendingCount,
    required this.unreadCount,
    required this.onSelect,
    this.onAddCoach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(right: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _DrawerItem(
            icon: Icons.dashboard_rounded,
            label: 'Stats',
            active: current == _AdminSection.stats,
            onTap: () => onSelect(_AdminSection.stats),
          ),
          _DrawerItem(
            icon: Icons.sports_rounded,
            label: 'Coachs',
            active: current == _AdminSection.coaches,
            onTap: () => onSelect(_AdminSection.coaches),
          ),
          _DrawerItem(
            icon: Icons.people_rounded,
            label: 'Membres',
            active: current == _AdminSection.members,
            onTap: () => onSelect(_AdminSection.members),
          ),
          _DrawerDivider(),
          _DrawerItem(
            icon: Icons.payments_rounded,
            label: 'Paiem.',
            active: current == _AdminSection.payments,
            badge: pendingCount,
            badgeColor: _kOrange,
            onTap: () => onSelect(_AdminSection.payments),
          ),
          _DrawerItem(
            icon: Icons.forum_rounded,
            label: 'Msgs',
            active: current == _AdminSection.messages,
            badge: unreadCount,
            badgeColor: _kRed,
            onTap: () => onSelect(_AdminSection.messages),
          ),
          _DrawerDivider(),
          _DrawerItem(
            icon: Icons.fitness_center_rounded,
            label: 'Exos',
            active: current == _AdminSection.exercises,
            onTap: () => onSelect(_AdminSection.exercises),
          ),
          _DrawerItem(
            icon: Icons.card_membership_rounded,
            label: 'Abons.',
            active: current == _AdminSection.subscriptions,
            onTap: () => onSelect(_AdminSection.subscriptions),
          ),
          _DrawerItem(
            icon: Icons.local_offer_rounded,
            label: 'Plans',
            active: current == _AdminSection.plans,
            onTap: () => onSelect(_AdminSection.plans),
          ),
          const Spacer(),
          if (onAddCoach != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: onAddCoach,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final int badge;
  final Color badgeColor;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
    this.badgeColor = _kRed,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 52,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
        decoration: BoxDecoration(
          color: active ? _kGreen.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? _kGreen.withValues(alpha: 0.30)
                : Colors.transparent,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: active ? _kGreen : _kTextSub),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: active ? _kGreen : _kTextSub,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kSurface, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 0.5,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    color: _kBorder,
  );
}

// ─────────────────────────────────────────────
// SECTION WIDGETS
// ─────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String value, label;
  final Color color, bg;
  final IconData icon;
  const _HeroCard({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.25)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
            Text(label, style: const TextStyle(color: _kTextSub, fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final Color color, bg;
  final IconData icon;
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          value,
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

class _GlassSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _GlassSection({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kTextSub,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _GenderBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _GenderBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
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
}

class _CoachCard extends StatelessWidget {
  final Map<String, dynamic> coach;
  final VoidCallback onDelete;
  const _CoachCard({required this.coach, required this.onDelete});
  @override
  Widget build(BuildContext context) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _kBlue.withValues(alpha: 0.25)),
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
                  style: const TextStyle(color: _kTextSub, fontSize: 11),
                ),
                Text(
                  "${coach['experience']} ans d'expérience",
                  style: const TextStyle(color: _kBlue, fontSize: 11),
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
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onDelete;
  const _MemberCard({required this.member, required this.onDelete});
  @override
  Widget build(BuildContext context) {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
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
                  style: const TextStyle(color: _kTextSub, fontSize: 11),
                ),
                if (member['registrationDate'] != null)
                  Text(
                    'Depuis ${member['registrationDate']}',
                    style: const TextStyle(color: _kTextSub, fontSize: 10),
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
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final String memberName, subType, price, startDate;
  final VoidCallback onConfirm, onReject;
  const _PendingCard({
    required this.memberName,
    required this.subType,
    required this.price,
    required this.startDate,
    required this.onConfirm,
    required this.onReject,
  });
  @override
  Widget build(BuildContext context) => Container(
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
                child: Icon(Icons.payments_rounded, color: _kOrange, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberName,
                    style: const TextStyle(
                      color: _kText,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$subType • $price DT • espèces',
                    style: const TextStyle(color: _kOrange, fontSize: 11),
                  ),
                  Text(
                    'Depuis: $startDate',
                    style: const TextStyle(color: _kTextSub, fontSize: 10),
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
                onTap: onConfirm,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 16),
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
                onTap: onReject,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kRedL,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kRed.withValues(alpha: 0.35)),
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
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _EmptyState({
    required this.icon,
    required this.label,
    this.color = _kTextSub,
  });
  @override
  Widget build(BuildContext context) => Center(
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
          child: Icon(icon, size: 30, color: color.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: _kTextSub, fontSize: 14)),
      ],
    ),
  );
}

// ─── DIALOG & FIELD HELPERS ───
class _LightDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final Color confirmColor;
  const _LightDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _kSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: Text(
      title,
      style: const TextStyle(color: _kText, fontWeight: FontWeight.w800),
    ),
    content: Text(
      message,
      style: const TextStyle(color: _kTextSub, fontSize: 13),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(
          confirmLabel,
          style: TextStyle(color: confirmColor, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _LightField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword, isNumber;
  const _LightField(
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

class _GreenBtn extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _GreenBtn({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: _kGreen,
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
