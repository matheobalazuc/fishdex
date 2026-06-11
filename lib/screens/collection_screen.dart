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

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

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
            title: const Text('Ma Collection',
              style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: Colors.black.withOpacity(0.06)),
            ),
          ),

          StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, authSnap) {
              if (authSnap.data == null) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Padding(
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
                    ),
                  ),
                );
              }
              return StreamBuilder<List<FishCatch>>(
                stream: CatchService.stream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text('Erreur : ${snap.error}',
                            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: FishdexTheme.primary, strokeWidth: 2),
                  ),
                );
              }

              final catches = snap.data ?? [];

              if (catches.isEmpty) {
                return SliverFillRemaining(child: _EmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _CatchTile(catch_: catches[i], index: i),
                    childCount: catches.length,
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
        decoration: BoxDecoration(
          color: FishdexTheme.coral.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(CupertinoIcons.trash, color: FishdexTheme.coral, size: 22),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        if (catch_.id != null) CatchService.delete(catch_.id!);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: catch_)),
          ),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(width: 64, height: 64, child: _buildThumbnail()),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(catch_.frenchName,
                          style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(catch_.species,
                          style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _pill(catch_.family, FishdexTheme.primary),
                            const SizedBox(width: 6),
                            _pill('${(catch_.confidence * 100).toStringAsFixed(0)}%', FishdexTheme.mint),
                            if (catch_.location != null) ...[
                              const SizedBox(width: 6),
                              _pill('📍', FishdexTheme.golden),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatDate(catch_.timestamp),
                        style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w500)),
                      Text(_formatTime(catch_.timestamp),
                        style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
                      const SizedBox(height: 4),
                      const Icon(CupertinoIcons.chevron_right, size: 14, color: FishdexTheme.textTertiary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index))
        .slideY(begin: 0.06, end: 0);
  }

  Widget _buildThumbnail() {
    if (catch_.imageBase64 != null && catch_.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(catch_.imageBase64!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    if (catch_.fishImageUrl != null) {
      return Image.network(catch_.fishImageUrl!, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback());
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    color: FishdexTheme.primary.withOpacity(0.07),
    child: const Center(child: Text('🐟', style: TextStyle(fontSize: 30))),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<bool> _confirmDelete(BuildContext ctx) async {
    return await showCupertinoDialog<bool>(
          context: ctx,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Supprimer'),
            content: Text('Supprimer "${catch_.frenchName}" de ta collection ?'),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Supprimer'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ) ?? false;
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: FishdexTheme.primary.withOpacity(0.07),
          ),
          child: const Center(child: Text('🎣', style: TextStyle(fontSize: 50))),
        ),
        const SizedBox(height: 20),
        const Text("Aucune prise pour l'instant",
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text("Utilise le scanner pour identifier\nun poisson et l'ajouter ici",
          style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14),
          textAlign: TextAlign.center),
      ],
    );
  }
}
