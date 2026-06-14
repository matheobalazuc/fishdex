import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../services/wiki_service.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

const _apiUrl = 'https://struck-dept-delayed-resulted.trycloudflare.com/api/predict';

String _fr(String name) => name;

String _emoji(String family) {
  switch (family.toLowerCase()) {
    case 'sparidae':   return '🐟';
    case 'salmonidae': return '🐠';
    case 'esocidae':   return '🐟';
    case 'cyprinidae': return '🐡';
    case 'percidae':   return '🐟';
    case 'moronidae':  return '🦈';
    default:           return '🐟';
  }
}

// ── Comma-safe decimal formatter ─────────────────────────────────────
double? _parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    final text = nw.text.replaceAll(',', '.');
    if (text == nw.text) return nw;
    return nw.copyWith(text: text,
      selection: TextSelection.collapsed(offset: text.length));
  }
}

// ─────────────────────────────────────────────────────────────────────
class _Result {
  final String family;
  final double confidence;
  final List<({String species, double score})> top5;
  const _Result({required this.family, required this.confidence, required this.top5});

  factory _Result.fromJson(Map<String, dynamic> j) => _Result(
    family: j['family'] as String,
    confidence: (j['confidence'] as num).toDouble(),
    top5: (j['top5'] as List)
        .map((e) => (species: e['species'] as String, score: (e['score'] as num).toDouble()))
        .toList(),
  );

  String get topSpecies => top5.isNotEmpty ? top5.first.species : '';
  double get topScore   => top5.isNotEmpty ? top5.first.score   : 0;
}

// ─────────────────────────────────────────────────────────────────────
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;

  bool _isScanning = false;
  bool _isSaving   = false;
  bool _saved      = false;
  bool _showDetail = false;
  bool _aiEnabled  = true;
  String? _error;
  _Result? _result;
  String   _selectedSpecies = '';
  String?  _fishImageUrl;
  XFile?    _pickedFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scanController  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final file = await _picker.pickImage(source: src, imageQuality: 60, maxWidth: 800, maxHeight: 800);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedFile = file; _imageBytes = bytes;
      _result = null; _error = null; _fishImageUrl = null;
      _saved = false; _showDetail = false;
    });
    if (_aiEnabled) await _identify(file, bytes);
  }

  Future<void> _identify(XFile file, Uint8List bytes) async {
    setState(() { _isScanning = true; _error = null; });
    try {
      final req = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      req.files.add(http.MultipartFile.fromBytes(
        'file', bytes, filename: file.name.isNotEmpty ? file.name : 'photo.jpg'));
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();
      if (!mounted) return;
      if (streamed.statusCode == 200) {
        final r = _Result.fromJson(jsonDecode(body) as Map<String, dynamic>);
        final imgUrl = await WikiService.getFishImageUrl(r.topSpecies);
        if (!mounted) return;
        setState(() {
          _result = r; _fishImageUrl = imgUrl; _isScanning = false;
          _selectedSpecies = r.topSpecies;
        });
      } else {
        setState(() { _error = 'Erreur serveur (${streamed.statusCode})'; _isScanning = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Impossible de contacter le serveur'; _isScanning = false; });
    }
  }

  void _openSaveSheet() {
    if (!AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔒 Connecte-toi dans Profil pour sauvegarder'),
        backgroundColor: Color(0xFFFF6B6B), duration: Duration(seconds: 3)));
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _SaveSheet(
        result: _result, imageBytes: _imageBytes, fishImageUrl: _fishImageUrl,
        selectedSpecies: _selectedSpecies,
        onSaved: () { if (mounted) setState(() => _saved = true); }));
  }

  void _reset() => setState(() {
    _pickedFile = null; _imageBytes = null; _result = null;
    _error = null; _fishImageUrl = null; _isScanning = false;
    _saved = false; _showDetail = false; _selectedSpecies = '';
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: _pickedFile == null ? _buildPickerView() : _buildAnalysisView(),
  );

  // ── Vue initiale ──────────────────────────────────────────────────
  Widget _buildPickerView() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: (_aiEnabled ? FishdexTheme.primary : FishdexTheme.textTertiary).withOpacity(0.10)),
                child: Center(child: Text(_aiEnabled ? '🤖' : '✏️', style: const TextStyle(fontSize: 18)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Reconnaissance IA',
                  style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(_aiEnabled ? 'L\'IA propose une liste, tu choisis' : 'Saisie manuelle — remplis toi-même',
                  style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 11)),
              ])),
              CupertinoSwitch(value: _aiEnabled, activeColor: FishdexTheme.primary,
                onChanged: (v) => setState(() => _aiEnabled = v)),
            ]),
          )),
        ),
        const Spacer(),
        Container(width: 130, height: 130,
          decoration: BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary.withOpacity(0.07)),
          child: Center(child: Text(_aiEnabled ? '🐟' : '✏️', style: const TextStyle(fontSize: 68)))),
        const SizedBox(height: 20),
        Text(_aiEnabled ? 'Identifier un poisson' : 'Saisie manuelle',
          style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text(_aiEnabled ? 'L\'IA reconnaît le poisson · tu valides le choix' : 'Prends une photo puis remplis la fiche',
          style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => GestureDetector(
            onTap: () => _pick(ImageSource.camera),
            child: Container(
              width: double.infinity, height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: [FishdexTheme.primary, Color(0xFF00B4D8)]),
                boxShadow: [BoxShadow(
                  color: FishdexTheme.primary.withOpacity(0.28 + _pulseController.value * 0.14),
                  blurRadius: 18 + _pulseController.value * 6, offset: const Offset(0, 6))]),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text('Prendre une photo', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pick(ImageSource.gallery),
          child: Container(
            width: double.infinity, height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: FishdexTheme.primary.withOpacity(0.07),
              border: Border.all(color: FishdexTheme.primary.withOpacity(0.18))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.photo_on_rectangle, color: FishdexTheme.primary, size: 20),
              SizedBox(width: 10),
              Text('Importer depuis la galerie', style: TextStyle(color: FishdexTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(height: 120),
      ]),
    ),
  );

  // ── Vue analyse / résultat ────────────────────────────────────────
  Widget _buildAnalysisView() => CustomScrollView(
    physics: const BouncingScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(child: Stack(children: [
        SizedBox(height: 300, width: double.infinity, child: _buildPreviewImage()),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GestureDetector(
              onTap: _reset,
              child: GlassCard(blur: 20, radius: 14, child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(CupertinoIcons.xmark, color: FishdexTheme.textPrimary, size: 16)))),
          ]),
        )),
        if (_isScanning)
          Positioned.fill(child: AnimatedBuilder(
            animation: _scanController,
            builder: (_, __) => CustomPaint(painter: _ScanPainter(_scanController.value)))),
      ])),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: _isScanning
            ? _buildLoadingCard()
            : _error != null
                ? _buildErrorCard()
                : (_result != null || !_aiEnabled)
                    ? _buildResultCard()
                    : const SizedBox.shrink(),
      )),
      const SliverToBoxAdapter(child: SizedBox(height: 140)),
    ],
  );

  Widget _buildPreviewImage() {
    if (_imageBytes != null) return Image.memory(_imageBytes!, fit: BoxFit.cover);
    if (kIsWeb && _pickedFile != null) return Image.network(_pickedFile!.path, fit: BoxFit.cover);
    if (_pickedFile != null) return Image.file(File(_pickedFile!.path), fit: BoxFit.cover);
    return Container(color: Colors.grey.shade100);
  }

  Widget _buildLoadingCard() => GlassCard(child: Padding(
    padding: const EdgeInsets.all(20),
    child: Row(children: [
      SizedBox(width: 22, height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: FishdexTheme.primary)),
      const SizedBox(width: 16),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analyse en cours…', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        SizedBox(height: 2),
        Text('Identification de l\'espèce par IA', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
      ]),
    ]),
  ));

  Widget _buildErrorCard() => SizedBox(
    width: double.infinity,
    child: GlassCard(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(CupertinoIcons.wifi_slash, color: FishdexTheme.coral, size: 32),
        const SizedBox(height: 10),
        const Text('Serveur IA indisponible',
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('L\'identification automatique n\'est pas disponible pour le moment.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _pickedFile != null && _imageBytes != null
                ? () => _identify(_pickedFile!, _imageBytes!) : _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: FishdexTheme.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12)),
              child: const Text('Réessayer', textAlign: TextAlign.center,
                style: TextStyle(color: FishdexTheme.primary, fontWeight: FontWeight.w600, fontSize: 13))))),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: () => setState(() { _aiEnabled = false; _error = null; }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: FishdexTheme.primary,
                borderRadius: BorderRadius.circular(12)),
              child: const Text('Saisie manuelle', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))))),
        ]),
      ]),
    )),
  );

  Widget _buildResultCard() {
    final r = _result;
    return Column(children: [
      if (r != null) ...[
        GlassCard(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _badge('${(r.topScore * 100).toStringAsFixed(0)}% confiance',
                  CupertinoIcons.checkmark_circle_fill, FishdexTheme.mint),
              const SizedBox(width: 8),
              _badge(r.family, CupertinoIcons.drop_fill, FishdexTheme.primary),
            ]),
            const SizedBox(height: 12),
            // Top5 selection list
            const Text('Choisis le poisson reconnu',
              style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...r.top5.asMap().entries.map((e) {
              final i   = e.key;
              final sp  = e.value;
              final sel = _selectedSpecies == sp.species;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSpecies = sp.species),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: sel ? FishdexTheme.primary.withOpacity(0.08) : Colors.black.withOpacity(0.02),
                      border: Border.all(
                        color: sel ? FishdexTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.06),
                        width: sel ? 1.5 : 1)),
                    child: Row(children: [
                      Container(width: 26, height: 26,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: sel ? FishdexTheme.primary.withOpacity(0.12) : Colors.black.withOpacity(0.04)),
                        child: Center(child: Text('${i + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: sel ? FishdexTheme.primary : FishdexTheme.textTertiary)))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_fr(sp.species), style: TextStyle(
                          color: sel ? FishdexTheme.textPrimary : FishdexTheme.textSecondary,
                          fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                        Text(sp.species, style: const TextStyle(
                          color: FishdexTheme.textTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
                      ])),
                      Text('${(sp.score * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? FishdexTheme.primary : FishdexTheme.textTertiary)),
                      if (sel) ...[
                        const SizedBox(width: 6),
                        const Icon(CupertinoIcons.checkmark_circle_fill,
                          color: FishdexTheme.primary, size: 16),
                      ],
                    ]),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _showDetail = !_showDetail),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.06))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, size: 12, color: FishdexTheme.textTertiary),
                  const SizedBox(width: 5),
                  Text('Voir la photo Wikipedia', style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
                  const SizedBox(width: 6),
                  AnimatedRotation(turns: _showDetail ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                    child: const Icon(CupertinoIcons.chevron_down, size: 11, color: FishdexTheme.textTertiary)),
                ]),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
              child: _showDetail && _fishImageUrl != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: Image.network(_fishImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover)))
                  : const SizedBox.shrink()),
          ]),
        )),
        const SizedBox(height: 12),
      ] else ...[
        GlassCard(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                color: FishdexTheme.primary.withOpacity(0.07)),
              child: const Center(child: Text('✏️', style: TextStyle(fontSize: 28)))),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mode saisie manuelle', style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('Tu rempliras le nom du poisson dans la fiche',
                style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
            ])),
          ]),
        )),
        const SizedBox(height: 12),
      ],
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
            boxShadow: [BoxShadow(
              color: (_saved ? FishdexTheme.mint : FishdexTheme.primary).withOpacity(0.25),
              blurRadius: 14, offset: const Offset(0, 5))]),
          child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_saved ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.tray_arrow_down,
              color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(_saved ? 'Enregistré !' : 'Remplir la fiche descriptive →',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ])),
        ),
      ),
    ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _badge(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.22))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Score bar ─────────────────────────────────────────────────────────
class _ScoreBar extends StatelessWidget {
  final double score;
  const _ScoreBar({required this.score});
  @override
  Widget build(BuildContext context) {
    final color = score > 0.7 ? FishdexTheme.mint : score > 0.5 ? FishdexTheme.golden : FishdexTheme.coral;
    return ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: score, minHeight: 5,
        backgroundColor: color.withOpacity(0.12),
        valueColor: AlwaysStoppedAnimation<Color>(color)));
  }
}

// ── Météo ─────────────────────────────────────────────────────────────
const _weatherOptions = [
  (key: 'sunny',  emoji: '☀️', label: 'Ensoleillé'),
  (key: 'cloudy', emoji: '⛅', label: 'Nuageux'),
  (key: 'rainy',  emoji: '🌧️', label: 'Pluvieux'),
  (key: 'stormy', emoji: '⛈️', label: 'Orageux'),
  (key: 'foggy',  emoji: '🌫️', label: 'Brumeux'),
];

const _seaOptions = [
  (key: 'calm',   emoji: '🟢', label: 'Calme'),
  (key: 'slight', emoji: '🟡', label: 'Légère'),
  (key: 'rough',  emoji: '🟠', label: 'Agitée'),
  (key: 'storm',  emoji: '🔴', label: 'Forte'),
];

// ── Feuille de sauvegarde ─────────────────────────────────────────────
class _SaveSheet extends StatefulWidget {
  final _Result?     result;
  final Uint8List?   imageBytes;
  final String?      fishImageUrl;
  final String       selectedSpecies;
  final VoidCallback onSaved;

  const _SaveSheet({
    required this.result,
    required this.imageBytes,
    required this.fishImageUrl,
    required this.selectedSpecies,
    required this.onSaved,
  });

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  // ── Common fields ─────────────────────────────────────────────────
  final _sizeCtrl   = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _locCtrl    = TextEditingController();
  final _notesCtrl  = TextEditingController();
  final _windCtrl   = TextEditingController();
  // ── Manual fields ─────────────────────────────────────────────────
  final _nameCtrl   = TextEditingController();
  final _latinCtrl  = TextEditingController();
  final _familyCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────
  int     _publishMode     = 0;   // 0=Privé, 1=Public
  String? _weather;
  String? _seaState;
  double? _lat;
  double? _lng;
  double  _locationRadius  = 0;   // km
  bool    _locating        = false;
  bool    _showMapPicker   = false;
  bool    _saving          = false;

  final _mapController = MapController();

  bool get _isManual => widget.result == null;

  @override
  void dispose() {
    for (final c in [_sizeCtrl, _weightCtrl, _locCtrl, _notesCtrl,
                     _windCtrl, _nameCtrl, _latinCtrl, _familyCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────
  Future<void> _detectGPS() async {
    setState(() => _locating = true);
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) { _snack('Service de localisation désactivé'); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _snack('Accès à la position refusé'); return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 10));
      await _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) { _snack('Impossible de localiser'); }
    finally { if (mounted) setState(() => _locating = false); }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() { _lat = point.latitude; _lng = point.longitude; _locating = true; });
    await _reverseGeocode(point.latitude, point.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() { _lat = lat; _lng = lng; });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&accept-language=fr');
      final resp = await http.get(uri, headers: {'User-Agent': 'Fishdex/1.0'})
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final d    = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = d['address'] as Map<String, dynamic>?;
        final city = addr?['city'] ?? addr?['town'] ?? addr?['village'] ?? addr?['municipality'];
        final dept = addr?['county'] ?? addr?['state'];
        final parts = <String>[];
        if (city != null) parts.add(city as String);
        if (dept != null) parts.add(dept as String);
        if (parts.isNotEmpty) setState(() => _locCtrl.text = parts.join(', '));
      }
    } catch (_) {}
    if (mounted) setState(() => _locating = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: FishdexTheme.coral, duration: const Duration(seconds: 2)));

  // ── Save ───────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_isManual && _nameCtrl.text.trim().isEmpty) {
      _snack('Indique le nom du poisson'); return;
    }
    setState(() => _saving = true);
    final b64        = widget.imageBytes != null ? base64Encode(widget.imageBytes!) : null;
    final r          = widget.result;
    final sel        = widget.selectedSpecies;
    final species    = _isManual ? (_latinCtrl.text.trim().isNotEmpty ? _latinCtrl.text.trim() : _nameCtrl.text.trim()) : sel;
    final frenchName = _isManual ? _nameCtrl.text.trim() : _fr(sel);
    final family     = _isManual ? _familyCtrl.text.trim() : r!.family;
    final confidence = _isManual ? 1.0 : (r?.top5.firstWhere((e) => e.species == sel, orElse: () => r!.top5.first).score ?? r!.topScore);
    final top5       = _isManual
        ? [{'species': species, 'score': 1.0}]
        : r!.top5.map((e) => {'species': e.species, 'score': e.score}).toList();

    await CatchService.save(FishCatch(
      userId:         CatchService.userId,
      userName:       CatchService.userName,
      userHandle:     AuthService.currentUserHandle,
      species:        species,
      frenchName:     frenchName,
      family:         family,
      confidence:     confidence,
      top5:           top5,
      imageBase64:    b64,
      fishImageUrl:   widget.fishImageUrl,
      timestamp:      DateTime.now(),
      sizecm:         _parseDecimal(_sizeCtrl.text),
      weightkg:       _parseDecimal(_weightCtrl.text),
      location:       _locCtrl.text.trim().isEmpty  ? null : _locCtrl.text.trim(),
      notes:          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isPublished:    _publishMode == 1,
      isPrivate:      false,
      weather:        _weather,
      seaState:       _seaState,
      windSpeed:      _parseDecimal(_windCtrl.text),
      lat:            _lat,
      lng:            _lng,
      locationRadius: _locationRadius > 0 ? _locationRadius : null,
      isManualEntry:  _isManual,
    ));
    if (!mounted) return;
    widget.onSaved();
    Navigator.pop(context);
  }

  // ── Build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, -4))]),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.12), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // ── Photo header ─────────────────────────────────────────
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 52, height: 52, child: _preview())),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (!_isManual) ...[
                Text(_fr(widget.selectedSpecies),
                  style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                Text(widget.selectedSpecies,
                  style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
              ] else ...[
                const Text('Saisie manuelle',
                  style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Remplis les infos ci-dessous',
                  style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 12)),
              ],
            ])),
          ]),
          const SizedBox(height: 20),

          // ── Identification manuelle ───────────────────────────────
          if (_isManual) ...[
            _sectionLabel('🐟', 'IDENTIFICATION DU POISSON'),
            const SizedBox(height: 10),
            _field('Nom du poisson *', _nameCtrl, 'Ex: Brochet, Truite…'),
            const SizedBox(height: 8),
            _field('Nom latin (optionnel)', _latinCtrl, 'Ex: Esox lucius'),
            const SizedBox(height: 8),
            _field('Famille (optionnel)', _familyCtrl, 'Ex: Esocidae'),
            const SizedBox(height: 20),
          ],

          // ── Mesures ───────────────────────────────────────────────
          _sectionLabel('📏', 'INFOS SUR LA PRISE (FACULTATIF)'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field('Taille (cm)', _sizeCtrl, '42',
                type: const TextInputType.numberWithOptions(decimal: true), decimal: true)),
            const SizedBox(width: 10),
            Expanded(child: _field('Poids (kg)', _weightCtrl, '1.8',
                type: const TextInputType.numberWithOptions(decimal: true), decimal: true)),
          ]),
          const SizedBox(height: 10),

          // ── Lieu + carte ──────────────────────────────────────────
          _sectionLabel('📍', 'LIEU DE PÊCHE'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field('Lieu de pêche', _locCtrl, 'Lac de Villefranche…')),
            const SizedBox(width: 6),
            // GPS
            GestureDetector(
              onTap: _locating ? null : _detectGPS,
              child: Container(
                height: 44, width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: FishdexTheme.primary.withOpacity(0.10),
                  border: Border.all(color: FishdexTheme.primary.withOpacity(0.25))),
                child: _locating
                    ? const Center(child: CupertinoActivityIndicator())
                    : const Icon(CupertinoIcons.location_fill, color: FishdexTheme.primary, size: 18))),
            const SizedBox(width: 6),
            // Toggle carte
            GestureDetector(
              onTap: () => setState(() => _showMapPicker = !_showMapPicker),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 44, width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _showMapPicker ? FishdexTheme.primary : FishdexTheme.primary.withOpacity(0.08),
                  border: Border.all(color: FishdexTheme.primary.withOpacity(0.3))),
                child: Icon(CupertinoIcons.map_fill,
                  color: _showMapPicker ? Colors.white : FishdexTheme.primary, size: 16))),
          ]),

          // ── Carte cliquable ──────────────────────────────────────
          if (_showMapPicker) ...[
            const SizedBox(height: 8),
            _buildMapPicker(),
          ],

          const SizedBox(height: 10),
          _field('Notes', _notesCtrl, 'Belle prise…', maxLines: 2),
          const SizedBox(height: 20),

          // ── Météo ─────────────────────────────────────────────────
          _sectionLabel('🌤️', 'CONDITIONS MÉTÉO (FACULTATIF)'),
          const SizedBox(height: 10),
          _label('Météo'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: _weatherOptions.map((w) {
            final sel = _weather == w.key;
            return GestureDetector(
              onTap: () => setState(() => _weather = sel ? null : w.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: sel ? FishdexTheme.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
                  border: Border.all(
                    color: sel ? FishdexTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.07),
                    width: sel ? 1.5 : 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(w.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(w.label, style: TextStyle(
                    color: sel ? FishdexTheme.primary : FishdexTheme.textSecondary,
                    fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                ])));
          }).toList()),
          const SizedBox(height: 12),
          _label('État de la mer / eau'),
          const SizedBox(height: 6),
          Row(children: _seaOptions.map((s) {
            final sel = _seaState == s.key;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _seaState = sel ? null : s.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: sel ? FishdexTheme.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
                  border: Border.all(
                    color: sel ? FishdexTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.07),
                    width: sel ? 1.5 : 1)),
                child: Column(children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(s.label, style: TextStyle(
                    color: sel ? FishdexTheme.primary : FishdexTheme.textSecondary,
                    fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                ]))));
          }).toList()),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Vent (km/h)', _windCtrl, '15',
                type: const TextInputType.numberWithOptions(decimal: true), decimal: true)),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),

          // ── Visibilité (2 options) ────────────────────────────────
          _sectionLabel('👁️', 'VISIBILITÉ'),
          const SizedBox(height: 10),
          Row(children: [
            _publishBtn(0, '🔒', 'Privé',  'Uniquement toi'),
            const SizedBox(width: 8),
            _publishBtn(1, '🌍', 'Public', 'Visible de tous'),
          ]),
          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: FishdexTheme.primary,
              borderRadius: BorderRadius.circular(16),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : const Text('Enregistrer',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
            const SizedBox(width: 10),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              color: Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              onPressed: () => Navigator.pop(context),
              child: const Text('Ignorer',
                style: TextStyle(color: FishdexTheme.textSecondary, fontWeight: FontWeight.w600))),
          ]),
        ]),
      ),
    );
  }

  // ── Map picker ─────────────────────────────────────────────────────
  Widget _buildMapPicker() {
    final hasPin = _lat != null && _lng != null;
    final center = hasPin ? LatLng(_lat!, _lng!) : const LatLng(46.5, 2.5);
    final zoom   = hasPin ? 12.0 : 5.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tap sur la carte pour placer le pin de pêche',
        style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(height: 220,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center, initialZoom: zoom,
              onTap: (_, point) => _onMapTap(point)),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fishdex.app'),
              if (hasPin) ...[
                if (_locationRadius > 0)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: LatLng(_lat!, _lng!),
                      radius: _locationRadius * 1000,
                      useRadiusInMeter: true,
                      color: FishdexTheme.primary.withOpacity(0.12),
                      borderColor: FishdexTheme.primary.withOpacity(0.5),
                      borderStrokeWidth: 2),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_lat!, _lng!),
                    child: _locating
                        ? const CupertinoActivityIndicator()
                        : const Icon(CupertinoIcons.location_fill, color: FishdexTheme.coral, size: 30)),
                ]),
              ],
            ],
          ),
        ),
      ),
      if (hasPin) ...[
        const SizedBox(height: 10),
        Row(children: [
          const Icon(CupertinoIcons.circle, color: FishdexTheme.primary, size: 14),
          const SizedBox(width: 6),
          Text('Périmètre : ${_locationRadius == 0 ? "Position exacte" : "${_locationRadius.toStringAsFixed(0)} km"}',
            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: FishdexTheme.primary,
            thumbColor: FishdexTheme.primary, inactiveTrackColor: FishdexTheme.primary.withOpacity(0.15),
            trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
          child: Slider(
            value: _locationRadius, min: 0, max: 20, divisions: 20,
            onChanged: (v) => setState(() => _locationRadius = v))),
        const Text('0 = position exacte · slider pour masquer l\'endroit précis',
          style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 10)),
      ],
    ]);
  }

  // ── Widgets helpers ────────────────────────────────────────────────
  Widget _preview() {
    if (widget.imageBytes != null) return Image.memory(widget.imageBytes!, fit: BoxFit.cover);
    if (widget.fishImageUrl != null) return Image.network(widget.fishImageUrl!, fit: BoxFit.cover);
    return Container(color: FishdexTheme.primary.withOpacity(0.07),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 26))));
  }

  Widget _sectionLabel(String emoji, String text, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 13)),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.4)),
      if (trailing != null) ...[const Spacer(), trailing],
    ]),
  );

  Widget _label(String text) => Text(text,
    style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500));

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, int maxLines = 1, bool decimal = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.07))),
        child: TextField(
          controller: ctrl, keyboardType: type, maxLines: maxLines,
          inputFormatters: decimal ? [_DecimalInputFormatter()] : null,
          style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
    ]);
  }

  Widget _publishBtn(int mode, String emoji, String label, String sub) {
    final sel = _publishMode == mode;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _publishMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: sel ? FishdexTheme.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
          border: Border.all(
            color: sel ? FishdexTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.07),
            width: sel ? 1.5 : 1)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color: sel ? FishdexTheme.primary : FishdexTheme.textSecondary,
            fontSize: 12, fontWeight: FontWeight.w700)),
          Text(sub, style: TextStyle(
            color: sel ? FishdexTheme.primary.withOpacity(0.7) : FishdexTheme.textTertiary,
            fontSize: 9, fontWeight: FontWeight.w500)),
        ]),
      ),
    ));
  }
}

// ── Scan line ─────────────────────────────────────────────────────────
class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 20, size.width, 40),
      Paint()..shader = LinearGradient(
        colors: [Colors.transparent, FishdexTheme.primary.withOpacity(0.5), Colors.transparent],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40)));
  }
  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}
