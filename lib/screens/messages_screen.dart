import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const _conversations = [
    _Conversation('@leBrochet', 'Belle prise ce matin ! 🎣', '09:24', true, 2),
    _Conversation('@mariePêche', 'On va au lac demain ?', '08:51', false, 0),
    _Conversation('@surfcaster33', 'Quel leurre tu utilises ?', 'Hier', false, 0),
    _Conversation('@Club Pêche 06', 'Sortie prévue samedi matin', 'Hier', true, 5),
    _Conversation('@thomas_cast', 'Record battu 🏆', 'Mar', false, 0),
    _Conversation('@fannyfish', 'Je vends ma canne Shimano', 'Lun', false, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          title: const Text(
            'Messages',
            style: TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.square_pencil,
                  color: FishdexTheme.primary),
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 12),
                        Icon(CupertinoIcons.search,
                            color: FishdexTheme.textSecondary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Rechercher…',
                          style: TextStyle(
                              color: FishdexTheme.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildConversationTile(_conversations[i], i),
              childCount: _conversations.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationTile(_Conversation c, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          FishdexTheme.primary.withOpacity(0.15),
                          FishdexTheme.primary.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        c.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: FishdexTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (c.unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: FishdexTheme.primary,
                        ),
                        child: Center(
                          child: Text(
                            '${c.unread}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.name,
                          style: TextStyle(
                            color: FishdexTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: c.unread > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          c.time,
                          style: TextStyle(
                            color: c.unread > 0
                                ? FishdexTheme.primary
                                : FishdexTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.unread > 0
                            ? FishdexTheme.textPrimary
                            : FishdexTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: 60 * index))
          .slideX(begin: -0.05, end: 0),
    );
  }
}

class _Conversation {
  final String name, lastMessage, time;
  final bool isGroup;
  final int unread;
  const _Conversation(
      this.name, this.lastMessage, this.time, this.isGroup, this.unread);
}