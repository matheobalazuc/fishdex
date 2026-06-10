import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FishdexTheme.abyss,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Simulated camera view
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1,
                colors: [
                  Color(0xFF0D2440),
                  FishdexTheme.abyss,
                ],
              ),
            ),
            child: const Center(
              child: Text('🐟', style: TextStyle(fontSize: 100)),
            ),
          ),
          // Scan overlay
          if (_isScanning)
            AnimatedBuilder(
              animation: _scanController,
              builder: (ctx, child) {
                return CustomPaint(
                  painter: _ScanPainter(_scanController.value),
                );
              },
            ),
          // Corner frame
          _buildCameraFrame(),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.camera_fill,
                              color: FishdexTheme.bioluminescent, size: 16),
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
                  Row(
                    children: [
                      _topButton(CupertinoIcons.bolt_slash, () {}),
                      const SizedBox(width: 8),
                      _topButton(CupertinoIcons.photo_on_rectangle, () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _identified ? _buildResultPanel() : _buildScanPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFrame() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, child) {
        final opacity = 0.4 + _pulseController.value * 0.4;
        return CustomPaint(
          painter: _FramePainter(
            FishdexTheme.bioluminescent.withOpacity(opacity),
          ),
        );
      },
    );
  }

  Widget _topButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: FishdexTheme.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _buildScanPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FishdexTheme.waterSurface.withOpacity(0.8),
                FishdexTheme.deepOcean.withOpacity(0.9),
              ],
            ),
            border: const Border(
              top: BorderSide(color: FishdexTheme.glassBorder, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FishdexTheme.textSecondary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Identifier un poisson',
                style: TextStyle(
                  color: FishdexTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pointez votre caméra vers le poisson',
                style: TextStyle(
                    color: FishdexTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _startIdentification,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (ctx, child) {
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            FishdexTheme.bioluminescent,
                            FishdexTheme.seafoam
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: FishdexTheme.bioluminescent.withOpacity(
                                0.3 + _pulseController.value * 0.3),
                            blurRadius: 20 + _pulseController.value * 10,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.camera_fill,
                        color: FishdexTheme.deepOcean,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildResultPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FishdexTheme.waterSurface.withOpacity(0.9),
                FishdexTheme.deepOcean.withOpacity(0.95),
              ],
            ),
            border: const Border(
              top: BorderSide(color: FishdexTheme.glassBorder, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FishdexTheme.seafoam.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.checkmark_circle_fill,
                            color: FishdexTheme.seafoam, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Identifié — 97%',
                          style: TextStyle(
                            color: FishdexTheme.seafoam,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('🐟', style: TextStyle(fontSize: 50)),
                  const SizedBox(width: 14),
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
                        _statRow('Taille moy.', '60–90 cm'),
                        _statRow('Poids moy.', '2–8 kg'),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              FishdexTheme.bioluminescent,
                              FishdexTheme.seafoam
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            '+ Ajouter à mon Fishdex',
                            style: TextStyle(
                              color: FishdexTheme.deepOcean,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: const Icon(CupertinoIcons.share,
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

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                color: FishdexTheme.textSecondary, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
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
          FishdexTheme.bioluminescent.withOpacity(0.6),
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

class _FramePainter extends CustomPainter {
  final Color color;
  _FramePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 60.0;
    const cornerLen = 30.0;
    final rect = Rect.fromLTWH(
        margin, size.height * 0.2, size.width - margin * 2, size.height * 0.5);

    // Top-left
    canvas.drawLine(
        Offset(rect.left, rect.top + cornerLen), Offset(rect.left, rect.top), paint);
    canvas.drawLine(
        Offset(rect.left, rect.top), Offset(rect.left + cornerLen, rect.top), paint);
    // Top-right
    canvas.drawLine(
        Offset(rect.right - cornerLen, rect.top), Offset(rect.right, rect.top), paint);
    canvas.drawLine(
        Offset(rect.right, rect.top), Offset(rect.right, rect.top + cornerLen), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(rect.left, rect.bottom - cornerLen), Offset(rect.left, rect.bottom), paint);
    canvas.drawLine(
        Offset(rect.left, rect.bottom), Offset(rect.left + cornerLen, rect.bottom), paint);
    // Bottom-right
    canvas.drawLine(
        Offset(rect.right - cornerLen, rect.bottom), Offset(rect.right, rect.bottom), paint);
    canvas.drawLine(
        Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}