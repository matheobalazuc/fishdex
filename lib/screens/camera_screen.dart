import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

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
  bool _identified = false;
  File? _selectedImage;

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
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (file != null && mounted) {
      setState(() {
        _selectedImage = File(file.path);
        _identified = false;
      });
      _startIdentification();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null && mounted) {
      setState(() {
        _selectedImage = File(file.path);
        _identified = false;
      });
      _startIdentification();
    }
  }

  void _startIdentification() {
    setState(() {
      _isScanning = true;
      _identified = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _identified = true;
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _identified = false;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FishdexTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond clair avec légère nuance
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F4FF), Color(0xFFF5FAFF)],
              ),
            ),
          ),

          // Zone de preview — image ou placeholder
          if (_selectedImage != null)
            Positioned.fill(
              bottom: _identified ? 320 : 220,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28)),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
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
                    child: const Center(
                      child: Text('🐟', style: TextStyle(fontSize: 60)),
                    ),
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
                    style: TextStyle(
                      color: FishdexTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Animation de scan sur l'image
          if (_isScanning && _selectedImage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 220,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.viewfinder,
                              color: FishdexTheme.primary, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Scanner',
                            style: TextStyle(
                              color: FishdexTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedImage != null)
                    GestureDetector(
                      onTap: _reset,
                      child: GlassCard(
                        blur: 20,
                        radius: 16,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(CupertinoIcons.xmark,
                              color: FishdexTheme.textPrimary, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Panel du bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _identified
                ? _buildResultPanel()
                : _isScanning
                    ? _buildScanningPanel()
                    : _buildPickerPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.88),
                Colors.white.withOpacity(0.72),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FishdexTheme.textTertiary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Bouton principal — Appareil photo
              GestureDetector(
                onTap: _pickFromCamera,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (ctx, child) {
                    return Container(
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
                            color: FishdexTheme.primary.withOpacity(
                                0.28 + _pulseController.value * 0.14),
                            blurRadius: 18 + _pulseController.value * 6,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.camera_fill,
                              color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Prendre une photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Bouton secondaire — Galerie
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: FishdexTheme.primary.withOpacity(0.08),
                    border: Border.all(
                      color: FishdexTheme.primary.withOpacity(0.18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.photo_on_rectangle,
                          color: FishdexTheme.primary, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Importer depuis la galerie',
                        style: TextStyle(
                          color: FishdexTheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildScanningPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.88),
                Colors.white.withOpacity(0.72),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
            ),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: FishdexTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analyse en cours…',
                      style: TextStyle(
                        color: FishdexTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Identification de l\'espèce par IA',
                style: TextStyle(
                    color: FishdexTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.90),
                Colors.white.withOpacity(0.75),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.9), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FishdexTheme.textTertiary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Badge identifié
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FishdexTheme.mint.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: FishdexTheme.mint.withOpacity(0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_circle_fill,
                            color: FishdexTheme.mint, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Identifié — 97% de confiance',
                          style: TextStyle(
                            color: FishdexTheme.mint,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Résultat
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: FishdexTheme.primary.withOpacity(0.08),
                    ),
                    child: const Center(
                        child: Text('🐟', style: TextStyle(fontSize: 40))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Brochet commun',
                          style: TextStyle(
                            color: FishdexTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const Text(
                          'Esox lucius',
                          style: TextStyle(
                            color: FishdexTheme.textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _statChip('60–90 cm', CupertinoIcons.arrow_left_right),
                            const SizedBox(width: 8),
                            _statChip('2–8 kg', CupertinoIcons.chart_bar),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 54,
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
                          child: Text(
                            '+ Ajouter à mon Fishdex',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GlassCard(
                    radius: 16,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(CupertinoIcons.share,
                          color: FishdexTheme.textPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.elasticOut);
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FishdexTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: FishdexTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: FishdexTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          FishdexTheme.primary.withOpacity(0.5),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));
    canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), paint);
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}
