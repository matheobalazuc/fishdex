import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

// Profil demo fixe
const _kName     = 'Alex Pêcheur';
const _kUsername = '@alex_fish';
const _kLocation = 'Nice 🌊';
const _kLevel    = 12;

// Version app
const _kVersion     = '1.0.0';
const _kBuildDate   = '10/06/2026';
const _kUpdateTime  = '14:32';

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
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildStats()),
        SliverToBoxAdapter(child: _buildTabBar()),
        if (_tab == 0) _buildCollectionGrid(),
        if (_tab == 1) _buildAchievements(),
        SliverToBoxAdapter(child: _buildVersionFooter()),
      ],
    );
  }

  // ── Header profil ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: FishdexTheme.primary.withOpacity(0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎣', style: TextStyle(fontSize: 44)),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FishdexTheme.golden,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text('$_kLevel',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(_kName,
            style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text('$_kUsername · $_kLocation',
            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
          // Badge demo
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FishdexTheme.golden.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FishdexTheme.golden.withOpacity(0.25)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.star_fill, color: FishdexTheme.golden, size: 11),
                SizedBox(width: 4),
                Text('Maître Pêcheur · Démo',
                  style: TextStyle(color: FishdexTheme.golden, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats suiveurs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _followStat('842', 'Abonnés'),
              _divider(),
              _followStat('234', 'Abonnements'),
              _divider(),
              _followStat('67', 'Espèces'),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _followStat(String n, String lbl) => Column(
    children: [
      Text(n, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
      Text(lbl, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 11)),
    ],
  );

  Widget _divider() => Container(
    width: 1, height: 24,
    color: Colors.black.withOpacity(0.08),
    margin: const EdgeInsets.symmetric(horizontal: 24),
  );

  // ── Stats cards ───────────────────────────────────────────────────
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
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GlassCard(
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(children: [_tabBtn('Ma Collection', 0), _tabBtn('Succès', 1)]),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int i) {
    final sel = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: sel ? FishdexTheme.primary : Colors.transparent,
            boxShadow: sel
                ? [BoxShadow(color: FishdexTheme.primary.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: Center(
            child: Text(label,
              style: TextStyle(color: sel ? Colors.white : FishdexTheme.textSecondary,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400, fontSize: 14)),
          ),
        ),
      ),
    );
  }

  // ── Collection grid ───────────────────────────────────────────────
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
                borderColor: fish.isRare ? FishdexTheme.golden.withOpacity(0.4) : null,
                child: Stack(children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(locked ? '❓' : fish.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 4),
                        Text(fish.name,
                          style: TextStyle(
                            color: locked ? FishdexTheme.textTertiary : FishdexTheme.textPrimary,
                            fontSize: 10, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center),
                        if (!locked && fish.stars > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(fish.stars,
                              (_) => const Icon(CupertinoIcons.star_fill, color: FishdexTheme.golden, size: 8)),
                          ),
                      ],
                    ),
                  ),
                  if (fish.isRare && !locked)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: FishdexTheme.golden.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: const Text('★', style: TextStyle(color: FishdexTheme.golden, fontSize: 10)),
                      ),
                    ),
                ]),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 40 * i))
                .scale(begin: const Offset(0.88, 0.88));
          },
          childCount: _collection.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.85),
      ),
    );
  }

  // ── Achievements ──────────────────────────────────────────────────
  Widget _buildAchievements() {
    final list = [
      _Achievement('Premier Lancer', 'Votre première prise !', '🎣', true),
      _Achievement('Chasseur du Brochet', 'Attrapez 10 brochets', '🏹', true),
      _Achievement('Noctambule', 'Pêche de nuit réussie', '🌙', true),
      _Achievement('Légende des Lacs', 'Attrapez 50 espèces', '🏆', false),
      _Achievement('Maître Carpe', 'Record de taille', '🐡', false),
    ];
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              borderColor: list[i].unlocked ? FishdexTheme.golden.withOpacity(0.3) : null,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: list[i].unlocked
                          ? FishdexTheme.golden.withOpacity(0.12)
                          : Colors.black.withOpacity(0.04),
                    ),
                    child: Center(child: Text(list[i].unlocked ? list[i].emoji : '🔒',
                      style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(list[i].title,
                        style: TextStyle(
                          color: list[i].unlocked ? FishdexTheme.textPrimary : FishdexTheme.textSecondary,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(list[i].desc,
                        style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
                    ],
                  )),
                  if (list[i].unlocked)
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: FishdexTheme.golden, size: 20),
                ]),
              ),
            ),
          ),
          childCount: list.length,
        ),
      ),
    );
  }

  // ── Footer version ────────────────────────────────────────────────
  Widget _buildVersionFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
      child: Column(children: [
        Divider(color: Colors.black.withOpacity(0.06)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00C6E0)]),
            ),
            child: const Center(child: Text('🐟', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          const Text('Fishdex', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text('Version $_kVersion', style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 2),
        Text('Mis à jour le $_kBuildDate à $_kUpdateTime',
          style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
        const SizedBox(height: 12),
        Text('Mode démo · Compte: demo_user',
          style: TextStyle(color: FishdexTheme.textTertiary.withOpacity(0.7), fontSize: 10)),
      ]),
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
