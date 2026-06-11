import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../services/social_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';
import 'catch_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<FishCatch>>            _feedStream;
  late final Stream<List<Map<String, dynamic>>> _topStream;
  Stream<List<FishCatch>>?  _recentStream;
  Stream<List<FishCatch>>?  _statsStream;
  Stream<int>?              _notifStream;
  late StreamSubscription<dynamic> _authSub;

  @override
  void initState() {
    super.initState();
    _feedStream = CatchService.feedStream();
    _topStream  = CatchService.topFishersStream();
    _refreshAuthStreams();
    _authSub = AuthService.authStateChanges.listen((_) {
      if (mounted) setState(_refreshAuthStreams);
    });
  }

  void _refreshAuthStreams() {
    _recentStream = CatchService.recentStream(limit: 5);
    _statsStream  = CatchService.stream();
    _notifStream  = SocialService.unreadNotificationsStream();
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        // 1. Fil des prises (en premier)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildFeed(),
          ),
        ),
        // 2. Top pêcheurs (réels)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildTopFishers(),
          ),
        ),
        // 3. Mes prises récentes
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildMyRecent(),
          ),
        ),
        // 4. Mes succès
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildMyAchievements(),
          ),
        ),
        // 5. Hot Spots
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
            child: _buildHotSpots(),
          ),
        ),
      ],
    );
  }

  // ── App bar ─────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StreamBuilder<dynamic>(
                    stream: AuthService.authStateChanges,
                    builder: (context, authSnap) {
                      final name = AuthService.isLoggedIn
                          ? AuthService.currentUserName.split(' ').first
                          : null;
                      return Text(
                        name != null ? 'Bonjour, $name 🎣' : 'Bonjour 🎣',
                        style: const TextStyle(
                          color: FishdexTheme.textPrimary,
                          fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  const Text('Fil des prises · Top pêcheurs',
                    style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00C6E0)]),
                  ),
                  child: const Center(child: Text('🐟', style: TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 8),
                const Text('Fishdex',
                  style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        StreamBuilder<int>(
          stream: _notifStream ?? Stream.value(0),
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return GestureDetector(
              onTap: () => _showNotifications(context),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.7),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(CupertinoIcons.bell, color: FishdexTheme.textPrimary, size: 18),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -2, right: -2,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.coral),
                          child: Center(child: Text('$count',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Fil des prises ─────────────────────────────────────────────────
  Widget _buildFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fil des prises',
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        StreamBuilder<List<FishCatch>>(
          stream: _feedStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CupertinoActivityIndicator(),
              ));
            }
            final catches = snap.data ?? [];
            if (catches.isEmpty) {
              return GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('🌊', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      const Text('Aucune prise publiée pour l\'instant',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Va dans ta collection et publie une prise !',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: catches.asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _FeedCard(catch_: e.value)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 60 * e.key))
                      .slideY(begin: 0.06, end: 0),
                ),
              ).toList(),
            );
          },
        ),
      ],
    );
  }

  // ── Top pêcheurs ───────────────────────────────────────────────────
  Widget _buildTopFishers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Pêcheurs',
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _topStream,
          builder: (context, snap) {
            final fishers = snap.data ?? [];
            if (fishers.isEmpty) {
              return Column(
                children: _staticTopFishers()
                    .asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: e.value.animate().fadeIn(delay: Duration(milliseconds: 80 * e.key)).slideX(begin: 0.06, end: 0),
                  ),
                ).toList(),
              );
            }
            return Column(
              children: fishers.asMap().entries.map((e) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildFisherTile(e.key, e.value)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 80 * e.key))
                      .slideX(begin: 0.06, end: 0),
                ),
              ).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFisherTile(int index, Map<String, dynamic> f) {
    final name     = f['displayName'] as String? ?? 'Pêcheur';
    final username = f['username']    as String? ?? '';
    final count    = (f['catchCount'] as num?)?.toInt() ?? 0;
    final rank     = index + 1;
    final rankColor = rank == 1 ? FishdexTheme.golden
        : rank == 2 ? FishdexTheme.textSecondary
        : FishdexTheme.coral;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor.withOpacity(0.12),
                border: Border.all(color: rankColor.withOpacity(0.3), width: 1.5),
              ),
              child: Center(child: Text('$rank',
                style: TextStyle(color: rankColor, fontSize: 14, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 12),
            const Text('🎣', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (username.isNotEmpty)
                    Text('@$username',
                      style: const TextStyle(color: FishdexTheme.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.star_fill, color: FishdexTheme.golden, size: 11),
                      const SizedBox(width: 3),
                      Text('$count prise${count > 1 ? "s" : ""}',
                        style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _staticTopFishers() => [
    _staticFisherTile(1, '@leBrochet',     2847, FishdexTheme.golden),
    _staticFisherTile(2, '@mariePêche',    2561, FishdexTheme.textSecondary),
    _staticFisherTile(3, '@surfcaster33',  2340, FishdexTheme.coral),
  ];

  Widget _staticFisherTile(int rank, String name, int pts, Color color) =>
    GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
              child: Center(child: Text('$rank', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)))),
            const SizedBox(width: 12),
            const Text('🎣', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Row(children: [
                const Icon(CupertinoIcons.star_fill, color: FishdexTheme.golden, size: 11),
                const SizedBox(width: 3),
                Text('$pts pts', style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
              ]),
            ])),
          ],
        ),
      ),
    );

  // ── Mes prises récentes ────────────────────────────────────────────
  Widget _buildMyRecent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mes prises récentes',
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        StreamBuilder<List<FishCatch>>(
          stream: _recentStream ?? Stream.value([]),
          builder: (context, snap) {
            if (!AuthService.isLoggedIn) {
              return GlassCard(
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Text('🔒', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 12),
                      Expanded(child: Text('Connecte-toi pour voir tes prises récentes',
                        style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13))),
                    ],
                  ),
                ),
              );
            }
            final catches = snap.data ?? [];
            if (catches.isEmpty) {
              return GlassCard(
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Aucune prise pour l\'instant. Utilise la caméra !',
                    style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center),
                ),
              );
            }
            return SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: catches.map((c) => _buildRecentTile(c)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentTile(FishCatch c) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: c)),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: GlassCard(
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: double.infinity, height: 60, child: _catchThumb(c)),
                ),
                const Spacer(),
                Text(c.frenchName,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                if (c.weightkg != null)
                  Text('${c.weightkg} kg',
                    style: const TextStyle(color: FishdexTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(_ago(c.timestamp),
                  style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 9)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _catchThumb(FishCatch c) {
    if (c.imageBase64 != null && c.imageBase64!.isNotEmpty) {
      try { return Image.memory(base64Decode(c.imageBase64!), fit: BoxFit.cover, width: double.infinity); } catch (_) {}
    }
    if (c.fishImageUrl != null) return Image.network(c.fishImageUrl!, fit: BoxFit.cover, width: double.infinity);
    return Container(color: FishdexTheme.primary.withOpacity(0.07),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 26))));
  }

  // ── Mes succès ────────────────────────────────────────────────────
  Widget _buildMyAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mes succès',
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        StreamBuilder<List<FishCatch>>(
          stream: _statsStream ?? Stream.value([]),
          builder: (context, snap) {
            if (!AuthService.isLoggedIn) {
              return GlassCard(child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(children: [
                  Text('🔒', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 10),
                  Text('Connecte-toi pour voir tes succès',
                    style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
                ]),
              ));
            }
            final catches   = snap.data ?? [];
            final total     = catches.length;
            final species   = catches.map((c) => c.species).toSet().length;
            final achv = [
              _AchievementDef('🎣', 'Premier Lancer', total >= 1),
              _AchievementDef('📖', 'Collectionneur', total >= 5),
              _AchievementDef('🔬', 'Explorateur',    species >= 3),
              _AchievementDef('🏆', 'Légende',         total >= 10),
              _AchievementDef('🌊', 'Maître',          species >= 10),
            ];
            return SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: achv.map((a) => _achievementBadge(a)).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _achievementBadge(_AchievementDef a) {
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: a.unlocked
            ? FishdexTheme.golden.withOpacity(0.08)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: a.unlocked
              ? FishdexTheme.golden.withOpacity(0.3)
              : Colors.black.withOpacity(0.06)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(a.unlocked ? a.emoji : '🔒', style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(a.label, textAlign: TextAlign.center, maxLines: 2,
          style: TextStyle(
            color: a.unlocked ? FishdexTheme.golden : FishdexTheme.textTertiary,
            fontSize: 9, fontWeight: a.unlocked ? FontWeight.w700 : FontWeight.w400)),
      ]),
    );
  }

  // ── Hot Spots ──────────────────────────────────────────────────────
  static const _hotSpots = [
    _HotSpot('Lac de Sainte-Croix', 'Truite, Brochet', 4.8, 43.7754, 6.1488),
    _HotSpot('Étang de Berre',      'Carpe, Anguille',  4.5, 43.4531, 5.1714),
    _HotSpot('Rivière Arc',         'Sandre, Perche',   4.2, 43.5298, 5.4380),
  ];

  Widget _buildHotSpots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Hot Spots',
              style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: FishdexTheme.coral.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FishdexTheme.coral.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(CupertinoIcons.flame_fill, color: FishdexTheme.coral, size: 12),
                SizedBox(width: 4),
                Text('Actif', style: TextStyle(color: FishdexTheme.coral, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(_hotSpots.length, (i) => Column(
                children: [
                  if (i > 0) Divider(color: Colors.black.withOpacity(0.05), height: 20),
                  _hotSpotRow(_hotSpots[i]),
                ],
              )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hotSpotRow(_HotSpot spot) {
    return GestureDetector(
      onTap: () => _openMap(spot),
      child: Row(children: [
        Container(width: 42, height: 42,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: FishdexTheme.primary.withOpacity(0.08)),
          child: const Center(child: Text('📍', style: TextStyle(fontSize: 20)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(spot.name, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(spot.fish, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
        ])),
        Row(children: [
          const Icon(CupertinoIcons.star_fill, color: FishdexTheme.golden, size: 12),
          const SizedBox(width: 3),
          Text('${spot.rating}', style: const TextStyle(color: FishdexTheme.golden, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.map, color: FishdexTheme.primary, size: 16),
        ]),
      ]),
    );
  }

  Future<void> _openMap(_HotSpot spot) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(spot.name)}&center=${spot.lat},${spot.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Notifications sheet ────────────────────────────────────────────
  void _showNotifications(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            const Text('🔔', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            const Text('Notifications', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Connecte-toi pour voir tes notifications', textAlign: TextAlign.center,
              style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(height: 50,
                decoration: BoxDecoration(color: FishdexTheme.primary, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
            )),
            const SizedBox(height: 8),
          ]),
        ),
      );
      return;
    }
    SocialService.markAllRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays    < 7)  return 'Il y a ${diff.inDays}j';
    const m = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

// ── Feed card avec likes/commentaires ────────────────────────────────
class _FeedCard extends StatelessWidget {
  final FishCatch catch_;
  const _FeedCard({required this.catch_});

  @override
  Widget build(BuildContext context) {
    final isLiked  = catch_.likedBy.contains(AuthService.currentUserId);
    final likesCnt = catch_.likedBy.length;
    final commentsCnt = catch_.commentsCount;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: catch_)),
      ),
      child: GlassCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auteur + date
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00C6E0)]),
                    ),
                    child: const Center(child: Text('🎣', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(catch_.userName,
                        style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                      if (catch_.userHandle.isNotEmpty)
                        Text('@${catch_.userHandle}',
                          style: const TextStyle(color: FishdexTheme.primary, fontSize: 10, fontWeight: FontWeight.w500)),
                      Text(_ago(catch_.timestamp),
                        style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catch_.isPrivate
                          ? FishdexTheme.golden.withOpacity(0.10)
                          : FishdexTheme.mint.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(catch_.isPrivate ? '🔒 Privé' : '🌍 Public',
                      style: TextStyle(
                        color: catch_.isPrivate ? FishdexTheme.golden : FishdexTheme.mint,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // Photo
            if (catch_.imageBase64 != null || catch_.fishImageUrl != null)
              SizedBox(height: 200, width: double.infinity, child: _photo()),

            // Infos + likes/commentaires
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catch_.frenchName,
                    style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(catch_.species,
                    style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    if (catch_.location != null) _chip('📍 ${catch_.location!}', FishdexTheme.primary),
                    if (catch_.weightkg != null) _chip('⚖️ ${catch_.weightkg} kg', FishdexTheme.mint),
                    if (catch_.sizecm   != null) _chip('📏 ${catch_.sizecm} cm',   FishdexTheme.coral),
                  ]),
                  if (catch_.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(catch_.notes!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
                  ],

                  // Séparateur + likes/commentaires
                  const SizedBox(height: 12),
                  Divider(color: Colors.black.withOpacity(0.05), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Like
                      GestureDetector(
                        onTap: () {
                          if (!AuthService.isLoggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Connecte-toi pour liker'),
                              duration: Duration(seconds: 2)));
                            return;
                          }
                          if (catch_.id != null) {
                            SocialService.toggleLike(catch_.id!, catch_.userId, catch_.frenchName);
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                              color: isLiked ? FishdexTheme.coral : FishdexTheme.textTertiary,
                              size: 20),
                            const SizedBox(width: 5),
                            Text('$likesCnt',
                              style: TextStyle(
                                color: isLiked ? FishdexTheme.coral : FishdexTheme.textTertiary,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Commentaire
                      GestureDetector(
                        onTap: () {
                          if (catch_.id == null) return;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _CommentsSheet(
                              catchId: catch_.id!,
                              ownerUserId: catch_.userId,
                              catchName: catch_.frenchName,
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.chat_bubble, color: FishdexTheme.textTertiary, size: 19),
                            const SizedBox(width: 5),
                            Text('$commentsCnt',
                              style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo() {
    if (catch_.imageBase64 != null && catch_.imageBase64!.isNotEmpty) {
      try { return Image.memory(base64Decode(catch_.imageBase64!), fit: BoxFit.cover, width: double.infinity); } catch (_) {}
    }
    if (catch_.fishImageUrl != null) return Image.network(catch_.fishImageUrl!, fit: BoxFit.cover, width: double.infinity);
    return Container(color: FishdexTheme.primary.withOpacity(0.06),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 48))));
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays    < 7)  return 'Il y a ${diff.inDays}j';
    const m = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

// ── Feuille de commentaires ──────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final String catchId, ownerUserId, catchName;
  const _CommentsSheet({required this.catchId, required this.ownerUserId, required this.catchName});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl    = TextEditingController();
  bool  _sending = false;
  // edit mode
  String? _editingId;
  final _editCtrl = TextEditingController();

  Future<void> _send() async {
    if (!AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecte-toi pour commenter')));
      return;
    }
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final err = await SocialService.addComment(
        widget.catchId, _ctrl.text,
        ownerUserId: widget.ownerUserId,
        catchName: widget.catchName,
      );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $err'), backgroundColor: FishdexTheme.coral));
      } else {
        _ctrl.clear();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _saveEdit(String commentId) async {
    if (_editCtrl.text.trim().isEmpty) return;
    final err = await SocialService.editComment(
        widget.catchId, commentId, _editCtrl.text);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $err'), backgroundColor: FishdexTheme.coral));
    } else {
      if (mounted) setState(() => _editingId = null);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final err = await SocialService.deleteComment(widget.catchId, commentId);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $err'), backgroundColor: FishdexTheme.coral));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); _editCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Commentaires', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.black.withOpacity(0.06)),
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: SocialService.commentsStream(widget.catchId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erreur: ${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FishdexTheme.coral, fontSize: 13))));
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Text('Aucun commentaire\nSois le premier !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 14)));
                }
                return ListView.builder(
                  itemCount: comments.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemBuilder: (_, i) {
                    final c   = comments[i];
                    final own = c.userId == AuthService.currentUserId;
                    if (_editingId == c.id) {
                      return _editRow(c);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 32, height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary.withOpacity(0.10)),
                            child: const Center(child: Text('🎣', style: TextStyle(fontSize: 16)))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(c.userName, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text(_ago(c.timestamp), style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
                            ]),
                            Text(c.text, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
                          ])),
                          if (own) ...[
                            GestureDetector(
                              onTap: () => setState(() {
                                _editingId = c.id;
                                _editCtrl.text = c.text;
                              }),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(CupertinoIcons.pencil, color: FishdexTheme.primary, size: 15))),
                            GestureDetector(
                              onTap: () => _deleteComment(c.id),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(CupertinoIcons.trash, color: FishdexTheme.coral, size: 15))),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.black.withOpacity(0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire…',
                        hintStyle: TextStyle(color: FishdexTheme.textTertiary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 14, color: FishdexTheme.textPrimary),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _sending ? FishdexTheme.primary.withOpacity(0.5) : FishdexTheme.primary),
                    child: _sending
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editRow(Comment c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: FishdexTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FishdexTheme.primary.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _editCtrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: FishdexTheme.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _saveEdit(c.id),
          child: Container(width: 32, height: 32,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary),
            child: const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 14))),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => setState(() => _editingId = null),
          child: Container(width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.06)),
            child: const Icon(CupertinoIcons.xmark, color: FishdexTheme.textSecondary, size: 14))),
      ]),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours   < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

// ── Feuille de notifications ─────────────────────────────────────────
class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(28))),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('🔔', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Notifications', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
          ),
          Divider(height: 20, color: Colors.black.withOpacity(0.06)),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: SocialService.notificationsStream(),
              builder: (context, snap) {
                final notifs = snap.data ?? [];
                if (notifs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎣', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 8),
                        Text('Aucune notification pour l\'instant',
                          style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: notifs.length,
                  itemBuilder: (context, i) {
                    final n = notifs[i];
                    final isLike = n.type == 'like';
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final catch_ = await CatchService.getById(n.catchId);
                        if (catch_ != null && context.mounted) {
                          Navigator.push(context,
                              CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: catch_)));
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.read ? Colors.transparent : FishdexTheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 36, height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (isLike ? FishdexTheme.coral : FishdexTheme.primary).withOpacity(0.10)),
                              child: Center(child: Text(isLike ? '❤️' : '💬',
                                style: const TextStyle(fontSize: 16)))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              RichText(text: TextSpan(
                                style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 13),
                                children: [
                                  TextSpan(text: n.fromUserName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  TextSpan(text: isLike ? ' a aimé ta prise ' : ' a commenté ta prise '),
                                  TextSpan(text: n.catchName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              )),
                              if (n.commentText != null)
                                Text('« ${n.commentText} »',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
                            ])),
                            if (!n.read)
                              Container(width: 8, height: 8,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HotSpot {
  final String name, fish;
  final double rating, lat, lng;
  const _HotSpot(this.name, this.fish, this.rating, this.lat, this.lng);
}

class _AchievementDef {
  final String emoji, label;
  final bool unlocked;
  const _AchievementDef(this.emoji, this.label, this.unlocked);
}
