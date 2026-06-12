import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/messaging_service.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _selectController;
  late Animation<double> _selectAnim;

  static const List<_NavItem> _items = [
    _NavItem(CupertinoIcons.house_fill, CupertinoIcons.house, 'Accueil'),
    _NavItem(CupertinoIcons.cart_fill, CupertinoIcons.cart, 'Marché'),
    _NavItem(CupertinoIcons.camera_fill, CupertinoIcons.camera, 'Scanner'),
    _NavItem(CupertinoIcons.tray_full_fill, CupertinoIcons.tray_full, 'Collection'),
    _NavItem(CupertinoIcons.person_fill, CupertinoIcons.person, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
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
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.82),
                  Colors.white.withOpacity(0.60),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.85),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: FishdexTheme.primary.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: StreamBuilder<int>(
              stream: MessagingService.totalUnreadStream(),
              builder: (context, snap) {
                final unread = snap.data ?? 0;
                return Row(
                  children: List.generate(_items.length, (i) {
                    final selected = i == widget.currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: _NavItemWidget(
                          item: _items[i],
                          selected: selected,
                          selectAnim: selected
                              ? _selectAnim
                              : const AlwaysStoppedAnimation(0),
                          isCamera: i == 2,
                          badgeCount: i == 4 ? unread : 0,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final Animation<double> selectAnim;
  final bool isCamera;
  final int badgeCount;

  const _NavItemWidget({
    required this.item,
    required this.selected,
    required this.selectAnim,
    required this.isCamera,
    this.badgeCount = 0,
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
              final scale = selected ? 1.0 + selectAnim.value * 0.12 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [FishdexTheme.primary, Color(0xFF00C6E0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FishdexTheme.primary.withOpacity(0.40),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.camera_fill,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            },
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
            return Transform.translate(
              offset: Offset(0, selected ? -1.5 * selectAnim.value : 0),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (selected)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FishdexTheme.primary.withOpacity(0.12),
                      ),
                    ),
                  Icon(
                    selected ? item.activeIcon : item.icon,
                    color: selected
                        ? FishdexTheme.primary
                        : FishdexTheme.textTertiary,
                    size: 22,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4, right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: FishdexTheme.coral,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5)),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 3),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected
                ? FishdexTheme.primary
                : FishdexTheme.textTertiary,
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
