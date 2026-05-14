import 'dart:async';
import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';

// ─── Design tokens light ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
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
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
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
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kRed.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: _kRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Administration',
                style: TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            // Indicateur de polling actif
            if (_pollingTimer?.isActive == true)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kText),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
            onPressed: () => _loadMessages(quiet: false),
            tooltip: 'Actualiser',
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
          // CORRECTION #1 : _kSurface au lieu de _kText
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
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
              Icons.chat_bubble_outline_rounded,
              size: 30,
              color: _kTextSub,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucun message avec l'administration",
            style: TextStyle(color: _kTextSub, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            "Envoyez un message, l'admin vous répondra",
            style: TextStyle(color: _kTextSub, fontSize: 12),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 16,
                    color: _kRed,
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
                        border: Border.all(color: _kSurface, width: 1.5),
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
                    // Coach (moi) = bleu, Admin = gris clair
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
                      // Texte blanc sur bleu, texte foncé sur gris
                      color: isMe ? Colors.white : _kText,
                      fontSize: 14,
                      height: 1.4,
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
                        isUnread ? Icons.done_rounded : Icons.done_all_rounded,
                        size: 13,
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlue.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.sports_rounded, size: 16, color: _kBlue),
            ),
          ],
        ],
      ),
    );
  }

  // CORRECTION #1 : fond _kSurface (blanc) au lieu de _kText (bleu foncé)
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface, // ✅ CORRIGÉ : était _kText (noir)
        border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: _kText),
              maxLines: null,
              // CORRECTION #2 : textInputAction ajouté
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Message à l'administration...",
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
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kBlue, // Bouton bleu pour le coach
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.3),
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
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays > 0) {
        return '${dt.day}/${dt.month} '
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
