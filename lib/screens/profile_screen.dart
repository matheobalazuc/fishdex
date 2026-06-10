import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/catch_model.dart';
import '../services/catch_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';
import 'catch_detail_screen.dart';

const _kName      = 'Alex Pêcheur';
const _kUsername  = '@alex_fish';
const _kLocation  = 'Nice 🌊';
const _kLevel     = 12;
const _kVersion   = '1.0.0';
const _kBuildDate = '10/06/2026';
const _kUpdateTime = '14:32';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FishCatch>>(
      stream: CatchService.stream(),
      builder: (context, snap) {
        final catches = snap.data ?? [];
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(catches)),
            SliverToBoxAdapter(child: _buildStats(catches)),
            SliverToBoxAdapter(child: _buildTabBar()),
            if (_tab == 0) _buildCollectionGrid(catches),
            if (_tab == 1) _buildAchievements(catches),
            SliverToBoxAdapter(child: _buildVersionFooter()),
          ],
        );
      },
    );
  }

  // ── Header profil ─────────────────────────────────────────────────
  Widget _buildHeader(List<FishCatch> catches) {
    final speciesCount = catches.map((c) => c.species).toSet().length;
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
              _followStat('$speciesCount', 'Espèces'),
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
  Widget _buildStats(List<FishCatch> catches) {
    final species = catches.map((c) => c.species).toSet().length;
    final bestWeight = catches
        .where((c) => c.weightkg != null)
        .map((c) => c.weightkg!)
        .fold<double?>(null, (best, w) => best == null || w > best ? w : best);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          _statCard('${catches.length}', 'Prises', '🎣', FishdexTheme.primary),
          const SizedBox(width: 10),
          _statCard(bestWeight != null ? '${bestWeight}kg' : '—', 'Record', '🏆', FishdexTheme.golden),
          const SizedBox(width: 10),
          _statCard('$species', 'Espèces', '📖', FishdexTheme.coral),
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

  // ── Collection grid (vraies données Firestore) ────────────────────
  Widget _buildCollectionGrid(List<FishCatch> catches) {
    if (catches.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Text('🎣', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Aucune prise enregistrée',
                style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 15)),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final c = catches[i];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: c)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: GlassCard(
                  radius: 18,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: _catchThumb(c),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                        child: Column(
                          children: [
                            Text(c.frenchName,
                              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                              style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
                            Text('${(c.confidence * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 40 * i))
                .scale(begin: const Offset(0.88, 0.88));
          },
          childCount: catches.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 0.78),
      ),
    );
  }

  Widget _catchThumb(FishCatch c) {
    if (c.imageBase64 != null && c.imageBase64!.isNotEmpty) {
      try {
        return Image.memory(base64Decode(c.imageBase64!), fit: BoxFit.cover, width: double.infinity);
      } catch (_) {}
    }
    if (c.fishImageUrl != null) {
      return Image.network(c.fishImageUrl!, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => _thumbFallback());
    }
    return _thumbFallback();
  }

  Widget _thumbFallback() => Container(
    color: FishdexTheme.primary.withOpacity(0.06),
    child: const Center(child: Text('🐟', style: TextStyle(fontSize: 22))),
  );

  // ── Achievements (basés sur vraies données) ───────────────────────
  Widget _buildAchievements(List<FishCatch> catches) {
    final list = [
      _Achievement('Premier Lancer', 'Ta première prise !', '🎣', catches.isNotEmpty),
      _Achievement('Collectionneur', '5 prises enregistrées', '📖', catches.length >= 5),
      _Achievement('Explorateur', 'Identifie 3 espèces différentes', '🔬', catches.map((c) => c.species).toSet().length >= 3),
      _Achievement('Légende', '10 prises enregistrées', '🏆', catches.length >= 10),
      _Achievement('Maître Pêcheur', '10 espèces différentes', '🌊', catches.map((c) => c.species).toSet().length >= 10),
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

class _Achievement {
  final String title, desc, emoji;
  final bool unlocked;
  const _Achievement(this.title, this.desc, this.emoji, this.unlocked);
}
