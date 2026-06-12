import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import '../theme/fishdex_theme.dart';
import 'conversation_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

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
          child: const Icon(CupertinoIcons.chevron_back, color: FishdexTheme.primary),
        ),
        title: const Text('Messages',
          style: TextStyle(
            color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.black.withOpacity(0.06)),
        ),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: MessagingService.conversationsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final convs = snap.data ?? [];
          if (convs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('💬', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Aucune conversation',
                  style: TextStyle(
                    color: FishdexTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Va sur le profil d\'un pêcheur\npour lui envoyer un message',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 13)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 72, color: Colors.black.withOpacity(0.05)),
            itemBuilder: (context, i) {
              final conv = convs[i];
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => ConversationScreen(
                      convId:      conv.id,
                      otherUid:    conv.otherUid,
                      otherName:   conv.otherName,
                      otherHandle: conv.otherHandle,
                    ),
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [FishdexTheme.primary, Color(0xFF00C6E0)]),
                  ),
                  child: const Center(
                    child: Text('🎣', style: TextStyle(fontSize: 22))),
                ),
                title: Row(children: [
                  Expanded(child: Text(
                    conv.otherName,
                    style: TextStyle(
                      color: FishdexTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: conv.unread > 0 ? FontWeight.w700 : FontWeight.w500),
                  )),
                  Text(_ago(conv.lastAt),
                    style: const TextStyle(
                      color: FishdexTheme.textTertiary, fontSize: 11)),
                ]),
                subtitle: Row(children: [
                  Expanded(child: Text(
                    conv.lastMessage.isEmpty
                        ? 'Nouvelle conversation'
                        : conv.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: conv.unread > 0
                          ? FishdexTheme.textPrimary
                          : FishdexTheme.textTertiary,
                      fontSize: 13,
                      fontWeight: conv.unread > 0
                          ? FontWeight.w600
                          : FontWeight.w400),
                  )),
                  if (conv.unread > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: FishdexTheme.primary,
                        borderRadius: BorderRadius.circular(10)),
                      child: Text('${conv.unread}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              );
            },
          );
        },
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1)  return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours   < 24) return '${diff.inHours}h';
    if (diff.inDays    < 7)  return '${diff.inDays}j';
    return '${d.day}/${d.month}';
  }
}
