import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';
import 'catch_detail_screen.dart';

const _kVersion   = '1.0.0';
const _kBuildDate = '11/06/2026';

// ── Helper dialog ──────────────────────────────────────────────────────
Future<bool> _showConfirmSheet(
  BuildContext context, {
  required String emoji,
  required String title,
  required String subtitle,
  required String confirmLabel,
  Color confirmColor = FishdexTheme.coral,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2))),
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(
          color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Container(height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('Annuler',
                style: TextStyle(color: FishdexTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)))),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(height: 52,
              decoration: BoxDecoration(
                color: confirmColor,
                borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
          )),
        ]),
        const SizedBox(height: 4),
      ]),
    ),
  );
  return result ?? false;
}

// ── Profile screen ─────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.userChanges,
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) return const _AuthView();
        return StreamBuilder<List<FishCatch>>(
          stream: CatchService.stream(),
          builder: (context, snap) {
            final catches = snap.data ?? [];
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(child: _buildHeader(user, catches)),
                SliverToBoxAdapter(child: _buildStats(catches)),
                SliverToBoxAdapter(child: _buildTabBar()),
                if (_tab == 0) _buildCollectionGrid(catches, context),
                if (_tab == 1) _buildAchievements(catches),
                SliverToBoxAdapter(child: _buildVersionFooter(context)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) => SliverAppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    pinned: true, elevation: 0,
    title: const Text('Mon Profil',
      style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
    actions: [
      CupertinoButton(
        padding: const EdgeInsets.only(right: 6),
        onPressed: () => _openEdit(context),
        child: const Icon(CupertinoIcons.pencil, color: FishdexTheme.primary, size: 22),
      ),
      CupertinoButton(
        padding: const EdgeInsets.only(right: 12),
        onPressed: () => _confirmLogout(context),
        child: const Icon(CupertinoIcons.square_arrow_right, color: FishdexTheme.coral, size: 22),
      ),
    ],
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(height: 1, color: Colors.black.withOpacity(0.06)),
    ),
  );

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await _showConfirmSheet(context,
      emoji: '👋',
      title: 'Se déconnecter ?',
      subtitle: 'Tu pourras te reconnecter quand tu veux.',
      confirmLabel: 'Se déconnecter',
    );
    if (ok) await AuthService.signOut();
  }

  Widget _buildHeader(User user, List<FishCatch> catches) {
    final speciesCount = catches.map((c) => c.species).toSet().length;
    final displayName  = user.displayName ?? 'Pêcheur';
    final username     = '@${user.email?.split('@').first ?? 'pêcheur'}';
    final level        = _level(catches.length);

    return Container(
      color: Colors.white,
      child: Column(children: [
        const SizedBox(height: 20),
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: FishdexTheme.primary.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: const Center(child: Text('🎣', style: TextStyle(fontSize: 44))),
          ),
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.golden,
              border: Border.all(color: Colors.white, width: 2)),
            child: Center(child: Text('$level',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        ]),
        const SizedBox(height: 12),
        Text(displayName,
          style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
        const SizedBox(height: 2),
        Text(username, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: FishdexTheme.golden.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FishdexTheme.golden.withOpacity(0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(CupertinoIcons.star_fill, color: FishdexTheme.golden, size: 11),
            const SizedBox(width: 4),
            Text('Niveau $level · ${_rankTitle(level)}',
              style: const TextStyle(color: FishdexTheme.golden, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _followStat('842', 'Abonnés'),
          _divider(),
          _followStat('234', 'Abonnements'),
          _divider(),
          _followStat('$speciesCount', 'Espèces'),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  int _level(int c) {
    if (c >= 100) return 20; if (c >= 50) return 15; if (c >= 20) return 12;
    if (c >= 10)  return 8;  if (c >= 5)  return 5;  if (c >= 1)  return 2;
    return 1;
  }

  String _rankTitle(int l) {
    if (l >= 20) return 'Maître Pêcheur'; if (l >= 15) return 'Expert';
    if (l >= 10) return 'Confirmé';       if (l >= 5)  return 'Amateur';
    return 'Débutant';
  }

  Widget _followStat(String n, String lbl) => Column(children: [
    Text(n,   style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
    Text(lbl, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 11)),
  ]);

  Widget _divider() => Container(
    width: 1, height: 24, color: Colors.black.withOpacity(0.08),
    margin: const EdgeInsets.symmetric(horizontal: 24));

  Widget _buildStats(List<FishCatch> catches) {
    final species    = catches.map((c) => c.species).toSet().length;
    final bestWeight = catches.where((c) => c.weightkg != null).map((c) => c.weightkg!)
        .fold<double?>(null, (best, w) => best == null || w > best ? w : best);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(children: [
        _statCard('${catches.length}', 'Prises',  '🎣', FishdexTheme.primary),
        const SizedBox(width: 10),
        _statCard(bestWeight != null ? '${bestWeight}kg' : '—', 'Record', '🏆', FishdexTheme.golden),
        const SizedBox(width: 10),
        _statCard('$species', 'Espèces', '📖', FishdexTheme.coral),
      ]),
    );
  }

  Widget _statCard(String val, String label, String icon, Color color) =>
    Expanded(child: GlassCard(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(val,   style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 11)),
      ]))));

  Widget _buildTabBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
    child: GlassCard(radius: 18,
      child: Padding(padding: const EdgeInsets.all(4),
        child: Row(children: [_tabBtn('Ma Collection', 0), _tabBtn('Succès', 1)]))));

  Widget _tabBtn(String label, int i) {
    final sel = _tab == i;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: sel ? FishdexTheme.primary : Colors.transparent,
          boxShadow: sel ? [BoxShadow(color: FishdexTheme.primary.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: sel ? Colors.white : FishdexTheme.textSecondary,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w400, fontSize: 14))),
      ),
    ));
  }

  Widget _buildCollectionGrid(List<FishCatch> catches, BuildContext context) {
    if (catches.isEmpty) {
      return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40),
        child: const Column(children: [
          Text('🎣', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Aucune prise enregistrée', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 15)),
        ])));
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final c = catches[i];
            return GestureDetector(
              onTap: () => Navigator.push(ctx, CupertinoPageRoute(builder: (_) => CatchDetailScreen(catch_: c))),
              child: Padding(padding: const EdgeInsets.all(4), child: GlassCard(radius: 18,
                child: Column(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: _catchThumb(c))),
                  Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 6), child: Column(children: [
                    Text(c.frenchName, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
                    Text('${(c.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 8)),
                  ])),
                ])),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 40 * i)).scale(begin: const Offset(0.88, 0.88));
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
      try { return Image.memory(base64Decode(c.imageBase64!), fit: BoxFit.cover, width: double.infinity); } catch (_) {}
    }
    if (c.fishImageUrl != null) return Image.network(c.fishImageUrl!, fit: BoxFit.cover, width: double.infinity,
      errorBuilder: (_, __, ___) => _thumbFallback());
    return _thumbFallback();
  }

  Widget _thumbFallback() => Container(
    color: FishdexTheme.primary.withOpacity(0.06),
    child: const Center(child: Text('🐟', style: TextStyle(fontSize: 22))));

  Widget _buildAchievements(List<FishCatch> catches) {
    final list = [
      _Achievement('Premier Lancer',  'Ta première prise !',             '🎣', catches.isNotEmpty),
      _Achievement('Collectionneur',  '5 prises enregistrées',           '📖', catches.length >= 5),
      _Achievement('Explorateur',     'Identifie 3 espèces différentes', '🔬', catches.map((c) => c.species).toSet().length >= 3),
      _Achievement('Légende',         '10 prises enregistrées',          '🏆', catches.length >= 10),
      _Achievement('Maître Pêcheur',  '10 espèces différentes',          '🌊', catches.map((c) => c.species).toSet().length >= 10),
    ];
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      sliver: SliverList(delegate: SliverChildBuilderDelegate(
        (context, i) => Padding(padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(borderColor: list[i].unlocked ? FishdexTheme.golden.withOpacity(0.3) : null,
            child: Padding(padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: list[i].unlocked ? FishdexTheme.golden.withOpacity(0.12) : Colors.black.withOpacity(0.04)),
                  child: Center(child: Text(list[i].unlocked ? list[i].emoji : '🔒',
                    style: const TextStyle(fontSize: 24)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(list[i].title, style: TextStyle(
                    color: list[i].unlocked ? FishdexTheme.textPrimary : FishdexTheme.textSecondary,
                    fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(list[i].desc, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
                ])),
                if (list[i].unlocked) const Icon(CupertinoIcons.checkmark_circle_fill, color: FishdexTheme.golden, size: 20),
              ])))
          ),
        childCount: list.length,
      )),
    );
  }

  Widget _buildVersionFooter(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
    child: Column(children: [
      Divider(color: Colors.black.withOpacity(0.06)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 28, height: 28,
          decoration: const BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00C6E0)])),
          child: const Center(child: Text('🐟', style: TextStyle(fontSize: 14)))),
        const SizedBox(width: 8),
        const Text('Fishdex', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      const Text('Version $_kVersion', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 2),
      const Text('Mis à jour le $_kBuildDate', style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: () => _confirmDeleteAccount(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: FishdexTheme.coral.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FishdexTheme.coral.withOpacity(0.2)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(CupertinoIcons.trash, color: FishdexTheme.coral, size: 16),
            SizedBox(width: 8),
            Text('Supprimer mon compte', style: TextStyle(
              color: FishdexTheme.coral, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final ok = await _showConfirmSheet(context,
      emoji: '🗑️',
      title: 'Supprimer le compte ?',
      subtitle: 'Toutes tes prises seront supprimées définitivement.',
      confirmLabel: 'Supprimer',
    );
    if (!ok || !context.mounted) return;
    // Ask for password confirmation
    final pwd = await _askPassword(context);
    if (pwd == null || !context.mounted) return;
    final err = await AuthService.deleteAccount(pwd);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err), backgroundColor: FishdexTheme.coral));
    }
  }

  Future<String?> _askPassword(BuildContext context) {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          margin: const EdgeInsets.all(12),
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            const Text('🔑', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 14),
            const Text('Confirmer avec ton mot de passe',
              textAlign: TextAlign.center,
              style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _inputField('Mot de passe', ctrl, obscure: true),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: GestureDetector(
              onTap: () => Navigator.pop(context, ctrl.text),
              child: Container(height: 52,
                decoration: BoxDecoration(color: FishdexTheme.coral, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('Confirmer la suppression',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
            )),
          ]),
        );
      },
    );
  }
}

// ── Edit profile sheet ─────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _nameCtrl     = TextEditingController();
  final _userCtrl     = TextEditingController();
  final _userPwdCtrl  = TextEditingController();
  final _oldPwdCtrl   = TextEditingController();
  final _newPwdCtrl   = TextEditingController();

  bool _loadingName = false;
  bool _loadingUser = false;
  bool _loadingPwd  = false;
  String? _errName, _errUser, _errPwd;
  String? _okName,  _okUser,  _okPwd;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _nameCtrl.text = user?.displayName ?? '';
    _userCtrl.text = user?.email?.split('@').first ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _userCtrl.dispose(); _userPwdCtrl.dispose();
    _oldPwdCtrl.dispose(); _newPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _loadingName = true; _errName = null; _okName = null; });
    final err = await AuthService.updateDisplayName(_nameCtrl.text);
    if (!mounted) return;
    setState(() {
      _loadingName = false;
      _errName = err;
      _okName  = err == null ? 'Nom mis à jour !' : null;
    });
  }

  Future<void> _saveUsername() async {
    if (_userCtrl.text.trim().isEmpty || _userPwdCtrl.text.isEmpty) return;
    setState(() { _loadingUser = true; _errUser = null; _okUser = null; });
    final err = await AuthService.updateUsername(_userCtrl.text, _userPwdCtrl.text);
    if (!mounted) return;
    setState(() {
      _loadingUser = false;
      _errUser = err;
      _okUser  = err == null ? 'Identifiant mis à jour !' : null;
    });
  }

  Future<void> _savePassword() async {
    if (_oldPwdCtrl.text.isEmpty || _newPwdCtrl.text.isEmpty) return;
    setState(() { _loadingPwd = true; _errPwd = null; _okPwd = null; });
    final err = await AuthService.changePassword(_oldPwdCtrl.text, _newPwdCtrl.text);
    if (!mounted) return;
    setState(() {
      _loadingPwd = false;
      _errPwd = err;
      _okPwd  = err == null ? 'Mot de passe modifié !' : null;
    });
    if (err == null) { _oldPwdCtrl.clear(); _newPwdCtrl.clear(); }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(children: [
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Row(children: [
              Text('Modifier le profil',
                style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
          ]),
        ),
        Divider(height: 1, color: Colors.black.withOpacity(0.06)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Nom
                _sectionHeader('✏️', 'Prénom affiché'),
                const SizedBox(height: 10),
                _inputField('Nouveau prénom', _nameCtrl),
                if (_errName != null) _errorMsg(_errName!),
                if (_okName  != null) _successMsg(_okName!),
                const SizedBox(height: 10),
                _saveBtn('Sauvegarder le nom', _loadingName, _saveName),
                const SizedBox(height: 24),

                // Section: Identifiant
                _sectionHeader('🪪', 'Identifiant'),
                const SizedBox(height: 10),
                _inputField('Nouvel identifiant', _userCtrl),
                const SizedBox(height: 8),
                _inputField('Mot de passe actuel', _userPwdCtrl, obscure: true),
                if (_errUser != null) _errorMsg(_errUser!),
                if (_okUser  != null) _successMsg(_okUser!),
                const SizedBox(height: 10),
                _saveBtn('Sauvegarder l\'identifiant', _loadingUser, _saveUsername),
                const SizedBox(height: 24),

                // Section: Mot de passe
                _sectionHeader('🔑', 'Mot de passe'),
                const SizedBox(height: 10),
                _inputField('Mot de passe actuel', _oldPwdCtrl, obscure: true),
                const SizedBox(height: 8),
                _inputField('Nouveau mot de passe', _newPwdCtrl, obscure: true),
                if (_errPwd != null) _errorMsg(_errPwd!),
                if (_okPwd  != null) _successMsg(_okPwd!),
                const SizedBox(height: 10),
                _saveBtn('Modifier le mot de passe', _loadingPwd, _savePassword),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(String emoji, String title) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 6),
    Text(title, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
  ]);

  Widget _saveBtn(String label, bool loading, VoidCallback onTap) =>
    GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(
          color: FishdexTheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: loading
          ? const CupertinoActivityIndicator(color: Colors.white)
          : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
      ),
    );

  Widget _errorMsg(String msg) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FishdexTheme.coral.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FishdexTheme.coral.withOpacity(0.2)),
      ),
      child: Text(msg, style: const TextStyle(color: FishdexTheme.coral, fontSize: 12)),
    ),
  );

  Widget _successMsg(String msg) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FishdexTheme.mint.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FishdexTheme.mint.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(CupertinoIcons.checkmark_circle_fill, color: FishdexTheme.mint, size: 14),
        const SizedBox(width: 6),
        Text(msg, style: const TextStyle(color: FishdexTheme.mint, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

Widget _inputField(String label, TextEditingController ctrl, {bool obscure = false}) =>
  Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.03),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black.withOpacity(0.07)),
    ),
    child: TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    ),
  );

// ── Vue authentification ───────────────────────────────────────────────
class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  bool _isRegister   = false;
  bool _loading      = false;
  bool _showPassword = false;
  String? _error;

  final _usernameCtrl = TextEditingController();
  final _displayCtrl  = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose(); _displayCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final u = _usernameCtrl.text.trim();
    final p = _passwordCtrl.text;
    final d = _displayCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Remplis tous les champs obligatoires');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = _isRegister
        ? await AuthService.register(u, d.isEmpty ? u : d, p)
        : await AuthService.signIn(u, p);
    if (!mounted) return;
    setState(() { _loading = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 80, height: 80,
                decoration: const BoxDecoration(shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00C6E0)])),
                child: const Center(child: Text('🐟', style: TextStyle(fontSize: 40))),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              const Text('Fishdex',
                style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: 4),
              const Text("La pêche n'a jamais été aussi simple !",
                style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 36),

              GlassCard(radius: 16, child: Padding(padding: const EdgeInsets.all(4),
                child: Row(children: [_tabBtn('Se connecter', false), _tabBtn('S\'inscrire', true)]))),

              const SizedBox(height: 24),

              if (_isRegister) ...[
                _field('Prénom affiché', _displayCtrl, 'Alex Pêcheur', CupertinoIcons.person),
                const SizedBox(height: 12),
              ],
              _field('Identifiant', _usernameCtrl, 'alex_peche', CupertinoIcons.at),
              const SizedBox(height: 12),
              _passwordField(),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FishdexTheme.coral.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FishdexTheme.coral.withOpacity(0.2)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: FishdexTheme.coral, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: FishdexTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(_isRegister ? 'Créer mon compte' : 'Se connecter',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tu peux naviguer et voir le fil sans compte.\nCrée un compte pour sauvegarder tes prises.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(String label, bool isReg) {
    final sel = _isRegister == isReg;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { _isRegister = isReg; _error = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: sel ? FishdexTheme.primary : Colors.transparent,
        ),
        child: Center(child: Text(label, style: TextStyle(
          color: sel ? Colors.white : FishdexTheme.textSecondary,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w400, fontSize: 14))),
      ),
    ));
  }

  Widget _field(String label, TextEditingController ctrl, String hint, IconData icon) =>
    Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: FishdexTheme.textTertiary),
          prefixIcon: Icon(icon, color: FishdexTheme.textTertiary, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          labelText: label,
          labelStyle: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );

  Widget _passwordField() => Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.03),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.black.withOpacity(0.07)),
    ),
    child: TextField(
      controller: _passwordCtrl,
      obscureText: !_showPassword,
      style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: '••••••',
        hintStyle: const TextStyle(color: FishdexTheme.textTertiary),
        prefixIcon: const Icon(CupertinoIcons.lock, color: FishdexTheme.textTertiary, size: 18),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _showPassword = !_showPassword),
          child: Icon(_showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            color: FishdexTheme.textTertiary, size: 18)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        labelText: 'Mot de passe',
        labelStyle: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    ),
  );
}

class _Achievement {
  final String title, desc, emoji;
  final bool unlocked;
  const _Achievement(this.title, this.desc, this.emoji, this.unlocked);
}
