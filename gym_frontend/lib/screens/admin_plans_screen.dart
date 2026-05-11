import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';

// ─── Design tokens (référence : admin_exercises_screen) ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00C853);
const Color _kGreenDark = Color(0xFF00963E);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

const _kColorPalette = [
  '#00C853',
  '#40C4FF',
  '#FF5252',
  '#FFAB40',
  '#CE93D8',
  '#F06292',
  '#4DB6AC',
  '#FFD740',
  '#90A4AE',
  '#A5D6A7',
];

const _kEmojiList = [
  '⭐',
  '🏋️',
  '🔥',
  '💪',
  '🌟',
  '🚀',
  '🎯',
  '💎',
  '🏆',
  '🍂',
  '❄️',
  '🌸',
  '☀️',
  '🎃',
  '🎄',
  '💫',
  '🥇',
  '🦁',
  '⚡',
  '🌙',
];

class AdminPlansScreen extends StatefulWidget {
  const AdminPlansScreen({super.key});

  @override
  State<AdminPlansScreen> createState() => _AdminPlansScreenState();
}

class _AdminPlansScreenState extends State<AdminPlansScreen> {
  List<dynamic> _plans = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/plans'),
        headers: await _headers(),
      );
      if (r.statusCode == 200 && mounted)
        setState(() => _plans = jsonDecode(r.body));
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered => _showInactive
      ? _plans
      : _plans.where((p) => p['active'] == true).toList();

  Future<void> _toggle(int id, bool currentActive) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/plans/$id/toggle'),
      headers: await _headers(),
    );
    if (r.statusCode == 200) {
      _snack(
        currentActive ? 'Plan désactivé' : 'Plan activé',
        currentActive ? _kOrange : _kGreen,
      );
      _loadPlans();
    } else {
      _snack('Erreur', _kRed);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Supprimer ce plan ?',
        message:
            'Le plan sera désactivé. Les abonnements existants ne sont pas affectés.',
        confirmLabel: 'Supprimer',
        confirmColor: _kRed,
      ),
    );
    if (ok != true) return;
    final r = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/plans/$id'),
      headers: await _headers(),
    );
    if (r.statusCode == 200) {
      _snack('Plan supprimé', _kOrange);
      _loadPlans();
    } else {
      _snack('Erreur', _kRed);
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

  void _showPlanDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(
      text: existing?['displayName'] ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing != null
          ? (existing['price'] as num).toStringAsFixed(0)
          : '',
    );
    final durationCtrl = TextEditingController(
      text: existing != null ? existing['duration'].toString() : '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description'] ?? '',
    );
    String selectedColor = existing?['color'] ?? _kColorPalette[0];
    String selectedEmoji = existing?['emoji'] ?? '⭐';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: _kSurf2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(selectedEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Nouveau plan' : 'Modifier le plan',
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogField(nameCtrl, 'Nom du plan', Icons.label_rounded),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogField(
                          priceCtrl,
                          'Prix (DT)',
                          Icons.attach_money_rounded,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DialogField(
                          durationCtrl,
                          'Durée (mois)',
                          Icons.calendar_month_rounded,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _DialogField(
                    descCtrl,
                    'Description (optionnel)',
                    Icons.description_rounded,
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('ICÔNE'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kEmojiList.map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () => setD(() => selectedEmoji = emoji),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _kGreen.withValues(alpha: 0.15)
                                : _kBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? _kGreen : _kBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel('COULEUR'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kColorPalette.map((hex) {
                      final color = _hexToColor(hex);
                      final isSelected = selectedColor == hex;
                      return GestureDetector(
                        onTap: () => setD(() => selectedColor = hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _kText : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('APERÇU'),
                  const SizedBox(height: 8),
                  _PlanPreview(
                    name: nameCtrl.text.isEmpty ? 'Nom du plan' : nameCtrl.text,
                    price: priceCtrl.text.isEmpty ? '0' : priceCtrl.text,
                    duration: durationCtrl.text.isEmpty
                        ? '0'
                        : durationCtrl.text,
                    emoji: selectedEmoji,
                    color: _hexToColor(selectedColor),
                    description: descCtrl.text,
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
            GestureDetector(
              onTap: loading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          priceCtrl.text.trim().isEmpty ||
                          durationCtrl.text.trim().isEmpty) {
                        _snack('Nom, prix et durée sont requis', _kRed);
                        return;
                      }
                      setD(() => loading = true);
                      final body = jsonEncode({
                        'name': nameCtrl.text.trim(),
                        'displayName': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'price': double.tryParse(priceCtrl.text) ?? 0,
                        'duration': int.tryParse(durationCtrl.text) ?? 1,
                        'color': selectedColor,
                        'emoji': selectedEmoji,
                      });
                      http.Response r;
                      if (existing == null) {
                        r = await http.post(
                          Uri.parse('${ApiConfig.baseUrl}/admin/plans'),
                          headers: await _headers(),
                          body: body,
                        );
                      } else {
                        r = await http.put(
                          Uri.parse(
                            '${ApiConfig.baseUrl}/admin/plans/${existing['id']}',
                          ),
                          headers: await _headers(),
                          body: body,
                        );
                      }
                      setD(() => loading = false);
                      if (r.statusCode == 200) {
                        Navigator.pop(ctx);
                        _snack(
                          existing == null
                              ? 'Plan créé !'
                              : 'Plan mis à jour !',
                          _kGreen,
                        );
                        _loadPlans();
                      } else {
                        try {
                          _snack(
                            jsonDecode(r.body)['error'] ?? 'Erreur',
                            _kRed,
                          );
                        } catch (_) {
                          _snack('Erreur serveur', _kRed);
                        }
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        existing == null ? 'Créer' : 'Enregistrer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: _kTextSub,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          "Plans d'abonnement",
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: () => setState(() => _showInactive = !_showInactive),
              icon: Icon(
                _showInactive
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 16,
                color: _showInactive ? _kOrange : _kTextSub,
              ),
              label: Text(
                _showInactive ? 'Masquer inactifs' : 'Tout voir',
                style: TextStyle(
                  color: _showInactive ? _kOrange : _kTextSub,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
            onPressed: _loadPlans,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanDialog(),
        backgroundColor: _kGreen,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nouveau plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _filtered.isEmpty && _plans.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadPlans,
              color: _kGreen,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: _kBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_plans.where((p) => p['active'] == true).length} plan(s) actif(s). Les plans créés sont disponibles dans l\'écran d\'abonnement.',
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Plans standard
                  _SectionHeader(
                    title: 'PLANS STANDARD',
                    subtitle: 'Intégrés dans l\'application',
                  ),
                  const SizedBox(height: 8),
                  ..._buildStandardCards(),
                  const SizedBox(height: 20),

                  // Plans custom
                  _SectionHeader(
                    title: 'PLANS PERSONNALISÉS',
                    subtitle: '${_filtered.length} plan(s) créé(s)',
                  ),
                  const SizedBox(height: 8),
                  if (_filtered.isEmpty)
                    _buildEmptyCustom()
                  else
                    ..._filtered.map(_buildPlanCard),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildStandardCards() {
    const standards = [
      {'name': 'BASIC', 'price': '60', 'duration': '1', 'emoji': '🔵'},
      {'name': 'STANDARD', 'price': '150', 'duration': '3', 'emoji': '🟣'},
      {'name': 'PREMIUM', 'price': '300', 'duration': '6', 'emoji': '🟢'},
      {'name': 'ANNUAL', 'price': '490', 'duration': '12', 'emoji': '🟠'},
    ];
    return standards
        .map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                Text(s['emoji']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name']!,
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${s['price']} DT • ${s['duration']} mois',
                        style: const TextStyle(color: _kTextSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kSurf2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Text(
                    'Intégré',
                    style: TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildPlanCard(dynamic plan) {
    final bool isActive = plan['active'] == true;
    final Color planColor = _hexToColor(plan['color'] as String? ?? '#00C853');
    final String emoji = plan['emoji'] as String? ?? '⭐';
    final String name = plan['displayName'] as String? ?? plan['name'] ?? '';
    final double price = (plan['price'] as num).toDouble();
    final int duration = plan['duration'] as int;
    final String? description = plan['description'] as String?;
    final int id = (plan['id'] as num).toInt();

    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? planColor.withValues(alpha: 0.3) : _kBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: planColor.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: planColor.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: planColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: planColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: _kText,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _kRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Inactif',
                                  style: TextStyle(color: _kRed, fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        if (description != null && description.isNotEmpty)
                          Text(
                            description,
                            style: const TextStyle(
                              color: _kTextSub,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          color: planColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$duration mois',
                        style: const TextStyle(color: _kTextSub, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: planColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: planColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      plan['name']?.toString().toUpperCase() ?? '',
                      style: TextStyle(
                        color: planColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _IconBtn(
                    icon: Icons.edit_rounded,
                    color: _kBlue,
                    tooltip: 'Modifier',
                    onTap: () => _showPlanDialog(existing: plan),
                  ),
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: isActive
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                    color: isActive ? _kGreen : _kOrange,
                    tooltip: isActive ? 'Désactiver' : 'Activer',
                    onTap: () => _toggle(id, isActive),
                  ),
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: _kRed,
                    tooltip: 'Supprimer',
                    onTap: () => _delete(id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📋', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text(
          'Aucun plan personnalisé',
          style: TextStyle(color: _kTextSub, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Créez votre premier plan avec le bouton +',
          style: TextStyle(color: _kBorder, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildEmptyCustom() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: const [
        Text('✨', style: TextStyle(fontSize: 36)),
        SizedBox(height: 12),
        Text(
          'Aucun plan personnalisé pour l\'instant',
          style: TextStyle(color: _kTextSub, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text(
          'Créez des plans saisonniers, promotionnels ou spéciaux',
          style: TextStyle(color: _kBorder, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ─── Helpers ───
Color _hexToColor(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return _kGreen;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(
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
      Text(subtitle, style: const TextStyle(color: _kBorder, fontSize: 10)),
    ],
  );
}

class _PlanPreview extends StatelessWidget {
  final String name, price, duration, emoji, description;
  final Color color;
  const _PlanPreview({
    required this.name,
    required this.price,
    required this.duration,
    required this.emoji,
    required this.color,
    required this.description,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
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
              if (description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(color: _kTextSub, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$price DT',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              '$duration mois',
              style: const TextStyle(color: _kTextSub, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isNumber;
  const _DialogField(this.ctrl, this.label, this.icon, {this.isNumber = false});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: _kText, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextSub, fontSize: 12),
      prefixIcon: Icon(icon, color: _kGreen, size: 18),
      filled: true,
      fillColor: _kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final Color confirmColor;
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _kSurf2,
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
