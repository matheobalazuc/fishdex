import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/fishdex_theme.dart';

class LiquidNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LiquidNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<LiquidNavBar> createState() => _LiquidNavBarState();
}

class _LiquidNavBarState extends State<LiquidNavBar>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  late AnimationController _selectController;
  late Animation<double> _selectAnim;

  static const List<_NavItem> _items = [
    _NavItem(CupertinoIcons.house_fill, CupertinoIcons.house, 'Accueil'),
    _NavItem(CupertinoIcons.cart_fill, CupertinoIcons.cart, 'Marché'),
    _NavItem(CupertinoIcons.camera_fill, CupertinoIcons.camera, 'Scanner'),
    _NavItem(CupertinoIcons.chat_bubble_fill, CupertinoIcons.chat_bubble, 'Messages'),
    _NavItem(CupertinoIcons.person_fill, CupertinoIcons.person, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _selectAnim = CurvedAnimation(
      parent: _selectController,
      curve: Curves.elasticOut,
    );
    _selectController.forward();
  }

  @override
  void didUpdateWidget(LiquidNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: 88 + bottomPad,
      child: Stack(
        children: [
          // Glassmorphic background with wave painter
          ClipPath(
            clipper: _WaveTopClipper(),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(_waveController.value),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            FishdexTheme.waterSurface.withOpacity(0.7),
                            FishdexTheme.deepOcean.withOpacity(0.85),
                          ],
                        ),
                        border: const Border(
                          top: BorderSide(
                            color: FishdexTheme.glassBorder,
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Floating bubbles
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _BubblePainter(_bubbleController.value),
                size: Size.infinite,
              );
            },
          ),
          // Nav items
          Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == widget.currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: _NavItemWidget(
                      item: _items[i],
                      selected: selected,
                      selectAnim: selected ? _selectAnim : const AlwaysStoppedAnimation(0),
                      isCamera: i == 2,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final Animation<double> selectAnim;
  final bool isCamera;

  const _NavItemWidget({
    required this.item,
    required this.selected,
    required this.selectAnim,
    required this.isCamera,
  });

  @override
  Widget build(BuildContext context) {
    if (isCamera) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: selectAnim,
            builder: (context, child) {
              final scale = selected ? 1.0 + (selectAnim.value * 0.15) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [FishdexTheme.bioluminescent, FishdexTheme.seafoam],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FishdexTheme.bioluminescent.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    item.activeIcon,
                    color: FishdexTheme.deepOcean,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? FishdexTheme.bioluminescent : FishdexTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: selectAnim,
          builder: (context, child) {
            final bounce = selected ? 1.0 + (selectAnim.value * 0.2) : 1.0;
            return Transform.translate(
              offset: Offset(0, selected ? -2 * selectAnim.value : 0),
              child: Transform.scale(
                scale: bounce,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (selected)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: FishdexTheme.bioluminescent.withOpacity(0.15),
                        ),
                      ),
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      color: selected
                          ? FishdexTheme.bioluminescent
                          : FishdexTheme.textSecondary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? FishdexTheme.bioluminescent : FishdexTheme.textSecondary,
          ),
          child: Text(item.label),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

class _WaveTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 14);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 8);
    path.quadraticBezierTo(size.width * 0.75, 16, size.width, 4);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveTopClipper old) => false;
}

class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FishdexTheme.bioluminescent.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.45 +
          math.sin((x / size.width * 2 * math.pi) + (t * 2 * math.pi)) * 6;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = FishdexTheme.seafoam.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 2 * math.pi) + (t * 2 * math.pi) + 1.2) * 8;
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

class _BubblePainter extends CustomPainter {
  final double t;
  static final List<_Bubble> _bubbles = List.generate(8, (i) {
    final rand = math.Random(i * 17);
    return _Bubble(
      x: rand.nextDouble(),
      phase: rand.nextDouble(),
      size: 2.0 + rand.nextDouble() * 3,
      speed: 0.3 + rand.nextDouble() * 0.4,
    );
  });

  _BubblePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FishdexTheme.bioluminescent.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    for (final b in _bubbles) {
      final progress = (t * b.speed + b.phase) % 1.0;
      final y = size.height * (1 - progress * 0.6);
      final x = size.width * b.x +
          math.sin(progress * math.pi * 4 + b.phase * 6) * 8;
      final opacity = (math.sin(progress * math.pi)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        b.size,
        paint..color = FishdexTheme.bioluminescent.withOpacity(0.3 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t;
}

class _Bubble {
  final double x, phase, size, speed;
  const _Bubble({
    required this.x,
    required this.phase,
    required this.size,
    required this.speed,
  });
}