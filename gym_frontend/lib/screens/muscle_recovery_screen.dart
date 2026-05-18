// lib/screens/muscle_recovery_screen.dart
// Écran de récupération musculaire détaillée
// Consomme GET /api/ai/recovery/{memberId}

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/muscle_recovery_service.dart';

// ─── Design tokens ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
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

class MuscleRecoveryScreen extends StatefulWidget {
  final int memberId;

  const MuscleRecoveryScreen({super.key, required this.memberId});

  @override
  State<MuscleRecoveryScreen> createState() => _MuscleRecoveryScreenState();
}

class _MuscleRecoveryScreenState extends State<MuscleRecoveryScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _recoveryData;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadRecovery();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecovery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await MuscleRecoveryService.getRecoveryStatus(
        widget.memberId,
      );
      if (mounted) {
        setState(() {
          _recoveryData = data;
          _isLoading = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Récupération musculaire',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: _kBorder),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
              onPressed: _loadRecovery,
              tooltip: 'Actualiser',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _loadRecovery,
                color: _kGreen,
                child: _buildContent(),
              ),
            ),
    );
  }

  // ══════════════════════════════════════
  // LOADING
  // ══════════════════════════════════════
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kGreenL,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                color: _kGreen,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Analyse en cours…',
            style: TextStyle(
              color: _kText,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'L\'IA calcule votre récupération musculaire',
            style: TextStyle(color: _kTextSub, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // ERROR
  // ══════════════════════════════════════
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kRedL,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: _kRed,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Données indisponibles',
              style: TextStyle(
                color: _kText,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enregistrez au moins une séance avec des exercices détaillés pour activer le suivi musculaire.',
              style: TextStyle(color: _kTextSub, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRecovery,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // MAIN CONTENT
  // ══════════════════════════════════════
  Widget _buildContent() {
    final data = _recoveryData!;
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final muscleStatuses =
        (data['muscleStatuses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final readyMuscles = (data['readyMuscles'] as List?)?.cast<String>() ?? [];
    final recoveringMuscles =
        (data['recoveringMuscles'] as List?)?.cast<String>() ?? [];
    final criticalMuscles =
        (data['criticalMuscles'] as List?)?.cast<String>() ?? [];
    final todayRec = data['todayRecommendation'] as Map<String, dynamic>? ?? {};
    final availableGroups =
        (data['availableMuscleGroups'] as List?)?.cast<String>() ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── HERO: Recommandation du jour ──
        _TodayRecommendationCard(
          rec: todayRec,
          availableGroups: availableGroups,
        ),
        const SizedBox(height: 16),

        // ── RÉSUMÉ ──
        _SummaryRow(
          total: summary['totalTracked'] ?? 0,
          ready: summary['readyCount'] ?? 0,
          recovering: summary['recoveringCount'] ?? 0,
          critical: summary['criticalCount'] ?? 0,
          level: summary['fitnessLevel'] ?? 'N/A',
        ),
        const SizedBox(height: 20),

        // ── ALERTES CRITIQUES ──
        if (criticalMuscles.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.warning_amber_rounded,
            label: 'Muscles critiques — Ne pas travailler',
            color: _kRed,
          ),
          const SizedBox(height: 10),
          ...muscleStatuses
              .where((m) => m['status'] == 'CRITICAL')
              .map((m) => _MuscleStatusCard(muscle: m)),
          const SizedBox(height: 20),
        ],

        // ── EN RÉCUPÉRATION ──
        if (recoveringMuscles.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.hourglass_bottom_rounded,
            label: 'En cours de récupération',
            color: _kOrange,
          ),
          const SizedBox(height: 10),
          ...muscleStatuses
              .where((m) => m['status'] == 'RECOVERING')
              .map((m) => _MuscleStatusCard(muscle: m)),
          const SizedBox(height: 20),
        ],

        // ── PRÊTS ──
        if (readyMuscles.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.check_circle_rounded,
            label: 'Prêts à l\'entraînement',
            color: _kGreen,
          ),
          const SizedBox(height: 10),
          ...muscleStatuses
              .where((m) => m['status'] == 'READY')
              .map((m) => _MuscleStatusCard(muscle: m)),
          const SizedBox(height: 20),
        ],

        // ── ÉTAT VIDE ──
        if (muscleStatuses.isEmpty) _EmptyMusclesCard(),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════
// TODAY RECOMMENDATION HERO CARD
// ════════════════════════════════════════════════════════
class _TodayRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  final List<String> availableGroups;

  const _TodayRecommendationCard({
    required this.rec,
    required this.availableGroups,
  });

  @override
  Widget build(BuildContext context) {
    final canTrain = rec['canTrain'] ?? true;
    final type = rec['type'] ?? 'FREE';
    final message = rec['message'] ?? '';
    final cardioOk = rec['cardioOk'] ?? true;
    final avoid = (rec['avoid'] as List?)?.cast<String>() ?? [];

    final (gradient, iconColor, icon) = _getStyle(type, canTrain);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (canTrain ? _kGreen : _kRed).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommandation du jour',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      canTrain ? 'Entraînement possible' : 'Repos recommandé',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          if (availableGroups.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: availableGroups
                  .map(
                    (g) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            g,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (avoid.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: avoid
                  .take(4)
                  .map(
                    (m) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            m,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _PillBadge(
                icon: cardioOk
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: cardioOk ? 'Cardio OK' : 'Cardio déconseillé',
                positive: cardioOk,
              ),
            ],
          ),
        ],
      ),
    );
  }

  (LinearGradient, Color, IconData) _getStyle(String type, bool canTrain) {
    if (!canTrain) {
      return (
        const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFB71C1C)]),
        _kRed,
        Icons.hotel_rounded,
      );
    }
    switch (type) {
      case 'PARTIAL':
        return (
          const LinearGradient(colors: [Color(0xFFF57C00), Color(0xFFE65100)]),
          _kOrange,
          Icons.warning_amber_rounded,
        );
      case 'TARGETED':
        return (
          const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00695C)]),
          _kGreen,
          Icons.fitness_center_rounded,
        );
      default:
        return (
          const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF0D47A1)]),
          _kBlue,
          Icons.check_circle_rounded,
        );
    }
  }
}

// ════════════════════════════════════════════════════════
// SUMMARY ROW
// ════════════════════════════════════════════════════════
class _SummaryRow extends StatelessWidget {
  final int total, ready, recovering, critical;
  final String level;

  const _SummaryRow({
    required this.total,
    required this.ready,
    required this.recovering,
    required this.critical,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: _kGreen, size: 16),
              const SizedBox(width: 6),
              Text(
                '$total muscle${total > 1 ? 's' : ''} suivis',
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              _LevelBadge(level: level),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCell(value: ready, label: 'Prêts', color: _kGreen),
              ),
              _Divider(),
              Expanded(
                child: _StatCell(
                  value: recovering,
                  label: 'En récup.',
                  color: _kOrange,
                ),
              ),
              _Divider(),
              Expanded(
                child: _StatCell(
                  value: critical,
                  label: 'Critiques',
                  color: _kRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: _kBorder,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  Color _color() {
    switch (level) {
      case 'ATHLETE':
        return _kRed;
      case 'ADVANCED':
        return _kOrange;
      case 'INTERMEDIATE':
        return _kBlue;
      default:
        return _kGreen;
    }
  }

  String _label() {
    switch (level) {
      case 'ATHLETE':
        return 'Athlète';
      case 'ADVANCED':
        return 'Avancé';
      case 'INTERMEDIATE':
        return 'Intermédiaire';
      default:
        return 'Débutant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        _label(),
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
// SECTION HEADER
// ════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    ],
  );
}

// ════════════════════════════════════════════════════════
// MUSCLE STATUS CARD
// ════════════════════════════════════════════════════════
class _MuscleStatusCard extends StatelessWidget {
  final Map<String, dynamic> muscle;
  const _MuscleStatusCard({required this.muscle});

  @override
  Widget build(BuildContext context) {
    final name = muscle['muscleName'] ?? '';
    final group = muscle['muscleGroup'] ?? '';
    final status = muscle['status'] ?? 'READY';
    final hoursRequired = (muscle['hoursRequired'] as num?)?.toInt() ?? 0;
    final hoursElapsed = (muscle['hoursElapsed'] as num?)?.toInt() ?? 0;
    final hoursRemaining = (muscle['hoursRemaining'] as num?)?.toInt() ?? 0;
    final isAvailable = muscle['isAvailable'] ?? false;
    final lastWorkedDate = muscle['lastWorkedDate'] ?? '';
    final lastIntensity = (muscle['lastIntensity'] as num?)?.toInt() ?? 0;
    final lastVolume = (muscle['lastVolume'] as num?)?.toDouble() ?? 0.0;

    final (color, bgColor, progressColor) = _getColors(status);
    final progressValue = hoursRequired > 0
        ? (hoursElapsed / hoursRequired).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: isAvailable ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _muscleEmoji(group),
                    style: const TextStyle(fontSize: 20),
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
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _groupLabel(group),
                      style: const TextStyle(color: _kTextSub, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status, color: color),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hoursRemaining == 0
                        ? '✅ Récupération complète'
                        : '⏱ ${_formatHours(hoursRemaining)} restants',
                    style: TextStyle(
                      color: hoursRemaining == 0 ? _kGreen : color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_formatHours(hoursElapsed)} / ${_formatHours(hoursRequired)}',
                    style: const TextStyle(color: _kTextSub, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: _kBorder,
                  valueColor: AlwaysStoppedAnimation(progressColor),
                  minHeight: 7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Metadata row
          Row(
            children: [
              _MetaChip(
                icon: Icons.calendar_today_rounded,
                label: _formatDate(lastWorkedDate),
                color: _kTextSub,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.speed_rounded,
                label: 'Intensité $lastIntensity/10',
                color: lastIntensity >= 8
                    ? _kRed
                    : lastIntensity >= 6
                    ? _kOrange
                    : _kGreen,
              ),
              if (lastVolume > 0) ...[
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.bar_chart_rounded,
                  label: '${lastVolume.toStringAsFixed(0)} vol.',
                  color: _kBlue,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _muscleEmoji(String group) {
    switch (group) {
      case 'PUSH':
        return '💪';
      case 'PULL':
        return '🏋️';
      case 'LEGS':
        return '🦵';
      case 'CORE':
        return '⬡';
      default:
        return '🔹';
    }
  }

  String _groupLabel(String group) {
    switch (group) {
      case 'PUSH':
        return 'Groupe PUSH';
      case 'PULL':
        return 'Groupe PULL';
      case 'LEGS':
        return 'Membres inférieurs';
      case 'CORE':
        return 'Core / Tronc';
      default:
        return group;
    }
  }

  (Color, Color, Color) _getColors(String status) {
    switch (status) {
      case 'CRITICAL':
        return (_kRed, _kRedL, _kRed);
      case 'RECOVERING':
        return (_kOrange, _kOrangeL, _kOrange);
      default:
        return (_kGreen, _kGreenL, _kGreen);
    }
  }

  String _formatHours(int hours) {
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    final remaining = hours % 24;
    return remaining > 0 ? '${days}j${remaining}h' : '${days}j';
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(date);
      final diff = DateTime.now().difference(dt).inDays;
      if (diff == 0) return "Aujourd'hui";
      if (diff == 1) return 'Hier';
      return 'Il y a ${diff}j';
    } catch (_) {
      return date;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  String _label() {
    switch (status) {
      case 'CRITICAL':
        return '⛔ Critique';
      case 'RECOVERING':
        return '🔄 Récupération';
      default:
        return '✅ Prêt';
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      _label(),
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _kSurf2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _kBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool positive;
  const _PillBadge({
    required this.icon,
    required this.label,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: positive ? Colors.greenAccent : Colors.white70,
          size: 13,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _EmptyMusclesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kBorder),
    ),
    child: Center(
      child: Column(
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Aucun exercice enregistré',
            style: TextStyle(
              color: _kText,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez des exercices avec le muscle ciblé lors de votre prochaine séance pour activer le suivi de récupération.',
            style: TextStyle(color: _kTextSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
