import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../theme/fishdex_theme.dart';

class CatchDetailScreen extends StatefulWidget {
  final FishCatch catch_;
  const CatchDetailScreen({super.key, required this.catch_});

  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  late FishCatch _c;
  bool _editMode = false;
  bool _saving   = false;

  // controllers édition
  late TextEditingController _frenchCtrl;
  late TextEditingController _speciesCtrl;
  late TextEditingController _familyCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _notesCtrl;
  Uint8List? _newImageBytes;   // nouvelle photo choisie

  @override
  void initState() {
    super.initState();
    _c = widget.catch_;
    _initControllers();
  }

  void _initControllers() {
    _frenchCtrl  = TextEditingController(text: _c.frenchName);
    _speciesCtrl = TextEditingController(text: _c.species);
    _familyCtrl  = TextEditingController(text: _c.family);
    _sizeCtrl    = TextEditingController(text: _c.sizecm?.toString()  ?? '');
    _weightCtrl  = TextEditingController(text: _c.weightkg?.toString() ?? '');
    _locCtrl     = TextEditingController(text: _c.location ?? '');
    _notesCtrl   = TextEditingController(text: _c.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_frenchCtrl, _speciesCtrl, _familyCtrl, _sizeCtrl, _weightCtrl, _locCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────
  Future<void> _pickNewPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() => _newImageBytes = bytes);
  }

  Future<void> _saveEdits() async {
    if (_c.id == null) return;
    setState(() => _saving = true);
    final newImage = _newImageBytes != null ? base64Encode(_newImageBytes!) : null;
    final updated = _c.copyWith(
      frenchName: _frenchCtrl.text.trim(),
      species:    _speciesCtrl.text.trim(),
      family:     _familyCtrl.text.trim(),
      sizecm:     double.tryParse(_sizeCtrl.text),
      weightkg:   double.tryParse(_weightCtrl.text),
      location:   _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
      notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      imageBase64: newImage,
      clearSize:   _sizeCtrl.text.trim().isEmpty,
      clearWeight: _weightCtrl.text.trim().isEmpty,
      clearLocation: _locCtrl.text.trim().isEmpty,
      clearNotes:  _notesCtrl.text.trim().isEmpty,
    );
    await CatchService.replace(updated);
    setState(() {
      _c        = updated;
      _editMode = false;
      _saving   = false;
      _newImageBytes = null;
    });
  }

  bool get _isOwner => _c.userId == AuthService.currentUserId;

  Future<void> _deleteCatch() async {
    final ok = await _showModernConfirm(
      context,
      emoji: '🗑️',
      title: 'Supprimer la prise ?',
      subtitle: '"${_c.frenchName}" sera supprimée définitivement.',
      confirmLabel: 'Supprimer',
    );
    if (!ok) return;
    await CatchService.delete(_c.id!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _togglePublish() async {
    if (_c.id == null) return;
    if (!_c.isPublished) {
      final mode = await _showPublishSheet(context);
      if (mode == null) return;
      await CatchService.update(_c.id!, {'isPublished': true, 'isPrivate': mode == 1});
      setState(() => _c = _c.copyWith(isPublished: true, isPrivate: mode == 1));
    } else {
      final ok = await _showModernConfirm(context,
        emoji: '👁️',
        title: 'Retirer du fil ?',
        subtitle: 'La publication ne sera plus visible dans le fil.',
        confirmLabel: 'Retirer',
        confirmColor: FishdexTheme.golden,
      );
      if (!ok) return;
      await CatchService.update(_c.id!, {'isPublished': false});
      setState(() => _c = _c.copyWith(isPublished: false));
    }
  }

  Future<int?> _showPublishSheet(BuildContext ctx) => showModalBottomSheet<int>(
    context: ctx,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
        const Text('📢', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 14),
        const Text('Publier dans le fil', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Qui peut voir cette prise ?', textAlign: TextAlign.center,
          style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pop(ctx, 0),
          child: Container(width: double.infinity, height: 52, margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: FishdexTheme.primary, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('🌍  Public — Tout le monde', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(ctx, 1),
          child: Container(width: double.infinity, height: 52,
            decoration: BoxDecoration(color: FishdexTheme.golden, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('🔒  Privé — Amis uniquement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
        ),
        const SizedBox(height: 4),
      ]),
    ),
  );

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  // ── App bar photo ──────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.35)),
          child: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 18),
        ),
      ),
      actions: [
        if (_isOwner) ...[
          // Supprimer
          if (!_editMode)
            CupertinoButton(
              padding: const EdgeInsets.only(right: 4),
              onPressed: _deleteCatch,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.35)),
                child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 16),
              ),
            ),
          // Éditer / Annuler
          CupertinoButton(
            padding: const EdgeInsets.only(right: 12),
            onPressed: () => setState(() {
              _editMode = !_editMode;
              if (!_editMode) { _initControllers(); _newImageBytes = null; }
            }),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.35)),
              child: Icon(
                _editMode ? CupertinoIcons.xmark : CupertinoIcons.pencil,
                color: Colors.white, size: 16),
            ),
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: _editMode ? _pickNewPhoto : () => _openFullScreen(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildHeroPhoto(),
              if (_editMode)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text('Changer la photo', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPhoto() {
    if (_newImageBytes != null) {
      return Image.memory(_newImageBytes!, fit: BoxFit.cover);
    }
    if (_c.imageBase64 != null && _c.imageBase64!.isNotEmpty) {
      try {
        return Image.memory(base64Decode(_c.imageBase64!), fit: BoxFit.cover);
      } catch (_) {}
    }
    if (_c.fishImageUrl != null) {
      return Image.network(_c.fishImageUrl!, fit: BoxFit.cover);
    }
    return Container(
      color: FishdexTheme.primary.withOpacity(0.08),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 80))),
    );
  }

  void _openFullScreen(BuildContext ctx) {
    final Widget img;
    if (_c.imageBase64 != null && _c.imageBase64!.isNotEmpty) {
      try {
        img = Image.memory(base64Decode(_c.imageBase64!), fit: BoxFit.contain);
        _pushFullScreen(ctx, img);
        return;
      } catch (_) {}
    }
    if (_c.fishImageUrl != null) {
      _pushFullScreen(ctx, Image.network(_c.fishImageUrl!, fit: BoxFit.contain));
    }
  }

  void _pushFullScreen(BuildContext ctx, Widget child) {
    Navigator.push(ctx, PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => _FullScreenViewer(child: child),
    ));
  }

  // ── Corps ──────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editMode ? _buildEditForm() : _buildReadView(),
        ],
      ),
    );
  }

  // ── Vue lecture ────────────────────────────────────────────────────
  Widget _buildReadView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Identité
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_c.frenchName,
                    style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  Text(_c.species,
                    style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDate(_c.timestamp),
                  style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(_formatTime(_c.timestamp),
                  style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _pill(_c.family, FishdexTheme.primary),
            _pill('${(_c.confidence * 100).toStringAsFixed(1)}%', FishdexTheme.mint),
            if (_c.isPublished)
              _pill(_c.isPrivate ? '🔒 Privé' : '🌍 Public', FishdexTheme.golden),
          ],
        ),

        // Données optionnelles
        if (_c.location != null || _c.sizecm != null || _c.weightkg != null || _c.notes != null) ...[
          const SizedBox(height: 20),
          if (_c.location != null) _infoRow(CupertinoIcons.location_fill, 'Lieu', _c.location!),
          if (_c.sizecm  != null) _infoRow(CupertinoIcons.arrow_left_right, 'Taille', '${_c.sizecm} cm'),
          if (_c.weightkg!= null) _infoRow(CupertinoIcons.chart_bar, 'Poids', '${_c.weightkg} kg'),
          if (_c.notes   != null) _infoRow(CupertinoIcons.text_alignleft, 'Notes', _c.notes!),
        ],

        // Photo Wikipedia
        if (_c.fishImageUrl != null) ...[
          const SizedBox(height: 20),
          _buildWikiCard(),
        ],

        // Confiance + Top 5
        const SizedBox(height: 20),
        _buildConfidence(),
        const SizedBox(height: 16),
        _buildTop5(),

        // Bouton publier (propriétaire uniquement)
        if (_isOwner) ...[
          const SizedBox(height: 28),
          _buildPublishButton(),
        ],
      ],
    );
  }

  Widget _buildWikiCard() {
    return GestureDetector(
      onTap: () => _pushFullScreen(context, Image.network(_c.fishImageUrl!, fit: BoxFit.contain)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(_c.fishImageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
            Positioned(
              bottom: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.zoom_in, color: Colors.white, size: 11),
                    SizedBox(width: 4),
                    Text('Photo Wikipedia', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidence() {
    final pct   = _c.confidence;
    final color = pct > 0.7 ? FishdexTheme.mint : pct > 0.4 ? FishdexTheme.golden : FishdexTheme.coral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Confiance IA', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
            Text('${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct, minHeight: 6,
            backgroundColor: Colors.black.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildTop5() {
    if (_c.top5.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top 5 identifications',
          style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...(_c.top5.asMap().entries.map((e) {
          final i  = e.key;
          final sp = e.value['species'] as String? ?? '';
          final sc = (e.value['score'] as num?)?.toDouble() ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == 0 ? FishdexTheme.primary.withOpacity(0.1) : Colors.black.withOpacity(0.04),
                  ),
                  child: Center(child: Text('${i + 1}',
                    style: TextStyle(color: i == 0 ? FishdexTheme.primary : FishdexTheme.textTertiary,
                      fontSize: 10, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(sp,
                  style: TextStyle(
                    color: i == 0 ? FishdexTheme.textPrimary : FishdexTheme.textSecondary,
                    fontSize: 13, fontStyle: FontStyle.italic,
                    fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400))),
                Text('${(sc * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: i == 0 ? FishdexTheme.primary : FishdexTheme.textTertiary,
                    fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        })),
      ],
    );
  }

  Widget _buildPublishButton() {
    final published = _c.isPublished;
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: published ? FishdexTheme.coral.withOpacity(0.12) : FishdexTheme.primary,
        borderRadius: BorderRadius.circular(16),
        onPressed: _togglePublish,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              published ? CupertinoIcons.eye_slash_fill : CupertinoIcons.paperplane_fill,
              color: published ? FishdexTheme.coral : Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              published
                ? (_c.isPrivate ? 'Publié (privé) · Retirer' : 'Publié (public) · Retirer')
                : 'Publier dans le fil',
              style: TextStyle(
                color: published ? FishdexTheme.coral : Colors.white,
                fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  // ── Vue édition ────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Modifier la prise',
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Tape sur la photo en haut pour la changer',
          style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 12)),
        const SizedBox(height: 20),

        _sectionLabel('Identification'),
        _field('Nom français', _frenchCtrl, 'Daurade royale'),
        const SizedBox(height: 10),
        _field('Nom scientifique', _speciesCtrl, 'Sparus aurata', italic: true),
        const SizedBox(height: 10),
        _field('Famille', _familyCtrl, 'Sparidae'),

        const SizedBox(height: 20),
        _sectionLabel('Ma prise (facultatif)'),
        Row(
          children: [
            Expanded(child: _field('Taille (cm)', _sizeCtrl, '42', type: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: _field('Poids (kg)', _weightCtrl, '1.8', type: const TextInputType.numberWithOptions(decimal: true))),
          ],
        ),
        const SizedBox(height: 10),
        _field('Lieu de pêche', _locCtrl, 'Lac de Villefranche…'),
        const SizedBox(height: 10),
        _field('Notes', _notesCtrl, 'Belle prise sur leurre…', maxLines: 3),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: FishdexTheme.primary,
            borderRadius: BorderRadius.circular(16),
            onPressed: _saving ? null : _saveEdits,
            child: _saving
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, int maxLines = 1, bool italic = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.07)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            style: TextStyle(
              color: FishdexTheme.textPrimary,
              fontSize: 14,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary.withOpacity(0.08)),
          child: Icon(icon, color: FishdexTheme.primary, size: 15),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
            Text(value, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    ),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  String _formatDate(DateTime d) {
    const m = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${d.day} ${m[d.month - 1]}. ${d.year}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

// ── Helpers ────────────────────────────────────────────────────────
Future<bool> _showModernConfirm(
  BuildContext context, {
  required String emoji, required String title,
  required String subtitle, required String confirmLabel,
  Color confirmColor = FishdexTheme.coral,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Container(height: 52,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('Annuler',
                style: TextStyle(color: FishdexTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)))),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(height: 52,
              decoration: BoxDecoration(color: confirmColor, borderRadius: BorderRadius.circular(16)),
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

// ── Visionneuse plein écran ────────────────────────────────────────
class _FullScreenViewer extends StatelessWidget {
  final Widget child;
  const _FullScreenViewer({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.92),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(minScale: 0.5, maxScale: 4, child: child),
              ),
              Positioned(
                top: 12, right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                    child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
