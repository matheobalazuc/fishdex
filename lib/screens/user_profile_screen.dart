import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/messaging_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';
import 'catch_detail_screen.dart';
import 'conversation_screen.dart';
import 'profile_screen.dart' show FollowListSheet;

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String displayName;
  final String userHandle;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.userHandle,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _openingChat = false;

  String get userId      => widget.userId;
  String get displayName => widget.displayName;
  String get userHandle  => widget.userHandle;

  Future<void> _openConversation(
      BuildContext context, String name, String handle) async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      final convId = await MessagingService.ensureConversation(
        otherUid:    userId,
        otherName:   name,
        otherHandle: handle,
      );
      if (mounted) {
        Navigator.push(context, CupertinoPageRoute(
          builder: (_) => ConversationScreen(
            convId:      convId,
            otherUid:    userId,
            otherName:   name,
            otherHandle: handle,
          )));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur messagerie : $e'),
          backgroundColor: FishdexTheme.coral));
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = userId == AuthService.currentUserId;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _appBar(context),
          SliverToBoxAdapter(child: _header(context, isOwn)),
          _catches(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _appBar(BuildContext context) => SliverAppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    pinned: true,
    elevation: 0,
    leading: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.pop(context),
      child: const Icon(CupertinoIcons.chevron_back, color: FishdexTheme.primary),
    ),
    title: Text('@$userHandle',
      style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(height: 1, color: Colors.black.withOpacity(0.06)),
    ),
  );

  Widget _header(BuildContext context, bool isOwn) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snap) {
        final data    = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name    = data['displayName'] as String? ?? displayName;
        final handle  = data['username']    as String? ?? userHandle;
        final catches = (data['catchCount'] as num?)?.toInt() ?? 0;

        return Column(children: [
          const SizedBox(height: 24),
          Container(
            width: 82, height: 82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: const Center(child: Text('🎣', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 12),
          Text(name,
            style: const TextStyle(
              color: FishdexTheme.textPrimary, fontSize: 20,
              fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text('@$handle',
            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            StreamBuilder<int>(
              stream: FollowService.followersCountStream(userId),
              builder: (_, s) => GestureDetector(
                onTap: () => _showFollowList(context, userId, isFollowers: true),
                child: _stat('${s.data ?? 0}', 'Abonnés')),
            ),
            _div(),
            StreamBuilder<int>(
              stream: FollowService.followingCountStream(userId),
              builder: (_, s) => GestureDetector(
                onTap: () => _showFollowList(context, userId, isFollowers: false),
                child: _stat('${s.data ?? 0}', 'Abonnements')),
            ),
            _div(),
            _stat('$catches', 'Prises'),
          ]),
          const SizedBox(height: 16),

          if (!isOwn && AuthService.isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(children: [
                Expanded(child: StreamBuilder<bool>(
                  stream: FollowService.isFollowingStream(userId),
                  builder: (context, snap) {
                    final following = snap.data ?? false;
                    return GestureDetector(
                      onTap: () async {
                        if (following) {
                          await FollowService.unfollow(userId);
                        } else {
                          await FollowService.follow(userId);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 46,
                        decoration: BoxDecoration(
                          color: following ? Colors.transparent : FishdexTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          border: following
                              ? Border.all(color: FishdexTheme.primary, width: 1.5)
                              : null,
                        ),
                        child: Center(child: Text(
                          following ? 'Abonné ✓' : 'S\'abonner',
                          style: TextStyle(
                            color: following ? FishdexTheme.primary : Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15),
                        )),
                      ),
                    );
                  },
                )),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _openConversation(context, name, handle),
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: FishdexTheme.primary.withOpacity(0.08),
                      border: Border.all(
                        color: FishdexTheme.primary.withOpacity(0.25))),
                    child: _openingChat
                        ? const Center(
                            child: CupertinoActivityIndicator())
                        : const Icon(
                            CupertinoIcons.chat_bubble_text_fill,
                            color: FishdexTheme.primary, size: 18)),
                ),
              ]),
            ),

          const SizedBox(height: 20),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
        ]);
      },
    );
  }

  Widget _stat(String v, String l) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(v, style: const TextStyle(
      color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
    Text(l, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 11)),
  ]);

  Widget _div() => Container(
    width: 1, height: 24, color: Colors.black.withOpacity(0.08),
    margin: const EdgeInsets.symmetric(horizontal: 20));

  Widget _catches() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('catches')
          .where('userId',      isEqualTo: userId)
          .where('isPublished', isEqualTo: true)
          .where('isPrivate',   isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(padding: EdgeInsets.all(40),
              child: CupertinoActivityIndicator())));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.all(40),
              child: Column(children: [
                Text('🎣', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text('Aucune prise publiée',
                  style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
              ])));
        }
        final catches = docs
            .map((d) => FishCatch.fromFirestore(d.id, d.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final c = catches[i];
                return GestureDetector(
                  onTap: () => Navigator.push(ctx,
                      CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: c))),
                  child: Padding(padding: const EdgeInsets.all(4),
                    child: GlassCard(radius: 16, child: Column(children: [
                      Expanded(child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: _thumb(c))),
                      Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                        child: Text(c.frenchName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FishdexTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.w600))),
                    ]))),
                );
              },
              childCount: catches.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.85),
          ),
        );
      },
    );
  }

  Widget _thumb(FishCatch c) {
    if (c.imageBase64 != null && c.imageBase64!.isNotEmpty) {
      try { return Image.memory(base64Decode(c.imageBase64!), fit: BoxFit.cover, width: double.infinity); } catch (_) {}
    }
    if (c.fishImageUrl != null) {
      return Image.network(c.fishImageUrl!, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    color: FishdexTheme.primary.withOpacity(0.07),
    child: const Center(child: Text('🐟', style: TextStyle(fontSize: 22))));

  void _showFollowList(BuildContext context, String uid, {required bool isFollowers}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FollowListSheet(uid: uid, isFollowers: isFollowers),
    );
  }
}
