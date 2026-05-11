import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/message_service.dart';
import '../services/auth_service.dart';
import '../providers/message_provider.dart';

// ─── Design tokens light ───
const Color _kBg = Color(0xFFF4F6FA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kSurf2 = Color(0xFFEEF1F8);
const Color _kGreen = Color(0xFF00897B);
const Color _kGreenL = Color(0xFFE0F2F1);
const Color _kBlue = Color(0xFF1976D2);
const Color _kBlueL = Color(0xFFE3F2FD);
const Color _kText = Color(0xFF1A2340);
const Color _kTextSub = Color(0xFF6B7A99);
const Color _kBorder = Color(0xFFDDE2EE);

// Bulle envoyée (moi) : vert
const Color _kMeBubble = Color(0xFF00897B);
// Bulle reçue : gris clair
const Color _kThemBubble = Color(0xFFEEF1F8);

class MessagesScreen extends ConsumerStatefulWidget {
  final int memberId;
  final bool isCoach;
  final String? memberName;

  const MessagesScreen({
    super.key,
    required this.memberId,
    this.isCoach = false,
    this.memberName,
  });

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _currentUsername;
  String? _receiverUsername;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _currentUsername = await AuthService.getUsername();
    _receiverUsername = widget.isCoach
        ? await MessageService.getMemberUsername(widget.memberId)
        : await MessageService.getCoachUsername();
    if (_currentUsername != null)
      await MessageService.markAsRead(widget.memberId, _currentUsername!);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_receiverUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Destinataire introuvable !'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }
    final content = _messageController.text.trim();
    _messageController.clear();
    final success = await MessageService.sendMessage(
      senderUsername: _currentUsername ?? '',
      receiverUsername: _receiverUsername!,
      memberId: widget.memberId,
      content: content,
    );
    if (success && mounted) {
      ref.invalidate(messagesProvider(widget.memberId));
      ref.invalidate(unreadCountProvider(_currentUsername ?? ''));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'envoi"),
          backgroundColor: Color(0xFFE53935),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients)
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.memberId));
    if (!messagesAsync.isLoading) _scrollToBottom();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isCoach ? _kBlueL : _kGreenL,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (widget.isCoach ? _kBlue : _kGreen).withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                widget.isCoach ? Icons.sports_rounded : Icons.person_rounded,
                color: widget.isCoach ? _kBlue : _kGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.isCoach ? widget.memberName ?? 'Membre' : 'Coach',
              style: const TextStyle(
                color: _kText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kText),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: _kBorder),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextSub),
            onPressed: () => ref.invalidate(messagesProvider(widget.memberId)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _kGreen),
              ),
              error: (e, _) => _buildError(e),
              data: (messages) => messages.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[i];
                        final isMe =
                            msg['sender']['username'] == _currentUsername;
                        return _buildBubble(msg, isMe);
                      },
                    ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    final isUnread = msg['isRead'] == false;
    final bubbleColor = isMe ? _kMeBubble : _kThemBubble;
    final textColor = isMe ? Colors.white : _kText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.isCoach ? _kBlueL : _kGreenL,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: (widget.isCoach ? _kBlue : _kGreen).withValues(alpha: 
                        0.25,
                      ),
                    ),
                  ),
                  child: Icon(
                    widget.isCoach
                        ? Icons.sports_rounded
                        : Icons.person_rounded,
                    size: 16,
                    color: widget.isCoach ? _kBlue : _kGreen,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
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
                    color: bubbleColor,
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg['sentAt']),
                      style: const TextStyle(color: _kTextSub, fontSize: 10),
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
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _kGreenL,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.person_rounded, size: 16, color: _kGreen),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
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
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
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
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withValues(alpha: 0.3),
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

  Widget _buildEmpty() => Center(
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
            size: 32,
            color: _kTextSub,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Aucun message',
          style: TextStyle(
            color: _kText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Envoyez un message pour commencer',
          style: const TextStyle(color: _kTextSub, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError(Object? error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: Color(0xFFE53935),
        ),
        const SizedBox(height: 12),
        const Text(
          'Impossible de charger les messages',
          style: TextStyle(color: _kText),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(messagesProvider(widget.memberId)),
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
          child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

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
