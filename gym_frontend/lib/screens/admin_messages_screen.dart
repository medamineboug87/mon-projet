import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/admin_service.dart';

// ─── Design tokens (référence : admin_exercises_screen) ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00C853);
const Color _kGreenL = Color(0xFFE8F5E9);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kRed = Color(0xFFE53935);
const Color _kRedL = Color(0xFFFFEBEE);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _members = [];
  List<dynamic> _coaches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final members = await AdminService.getAllMembers();
    final coaches = await AdminService.getAllCoaches();
    if (mounted) {
      setState(() {
        _members = members;
        _coaches = coaches;
        _isLoading = false;
      });
    }
  }

  void _showBroadcastDialog() {
    final controller = TextEditingController();
    String target = 'ALL';
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign, color: _kGreen),
              SizedBox(width: 8),
              Text(
                'Diffuser un message',
                style: TextStyle(color: _kText, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Destinataires',
                  style: TextStyle(color: _kTextSub, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _targetChip(
                      'Membres',
                      'MEMBERS',
                      target,
                      (v) => setDialogState(() => target = v),
                    ),
                    const SizedBox(width: 6),
                    _targetChip(
                      'Coachs',
                      'COACHES',
                      target,
                      (v) => setDialogState(() => target = v),
                    ),
                    const SizedBox(width: 6),
                    _targetChip(
                      'Tous',
                      'ALL',
                      target,
                      (v) => setDialogState(() => target = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: const TextStyle(color: _kText),
                  decoration: InputDecoration(
                    hintText: 'Votre message...',
                    hintStyle: const TextStyle(color: _kTextSub),
                    filled: true,
                    fillColor: _kSurf2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kGreen, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler', style: TextStyle(color: _kTextSub)),
            ),
            GestureDetector(
              onTap: isSending
                  ? null
                  : () async {
                      if (controller.text.trim().isEmpty) return;
                      setDialogState(() => isSending = true);
                      final result = await MessageService.adminBroadcast(
                        target: target,
                        content: controller.text.trim(),
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result != null
                                ? result['message'] ?? 'Message envoyé !'
                                : "Erreur lors de l'envoi",
                          ),
                          backgroundColor: result != null ? _kGreen : _kRed,
                        ),
                      );
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Envoyer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastHistory() async {
    final history = await MessageService.getBroadcastHistory();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text(
          'Historique des broadcasts',
          style: TextStyle(color: _kText),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: history.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun broadcast',
                    style: TextStyle(color: _kTextSub),
                  ),
                )
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final msg = history[i];
                    return ListTile(
                      title: Text(
                        msg['content'] ?? '',
                        style: const TextStyle(color: _kText, fontSize: 12),
                      ),
                      subtitle: Text(
                        'Envoyé le ${_formatDate(msg['sentAt'])}',
                        style: const TextStyle(color: _kTextSub, fontSize: 10),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: _kGreen)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
    } catch (_) {
      return '';
    }
  }

  Widget _targetChip(
    String label,
    String value,
    String current,
    void Function(String) onTap,
  ) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _kGreen.withValues(alpha: 0.15) : _kSurf2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? _kGreen : _kBorder),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? _kGreen : _kTextSub,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Messagerie',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: _kTextSub),
            onPressed: _showBroadcastHistory,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _kTextSub),
            onPressed: _loadUsers,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            48,
          ), // Hauteur totale du TabBar + ligne
          child: Column(
            children: [
              Container(height: 1, color: _kBorder), // La ligne de séparation
              TabBar(
                controller: _tabController,
                indicatorColor: _kGreen,
                indicatorWeight: 2,
                labelColor: _kGreen,
                unselectedLabelColor: _kTextSub,
                tabs: const [
                  Tab(icon: Icon(Icons.people), text: 'Membres'),
                  Tab(icon: Icon(Icons.sports), text: 'Coachs'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_members, isCoach: false),
                _buildList(_coaches, isCoach: true),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBroadcastDialog,
        backgroundColor: _kGreen,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text(
          'Diffuser',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> users, {required bool isCoach}) {
    if (users.isEmpty) {
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
              child: Icon(
                isCoach ? Icons.sports_rounded : Icons.people_rounded,
                size: 30,
                color: _kTextSub,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isCoach ? 'Aucun coach' : 'Aucun membre',
              style: const TextStyle(color: _kTextSub, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) => _buildUserTile(users[i], isCoach: isCoach),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, {required bool isCoach}) {
    final color = isCoach ? _kBlue : _kGreen;
    final icon = isCoach ? Icons.sports : Icons.person;
    final int userId = (user['userId'] as num?)?.toInt() ?? 0;
    final String? username = user['username'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          user['fullName'] ?? 'N/A',
          style: const TextStyle(color: _kText, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user['email'] ?? '',
          style: const TextStyle(color: _kTextSub, fontSize: 12),
        ),
        trailing: userId == 0
            ? const Icon(Icons.error_outline, color: _kRed)
            : Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.chat_bubble_outline, color: color, size: 18),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDirectMessageScreen(
                        userId: userId,
                        userName: user['fullName'] ?? 'N/A',
                        isCoach: isCoach,
                        coachUsername: username,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// ÉCRAN CONVERSATION DIRECTE admin ↔ utilisateur
// ════════════════════════════════════════════════════════════
class AdminDirectMessageScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final bool isCoach;
  final String? coachUsername;

  const AdminDirectMessageScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.isCoach,
    this.coachUsername,
  });

  @override
  State<AdminDirectMessageScreen> createState() =>
      _AdminDirectMessageScreenState();
}

class _AdminDirectMessageScreenState extends State<AdminDirectMessageScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _adminUsername;
  String? _receiverUsername;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _adminUsername = await AuthService.getUsername();
    if (widget.coachUsername != null) {
      _receiverUsername = widget.coachUsername;
    } else if (!widget.isCoach) {
      _receiverUsername = await MessageService.getMemberUsername(widget.userId);
    }
    await _loadMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    final msgs = await MessageService.getAdminConversationWithUser(
      widget.userId,
    );
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    if (_receiverUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de trouver le destinataire'),
          backgroundColor: _kRed,
        ),
      );
      return;
    }
    _controller.clear();
    final success = await MessageService.sendAdminMessageToUser(
      receiverUsername: _receiverUsername!,
      content: content,
    );
    if (mounted) {
      if (success) {
        await _loadMessages();
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'envoi"),
            backgroundColor: _kRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isCoach ? _kBlue : _kGreen;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.25)),
              ),
              child: Icon(
                widget.isCoach ? Icons.sports : Icons.person,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.userName,
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: _kSurface,
        iconTheme: const IconThemeData(color: _kText),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kTextSub),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) =>
                        _buildBubble(_messages[i], accentColor),
                  ),
          ),
          _buildInputBar(accentColor),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
              Icons.chat_bubble_outline,
              size: 32,
              color: _kTextSub,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Démarrez la conversation avec ${widget.userName}',
            style: const TextStyle(color: _kTextSub, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> message, Color accentColor) {
    final senderUsername = message['sender']?['username'] ?? '';
    final isMe = senderUsername == _adminUsername;
    final bool isUnread = message['isRead'] == false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    widget.isCoach ? Icons.sports : Icons.person,
                    size: 16,
                    color: accentColor,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _kGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? _kBlue : _kSurf2,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: (!isMe && isUnread)
                        ? Border.all(
                            color: _kGreen.withValues(alpha: 0.4),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : _kText,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message['sentAt']),
                      style: const TextStyle(color: _kTextSub, fontSize: 11),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isUnread ? Icons.done : Icons.done_all,
                        size: 12,
                        color: isUnread ? _kTextSub : _kGreen,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlue.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 16,
                color: _kBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: _kText),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                hintStyle: const TextStyle(color: _kTextSub),
                filled: true,
                fillColor: _kSurf2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
