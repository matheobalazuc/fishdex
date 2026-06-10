import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/catch_model.dart';
import '../services/catch_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';
import 'catch_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _buildActivityBanner(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildStarRankingSection(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: _buildRecentCatches(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _buildHotSpots(),
          ),
        ),
        _buildFeedSection(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      expandedHeight: 180,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FishdexTheme.golden.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: FishdexTheme.golden.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.star_fill,
                            color: FishdexTheme.golden, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Niveau 12 — Maître Pêcheur',
                          style: TextStyle(
                            color: FishdexTheme.golden,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bonjour, Alex 🎣',
                    style: TextStyle(
                      color: FishdexTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '3 nouvelles prises ce mois-ci',
                    style: TextStyle(
                      color: FishdexTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                    ),
                  ),
                  child: const Center(
                    child: Text('🐟', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Fishdex',
                  style: TextStyle(
                    color: FishdexTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.bell,
              color: FishdexTheme.textPrimary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityBanner() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(child: Text('🎯', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Objectif hebdo',
                    style: TextStyle(
                      color: FishdexTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: FishdexTheme.primary.withOpacity(0.12),
                      color: FishdexTheme.primary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '5/8 prises · encore 3 pour le badge',
                    style: TextStyle(
                      color: FishdexTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '65%',
              style: TextStyle(
                color: FishdexTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStarRankingSection() {
    final topFishers = [
      _Fisher('@leBrochet', 2847, '🎣', FishdexTheme.golden, 1),
      _Fisher('@mariePêche', 2561, '🐟', FishdexTheme.textSecondary, 2),
      _Fisher('@surfcaster33', 2340, '🎣', FishdexTheme.coral, 3),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Pêcheurs',
              style: TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: FishdexTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...topFishers.asMap().entries.map((e) {
          final fisher = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fisher.color.withOpacity(0.12),
                        border: Border.all(
                            color: fisher.color.withOpacity(0.3), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${fisher.rank}',
                          style: TextStyle(
                            color: fisher.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(fisher.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fisher.name,
                            style: const TextStyle(
                              color: FishdexTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.star_fill,
                                  color: FishdexTheme.golden, size: 11),
                              const SizedBox(width: 3),
                              Text(
                                '${fisher.score} pts',
                                style: const TextStyle(
                                  color: FishdexTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: FishdexTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: FishdexTheme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Text(
                        'Suivre',
                        style: TextStyle(
                          color: FishdexTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 80 * e.key))
              .slideX(begin: 0.08, end: 0);
        }),
      ],
    );
  }

  Widget _buildRecentCatches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prises récentes',
          style: TextStyle(
            color: FishdexTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCatchCard('🐟', 'Brochet', '4.2 kg', 'Il y a 2h', FishdexTheme.primary),
              _buildCatchCard('🦈', 'Bar', '2.8 kg', 'Hier', FishdexTheme.mint),
              _buildCatchCard('🐠', 'Truite', '1.5 kg', 'Il y a 2j', FishdexTheme.golden),
              _buildCatchCard('🐡', 'Carpe', '6.1 kg', 'Il y a 3j', FishdexTheme.coral),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatchCard(String emoji, String name, String weight, String time, Color accent) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const Spacer(),
              Text(
                name,
                style: const TextStyle(
                  color: FishdexTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                weight,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: FishdexTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotSpots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hot Spots',
              style: TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: FishdexTheme.coral.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FishdexTheme.coral.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.flame_fill,
                      color: FishdexTheme.coral, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Actif',
                    style: TextStyle(
                      color: FishdexTheme.coral,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHotSpotRow('Lac de Sainte-Croix', 'Truite, Brochet', 4.8),
                Divider(color: Colors.black.withOpacity(0.05), height: 20),
                _buildHotSpotRow('Étang de Berre', 'Carpe, Anguille', 4.5),
                Divider(color: Colors.black.withOpacity(0.05), height: 20),
                _buildHotSpotRow('Rivière Arc', 'Sandre, Perche', 4.2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHotSpotRow(String name, String fish, double rating) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: FishdexTheme.primary.withOpacity(0.08),
          ),
          child: const Center(child: Text('📍', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: FishdexTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(fish,
                  style: const TextStyle(
                      color: FishdexTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Row(
          children: [
            const Icon(CupertinoIcons.star_fill,
                color: FishdexTheme.golden, size: 12),
            const SizedBox(width: 3),
            Text(
              rating.toString(),
              style: const TextStyle(
                  color: FishdexTheme.golden,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

  // ── Fil des prises publiées ────────────────────────────────────────
  Widget _buildFeedSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fil des prises',
              style: TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
            const SizedBox(height: 12),
            StreamBuilder<List<FishCatch>>(
              stream: CatchService.feedStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CupertinoActivityIndicator(),
                    ),
                  );
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
                  children: catches.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _FeedCard(catch_: e.value)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 60 * e.key))
                          .slideY(begin: 0.08, end: 0),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte fil social ──────────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  final FishCatch catch_;
  const _FeedCard({required this.catch_});

  @override
  Widget build(BuildContext context) {
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                      ),
                    ),
                    child: const Center(child: Text('🎣', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _authorName(catch_),
                          style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(_ago(catch_.timestamp),
                          style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catch_.isPrivate
                          ? FishdexTheme.golden.withOpacity(0.10)
                          : FishdexTheme.mint.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catch_.isPrivate ? '🔒 Privé' : '🌍 Public',
                      style: TextStyle(
                        color: catch_.isPrivate ? FishdexTheme.golden : FishdexTheme.mint,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // Photo
            if (catch_.imageBase64 != null || catch_.fishImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: SizedBox(
                  height: 200, width: double.infinity,
                  child: _photo(),
                ),
              ),

            // Infos
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (catch_.location != null)
                        _chip('📍 ${catch_.location!}', FishdexTheme.primary),
                      if (catch_.weightkg != null)
                        _chip('⚖️ ${catch_.weightkg} kg', FishdexTheme.mint),
                      if (catch_.sizecm != null)
                        _chip('📏 ${catch_.sizecm} cm', FishdexTheme.coral),
                    ],
                  ),
                  if (catch_.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(catch_.notes!,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
                  ],
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
      try {
        return Image.memory(base64Decode(catch_.imageBase64!), fit: BoxFit.cover, width: double.infinity);
      } catch (_) {}
    }
    if (catch_.fishImageUrl != null) {
      return Image.network(catch_.fishImageUrl!, fit: BoxFit.cover, width: double.infinity);
    }
    return Container(
      color: FishdexTheme.primary.withOpacity(0.06),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 48))),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  String _authorName(FishCatch c) =>
      c.userId == CatchService.userId ? CatchService.userName : c.userId;

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7)     return 'Il y a ${diff.inDays}j';
    const m = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

class _Fisher {
  final String name;
  final int score;
  final String emoji;
  final Color color;
  final int rank;
  const _Fisher(this.name, this.score, this.emoji, this.color, this.rank);
}
