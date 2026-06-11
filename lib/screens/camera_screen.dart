import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../services/wiki_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

const _apiUrl =
    'https://acids-definitely-leo-his.trycloudflare.com/api/predict';

const _frenchNames = {
  'Sparus aurata': 'Daurade royale',
  'Spondyliosoma cantharus': 'Dorade grise',
  'Pagellus erythrinus': 'Pageot rouge',
  'Diplodus puntazzo': 'Sar museau pointu',
  'Oblada melanurus': 'Oblada',
  'Dicentrarchus labrax': 'Bar commun',
  'Mugil cephalus': 'Mulet cabot',
  'Esox lucius': 'Brochet commun',
  'Salmo trutta': 'Truite fario',
  'Cyprinus carpio': 'Carpe commune',
  'Sander lucioperca': 'Sandre',
  'Perca fluviatilis': 'Perche',
  'Anguilla anguilla': 'Anguille européenne',
  'Thunnus thynnus': 'Thon rouge',
  'Solea solea': 'Sole commune',
  'Merluccius merluccius': 'Merlu',
  'Tinca tinca': 'Tanche',
  'Abramis brama': 'Brème',
  'Rutilus rutilus': 'Gardon',
};

String _fr(String latin) => _frenchNames[latin] ?? latin;

String _emoji(String family) {
  switch (family.toLowerCase()) {
    case 'sparidae': return '🐟';
    case 'salmonidae': return '🐠';
    case 'esocidae': return '🐟';
    case 'cyprinidae': return '🐡';
    case 'percidae': return '🐟';
    case 'moronidae': return '🦈';
    default: return '🐟';
  }
}

class _Result {
  final String family;
  final double confidence;
  final List<({String species, double score})> top5;

  const _Result({required this.family, required this.confidence, required this.top5});

  factory _Result.fromJson(Map<String, dynamic> j) => _Result(
    family: j['family'] as String,
    confidence: (j['confidence'] as num).toDouble(),
    top5: (j['top5'] as List)
        .map((e) => (
              species: e['species'] as String,
              score: (e['score'] as num).toDouble(),
            ))
        .toList(),
  );

  String get topSpecies => top5.isNotEmpty ? top5.first.species : '';
  double get topScore => top5.isNotEmpty ? top5.first.score : 0;
}

// ─────────────────────────────────────────────────────────────────
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;

  bool _isScanning = false;
  bool _isSaving = false;
  bool _saved = false;
  bool _showDetail = false;
  String? _error;
  _Result? _result;
  String? _fishImageUrl;

  XFile? _pickedFile;
  Uint8List? _imageBytes;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final file = await _picker.pickImage(
      source: src,
      imageQuality: 60,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedFile = file;
      _imageBytes = bytes;
      _result = null;
      _error = null;
      _fishImageUrl = null;
      _saved = false;
      _showDetail = false;
    });
    await _identify(file, bytes);
  }

  Future<void> _identify(XFile file, Uint8List bytes) async {
    setState(() { _isScanning = true; _error = null; });
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      req.files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: file.name.isNotEmpty ? file.name : 'photo.jpg',
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (!mounted) return;
      if (streamed.statusCode == 200) {
        final r = _Result.fromJson(jsonDecode(body) as Map<String, dynamic>);
        // Fetch Wikipedia image en parallèle
        final imgUrl = await WikiService.getFishImageUrl(r.topSpecies);
        if (!mounted) return;
        setState(() { _result = r; _fishImageUrl = imgUrl; _isScanning = false; });
      } else {
        setState(() { _error = 'Erreur serveur (${streamed.statusCode})'; _isScanning = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Impossible de contacter le serveur'; _isScanning = false; });
    }
  }

  void _openSaveSheet() {
    if (_result == null) return;
    if (!AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔒 Connecte-toi dans Profil pour sauvegarder'),
        backgroundColor: Color(0xFFFF6B6B),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveSheet(
        result: _result!,
        imageBytes: _imageBytes,
        fishImageUrl: _fishImageUrl,
        onSaved: () { if (mounted) setState(() => _saved = true); },
      ),
    );
  }

  void _reset() => setState(() {
    _pickedFile = null; _imageBytes = null; _result = null;
    _error = null; _fishImageUrl = null; _isScanning = false;
    _saved = false; _showDetail = false;
  });

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pickedFile == null
          ? _buildPickerView()
          : _buildAnalysisView(),
    );
  }

  // ── Vue initiale ──────────────────────────────────────────────────
  Widget _buildPickerView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FishdexTheme.primary.withOpacity(0.07),
              ),
              child: const Center(child: Text('🐟', style: TextStyle(fontSize: 68))),
            ),
            const SizedBox(height: 20),
            const Text('Identifier un poisson',
              style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Reconnaissance IA · photo ou galerie',
              style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
            const Spacer(),
            // Bouton caméra
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => GestureDetector(
                onTap: () => _pick(ImageSource.camera),
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [FishdexTheme.primary, Color(0xFF00B4D8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FishdexTheme.primary.withOpacity(0.28 + _pulseController.value * 0.14),
                        blurRadius: 18 + _pulseController.value * 6,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('Prendre une photo', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bouton galerie
            GestureDetector(
              onTap: () => _pick(ImageSource.gallery),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: FishdexTheme.primary.withOpacity(0.07),
                  border: Border.all(color: FishdexTheme.primary.withOpacity(0.18)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.photo_on_rectangle, color: FishdexTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Text('Importer depuis la galerie', style: TextStyle(color: FishdexTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // ── Vue analyse / résultat ────────────────────────────────────────
  Widget _buildAnalysisView() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Image preview
        SliverToBoxAdapter(
          child: Stack(
            children: [
              // Image uploadée
              SizedBox(
                height: 300,
                width: double.infinity,
                child: _buildPreviewImage(),
              ),
              // Barre haut
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _reset,
                        child: GlassCard(blur: 20, radius: 14,
                          child: const Padding(
                            padding: EdgeInsets.all(9),
                            child: Icon(CupertinoIcons.xmark, color: FishdexTheme.textPrimary, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scan line
              if (_isScanning)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scanController,
                    builder: (_, __) => CustomPaint(painter: _ScanPainter(_scanController.value)),
                  ),
                ),
            ],
          ),
        ),

        // Panel de résultat
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _isScanning
                ? _buildLoadingCard()
                : _error != null
                    ? _buildErrorCard()
                    : _result != null
                        ? _buildResultCard(_result!)
                        : const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  Widget _buildPreviewImage() {
    if (_imageBytes != null) {
      return Image.memory(_imageBytes!, fit: BoxFit.cover);
    }
    if (kIsWeb && _pickedFile != null) {
      return Image.network(_pickedFile!.path, fit: BoxFit.cover);
    }
    if (_pickedFile != null) {
      return Image.file(File(_pickedFile!.path), fit: BoxFit.cover);
    }
    return Container(color: Colors.grey.shade100);
  }

  // ── Loading card ──────────────────────────────────────────────────
  Widget _buildLoadingCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: FishdexTheme.primary)),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analyse en cours…', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Identification de l\'espèce par IA', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Error card ────────────────────────────────────────────────────
  Widget _buildErrorCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, color: FishdexTheme.coral, size: 32),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickedFile != null && _imageBytes != null
                  ? () => _identify(_pickedFile!, _imageBytes!)
                  : _reset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: FishdexTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Réessayer', style: TextStyle(color: FishdexTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Result card ───────────────────────────────────────────────────
  Widget _buildResultCard(_Result r) {
    final topName = _fr(r.topSpecies);
    final pct = (r.topScore * 100).toStringAsFixed(0);

    return Column(
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                Row(
                  children: [
                    _badge(
                      '${pct}% confiance',
                      CupertinoIcons.checkmark_circle_fill,
                      FishdexTheme.mint,
                    ),
                    const SizedBox(width: 8),
                    _badge(r.family, CupertinoIcons.drop_fill, FishdexTheme.primary),
                  ],
                ),
                const SizedBox(height: 14),

                // Poisson : image Wikipedia + nom
                Row(
                  children: [
                    // Image de l'espèce
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _fishImageUrl != null
                          ? Image.network(
                              _fishImageUrl!,
                              width: 72, height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _emojiBox(r.family),
                            )
                          : _emojiBox(r.family),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topName,
                            style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                          Text(r.topSpecies,
                            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 6),
                          _ScoreBar(score: r.topScore),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bouton "Détail de l'analyse"
                GestureDetector(
                  onTap: () => setState(() => _showDetail = !_showDetail),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Détail de l\'analyse', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _showDetail ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(CupertinoIcons.chevron_down, size: 13, color: FishdexTheme.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top 5
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _showDetail
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: r.top5.asMap().entries.map((e) {
                              final i = e.key;
                              final sp = e.value;
                              final isTop = i == 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26, height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isTop
                                            ? FishdexTheme.primary.withOpacity(0.12)
                                            : Colors.black.withOpacity(0.04),
                                      ),
                                      child: Center(
                                        child: Text('${i+1}',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                            color: isTop ? FishdexTheme.primary : FishdexTheme.textTertiary)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_fr(sp.species),
                                            style: TextStyle(fontSize: 13,
                                              fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                                              color: isTop ? FishdexTheme.textPrimary : FishdexTheme.textSecondary)),
                                          Text(sp.species,
                                            style: const TextStyle(fontSize: 11, color: FishdexTheme.textTertiary, fontStyle: FontStyle.italic)),
                                        ],
                                      ),
                                    ),
                                    Text('${(sp.score * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                        color: isTop ? FishdexTheme.primary : FishdexTheme.textTertiary)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // CTA : Enregistrer
        GestureDetector(
          onTap: _saved ? null : _openSaveSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 54, width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _saved
                  ? const LinearGradient(colors: [FishdexTheme.mint, FishdexTheme.mint])
                  : const LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00B4D8)]),
              boxShadow: [
                BoxShadow(
                  color: (_saved ? FishdexTheme.mint : FishdexTheme.primary).withOpacity(0.25),
                  blurRadius: 14, offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_saved ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.tray_arrow_down,
                    color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(_saved ? 'Enregistré !' : 'Enregistrer la prise',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _badge(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _emojiBox(String family) => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: FishdexTheme.primary.withOpacity(0.07),
    ),
    child: Center(child: Text(_emoji(family), style: const TextStyle(fontSize: 38))),
  );
}

// ── Score bar ────────────────────────────────────────────────────────
class _ScoreBar extends StatelessWidget {
  final double score;
  const _ScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0.7
        ? FishdexTheme.mint
        : score > 0.5
            ? FishdexTheme.golden
            : FishdexTheme.coral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 5,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 3),
        Text('${(score * 100).toStringAsFixed(0)}% correspondance',
          style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 10)),
      ],
    );
  }
}

// ── Feuille de sauvegarde ────────────────────────────────────────────
const _frSave = _frenchNames; // alias local

class _SaveSheet extends StatefulWidget {
  final _Result result;
  final Uint8List? imageBytes;
  final String? fishImageUrl;
  final VoidCallback onSaved;
  const _SaveSheet({
    required this.result, required this.imageBytes,
    required this.fishImageUrl, required this.onSaved,
  });

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  final _sizeCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _locCtrl    = TextEditingController();
  final _notesCtrl  = TextEditingController();
  // 0 = privé (non publié), 1 = amis (privé), 2 = public
  int  _publishMode = 0;
  bool _saving = false;

  @override
  void dispose() {
    _sizeCtrl.dispose(); _weightCtrl.dispose();
    _locCtrl.dispose();  _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final b64 = widget.imageBytes != null ? base64Encode(widget.imageBytes!) : null;
    await CatchService.save(FishCatch(
      userId:       CatchService.userId,
      userName:     CatchService.userName,
      userHandle:   AuthService.currentUserHandle,
      species:      widget.result.topSpecies,
      frenchName:   _fr(widget.result.topSpecies),
      family:       widget.result.family,
      confidence:   widget.result.topScore,
      top5:         widget.result.top5
          .map((e) => {'species': e.species, 'score': e.score})
          .toList(),
      imageBase64:  b64,
      fishImageUrl: widget.fishImageUrl,
      timestamp:    DateTime.now(),
      sizecm:       double.tryParse(_sizeCtrl.text),
      weightkg:     double.tryParse(_weightCtrl.text),
      location:     _locCtrl.text.trim().isEmpty  ? null : _locCtrl.text.trim(),
      notes:        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isPublished:  _publishMode > 0,
      isPrivate:    _publishMode == 1,
    ));
    if (!mounted) return;
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final topName = _fr(widget.result.topSpecies);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, -4))],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // En-tête
            Row(
              children: [
                // Photo preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 52, height: 52, child: _preview()),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topName,
                        style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(widget.result.topSpecies,
                        style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Champs facultatifs
            const Text('INFOS SUR LA PRISE (FACULTATIF)',
              style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field('Taille (cm)', _sizeCtrl, '42',
                    type: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _field('Poids (kg)',  _weightCtrl, '1.8',
                    type: const TextInputType.numberWithOptions(decimal: true))),
              ],
            ),
            const SizedBox(height: 10),
            _field('Lieu de pêche', _locCtrl, 'Lac de Villefranche…'),
            const SizedBox(height: 10),
            _field('Notes', _notesCtrl, 'Belle prise…', maxLines: 2),

            const SizedBox(height: 20),

            // Options de publication
            const Text('VISIBILITÉ',
              style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                _publishBtn(0, '🔒', 'Privé'),
                const SizedBox(width: 8),
                _publishBtn(1, '👥', 'Amis'),
                const SizedBox(width: 8),
                _publishBtn(2, '🌍', 'Public'),
              ],
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: FishdexTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text('Enregistrer',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ignorer',
                    style: TextStyle(color: FishdexTheme.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    if (widget.imageBytes != null) return Image.memory(widget.imageBytes!, fit: BoxFit.cover);
    if (widget.fishImageUrl != null) return Image.network(widget.fishImageUrl!, fit: BoxFit.cover);
    return Container(color: FishdexTheme.primary.withOpacity(0.07),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 26))));
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
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
            controller: ctrl, keyboardType: type, maxLines: maxLines,
            style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _publishBtn(int mode, String emoji, String label) {
    final sel = _publishMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _publishMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: sel ? FishdexTheme.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
            border: Border.all(
              color: sel ? FishdexTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.07),
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(
                color: sel ? FishdexTheme.primary : FishdexTheme.textSecondary,
                fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scan line ────────────────────────────────────────────────────────
class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 20, size.width, 40),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, FishdexTheme.primary.withOpacity(0.5), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40)),
    );
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}
