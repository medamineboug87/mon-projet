// lib/screens/sessions_tab.dart
// ✅ CORRIGÉ : version mobile-first
// - Suppression du double Scaffold
// - TabBar sorti de l'AppBar, intégré dans le body
// - IndexedStack au lieu de TabBarView (pas de conflit de navigation)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'new_session_screen.dart';
import 'sessions_history_screen.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kOrange = Color(0xFFF57C00);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class SessionsTab extends ConsumerStatefulWidget {
  final int memberId;

  const SessionsTab({super.key, required this.memberId});

  @override
  ConsumerState<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends ConsumerState<SessionsTab> {
  int _selectedIndex = 0; // 0 = Nouvelle, 1 = Historique

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // ✅ AppBar simplifiée : plus de bottom TabBar
      appBar: AppBar(
        title: const Text(
          'Séances',
          style: TextStyle(
            color: _kText,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ✅ TabBar intégré dans le body (header collé)
          Container(
            color: Colors.transparent,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabChip(
                          icon: Icons.add_circle_outline,
                          label: 'Nouvelle',
                          isSelected: _selectedIndex == 0,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTabChip(
                          icon: Icons.history,
                          label: 'Historique',
                          isSelected: _selectedIndex == 1,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0.5, color: _kBorder),
              ],
            ),
          ),
          // ✅ Contenu avec IndexedStack (pas de conflit)
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildNewSessionTab(),
                SessionsHistoryScreen(memberId: widget.memberId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? _kGreen : _kTextSub;
    final backgroundColor = isSelected
        ? _kGreen.withValues(alpha: 0.12)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _kGreen.withValues(alpha: 0.4) : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewSessionTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.fitness_center, size: 50, color: _kGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Prêt pour une séance ?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enregistrez votre entraînement et obtenez\nune analyse IA personnalisée',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextSub, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewSessionScreen(memberId: widget.memberId),
                  ),
                );
                if (result == true && mounted) {
                  setState(() => _selectedIndex = 1);
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Commencer une séance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                minimumSize: const Size(200, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
