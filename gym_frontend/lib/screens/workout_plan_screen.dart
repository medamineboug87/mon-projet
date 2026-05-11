import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/index.dart';

// ─── Design tokens light ───
const Color _kBg      = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen   = Color(0xFF00897B);
const Color _kGreenL  = Color(0xFFE0F2F1);
const Color _kGreenDark = Color(0xFF00695C);
const Color _kBlue    = Color(0xFF1976D2);
const Color _kBlueL   = Color(0xFFE3F2FD);
const Color _kOrange  = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kRed     = Color(0xFFE53935);
const Color _kRedL    = Color(0xFFFFEBEE);
const Color _kPurple  = Color(0xFF7B1FA2);
const Color _kPurpleL = Color(0xFFF3E5F5);
const Color _kText    = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder  = Color(0xFFDDE2EE);


class WorkoutPlanScreen extends ConsumerStatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  ConsumerState<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends ConsumerState<WorkoutPlanScreen> {
  String? _selectedPlan;
  bool _showDetails = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Push/Pull/Legs',
      'level': 'Intermédiaire',
      'days': 6,
      'description':
          'Sépare les mouvements poussés, tirés et jambes pour une récupération optimale.',
      'schedule': {
        'Lundi': {'type': 'PUSH', 'muscles': 'Pectoraux + Épaules + Triceps'},
        'Mardi': {'type': 'PULL', 'muscles': 'Dorsaux + Biceps'},
        'Mercredi': {'type': 'REPOS', 'muscles': ''},
        'Jeudi': {'type': 'LEGS', 'muscles': 'Quadriceps + Ischio + Fessiers'},
        'Vendredi': {
          'type': 'PUSH',
          'muscles': 'Pectoraux + Épaules + Triceps',
        },
        'Samedi': {'type': 'PULL', 'muscles': 'Dorsaux + Biceps'},
        'Dimanche': {'type': 'REPOS', 'muscles': ''},
      },
      'benefits':
          'Entraîne chaque muscle 2x/semaine — optimal selon les études 2024 (Journal of Strength & Conditioning Research)',
    },
    {
      'name': 'Upper/Lower',
      'level': 'Débutant',
      'days': 4,
      'description':
          'Alterne entraînement du haut et du bas du corps pour une progression simple.',
      'schedule': {
        'Lundi': {
          'type': 'UPPER',
          'muscles': 'Pectoraux + Dorsaux + Épaules + Bras',
        },
        'Mardi': {
          'type': 'LOWER',
          'muscles': 'Quadriceps + Ischio + Fessiers + Mollets',
        },
        'Mercredi': {'type': 'REPOS', 'muscles': ''},
        'Jeudi': {
          'type': 'UPPER',
          'muscles': 'Pectoraux + Dorsaux + Épaules + Bras',
        },
        'Vendredi': {
          'type': 'LOWER',
          'muscles': 'Quadriceps + Ischio + Fessiers + Mollets',
        },
        'Samedi': {'type': 'REPOS', 'muscles': ''},
        'Dimanche': {'type': 'REPOS', 'muscles': ''},
      },
      'benefits':
          'Idéal pour débutants — permet une récupération complète (American College of Sports Medicine)',
    },
    {
      'name': 'Full Body',
      'level': 'Débutant',
      'days': 3,
      'description':
          'Entraîne tout le corps à chaque séance pour une efficacité maximale.',
      'schedule': {
        'Lundi': {'type': 'FULL BODY', 'muscles': 'Tout le corps'},
        'Mardi': {'type': 'REPOS', 'muscles': ''},
        'Mercredi': {'type': 'FULL BODY', 'muscles': 'Tout le corps'},
        'Jeudi': {'type': 'REPOS', 'muscles': ''},
        'Vendredi': {'type': 'FULL BODY', 'muscles': 'Tout le corps'},
        'Samedi': {'type': 'REPOS', 'muscles': ''},
        'Dimanche': {'type': 'REPOS', 'muscles': ''},
      },
      'benefits':
          'Stimulation hormonale maximale — augmente la testostérone naturelle (European Journal of Applied Physiology)',
    },
    {
      'name': '4-Day Split',
      'level': 'Avancé',
      'days': 4,
      'description':
          'Division spécialisée pour athlètes expérimentés cherchant l\'hypertrophie maximale.',
      'schedule': {
        'Lundi': {
          'type': 'POITRINE + TRICEPS',
          'muscles': 'Pectoraux + Triceps',
        },
        'Mardi': {'type': 'DOS + BICEPS', 'muscles': 'Dorsaux + Biceps'},
        'Mercredi': {'type': 'REPOS', 'muscles': ''},
        'Jeudi': {
          'type': 'JAMBES',
          'muscles': 'Quadriceps + Ischio + Fessiers + Mollets',
        },
        'Vendredi': {
          'type': 'ÉPAULES + TRAPÈZES',
          'muscles': 'Épaules + Trapèzes',
        },
        'Samedi': {'type': 'REPOS', 'muscles': ''},
        'Dimanche': {'type': 'REPOS', 'muscles': ''},
      },
      'benefits':
          'Volume élevé par muscle — prouvé pour maximiser la croissance (Journal of the International Society of Sports Nutrition)',
    },
  ];

  String _getRecommendedPlan(int sessionsThisWeek) {
    if (sessionsThisWeek < 3) return 'Upper/Lower';
    if (sessionsThisWeek <= 5) return 'Push/Pull/Legs';
    return '4-Day Split';
  }

  Future<void> _adoptPlan(String planName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adopted_plan', planName);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plan adopté !')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberIdAsync = ref.watch(memberIdProvider);
    final sessionsAsync = memberIdAsync.maybeWhen(
      data: (memberId) => ref.watch(sessionsProvider(memberId)),
      orElse: () => null,
    );

    int sessionsThisWeek = 0;
    if (sessionsAsync?.hasValue == true) {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      sessionsThisWeek = sessionsAsync!.value!.where((session) {
        final sessionDate =
            DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
        return sessionDate.isAfter(weekAgo);
      }).length;
    }

    final recommendedPlan = _getRecommendedPlan(sessionsThisWeek);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Plans d\'entraînement'),
        backgroundColor: const Color(0xFFEEF1F8),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec recommandation
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommandation personnalisée',
                      style: TextStyle(
                        color: _kText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Basé sur vos $sessionsThisWeek séances cette semaine, nous vous recommandons le Plan $recommendedPlan',
                      style: const TextStyle(color: _kText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Plans disponibles',
                style: TextStyle(
                  color: _kText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._plans.map(
                (plan) => _buildPlanCard(plan, recommendedPlan == plan['name']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isRecommended) {
    final isSelected = _selectedPlan == plan['name'];
    final isExpanded = isSelected && _showDetails;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan['name'],
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _kGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Recommandé',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: plan['level'] == 'Avancé'
                            ? _kRed
                            : plan['level'] == 'Intermédiaire'
                            ? _kOrange
                            : _kGreenDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plan['level'],
                        style: const TextStyle(
                          color: _kText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${plan['days']} jours/semaine',
                      style: const TextStyle(color: _kText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['description'],
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_selectedPlan == plan['name']) {
                      _showDetails = !_showDetails;
                    } else {
                      _selectedPlan = plan['name'];
                      _showDetails = true;
                    }
                  });
                },
                icon: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: _kGreen,
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 16),
            const Text(
              'Programme hebdomadaire',
              style: TextStyle(
                color: _kText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // ✅ Correction: Suppression du TweenAnimationBuilder inutile
            _buildWeeklySchedule(plan['schedule']),
            const SizedBox(height: 16),
            Text(
              'Bénéfices: ${plan['benefits']}',
              style: const TextStyle(color: _kText, fontSize: 14),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Adopter ce plan',
              onPressed: () => _adoptPlan(plan['name']),
              iconPath: 'assets/icons/check.svg',
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Correction: Widget statique sans animation inutile
  Widget _buildWeeklySchedule(Map<String, dynamic> schedule) {
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    return Column(
      children: days.map((day) {
        final dayData = schedule[day];
        final isRest = dayData['type'] == 'REPOS';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRest
                  ? Colors.grey
                  : _kGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                day,
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isRest
                      ? '🔴 REPOS'
                      : '🟢 ${dayData['type']} — ${dayData['muscles']}',
                  style: TextStyle(color: isRest ? Colors.grey : _kText),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}