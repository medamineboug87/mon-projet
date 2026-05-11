import 'dart:async';
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

// ─── Design tokens light ───
const Color _kGreen = Color(0xFF00897B);
const Color _kBlue = Color(0xFF1976D2);
const Color _kRed = Color(0xFFE53935);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

class CoachAdminMessagesScreen extends StatefulWidget {
  const CoachAdminMessagesScreen({super.key});

  @override
  State<CoachAdminMessagesScreen> createState() =>
      _CoachAdminMessagesScreenState();
}

class _CoachAdminMessagesScreenState extends State<CoachAdminMessagesScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _coachUsername;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _coachUsername = await AuthService.getUsername();
    await _loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadMessages(quiet: true);
    });
  }

  Future<void> _loadMessages({bool quiet = false}) async {
    if (!quiet) setState(() => _isLoading = true);
    final msgs = await MessageService.getMemberAdminConversation();
    if (mounted) {
      setState(() {
        _messages = msgs;
        if (!quiet) _isLoading = false;
      });
      _scrollToBottom();
    }
    await MessageService.markAdminMessagesAsRead();
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final success = await MessageService.sendMessageToAdmin(content);

    if (mounted) {
      if (success) {
        await _loadMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de l'envoi"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: _kRed, size: 24),
            SizedBox(width: 8),
            Text('Administration', style: TextStyle(color: _kText)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kText),
            onPressed: () => _loadMessages(quiet: false),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kGreen))
                : _messages.isEmpty
                ? _buildEmptyScreen()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: _kBorder),
          SizedBox(height: 16),
          Text(
            'Aucun message avec l\'administration',
            style: TextStyle(color: _kTextSub),
          ),
          SizedBox(height: 8),
          Text(
            'Envoyez un message, l\'admin vous répondra',
            style: TextStyle(color: _kTextSub),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> message) {
    final senderUsername = message['sender']?['username'] ?? '';
    final isMe = senderUsername == _coachUsername;
    final bool isUnread = message['isRead'] == false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar admin (gauche) avec point vert si non lu
          if (!isMe) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: _kRed,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 14,
                    color: _kText,
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
                        border: Border.all(
                          color: const Color(0xFFFFFFFF),
                          width: 1.5,
                        ),
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
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? _kBlue : const Color(0xFFEEF1F8),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: (!isMe && isUnread)
                        ? Border.all(
                            color: _kGreen.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Text(
                    message['content'] ?? '',
                    style: const TextStyle(color: _kText),
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
          // Avatar coach (droite)
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: _kBlue,
              child: Icon(Icons.sports, size: 14, color: _kText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: _kText,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: _kText),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Message à l\'administration...',
                hintStyle: const TextStyle(color: _kTextSub),
                filled: true,
                fillColor: const Color(0xFFF4F6FA),
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
          CircleAvatar(
            backgroundColor: _kRed,
            child: IconButton(
              icon: const Icon(Icons.send, color: _kText, size: 20),
              onPressed: _sendMessage,
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
