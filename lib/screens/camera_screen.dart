import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

const _apiUrl = 'https://nashville-healthy-tomato-depot.trycloudflare.com/api/predict';

// Mapping noms latins → français courant
const _frenchNames = {
  'Sparus aurata': 'Daurade royale',
  'Spondyliosoma cantharus': 'Dorade grise',
  'Pagellus erythrinus': 'Pageot rouge',
  'Diplodus puntazzo': 'Sar à museau pointu',
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
  'Gadus morhua': 'Morue',
  'Tinca tinca': 'Tanche',
  'Abramis brama': 'Brème',
  'Rutilus rutilus': 'Gardon',
};

String _frenchName(String latin) => _frenchNames[latin] ?? latin;

// Emoji selon la famille
String _familyEmoji(String family) {
  switch (family.toLowerCase()) {
    case 'sparidae': return '🐟';
    case 'salmonidae': return '🐠';
    case 'esocidae': return '🐟';
    case 'cyprinidae': return '🐡';
    case 'percidae': return '🐟';
    case 'moronidae': return '🦈';
    case 'scombridae': return '🐟';
    default: return '🐟';
  }
}

class _PredictResult {
  final String family;
  final double confidence;
  final List<_Species> top5;
  const _PredictResult({required this.family, required this.confidence, required this.top5});

  factory _PredictResult.fromJson(Map<String, dynamic> j) => _PredictResult(
    family: j['family'] as String,
    confidence: (j['confidence'] as num).toDouble(),
    top5: (j['top5'] as List)
        .map((e) => _Species(species: e['species'], score: (e['score'] as num).toDouble()))
        .toList(),
  );

  String get topSpecies => top5.isNotEmpty ? top5.first.species : '';
  double get topScore => top5.isNotEmpty ? top5.first.score : 0;
}

class _Species {
  final String species;
  final double score;
  const _Species({required this.species, required this.score});
}

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
  _PredictResult? _result;
  String? _error;
  bool _showDetail = false;

  XFile? _pickedFile;

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

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file != null && mounted) {
      setState(() { _pickedFile = file; _result = null; _error = null; _showDetail = false; });
      await _identify(file);
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null && mounted) {
      setState(() { _pickedFile = file; _result = null; _error = null; _showDetail = false; });
      await _identify(file);
    }
  }

  Future<void> _identify(XFile file) async {
    setState(() { _isScanning = true; _error = null; });

    try {
      final bytes = await file.readAsBytes();
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'photo.jpg',
      ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      if (!mounted) return;

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        setState(() {
          _result = _PredictResult.fromJson(data);
          _isScanning = false;
        });
      } else {
        setState(() {
          _error = 'Erreur serveur (${streamed.statusCode})';
          _isScanning = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de contacter le serveur';
        _isScanning = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _pickedFile = null;
      _result = null;
      _error = null;
      _isScanning = false;
      _showDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _pickedFile != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.white),

          // Preview image
          if (hasImage)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: _result != null ? 340 : (_isScanning ? 120 : 200),
              child: _ImagePreview(file: _pickedFile!),
            )
          else
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FishdexTheme.primary.withOpacity(0.08),
                    ),
                    child: const Center(child: Text('🐟', style: TextStyle(fontSize: 60))),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Identifier un poisson',
                    style: TextStyle(
                      color: FishdexTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Photo ou galerie · reconnaissance IA',
                    style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Scan line animation
          if (_isScanning && hasImage)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 120,
              child: AnimatedBuilder(
                animation: _scanController,
                builder: (ctx, _) => CustomPaint(
                  painter: _ScanPainter(_scanController.value),
                ),
              ),
            ),

          // Barre du haut
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassCard(
                    blur: 20,
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.viewfinder, color: FishdexTheme.primary, size: 16),
                          const SizedBox(width: 6),
                          const Text('Scanner',
                            style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  if (hasImage)
                    GestureDetector(
                      onTap: _reset,
                      child: GlassCard(
                        blur: 20,
                        radius: 16,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(CupertinoIcons.xmark, color: FishdexTheme.textPrimary, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Panel bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _result != null
                ? _buildResultPanel(_result!)
                : _isScanning
                    ? _buildScanningPanel()
                    : _error != null
                        ? _buildErrorPanel()
                        : _buildPickerPanel(),
          ),
        ],
      ),
    );
  }

  // ── Panneau sélection ──────────────────────────────────────────
  Widget _buildPickerPanel() {
    return _glassPanel(
      child: Column(
        children: [
          _dragHandle(),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickFromCamera,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (ctx, _) => Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [FishdexTheme.primary, Color(0xFF00B4D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                    Text('Prendre une photo',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              width: double.infinity,
              height: 58,
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
                  Text('Importer depuis la galerie',
                    style: TextStyle(color: FishdexTheme.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic);
  }

  // ── Panneau chargement ─────────────────────────────────────────
  Widget _buildScanningPanel() {
    return _glassPanel(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: FishdexTheme.primary),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analyse en cours…',
                style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Identification de l\'espèce par IA',
                style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Panneau erreur ─────────────────────────────────────────────
  Widget _buildErrorPanel() {
    return _glassPanel(
      child: Column(
        children: [
          _dragHandle(),
          const SizedBox(height: 16),
          const Icon(CupertinoIcons.exclamationmark_circle, color: FishdexTheme.coral, size: 32),
          const SizedBox(height: 8),
          Text(_error ?? 'Erreur inconnue',
            style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickedFile != null ? () => _identify(_pickedFile!) : _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: FishdexTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Réessayer',
                style: TextStyle(color: FishdexTheme.primary, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Panneau résultat ───────────────────────────────────────────
  Widget _buildResultPanel(_PredictResult r) {
    final topName = _frenchName(r.topSpecies);
    final topLatin = r.topSpecies;
    final pct = (r.topScore * 100).toStringAsFixed(0);
    final emoji = _familyEmoji(r.family);

    return _glassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dragHandle(),
          const SizedBox(height: 14),

          // Badge confiance
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FishdexTheme.mint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FishdexTheme.mint.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle_fill, color: FishdexTheme.mint, size: 14),
                    const SizedBox(width: 5),
                    Text('$pct% de confiance',
                      style: const TextStyle(color: FishdexTheme.mint, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: FishdexTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FishdexTheme.primary.withOpacity(0.15)),
                ),
                child: Text(r.family,
                  style: TextStyle(color: FishdexTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Résultat principal
          Row(
            children: [
              Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: FishdexTheme.primary.withOpacity(0.07),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 38))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topName,
                      style: const TextStyle(
                        color: FishdexTheme.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      )),
                    Text(topLatin,
                      style: const TextStyle(
                        color: FishdexTheme.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      )),
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
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Détail de l\'analyse',
                    style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _showDetail ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(CupertinoIcons.chevron_down, size: 14, color: FishdexTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Top 5 expandable
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _showDetail
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: r.top5.asMap().entries.map((e) {
                        final i = e.key;
                        final sp = e.value;
                        final pctSp = (sp.score * 100).toStringAsFixed(1);
                        final isTop = i == 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTop
                                      ? FishdexTheme.primary.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.04),
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isTop ? FishdexTheme.primary : FishdexTheme.textTertiary,
                                    )),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_frenchName(sp.species),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                                        color: isTop ? FishdexTheme.textPrimary : FishdexTheme.textSecondary,
                                      )),
                                    Text(sp.species,
                                      style: const TextStyle(fontSize: 11, color: FishdexTheme.textTertiary, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              Text('$pctSp%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isTop ? FishdexTheme.primary : FishdexTheme.textTertiary,
                                )),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          // CTA
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [FishdexTheme.primary, Color(0xFF00B4D8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FishdexTheme.primary.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('+ Ajouter à mon Fishdex',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GlassCard(
                radius: 16,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(CupertinoIcons.share, color: FishdexTheme.textPrimary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.elasticOut);
  }

  Widget _glassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.92), Colors.white.withOpacity(0.80)],
            ),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.9), width: 1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 32, offset: const Offset(0, -8))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _dragHandle() => Center(
    child: Container(
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

// ── Widget image (web + native) ────────────────────────────────────
class _ImagePreview extends StatelessWidget {
  final XFile file;
  const _ImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Sur web, XFile.path est un blob URL
      return Image.network(file.path, fit: BoxFit.cover);
    }
    // Sur mobile, c'est un chemin fichier
    return Image.file(File(file.path), fit: BoxFit.cover);
  }
}

// ── Barre de score ─────────────────────────────────────────────────
class _ScoreBar extends StatelessWidget {
  final double score;
  const _ScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 5,
            backgroundColor: FishdexTheme.primary.withOpacity(0.10),
            valueColor: AlwaysStoppedAnimation<Color>(
              score > 0.7 ? FishdexTheme.mint : score > 0.5 ? FishdexTheme.golden : FishdexTheme.coral,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text('${(score * 100).toStringAsFixed(0)}% de correspondance',
          style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
      ],
    );
  }
}

// ── Scan line painter ──────────────────────────────────────────────
class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, FishdexTheme.primary.withOpacity(0.5), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));
    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), paint);
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}
