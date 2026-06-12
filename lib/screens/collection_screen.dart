import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';
import 'catch_detail_screen.dart';

// ── Sort options ───────────────────────────────────────────────────────
enum _Sort { dateDesc, dateAsc, nameAsc, nameDesc, location }

extension _SortLabel on _Sort {
  String get label => switch (this) {
    _Sort.dateDesc  => 'Date ↓',
    _Sort.dateAsc   => 'Date ↑',
    _Sort.nameAsc   => 'A → Z',
    _Sort.nameDesc  => 'Z → A',
    _Sort.location  => '📍 Lieu',
  };
}

// ─────────────────────────────────────────────────────────────────────
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  _Sort  _sort      = _Sort.dateDesc;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FishCatch> _apply(List<FishCatch> raw) {
    // filter
    final q = _query.toLowerCase().trim();
    var list = q.isEmpty ? raw : raw.where((c) =>
      c.frenchName.toLowerCase().contains(q) ||
      c.species.toLowerCase().contains(q) ||
      c.family.toLowerCase().contains(q) ||
      (c.location?.toLowerCase().contains(q) ?? false)
    ).toList();
    // sort
    switch (_sort) {
      case _Sort.dateDesc:  list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      case _Sort.dateAsc:   list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      case _Sort.nameAsc:   list.sort((a, b) => a.frenchName.compareTo(b.frenchName));
      case _Sort.nameDesc:  list.sort((a, b) => b.frenchName.compareTo(a.frenchName));
      case _Sort.location:
        list.sort((a, b) => (a.location ?? 'zzz').compareTo(b.location ?? 'zzz'));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            elevation: 0,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              title: const Text('Ma Collection',
                style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.black.withOpacity(0.06))),
          ),

          // ── Search + sort ─────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Barre de recherche
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withOpacity(0.07))),
                child: Row(children: [
                  const SizedBox(width: 12),
                  const Icon(CupertinoIcons.search, color: FishdexTheme.textTertiary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher par poisson, lieu…',
                      hintStyle: TextStyle(color: FishdexTheme.textTertiary, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true),
                  )),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(CupertinoIcons.xmark_circle_fill, color: FishdexTheme.textTertiary, size: 16))),
                ]),
              ),
              const SizedBox(height: 10),
              // Chips de tri
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _Sort.values.map((s) {
                  final sel = _sort == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _sort = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? FishdexTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? FishdexTheme.primary : Colors.black.withOpacity(0.12))),
                        child: Text(s.label, style: TextStyle(
                          color: sel ? Colors.white : FishdexTheme.textSecondary,
                          fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    ),
                  );
                }).toList()),
              ),
            ]),
          )),

          // ── Liste ─────────────────────────────────────────────────
          StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, authSnap) {
              if (authSnap.data == null) {
                return const SliverFillRemaining(child: _LoginPrompt());
              }
              return StreamBuilder<List<FishCatch>>(
                stream: CatchService.stream(),
                builder: (context, snap) {
                  if (snap.hasError) return SliverFillRemaining(child: _ErrorState('${snap.error}'));
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(
                      child: CircularProgressIndicator(color: FishdexTheme.primary, strokeWidth: 2)));
                  }
                  final all      = snap.data ?? [];
                  final filtered = _apply(all);

                  if (all.isEmpty) return SliverFillRemaining(child: _EmptyState());
                  if (filtered.isEmpty) {
                    return SliverFillRemaining(child: Center(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Aucun résultat pour "$_query"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                    )));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _CatchTile(catch_: filtered[i], index: i),
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────
class _CatchTile extends StatelessWidget {
  final FishCatch catch_;
  final int index;
  const _CatchTile({required this.catch_, required this.index});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(catch_.id ?? catch_.timestamp.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: FishdexTheme.coral.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(CupertinoIcons.trash, color: FishdexTheme.coral, size: 22),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) { if (catch_.id != null) CatchService.delete(catch_.id!); },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => Navigator.push(context,
            CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: catch_))),
          child: GlassCard(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 64, height: 64, child: _buildThumbnail())),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(catch_.frenchName,
                  style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                Text(catch_.species,
                  style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 5),
                Wrap(spacing: 5, runSpacing: 4, children: [
                  _pill(catch_.family, FishdexTheme.primary),
                  _pill('${(catch_.confidence * 100).toStringAsFixed(0)}%', FishdexTheme.mint),
                  if (catch_.sizecm   != null) _pill('📏 ${catch_.sizecm} cm',  FishdexTheme.coral),
                  if (catch_.weightkg != null) _pill('⚖️ ${catch_.weightkg} kg', FishdexTheme.golden),
                  if (catch_.location != null) _pill('📍 ${catch_.location!}',   FishdexTheme.primary),
                  if (catch_.weather  != null) _pill(_weatherEmoji(catch_.weather!), FishdexTheme.golden),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_formatDate(catch_.timestamp),
                  style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
                Text(_formatTime(catch_.timestamp),
                  style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
                const SizedBox(height: 4),
                const Icon(CupertinoIcons.chevron_right, size: 14, color: FishdexTheme.textTertiary),
              ]),
            ]),
          )),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 40 * index)).slideY(begin: 0.04, end: 0);
  }

  String _weatherEmoji(String key) => const {
    'sunny': '☀️', 'cloudy': '⛅', 'rainy': '🌧️', 'stormy': '⛈️', 'foggy': '🌫️',
  }[key] ?? '🌡️';

  Widget _buildThumbnail() {
    if (catch_.imageBase64 != null && catch_.imageBase64!.isNotEmpty) {
      try { return Image.memory(base64Decode(catch_.imageBase64!), fit: BoxFit.cover); } catch (_) {}
    }
    if (catch_.fishImageUrl != null) {
      return Image.network(catch_.fishImageUrl!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    color: FishdexTheme.primary.withOpacity(0.07),
    child: const Center(child: Text('🐟', style: TextStyle(fontSize: 30))));

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      maxLines: 1, overflow: TextOverflow.ellipsis));

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  Future<bool> _confirmDelete(BuildContext ctx) async {
    final result = await showModalBottomSheet<bool>(
      context: ctx, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
          const Text('🗑️', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          const Text('Supprimer la prise ?',
            style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('"${catch_.frenchName}" sera supprimée de ta collection.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(ctx, false),
              child: Container(height: 52,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('Annuler',
                  style: TextStyle(color: FishdexTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(ctx, true),
              child: Container(height: 52,
                decoration: BoxDecoration(color: FishdexTheme.coral, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('Supprimer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))))),
          ]),
          const SizedBox(height: 4),
        ]),
      ),
    );
    return result ?? false;
  }
}

// ── Placeholders ──────────────────────────────────────────────────────
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('🔒', style: TextStyle(fontSize: 48)),
      SizedBox(height: 12),
      Text('Connecte-toi pour voir ta collection',
        textAlign: TextAlign.center,
        style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
      SizedBox(height: 8),
      Text('Va dans Profil pour créer ton compte.',
        textAlign: TextAlign.center,
        style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 13)),
    ]),
  ));
}

class _ErrorState extends StatelessWidget {
  final String msg;
  const _ErrorState(this.msg);
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('⚠️', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text('Erreur : $msg', style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
    ]),
  ));
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary.withOpacity(0.07)),
        child: const Center(child: Text('🎣', style: TextStyle(fontSize: 50)))),
      const SizedBox(height: 20),
      const Text("Aucune prise pour l'instant",
        style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text("Utilise le scanner pour identifier\nun poisson et l'ajouter ici",
        style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
    ],
  );
}
