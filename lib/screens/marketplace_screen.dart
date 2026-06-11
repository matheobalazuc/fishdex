import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int    _selectedCat  = 0;
  bool   _searchActive = false;
  String _searchQuery  = '';
  final  _searchCtrl   = TextEditingController();

  final _categories = ['Tout', 'Cannes', 'Moulinets', 'Leurres', 'Accessoires'];

  static const _products = [
    _Product('Canne Shimano Nexave CI4+', '89,99 €', 4.8, 'Cannes',
        '🎣', 'Lancer léger, fibre de carbone, 2,70 m'),
    _Product('Canne Daiwa Ninja LT', '69,99 €', 4.5, 'Cannes',
        '🎣', 'Polyvalente rivière & étang'),
    _Product('Canne Mitchell 308 Pro', '129,00 €', 4.7, 'Cannes',
        '🎣', 'Carbonne haute densité, anneaux SIC'),
    _Product('Moulinet Shimano FX 4000', '59,90 €', 4.6, 'Moulinets',
        '🔄', 'Léger, débrayage rapide, 5 roulements'),
    _Product('Moulinet Daiwa Crossfire', '149,00 €', 4.9, 'Moulinets',
        '🔄', 'Frein avant, anti-retour immédiat'),
    _Product('Moulinet Penn Clash II', '199,00 €', 4.8, 'Moulinets',
        '🔄', 'Full métal, 7 roulements, surf'),
    _Product('Leurre Savage Gear 3D Crayfish', '12,50 €', 4.6, 'Leurres',
        '🪝', 'Shrimp réaliste, brochet & perche'),
    _Product('Poisson nageur Rapala Original', '18,00 €', 4.8, 'Leurres',
        '🪝', 'Flottant, 9 cm, action mythique'),
    _Product('Pack leurres souples x20', '24,99 €', 4.5, 'Leurres',
        '🪝', 'Twister, shad, paddle — assortiment'),
    _Product('Épuisette télescopique', '29,90 €', 4.4, 'Accessoires',
        '🥅', 'Manche alu 2 m, maille fine'),
    _Product('Boîte de rangement Plano', '19,99 €', 4.6, 'Accessoires',
        '📦', '3700, 22 compartiments réglables'),
    _Product('Gilet de pêche XL', '79,00 €', 4.7, 'Accessoires',
        '🧥', '14 poches, tissu respirant'),
  ];

  List<_Product> get _filtered {
    final cat = _categories[_selectedCat];
    var list = cat == 'Tout'
        ? _products.toList()
        : _products.where((p) => p.category == cat).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openNearbyStores() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("magasin pêche")}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          pinned: true, elevation: 0,
          title: _searchActive
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    hintStyle: const TextStyle(color: FishdexTheme.textTertiary),
                    border: InputBorder.none,
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchActive = false;
                          _searchQuery  = '';
                          _searchCtrl.clear();
                        });
                      },
                      child: const Icon(CupertinoIcons.xmark_circle_fill,
                          color: FishdexTheme.textTertiary, size: 18),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )
              : const Text('Marché',
                  style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          actions: [
            if (!_searchActive) ...[
              IconButton(
                icon: const Icon(CupertinoIcons.search, color: FishdexTheme.textPrimary),
                onPressed: () => setState(() => _searchActive = true),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.map, color: FishdexTheme.primary),
                tooltip: 'Magasins de pêche près de moi',
                onPressed: _openNearbyStores,
              ),
            ],
          ],
          bottom: _searchActive ? null : PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: _buildCategories(),
          ),
        ),

        if (filtered.isEmpty)
          SliverFillRemaining(
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔍', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Aucun résultat pour "$_searchQuery"',
                style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 15)),
            ])),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildProductCard(filtered[i], i),
                childCount: filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
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
                color: selected ? FishdexTheme.primary : Colors.white.withOpacity(0.7),
                border: Border.all(
                  color: selected ? FishdexTheme.primary : Colors.black.withOpacity(0.08)),
              ),
              child: Text(_categories[i],
                style: TextStyle(
                  color: selected ? Colors.white : FishdexTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
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
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                color: FishdexTheme.primary.withOpacity(0.06),
              ),
              child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 52))),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.price,
                        style: const TextStyle(color: FishdexTheme.golden, fontSize: 14, fontWeight: FontWeight.w700)),
                      Row(children: [
                        const Icon(CupertinoIcons.star_fill, color: FishdexTheme.golden, size: 10),
                        const SizedBox(width: 2),
                        Text('${p.rating}',
                          style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 10)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * index))
        .scale(begin: const Offset(0.92, 0.92));
  }
}

class _Product {
  final String name, price, category, emoji, description;
  final double rating;
  const _Product(this.name, this.price, this.rating, this.category,
      this.emoji, this.description);
}
