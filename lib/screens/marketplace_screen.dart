import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int _selectedCat = 0;
  final _categories = ['Tout', 'Cannes', 'Leurres', 'Moulinets', 'Vêtements', 'Bateaux'];

  final _products = [
    _Product('Canne Shimano Nexave', '89,99 €', '⭐ 4.8', 'Cannes', '🎣'),
    _Product('Leurre Savage Gear', '12,50 €', '⭐ 4.6', 'Leurres', '🪝'),
    _Product('Moulinet Daiwa', '149,00 €', '⭐ 4.9', 'Moulinets', '🔄'),
    _Product('Veste imperméable', '79,00 €', '⭐ 4.7', 'Vêtements', '🧥'),
    _Product('Pack Leurres x20', '24,99 €', '⭐ 4.5', 'Leurres', '🪝'),
    _Product('Canne carbone 3m', '199,00 €', '⭐ 4.9', 'Cannes', '🎣'),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          title: const Text(
            'Marché',
            style: TextStyle(
                color: FishdexTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.search,
                  color: FishdexTheme.textPrimary),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.cart,
                  color: FishdexTheme.textPrimary),
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: _buildCategories(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildProductCard(_products[i], i),
              childCount: _products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final selected = i == _selectedCat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: selected
                    ? FishdexTheme.primary
                    : Colors.white.withOpacity(0.7),
                border: Border.all(
                  color: selected
                      ? FishdexTheme.primary
                      : Colors.black.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Text(
                _categories[i],
                style: TextStyle(
                  color: selected ? Colors.white : FishdexTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(_Product p, int index) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                color: FishdexTheme.primary.withOpacity(0.06),
              ),
              child: Center(
                child: Text(p.emoji, style: const TextStyle(fontSize: 56)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FishdexTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.price,
                      style: const TextStyle(
                        color: FishdexTheme.golden,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      p.rating,
                      style: const TextStyle(
                        color: FishdexTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * index))
        .scale(begin: const Offset(0.9, 0.9));
  }
}

class _Product {
  final String name, price, rating, category, emoji;
  const _Product(this.name, this.price, this.rating, this.category, this.emoji);
}