// lib/screens/sessions_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/member_provider.dart';
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
  const SessionsTab({super.key});

  @override
  ConsumerState<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends ConsumerState<SessionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _memberId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMemberId();
  }

  Future<void> _loadMemberId() async {
    final memberIdAsync = ref.read(memberIdProvider);
    final id = memberIdAsync;
    if (id != 0) {
      setState(() => _memberId = id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_memberId == null) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kGreen,
          labelColor: _kGreen,
          unselectedLabelColor: _kTextSub,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Nouvelle'),
            Tab(icon: Icon(Icons.history), text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewSessionTab(),
          SessionsHistoryScreen(memberId: _memberId!),
        ],
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
                    builder: (_) => NewSessionScreen(memberId: _memberId!),
                  ),
                );
                if (result == true && mounted) {
                  _tabController.animateTo(1);
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Commencer une séance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
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
