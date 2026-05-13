// lib/screens/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';
import 'ai_profile_screen.dart';
import 'workout_plan_screen.dart';
import 'login_screen.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kOrange = Color(0xFFF57C00);
const Color _kOrangeL = Color(0xFFFFF3E0);
const Color _kPurple = Color(0xFF7B1FA2);
const Color _kPurpleL = Color(0xFFF3E5F5);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class ProfileTab extends ConsumerWidget {
  final int memberId; // ✅ FIX #2 : paramètre ajouté

  const ProfileTab({super.key, required this.memberId});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuItems = [
      ProfileMenuItem(
        icon: Icons.person_outline_rounded,
        title: 'Mon profil',
        subtitle: 'Informations personnelles',
        color: _kBlue,
        bgColor: _kBlueL,
        screen: ProfileScreen(memberId: memberId),
      ),
      ProfileMenuItem(
        icon: Icons.card_membership_rounded,
        title: 'Mon abonnement',
        subtitle: 'Gérer mon abonnement',
        color: _kGreen,
        bgColor: _kGreenL,
        screen: SubscriptionScreen(memberId: memberId),
      ),
      ProfileMenuItem(
        icon: Icons.auto_awesome_rounded,
        title: 'Profil IA',
        subtitle: 'Objectif, sommeil, stress, santé',
        color: _kPurple,
        bgColor: _kPurpleL,
        screen: AIProfileScreen(memberId: memberId),
      ),
      ProfileMenuItem(
        icon: Icons.calendar_month_rounded,
        title: "Plans d'entraînement",
        subtitle: 'Programmes recommandés',
        color: _kOrange,
        bgColor: _kOrangeL,
        screen: const WorkoutPlanScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Mon espace',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _kTextSub),
            onPressed: () => _logout(context),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: const TextStyle(color: _kTextSub, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: _kTextSub,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.screen),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfileMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final Widget screen;

  ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.screen,
  });
}
