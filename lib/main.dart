import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/fishdex_theme.dart';
import 'widgets/liquid_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/marketplace_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    MarketplaceScreen(),
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
    for (final c in _pageControllers) {
      c.dispose();
    }
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
      backgroundColor: FishdexTheme.background,
      extendBody: true,
      body: Stack(
        children: [
          // Fond blanc épuré avec légère nuance d'eau
          Container(
            color: Colors.white,
          ),
          // Page stack
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
        ],
      ),
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
