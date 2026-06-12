import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../theme/fishdex_theme.dart';

class ConversationScreen extends StatefulWidget {
  final String convId, otherUid, otherName, otherHandle;

  const ConversationScreen({
    super.key,
    required this.convId,
    required this.otherUid,
    required this.otherName,
    required this.otherHandle,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    MessagingService.markRead(widget.convId);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() { _sending = true; });
    _ctrl.clear();
    final err = await MessagingService.sendMessage(
        widget.convId, widget.otherUid, text);
    if (mounted) {
      setState(() => _sending = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: FishdexTheme.coral));
      } else {
        Future.delayed(
            const Duration(milliseconds: 100), _scrollToBottom);
      }
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
              CupertinoIcons.chevron_back, color: FishdexTheme.primary),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.otherName,
            style: const TextStyle(
              color: FishdexTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
          Text('@${widget.otherHandle}',
            style: const TextStyle(
              color: FishdexTheme.textSecondary, fontSize: 11)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.black.withOpacity(0.06)),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: MessagingService.messagesStream(widget.convId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CupertinoActivityIndicator());
              }
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('👋', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text('Envoie un message à ${widget.otherName} !',
                    style: const TextStyle(
                      color: FishdexTheme.textSecondary, fontSize: 14)),
                ]));
              }
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom());
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final msg = msgs[i];
                  final isMe = msg.senderId == AuthService.currentUserId;
                  return _bubble(msg, isMe);
                },
              );
            },
          ),
        ),
        _inputBar(context),
      ]),
    );
  }

  Widget _bubble(ChatMessage msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [FishdexTheme.primary, Color(0xFF00C6E0)])),
              child: const Center(
                child: Text('🎣', style: TextStyle(fontSize: 13)))),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? FishdexTheme.primary
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4  : 18),
                ),
              ),
              child: Text(msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : FishdexTheme.textPrimary,
                  fontSize: 14)),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.black.withOpacity(0.06)))),
      child: Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(22)),
          child: TextField(
            controller: _ctrl,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Message…',
              hintStyle: TextStyle(color: FishdexTheme.textTertiary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10)),
            style: const TextStyle(
                fontSize: 14, color: FishdexTheme.textPrimary),
            onSubmitted: (_) => _send(),
          ),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _send,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _sending
                  ? FishdexTheme.primary.withOpacity(0.5)
                  : FishdexTheme.primary),
            child: _sending
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Icon(
                    CupertinoIcons.paperplane_fill,
                    color: Colors.white, size: 18)),
        ),
      ]),
    );
  }
}
