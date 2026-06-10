import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;

  static const _collection = [
    _Fish('Brochet', '🐟', 4, false),
    _Fish('Truite', '🐠', 3, true),
    _Fish('Carpe', '🐡', 5, false),
    _Fish('Bar', '🦈', 3, false),
    _Fish('Sandre', '🐟', 4, false),
    _Fish('Perche', '🐠', 2, true),
    _Fish('Anguille', '🐍', 5, true),
    _Fish('Tanche', '🐡', 1, false),
    _Fish('???', '❓', 0, false),
    _Fish('???', '❓', 0, false),
    _Fish('???', '❓', 0, false),
    _Fish('???', '❓', 0, false),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildProfileHeader()),
        SliverToBoxAdapter(child: _buildStats()),
        SliverToBoxAdapter(child: _buildTabBar()),
        if (_tab == 0) _buildCollectionGrid(),
        if (_tab == 1) _buildAchievements(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          // Fond subtil
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFDCEEFB), Color(0xFFF0F6FF)],
              ),
            ),
          ),
          // Cercles décoratifs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FishdexTheme.primary.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      const Text(
                        'Mon Profil',
                        style: TextStyle(
                          color: FishdexTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 40,
                          height: 40,
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
                          child: const Icon(CupertinoIcons.settings,
                              color: FishdexTheme.textPrimary, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: FishdexTheme.primary.withOpacity(0.30),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎣', style: TextStyle(fontSize: 44)),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: FishdexTheme.golden,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text('12',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Alex Pêcheur',
                  style: TextStyle(
                    color: FishdexTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const Text(
                  '@alex_fish · Marseille 🌊',
                  style: TextStyle(
                      color: FishdexTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _followStat('842', 'Abonnés'),
                    Container(
                        width: 1,
                        height: 24,
                        color: Colors.black.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 24)),
                    _followStat('234', 'Abonnements'),
                    Container(
                        width: 1,
                        height: 24,
                        color: Colors.black.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 24)),
                    _followStat('67', 'Espèces'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _followStat(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(
                color: FishdexTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          _statCard('127', 'Prises', '🎣', FishdexTheme.primary),
          const SizedBox(width: 10),
          _statCard('8,4 kg', 'Record', '🏆', FishdexTheme.golden),
          const SizedBox(width: 10),
          _statCard('67/200', 'Dex', '📖', FishdexTheme.coral),
        ],
      ),
    );
  }

  Widget _statCard(String val, String label, String icon, Color color) {
    return Expanded(
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(val,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              Text(label,
                  style: const TextStyle(
                      color: FishdexTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GlassCard(
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _tabBtn('Ma Collection', 0),
              _tabBtn('Succès', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int i) {
    final selected = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? FishdexTheme.primary : Colors.transparent,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: FishdexTheme.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : FishdexTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final fish = _collection[i];
            final locked = fish.name == '???';
            return Padding(
              padding: const EdgeInsets.all(4),
              child: GlassCard(
                radius: 18,
                borderColor: fish.isRare
                    ? FishdexTheme.golden.withOpacity(0.4)
                    : null,
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            locked ? '❓' : fish.emoji,
                            style: TextStyle(
                                fontSize: 32,
                                color: locked ? null : null),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fish.name,
                            style: TextStyle(
                              color: locked
                                  ? FishdexTheme.textTertiary
                                  : FishdexTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!locked && fish.stars > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                fish.stars,
                                (_) => const Icon(CupertinoIcons.star_fill,
                                    color: FishdexTheme.golden, size: 8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (fish.isRare && !locked)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: FishdexTheme.golden.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('★',
                              style: TextStyle(
                                  color: FishdexTheme.golden, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 40 * i))
                .scale(begin: const Offset(0.88, 0.88));
          },
          childCount: _collection.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.85,
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      _Achievement('Premier Lancer', 'Votre première prise !', '🎣', true),
      _Achievement('Chasseur du Brochet', 'Attrapez 10 brochets', '🏹', true),
      _Achievement('Noctambule', 'Pêche de nuit réussie', '🌙', true),
      _Achievement('Légende des Lacs', 'Attrapez 50 espèces', '🏆', false),
      _Achievement('Maître Carpe', 'Record de taille', '🐡', false),
    ];
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              borderColor: achievements[i].unlocked
                  ? FishdexTheme.golden.withOpacity(0.3)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: achievements[i].unlocked
                            ? FishdexTheme.golden.withOpacity(0.12)
                            : Colors.black.withOpacity(0.04),
                      ),
                      child: Center(
                        child: Text(
                          achievements[i].unlocked
                              ? achievements[i].emoji
                              : '🔒',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievements[i].title,
                            style: TextStyle(
                              color: achievements[i].unlocked
                                  ? FishdexTheme.textPrimary
                                  : FishdexTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            achievements[i].desc,
                            style: const TextStyle(
                                color: FishdexTheme.textSecondary,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (achievements[i].unlocked)
                      const Icon(CupertinoIcons.checkmark_circle_fill,
                          color: FishdexTheme.golden, size: 20),
                  ],
                ),
              ),
            ),
          ),
          childCount: achievements.length,
        ),
      ),
    );
  }
}

class _Fish {
  final String name, emoji;
  final int stars;
  final bool isRare;
  const _Fish(this.name, this.emoji, this.stars, this.isRare);
}

class _Achievement {
  final String title, desc, emoji;
  final bool unlocked;
  const _Achievement(this.title, this.desc, this.emoji, this.unlocked);
}
