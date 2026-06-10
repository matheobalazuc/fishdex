import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: _buildHotSpots(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Ocean gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FishdexTheme.waterSurface,
                    FishdexTheme.deepOcean,
                    FishdexTheme.abyss,
                  ],
                ),
              ),
            ),
            // Ripple circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FishdexTheme.bioluminescent.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FishdexTheme.bioluminescent.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FishdexTheme.goldenScales.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: FishdexTheme.goldenScales.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.star_fill,
                              color: FishdexTheme.goldenScales,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Niveau 12 — Maître Pêcheur',
                              style: TextStyle(
                                color: FishdexTheme.goldenScales,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bonjour, Alex 🎣',
                    style: TextStyle(
                      color: FishdexTheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '3 nouveaux poissons ce mois-ci',
                    style: TextStyle(
                      color: FishdexTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      title: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: FishdexTheme.bioluminescent,
              ),
              child: const Center(
                child: Text('🐟', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Fishdex',
              style: TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.bell, color: FishdexTheme.textPrimary),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStarRankingSection() {
    final topFishers = [
      _Fisher('@leBrochet', 2847, '🎣', FishdexTheme.goldenScales, 1),
      _Fisher('@mariePêche', 2561, '🐟', FishdexTheme.textSecondary, 2),
      _Fisher('@surfcaster33', 2340, '🎣', FishdexTheme.coralAccent, 3),
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
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: FishdexTheme.bioluminescent,
                  fontSize: 13,
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
                        color: fisher.color.withOpacity(0.15),
                        border: Border.all(
                            color: fisher.color.withOpacity(0.4), width: 1.5),
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
                                  color: FishdexTheme.goldenScales, size: 11),
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
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FishdexTheme.bioluminescent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Suivre',
                        style: TextStyle(
                          color: FishdexTheme.bioluminescent,
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
              .fadeIn(delay: Duration(milliseconds: 100 * e.key))
              .slideX(begin: 0.1, end: 0);
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
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCatchCard('🐟', 'Brochet', '4.2 kg', 'Il y a 2h'),
              _buildCatchCard('🦈', 'Bar', '2.8 kg', 'Hier'),
              _buildCatchCard('🐠', 'Truite', '1.5 kg', 'Il y a 2j'),
              _buildCatchCard('🐡', 'Carpe', '6.1 kg', 'Il y a 3j'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatchCard(
      String emoji, String name, String weight, String time) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FishdexTheme.waterSurface.withOpacity(0.6),
            FishdexTheme.deepOcean.withOpacity(0.8),
          ],
        ),
        border: Border.all(
          color: FishdexTheme.glassBorder,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const Spacer(),
                Text(
                  name,
                  style: const TextStyle(
                    color: FishdexTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weight,
                  style: const TextStyle(
                    color: FishdexTheme.goldenScales,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: FishdexTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
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
              '🗺️ Hot Spots',
              style: TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: FishdexTheme.coralAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: FishdexTheme.coralAccent.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.flame_fill,
                      color: FishdexTheme.coralAccent, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Actif',
                    style: TextStyle(
                      color: FishdexTheme.coralAccent,
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
                const Divider(color: FishdexTheme.glassBorder, height: 20),
                _buildHotSpotRow('Étang de Berre', 'Carpe, Anguille', 4.5),
                const Divider(color: FishdexTheme.glassBorder, height: 20),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: FishdexTheme.waterSurface,
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
                color: FishdexTheme.goldenScales, size: 12),
            const SizedBox(width: 3),
            Text(
              rating.toString(),
              style: const TextStyle(
                  color: FishdexTheme.goldenScales,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
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