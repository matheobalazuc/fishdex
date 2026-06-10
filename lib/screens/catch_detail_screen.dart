import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/catch_model.dart';
import '../services/catch_service.dart';
import '../theme/fishdex_theme.dart';

class CatchDetailScreen extends StatefulWidget {
  final FishCatch catch_;
  const CatchDetailScreen({super.key, required this.catch_});

  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  late FishCatch _catch;
  bool _editing = false;
  bool _saving = false;

  final _sizeCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _locCtrl    = TextEditingController();
  final _notesCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _catch = widget.catch_;
    _sizeCtrl.text   = _catch.sizecm?.toString() ?? '';
    _weightCtrl.text = _catch.weightkg?.toString() ?? '';
    _locCtrl.text    = _catch.location ?? '';
    _notesCtrl.text  = _catch.notes ?? '';
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    _weightCtrl.dispose();
    _locCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_catch.id == null) return;
    setState(() => _saving = true);
    final fields = <String, dynamic>{};
    final size   = double.tryParse(_sizeCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    fields['sizecm']   = size;
    fields['weightkg'] = weight;
    fields['location'] = _locCtrl.text.isEmpty ? null : _locCtrl.text;
    fields['notes']    = _notesCtrl.text.isEmpty ? null : _notesCtrl.text;
    await CatchService.update(_catch.id!, fields);
    setState(() {
      _catch = _catch.copyWith(
        sizecm:   size,
        weightkg: weight,
        location: _locCtrl.text.isEmpty ? null : _locCtrl.text,
        notes:    _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      );
      _editing = false;
      _saving  = false;
    });
  }

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

  // ── App bar avec la photo de l'utilisateur ─────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.only(left: 12),
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.35),
          ),
          child: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroPhoto(),
      ),
    );
  }

  Widget _buildHeroPhoto() {
    Widget photo;

    if (_catch.imageBase64 != null && _catch.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(_catch.imageBase64!);
        photo = Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      } catch (_) {
        photo = _wikiOrFallback();
      }
    } else {
      photo = _wikiOrFallback();
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Hero(
        tag: 'catch_${_catch.id}',
        child: photo,
      ),
    );
  }

  Widget _wikiOrFallback() {
    if (_catch.fishImageUrl != null) {
      return GestureDetector(
        onTap: () => _showFullScreenWiki(context),
        child: Image.network(_catch.fishImageUrl!, fit: BoxFit.cover, width: double.infinity),
      );
    }
    return Container(
      color: FishdexTheme.primary.withOpacity(0.08),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 80))),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    if (_catch.imageBase64 == null) { _showFullScreenWiki(context); return; }
    try {
      final bytes = base64Decode(_catch.imageBase64!);
      _openFullScreen(context, Image.memory(bytes, fit: BoxFit.contain));
    } catch (_) {}
  }

  void _showFullScreenWiki(BuildContext context) {
    if (_catch.fishImageUrl == null) return;
    _openFullScreen(context, Image.network(_catch.fishImageUrl!, fit: BoxFit.contain));
  }

  void _openFullScreen(BuildContext context, Widget image) {
    Navigator.push(context, PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => _FullScreenImage(child: image),
      transitionDuration: const Duration(milliseconds: 280),
    ));
  }

  // ── Corps principal ────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentity(),
          const SizedBox(height: 20),
          if (_catch.fishImageUrl != null) _buildWikiCard(),
          const SizedBox(height: 20),
          _buildConfidence(),
          const SizedBox(height: 20),
          _buildTop5(),
          const SizedBox(height: 24),
          _buildEditSection(),
          if (_editing) ...[
            const SizedBox(height: 16),
            _buildEditForm(),
            const SizedBox(height: 20),
            _buildSaveButton(),
          ] else if (_hasOptionalData()) ...[
            const SizedBox(height: 16),
            _buildOptionalData(),
          ],
        ],
      ),
    );
  }

  Widget _buildIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_catch.frenchName,
                    style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  Text(_catch.species,
                    style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDate(_catch.timestamp),
                  style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(_formatTime(_catch.timestamp),
                  style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _pill(_catch.family, FishdexTheme.primary),
            const SizedBox(width: 8),
            _pill('${(_catch.confidence * 100).toStringAsFixed(1)}% confiance', FishdexTheme.mint),
          ],
        ),
      ],
    );
  }

  Widget _buildWikiCard() {
    return GestureDetector(
      onTap: () => _showFullScreenWiki(context),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(_catch.fishImageUrl!, fit: BoxFit.cover, width: double.infinity, height: 140),
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.zoom_in, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Photo Wikipedia', style: TextStyle(color: Colors.white, fontSize: 10)),
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

  Widget _buildConfidence() {
    final pct = _catch.confidence;
    final color = pct > 0.7 ? FishdexTheme.mint : pct > 0.4 ? FishdexTheme.golden : FishdexTheme.coral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Niveau de confiance', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
            Text('${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.black.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildTop5() {
    if (_catch.top5.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top 5 espèces possibles',
          style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...(_catch.top5.asMap().entries.map((e) {
          final i = e.key;
          final sp = e.value['species'] as String? ?? '';
          final sc = ((e.value['score'] as num?)?.toDouble() ?? 0);
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
                  child: Center(
                    child: Text('${i + 1}',
                      style: TextStyle(
                        color: i == 0 ? FishdexTheme.primary : FishdexTheme.textTertiary,
                        fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(sp,
                    style: TextStyle(
                      color: i == 0 ? FishdexTheme.textPrimary : FishdexTheme.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400)),
                ),
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

  bool _hasOptionalData() =>
      _catch.sizecm != null || _catch.weightkg != null || _catch.location != null || _catch.notes != null;

  Widget _buildEditSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Ma prise', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: () => setState(() => _editing = !_editing),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _editing ? FishdexTheme.coral.withOpacity(0.08) : FishdexTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_editing ? FishdexTheme.coral : FishdexTheme.primary).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _editing ? CupertinoIcons.xmark : CupertinoIcons.pencil,
                  color: _editing ? FishdexTheme.coral : FishdexTheme.primary,
                  size: 13),
                const SizedBox(width: 5),
                Text(
                  _editing ? 'Annuler' : 'Modifier',
                  style: TextStyle(
                    color: _editing ? FishdexTheme.coral : FishdexTheme.primary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _field('Taille (cm)', _sizeCtrl, TextInputType.numberWithOptions(decimal: true), '42')),
            const SizedBox(width: 12),
            Expanded(child: _field('Poids (kg)', _weightCtrl, TextInputType.numberWithOptions(decimal: true), '1.8')),
          ],
        ),
        const SizedBox(height: 12),
        _field('Lieu de pêche', _locCtrl, TextInputType.text, 'Lac de Villefranche…'),
        const SizedBox(height: 12),
        _field('Notes', _notesCtrl, TextInputType.multiline, 'Belle prise sur leurre…', maxLines: 3),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type, String hint, {int maxLines = 1}) {
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
            style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: FishdexTheme.primary,
        borderRadius: BorderRadius.circular(16),
        onPressed: _saving ? null : _save,
        child: _saving
            ? const CupertinoActivityIndicator(color: Colors.white)
            : const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  Widget _buildOptionalData() {
    return Column(
      children: [
        if (_catch.location != null)
          _infoRow(CupertinoIcons.location_fill, 'Lieu', _catch.location!),
        if (_catch.sizecm != null)
          _infoRow(CupertinoIcons.arrow_left_right, 'Taille', '${_catch.sizecm} cm'),
        if (_catch.weightkg != null)
          _infoRow(CupertinoIcons.chart_bar, 'Poids', '${_catch.weightkg} kg'),
        if (_catch.notes != null)
          _infoRow(CupertinoIcons.text_alignleft, 'Notes', _catch.notes!),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FishdexTheme.primary.withOpacity(0.08),
            ),
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
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  String _formatDate(DateTime d) {
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'jun', 'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'];
    return '${d.day} ${months[d.month - 1]}. ${d.year}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ── Visionneuse plein écran ────────────────────────────────────────
class _FullScreenImage extends StatelessWidget {
  final Widget child;
  const _FullScreenImage({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black.withOpacity(0.92),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: child,
                ),
              ),
              Positioned(
                top: 12, right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
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
