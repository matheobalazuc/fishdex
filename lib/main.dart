// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'theme/fishdex_theme.dart';
import 'widgets/liquid_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const FishdexApp());
}

class FishdexApp extends StatelessWidget {
  const FishdexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fishdex',
      theme: FishdexTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const FishdexShell(),
    );
  }
}

class FishdexShell extends StatefulWidget {
  const FishdexShell({super.key});

  @override
  State<FishdexShell> createState() => _FishdexShellState();
}

class _FishdexShellState extends State<FishdexShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<AnimationController> _pageControllers;

  final _screens = const [
    HomeScreen(),
    CollectionScreen(),
    CameraScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageControllers = List.generate(
      5,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 280),
        value: i == 0 ? 1.0 : 0.0,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _pageControllers) c.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    _pageControllers[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _pageControllers[index].forward();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          Container(color: Colors.white),
          ...List.generate(_screens.length, (i) {
            return AnimatedBuilder(
              animation: _pageControllers[i],
              builder: (context, child) {
                final anim = CurvedAnimation(
                  parent: _pageControllers[i],
                  curve: Curves.easeOutCubic,
                );
                return Opacity(
                  opacity: anim.value,
                  child: IgnorePointer(
                    ignoring: i != _currentIndex,
                    child: Transform.translate(
                      offset: Offset(0, (1 - anim.value) * 16),
                      child: child,
                    ),
                  ),
                );
              },
              child: _screens[i],
            );
          }),
          if (_currentIndex == 0)
            const Positioned(
              left: 0, right: 0, bottom: 0,
              child: _InstallBanner(),
            ),
        ],
      ),
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ── Install banner ─────────────────────────────────────────────────────
const _kDismissedKey = 'fdx_install_dismissed';

class _InstallBanner extends StatefulWidget {
  const _InstallBanner();

  @override
  State<_InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<_InstallBanner>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  late AnimationController _anim;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slide = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);

    // Ne pas montrer si déjà fermé ou si l'app est en mode standalone (PWA installée)
    final dismissed = html.window.localStorage[_kDismissedKey] == '1';
    final isStandalone =
        html.window.matchMedia('(display-mode: standalone)').matches;
    if (!dismissed && !isStandalone) {
      // Petit délai pour que l'app soit bien chargée avant d'apparaître
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() => _visible = true);
          _anim.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _dismiss() {
    _anim.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
    html.window.localStorage[_kDismissedKey] = '1';
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final bottom = MediaQuery.of(context).padding.bottom;
    // Hauteur nav bar (~72) + son padding bas + son propre bottom offset (12)
    final navH = 72.0 + bottom + 12.0 + 16.0;

    return AnimatedBuilder(
      animation: _slide,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, (1 - _slide.value) * 120),
        child: Opacity(opacity: _slide.value, child: child),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, navH),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 6)),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.share, color: Colors.white, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Installe l\'app sur ton téléphone',
                  style: TextStyle(
                    color: FishdexTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                RichText(text: TextSpan(
                  style: const TextStyle(
                    color: FishdexTheme.textSecondary, fontSize: 12, height: 1.4),
                  children: [
                    const TextSpan(text: 'Appuie sur '),
                    WidgetSpan(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(CupertinoIcons.share,
                        size: 13, color: FishdexTheme.primary))),
                    const TextSpan(text: ' puis '),
                    const TextSpan(
                      text: '« Ajouter à l\'écran d\'accueil »',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: FishdexTheme.textPrimary)),
                    const TextSpan(
                      text: ' pour utiliser Fishdex App plus facilement.'),
                  ],
                )),
              ],
            )),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _dismiss,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.05)),
                child: const Icon(CupertinoIcons.xmark,
                  size: 13, color: FishdexTheme.textTertiary),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
