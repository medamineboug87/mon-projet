import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

// ─── Design tokens light ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00C853);
const Color _kGreenL = Color(0xFFE0F2F1);
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

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<dynamic> _subscriptions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _filterStatus = 'ALL';
  String _filterType = 'ALL';
  String _searchQuery = '';

  final List<String> _statuses = [
    'ALL',
    'ACTIVE',
    'PENDING',
    'SUSPENDED',
    'CANCELLED',
  ];
  final List<String> _types = ['ALL', 'BASIC', 'STANDARD', 'PREMIUM', 'ANNUAL'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // DATA
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
    await Future.wait([_loadSubscriptions(), _loadStats()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSubscriptions() async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions'),
        headers: await _headers(),
      );
      if (r.statusCode == 200 && mounted) {
        setState(() => _subscriptions = jsonDecode(r.body));
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/stats'),
        headers: await _headers(),
      );
      if (r.statusCode == 200 && mounted) {
        setState(() => _stats = jsonDecode(r.body));
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // FILTERED LIST
  // ─────────────────────────────────────────────

  List<dynamic> get _filtered {
    return _subscriptions.where((s) {
      final statusOk = _filterStatus == 'ALL' || s['status'] == _filterStatus;
      final typeOk = _filterType == 'ALL' || s['type'] == _filterType;
      final memberName =
          s['member']?['fullName']?.toString().toLowerCase() ?? '';
      final searchOk =
          _searchQuery.isEmpty ||
          memberName.contains(_searchQuery.toLowerCase()) ||
          (s['type']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
      return statusOk && typeOk && searchOk;
    }).toList();
  }

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────

  Future<void> _activate(int id) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/$id/activate'),
      headers: await _headers(),
    );
    _handleResponse(r, 'Abonnement activé !');
  }

  Future<void> _suspend(int id) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/$id/suspend'),
      headers: await _headers(),
    );
    _handleResponse(r, 'Abonnement suspendu');
  }

  Future<void> _cancel(int id) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/$id/cancel'),
      headers: await _headers(),
    );
    _handleResponse(r, 'Abonnement annulé');
  }

  Future<void> _renew(int id) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/$id/renew'),
      headers: await _headers(),
    );
    _handleResponse(r, 'Abonnement renouvelé !');
  }

  Future<void> _resetPrice(int id) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/$id/reset-price'),
      headers: await _headers(),
    );
    _handleResponse(r, 'Prix remis au tarif standard');
  }

  Future<void> _delete(int id) async {
    final ok = await _confirmDialog(
      'Supprimer cet abonnement ?',
      'Cette action est irréversible.',
    );
    if (!ok) return;
    final r = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/subscriptions/$id'),
      headers: await _headers(),
    );
    _handleResponse(r, 'Abonnement supprimé');
  }

  void _handleResponse(http.Response r, String successMsg) {
    if (r.statusCode == 200) {
      _snack(successMsg, _kGreen);
      _loadAll();
    } else {
      try {
        final err = jsonDecode(r.body)['error'] ?? 'Erreur';
        _snack(err, _kRed);
      } catch (_) {
        _snack('Erreur serveur', _kRed);
      }
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DIALOGS (inchangés, déjà OK)
  // ─────────────────────────────────────────────

  void _showDiscountDialog(Map<String, dynamic> sub) {
    final valueCtrl = TextEditingController();
    String discountType = 'PERCENTAGE';
    bool loading = false;
    final double currentPrice = (sub['price'] as num).toDouble();
    final standardPrice = _standardPrice(sub['type']);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final value = double.tryParse(valueCtrl.text) ?? 0;
          final preview = discountType == 'PERCENTAGE'
              ? currentPrice * (1 - value / 100)
              : currentPrice - value;

          return AlertDialog(
            backgroundColor: _kSurf2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.local_offer_rounded, color: _kOrange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Appliquer une réduction',
                  style: TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    'Prix actuel',
                    '${currentPrice.toStringAsFixed(0)} DT',
                    _kOrange,
                  ),
                  _InfoRow(
                    'Tarif standard',
                    '${standardPrice.toStringAsFixed(0)} DT',
                    _kTextSub,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Type de réduction',
                    style: TextStyle(color: _kTextSub, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeChip(
                          label: '% Pourcentage',
                          active: discountType == 'PERCENTAGE',
                          color: _kOrange,
                          onTap: () => setD(() => discountType = 'PERCENTAGE'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TypeChip(
                          label: '⊟ Montant fixe',
                          active: discountType == 'FIXED',
                          color: _kBlue,
                          onTap: () => setD(() => discountType = 'FIXED'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: valueCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    onChanged: (_) => setD(() {}),
                    decoration: InputDecoration(
                      labelText: discountType == 'PERCENTAGE'
                          ? 'Pourcentage (%)'
                          : 'Montant (DT)',
                      labelStyle: const TextStyle(
                        color: _kTextSub,
                        fontSize: 13,
                      ),
                      suffixText: discountType == 'PERCENTAGE' ? '%' : 'DT',
                      suffixStyle: const TextStyle(
                        color: _kOrange,
                        fontWeight: FontWeight.w800,
                      ),
                      filled: true,
                      fillColor: _kBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _kOrange,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (value > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward,
                            color: _kGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nouveau prix : ${preview.clamp(0, double.infinity).toStringAsFixed(0)} DT',
                            style: const TextStyle(
                              color: _kGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: _kTextSub),
                ),
              ),
              _ActionButton(
                label: 'Appliquer',
                color: _kOrange,
                isLoading: loading,
                onTap: () async {
                  if (valueCtrl.text.trim().isEmpty) return;
                  setD(() => loading = true);
                  final r = await http.post(
                    Uri.parse(
                      '${ApiConfig.baseUrl}/admin/subscriptions/${sub['id']}/discount',
                    ),
                    headers: await _headers(),
                    body: jsonEncode({
                      'discountType': discountType,
                      'discountValue': double.parse(valueCtrl.text),
                    }),
                  );
                  setD(() => loading = false);
                  Navigator.pop(ctx);
                  _handleResponse(r, 'Réduction appliquée !');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExtendDialog(Map<String, dynamic> sub) {
    int months = 1;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: _kSurf2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: _kBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Prolonger l\'abonnement',
                style: TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nombre de mois à ajouter',
                style: TextStyle(color: _kTextSub, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleBtn(
                    icon: Icons.remove,
                    onTap: () => setD(() => months = (months - 1).clamp(1, 24)),
                    color: _kRed,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          '$months',
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'mois',
                          style: TextStyle(color: _kTextSub, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _CircleBtn(
                    icon: Icons.add,
                    onTap: () => setD(() => months = (months + 1).clamp(1, 24)),
                    color: _kGreen,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (sub['endDate'] != null)
                Text(
                  'Nouvelle fin : ${_addMonths(sub['endDate'], months)}',
                  style: const TextStyle(color: _kBlue, fontSize: 13),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
            ),
            _ActionButton(
              label: 'Prolonger',
              color: _kBlue,
              isLoading: loading,
              onTap: () async {
                setD(() => loading = true);
                final r = await http.post(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/admin/subscriptions/${sub['id']}/extend',
                  ),
                  headers: await _headers(),
                  body: jsonEncode({'months': months}),
                );
                setD(() => loading = false);
                Navigator.pop(ctx);
                _handleResponse(r, 'Prolongé de $months mois !');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> sub) {
    String selectedType = sub['type'] ?? 'BASIC';
    String selectedStatus = sub['status'] ?? 'ACTIVE';
    final startCtrl = TextEditingController(
      text:
          sub['startDate']?.toString().substring(0, 10) ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
    final endCtrl = TextEditingController(
      text: sub['endDate']?.toString().substring(0, 10) ?? '',
    );
    final priceCtrl = TextEditingController(
      text: sub['price']?.toString() ?? '',
    );
    bool autoRenew = sub['autoRenew'] ?? true;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: _kSurf2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Modifier l\'abonnement',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Type d\'abonnement'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['BASIC', 'STANDARD', 'PREMIUM', 'ANNUAL']
                        .map(
                          (t) => _TypeChip(
                            label: t,
                            active: selectedType == t,
                            color: _planColor(t),
                            onTap: () => setD(() => selectedType = t),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  const _SectionLabel('Statut'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['ACTIVE', 'PENDING', 'SUSPENDED', 'CANCELLED']
                        .map(
                          (s) => _TypeChip(
                            label: s,
                            active: selectedStatus == s,
                            color: _statusColor(s),
                            onTap: () => setD(() => selectedStatus = s),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  const _SectionLabel('Prix personnalisé (DT)'),
                  const SizedBox(height: 6),
                  _DialogField(
                    priceCtrl,
                    'Prix',
                    Icons.attach_money_rounded,
                    isNumber: true,
                  ),
                  const SizedBox(height: 10),
                  _DialogField(
                    startCtrl,
                    'Date de début (YYYY-MM-DD)',
                    Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 10),
                  _DialogField(
                    endCtrl,
                    'Date de fin (YYYY-MM-DD)',
                    Icons.event_rounded,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Renouvellement auto',
                          style: TextStyle(color: _kText, fontSize: 13),
                        ),
                      ),
                      Switch(
                        value: autoRenew,
                        onChanged: (v) => setD(() => autoRenew = v),
                        activeColor: _kGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
            ),
            _ActionButton(
              label: 'Sauvegarder',
              color: _kGreen,
              isLoading: loading,
              onTap: () async {
                setD(() => loading = true);
                final body = <String, dynamic>{
                  'type': selectedType,
                  'status': selectedStatus,
                  'autoRenew': autoRenew,
                };
                if (priceCtrl.text.isNotEmpty)
                  body['price'] = double.parse(priceCtrl.text);
                if (startCtrl.text.isNotEmpty)
                  body['startDate'] = startCtrl.text;
                if (endCtrl.text.isNotEmpty) body['endDate'] = endCtrl.text;

                final r = await http.put(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/admin/subscriptions/${sub['id']}',
                  ),
                  headers: await _headers(),
                  body: jsonEncode(body),
                );
                setD(() => loading = false);
                Navigator.pop(ctx);
                _handleResponse(r, 'Abonnement modifié !');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    _showMemberPickerThenCreate();
  }

  void _showMemberPickerThenCreate() async {
    try {
      final token = await AuthService.getToken();
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (r.statusCode != 200) {
        _snack('Impossible de charger les membres', _kRed);
        return;
      }
      final members = jsonDecode(r.body) as List;
      if (!mounted) return;

      int? selectedMemberId;
      String searchMember = '';

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setD) {
            final filtered = members
                .where(
                  (m) =>
                      searchMember.isEmpty ||
                      (m['fullName'] as String).toLowerCase().contains(
                        searchMember.toLowerCase(),
                      ),
                )
                .toList();

            return AlertDialog(
              backgroundColor: _kSurf2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Choisir un membre',
                style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (v) => setD(() => searchMember = v),
                      style: const TextStyle(color: _kText),
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        hintStyle: const TextStyle(color: _kTextSub),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: _kTextSub,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: _kBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final m = filtered[i];
                          final isSelected = selectedMemberId == m['id'];
                          return GestureDetector(
                            onTap: () => setD(() => selectedMemberId = m['id']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _kGreen.withOpacity(0.12)
                                    : _kBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? _kGreen.withOpacity(0.4)
                                      : _kBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: _kGreen.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        (m['fullName'] as String)
                                            .split(' ')
                                            .take(2)
                                            .map(
                                              (w) => w.isNotEmpty
                                                  ? w[0].toUpperCase()
                                                  : '',
                                            )
                                            .join(),
                                        style: const TextStyle(
                                          color: _kGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m['fullName'],
                                      style: const TextStyle(
                                        color: _kText,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: _kGreen,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: _kTextSub),
                  ),
                ),
                _ActionButton(
                  label: 'Continuer',
                  color: _kGreen,
                  onTap: () {
                    if (selectedMemberId == null) {
                      _snack('Sélectionnez un membre', _kOrange);
                      return;
                    }
                    Navigator.pop(ctx);
                    _showCreateSubDialog(selectedMemberId!);
                  },
                ),
              ],
            );
          },
        ),
      );
    } catch (_) {
      _snack('Erreur réseau', _kRed);
    }
  }

  void _showCreateSubDialog(int memberId) {
    String selectedType = 'BASIC';
    String selectedStatus = 'ACTIVE';
    bool autoRenew = true;
    bool loading = false;
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final standardP = _standardPrice(selectedType);
          return AlertDialog(
            backgroundColor: _kSurf2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.add_circle_rounded, color: _kGreen, size: 20),
                SizedBox(width: 8),
                Text(
                  'Créer un abonnement',
                  style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SectionLabel('Type'),
                  const SizedBox(height: 8),
                  ...['BASIC', 'STANDARD', 'PREMIUM', 'ANNUAL'].map((t) {
                    final isSelected = selectedType == t;
                    final p = _standardPrice(t);
                    return GestureDetector(
                      onTap: () {
                        setD(() {
                          selectedType = t;
                          priceCtrl.clear();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _planColor(t).withOpacity(0.12)
                              : _kBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _planColor(t).withOpacity(0.4)
                                : _kBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              t,
                              style: TextStyle(
                                color: isSelected ? _planColor(t) : _kTextSub,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$p DT',
                              style: TextStyle(
                                color: isSelected ? _planColor(t) : _kTextSub,
                                fontSize: 12,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: _planColor(t),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  const _SectionLabel('Prix personnalisé (optionnel)'),
                  const SizedBox(height: 6),
                  _DialogField(
                    priceCtrl,
                    'Laisser vide pour le prix standard (${standardP.toStringAsFixed(0)} DT)',
                    Icons.attach_money_rounded,
                    isNumber: true,
                  ),
                  const SizedBox(height: 12),
                  const _SectionLabel('Statut initial'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: ['ACTIVE', 'PENDING']
                        .map(
                          (s) => _TypeChip(
                            label: s,
                            active: selectedStatus == s,
                            color: _statusColor(s),
                            onTap: () => setD(() => selectedStatus = s),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Renouvellement auto',
                          style: TextStyle(color: _kText, fontSize: 13),
                        ),
                      ),
                      Switch(
                        value: autoRenew,
                        onChanged: (v) => setD(() => autoRenew = v),
                        activeColor: _kGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: _kTextSub),
                ),
              ),
              _ActionButton(
                label: 'Créer',
                color: _kGreen,
                isLoading: loading,
                onTap: () async {
                  setD(() => loading = true);
                  final body = <String, dynamic>{
                    'type': selectedType,
                    'status': selectedStatus,
                    'autoRenew': autoRenew,
                  };
                  if (priceCtrl.text.isNotEmpty) {
                    body['customPrice'] = double.parse(priceCtrl.text);
                  }
                  final r = await http.post(
                    Uri.parse(
                      '${ApiConfig.baseUrl}/admin/subscriptions/member/$memberId',
                    ),
                    headers: await _headers(),
                    body: jsonEncode(body),
                  );
                  setD(() => loading = false);
                  Navigator.pop(ctx);
                  _handleResponse(r, 'Abonnement créé !');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBulkDiscountDialog() {
    String discountType = 'PERCENTAGE';
    String targetType = 'ALL';
    final valueCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: _kSurf2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: _kPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Réduction en masse',
                style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Applique une réduction à TOUS les abonnements ACTIFS du type sélectionné.',
                style: TextStyle(color: _kTextSub, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Type ciblé'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['ALL', 'BASIC', 'STANDARD', 'PREMIUM', 'ANNUAL']
                    .map(
                      (t) => _TypeChip(
                        label: t == 'ALL' ? 'Tous' : t,
                        active: targetType == t,
                        color: t == 'ALL' ? _kPurple : _planColor(t),
                        onTap: () => setD(() => targetType = t),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Type de réduction'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: '% Pourcentage',
                      active: discountType == 'PERCENTAGE',
                      color: _kOrange,
                      onTap: () => setD(() => discountType = 'PERCENTAGE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeChip(
                      label: '⊟ Fixe (DT)',
                      active: discountType == 'FIXED',
                      color: _kBlue,
                      onTap: () => setD(() => discountType = 'FIXED'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DialogField(
                valueCtrl,
                discountType == 'PERCENTAGE' ? 'Valeur (%)' : 'Valeur (DT)',
                Icons.discount_rounded,
                isNumber: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
            ),
            _ActionButton(
              label: 'Appliquer à tous',
              color: _kPurple,
              isLoading: loading,
              onTap: () async {
                if (valueCtrl.text.isEmpty) return;
                setD(() => loading = true);
                final body = <String, dynamic>{
                  'discountType': discountType,
                  'discountValue': double.parse(valueCtrl.text),
                };
                if (targetType != 'ALL') body['type'] = targetType;
                final r = await http.post(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/admin/subscriptions/bulk-discount',
                  ),
                  headers: await _headers(),
                  body: jsonEncode(body),
                );
                setD(() => loading = false);
                Navigator.pop(ctx);
                _handleResponse(r, 'Réduction en masse appliquée !');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeTypeDialog(Map<String, dynamic> sub) async {
    String newType = sub['type'] ?? 'BASIC';
    bool keepPrice = false;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: _kSurf2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Changer le type',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Nouveau type'),
              const SizedBox(height: 10),
              ...['BASIC', 'STANDARD', 'PREMIUM', 'ANNUAL'].map((t) {
                final isSelected = newType == t;
                return GestureDetector(
                  onTap: () => setD(() => newType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _planColor(t).withOpacity(0.12)
                          : _kBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _planColor(t).withOpacity(0.4)
                            : _kBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t,
                          style: TextStyle(
                            color: isSelected ? _planColor(t) : _kTextSub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_standardPrice(t).toStringAsFixed(0)} DT',
                          style: TextStyle(
                            color: isSelected ? _planColor(t) : _kTextSub,
                            fontSize: 12,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            color: _planColor(t),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Row(
                children: [
                  Checkbox(
                    value: keepPrice,
                    onChanged: (v) => setD(() => keepPrice = v ?? false),
                    activeColor: _kOrange,
                  ),
                  const Text(
                    'Garder le prix actuel',
                    style: TextStyle(color: _kText, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
            ),
            _ActionButton(
              label: 'Changer',
              color: _planColor(newType),
              isLoading: loading,
              onTap: () async {
                setD(() => loading = true);
                final r = await http.post(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/admin/subscriptions/${sub['id']}/change-type',
                  ),
                  headers: await _headers(),
                  body: jsonEncode({'type': newType, 'keepPrice': keepPrice}),
                );
                setD(() => loading = false);
                Navigator.pop(ctx);
                _handleResponse(r, 'Type changé vers $newType !');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _kSurf2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              msg,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: _kTextSub),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Confirmer',
                  style: TextStyle(color: _kRed, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text(
          'Gestion Abonnements',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showBulkDiscountDialog,
            icon: const Icon(Icons.discount_rounded, size: 16, color: _kPurple),
            label: const Text(
              'En masse',
              style: TextStyle(
                color: _kPurple,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub, size: 20),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _kGreen,
          indicatorWeight: 2,
          labelColor: _kGreen,
          unselectedLabelColor: _kTextSub,
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded, size: 18), text: 'Abonnements'),
            Tab(
              icon: Icon(Icons.analytics_rounded, size: 18),
              text: 'Statistiques',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : TabBarView(
              controller: _tabCtrl,
              children: [_buildListTab(), _buildStatsTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: _kGreen,
        icon: const Icon(Icons.add_rounded, color: _kText),
        label: const Text(
          'Nouvel abonnement',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIST TAB
  // ─────────────────────────────────────────────

  Widget _buildListTab() {
    final filtered = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: _kText),
            decoration: InputDecoration(
              hintText: 'Rechercher par membre ou type...',
              hintStyle: const TextStyle(color: _kTextSub, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _kTextSub,
                size: 18,
              ),
              filled: true,
              fillColor: _kSurface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Status filter (horizontal scroll reste OK pour mobile)
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _statuses.length,
            itemBuilder: (_, i) {
              final s = _statuses[i];
              final active = _filterStatus == s;
              return GestureDetector(
                onTap: () => setState(() => _filterStatus = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? _statusColor(s).withOpacity(0.12)
                        : _kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? _statusColor(s).withOpacity(0.4)
                          : _kBorder,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      color: active ? _statusColor(s) : _kTextSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Type filter
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _types.length,
            itemBuilder: (_, i) {
              final t = _types[i];
              final active = _filterType == t;
              final color = t == 'ALL' ? _kText : _planColor(t);
              return GestureDetector(
                onTap: () => setState(() => _filterType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? color.withOpacity(0.12) : _kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? color.withOpacity(0.4) : _kBorder,
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: active ? color : _kTextSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} abonnement${filtered.length > 1 ? 's' : ''}',
                style: const TextStyle(color: _kTextSub, fontSize: 12),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun abonnement',
                    style: TextStyle(color: _kBorder),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: _kGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildSubCard(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubCard(Map<String, dynamic> sub) {
    final status = sub['status'] ?? 'UNKNOWN';
    final type = sub['type'] ?? 'N/A';
    final memberName =
        sub['member']?['fullName'] ?? 'Membre #${sub['member']?['id'] ?? '?'}';
    final memberId = (sub['member']?['id'] as num?)?.toInt() ?? 0;
    final double price = (sub['price'] as num?)?.toDouble() ?? 0;
    final double standardPrice = _standardPrice(type);
    final bool hasDiscount = price < standardPrice - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _planColor(type).withOpacity(0.18)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _planColor(type).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _planColor(type).withOpacity(0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.card_membership_rounded,
                    color: _planColor(type),
                    size: 22,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _StatusBadge(status: status),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _planColor(type).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: _planColor(type),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${price.toStringAsFixed(0)} DT',
                      style: TextStyle(
                        color: hasDiscount ? _kOrange : _kText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        '${standardPrice.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          color: _kBorder,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Dates
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: _kBorder,
                ),
                const SizedBox(width: 5),
                Text(
                  '${_fmtDate(sub['startDate'])} → ${_fmtDate(sub['endDate'])}',
                  style: const TextStyle(color: _kTextSub, fontSize: 11),
                ),
                const Spacer(),
                if (sub['autoRenew'] == true)
                  const Row(
                    children: [
                      Icon(Icons.autorenew_rounded, size: 11, color: _kGreen),
                      SizedBox(width: 3),
                      Text(
                        'Auto',
                        style: TextStyle(color: _kGreen, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // ✅ CORRECTION : Action buttons avec Wrap (mobile-first)
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kBorder)),
            ),
            child: _buildActionRow(
              sub,
              status,
              type,
              memberId,
              price,
              standardPrice,
              hasDiscount,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTION MOBILE-FIRST : Remplacement de SingleChildScrollView horizontal par Wrap
  Widget _buildActionRow(
    Map<String, dynamic> sub,
    String status,
    String type,
    int memberId,
    double price,
    double standardPrice,
    bool hasDiscount,
  ) {
    final id = (sub['id'] as num).toInt();

    // Construction dynamique de la liste des actions
    final List<MapEntry<String, VoidCallback>> actions = [];

    actions.add(MapEntry('Réduction', () => _showDiscountDialog(sub)));
    if (hasDiscount) {
      actions.add(MapEntry('Tarif normal', () => _resetPrice(id)));
    }
    if (status == 'ACTIVE') {
      actions.add(MapEntry('Prolonger', () => _showExtendDialog(sub)));
    }
    actions.add(MapEntry('Changer type', () => _showChangeTypeDialog(sub)));
    actions.add(MapEntry('Modifier', () => _showEditDialog(sub)));
    if (status == 'PENDING' || status == 'SUSPENDED') {
      actions.add(MapEntry('Activer', () => _activate(id)));
    }
    if (status == 'ACTIVE') {
      actions.add(MapEntry('Suspendre', () => _suspend(id)));
    }
    if (status == 'ACTIVE') {
      actions.add(MapEntry('Renouveler', () => _renew(id)));
    }
    if (status != 'CANCELLED') {
      actions.add(MapEntry('Annuler', () => _cancel(id)));
    }
    actions.add(MapEntry('Supprimer', () => _delete(id)));

    // ✅ WRAP : remplacement du scroll horizontal
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: actions.map((entry) {
          Color getColor(String action) {
            switch (action) {
              case 'Réduction':
                return _kOrange;
              case 'Tarif normal':
                return _kTextSub;
              case 'Prolonger':
                return _kBlue;
              case 'Changer type':
                return _kPurple;
              case 'Modifier':
                return _kTextSub;
              case 'Activer':
                return _kGreen;
              case 'Suspendre':
                return _kOrange;
              case 'Renouveler':
                return _kGreen;
              case 'Annuler':
                return Colors.white30;
              default:
                return _kRed;
            }
          }

          IconData getIcon(String action) {
            switch (action) {
              case 'Réduction':
                return Icons.local_offer_rounded;
              case 'Tarif normal':
                return Icons.price_change_rounded;
              case 'Prolonger':
                return Icons.calendar_today_rounded;
              case 'Changer type':
                return Icons.swap_horiz_rounded;
              case 'Modifier':
                return Icons.edit_rounded;
              case 'Activer':
                return Icons.play_circle_rounded;
              case 'Suspendre':
                return Icons.pause_circle_rounded;
              case 'Renouveler':
                return Icons.autorenew_rounded;
              case 'Annuler':
                return Icons.cancel_rounded;
              default:
                return Icons.delete_rounded;
            }
          }

          return _QuickBtnFixed(
            icon: getIcon(entry.key),
            label: entry.key,
            color: getColor(entry.key),
            onTap: entry.value,
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STATS TAB
  // ─────────────────────────────────────────────

  Widget _buildStatsTab() {
    final total = _stats['total'] ?? 0;
    final active = _stats['active'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final suspended = _stats['suspended'] ?? 0;
    final cancelled = _stats['cancelled'] ?? 0;
    final revenue = (_stats['totalRevenue'] as num?)?.toDouble() ?? 0;
    final basic = _stats['basicCount'] ?? 0;
    final standard = _stats['standardCount'] ?? 0;
    final premium = _stats['premiumCount'] ?? 0;
    final annual = _stats['annualCount'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _kGreen,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kGreen, _kGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money_rounded, color: _kText, size: 32),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenus abonnements actifs',
                      style: TextStyle(color: _kText, fontSize: 12),
                    ),
                    Text(
                      '${revenue.toStringAsFixed(0)} DT',
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatsSection(
            title: 'Répartition par statut',
            child: Column(
              children: [
                _StatBar('Actifs', active, total, _kGreen),
                const SizedBox(height: 8),
                _StatBar('En attente', pending, total, _kOrange),
                const SizedBox(height: 8),
                _StatBar('Suspendus', suspended, total, _kBlue),
                const SizedBox(height: 8),
                _StatBar('Annulés', cancelled, total, _kRed),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StatsSection(
            title: 'Répartition par type',
            child: Column(
              children: [
                _StatBar('BASIC', basic, total, _planColor('BASIC')),
                const SizedBox(height: 8),
                _StatBar('STANDARD', standard, total, _planColor('STANDARD')),
                const SizedBox(height: 8),
                _StatBar('PREMIUM', premium, total, _planColor('PREMIUM')),
                const SizedBox(height: 8),
                _StatBar('ANNUAL', annual, total, _planColor('ANNUAL')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StatsSection(
            title: 'Actions rapides globales',
            child: Column(
              children: [
                _GlobalActionTile(
                  icon: Icons.discount_rounded,
                  title: 'Réduction en masse',
                  subtitle: 'Appliquer une promo à tous les abonnements actifs',
                  color: _kPurple,
                  onTap: _showBulkDiscountDialog,
                ),
                const SizedBox(height: 8),
                _GlobalActionTile(
                  icon: Icons.add_card_rounded,
                  title: 'Créer un abonnement',
                  subtitle: 'Ajouter manuellement un abonnement à un membre',
                  color: _kGreen,
                  onTap: _showCreateDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  double _standardPrice(String? type) {
    return switch (type) {
      'BASIC' => 60,
      'STANDARD' => 150,
      'PREMIUM' => 300,
      'ANNUAL' => 490,
      _ => 0,
    };
  }

  Color _planColor(String? type) {
    return switch (type) {
      'BASIC' => _kBlue,
      'STANDARD' => _kPurple,
      'PREMIUM' => _kGreen,
      'ANNUAL' => _kOrange,
      _ => _kTextSub,
    };
  }

  Color _statusColor(String? status) {
    return switch (status) {
      'ACTIVE' => _kGreen,
      'PENDING' => _kOrange,
      'SUSPENDED' => _kBlue,
      'CANCELLED' => _kRed,
      _ => _kTextSub,
    };
  }

  String _fmtDate(dynamic d) {
    if (d == null) return 'N/A';
    try {
      final dt = DateTime.parse(d.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'N/A';
    }
  }

  String _addMonths(dynamic dateStr, int months) {
    try {
      final dt = DateTime.parse(dateStr.toString());
      final newDt = DateTime(dt.year, dt.month + months, dt.day);
      return '${newDt.day}/${newDt.month}/${newDt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────

// ✅ NOUVEAU WIDGET : version fixe pour Wrap (sans scroll horizontal)
class _QuickBtnFixed extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtnFixed({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
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
        ),
      ),
    );
  }
}

// Garder l'ancien _QuickBtn pour compatibilité (inchangé)
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color _color() => switch (status) {
    'ACTIVE' => _kGreen,
    'PENDING' => _kOrange,
    'SUSPENDED' => _kBlue,
    'CANCELLED' => _kRed,
    _ => _kTextSub,
  };

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : _kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withOpacity(0.4) : _kBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : _kTextSub,
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: color, strokeWidth: 2),
              )
            : Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _kTextSub,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 12)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isNumber;

  const _DialogField(this.ctrl, this.label, this.icon, {this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSub, fontSize: 12),
        prefixIcon: Icon(icon, color: _kGreen, size: 18),
        filled: true,
        fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
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

class _StatsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class _StatBar extends StatelessWidget {
  final String label;
  final dynamic count;
  final dynamic total;
  final Color color;

  const _StatBar(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final int c = (count as num).toInt();
    final int t = (total as num).toInt();
    final double pct = t > 0 ? c / t : 0;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: const TextStyle(color: _kTextSub, fontSize: 11),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: _kText.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$c',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlobalActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GlobalActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}
