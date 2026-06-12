import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/fishdex_theme.dart';

class _FishingSpot {
  final String name;
  final double lat, lng;
  final String type; // 'river' | 'lake' | 'sea'
  final String fish;
  const _FishingSpot(this.name, this.lat, this.lng, this.type, this.fish);
}

const _spots = <_FishingSpot>[
  // Eau douce - rivières
  _FishingSpot('Gave de Pau',        43.22, -0.77, 'river', 'Saumon, Truite'),
  _FishingSpot('Dordogne',           44.84,  0.60, 'river', 'Truite, Brochet, Sandre'),
  _FishingSpot('Loire',              47.39,  0.69, 'river', 'Sandre, Brochet, Carpe'),
  _FishingSpot('Ardèche',            44.30,  4.46, 'river', 'Truite, Brochet'),
  _FishingSpot('Rhône (Lyon)',        45.74,  4.85, 'river', 'Sandre, Carpe, Brochet'),
  _FishingSpot('Allier',             46.13,  3.43, 'river', 'Saumon, Truite fario'),
  _FishingSpot('Gave d\'Oloron',     43.49, -0.91, 'river', 'Saumon atlantique'),
  _FishingSpot('Tarn',               43.83,  2.15, 'river', 'Truite, Brochet'),
  _FishingSpot('Ain',                45.92,  5.34, 'river', 'Truite, Ombre'),
  // Lacs
  _FishingSpot('Lac d\'Annecy',      45.87,  6.17, 'lake',  'Omble chevalier, Truite'),
  _FishingSpot('Lac du Bourget',     45.73,  5.87, 'lake',  'Omble, Lavaret, Perche'),
  _FishingSpot('Lac du Der',         48.57,  4.73, 'lake',  'Carpe, Brochet, Sandre'),
  _FishingSpot('Lac de Serre-Ponçon',44.55,  6.34, 'lake',  'Truite, Perche, Sandre'),
  _FishingSpot('Lac de Grand-Lieu',  47.06, -1.66, 'lake',  'Brochet, Carpe, Brème'),
  // Mer - Manche
  _FishingSpot('Côte d\'Opale',      50.92,  1.60, 'sea',   'Maquereau, Bar, Lieu'),
  _FishingSpot('Baie de la Seine',   49.42,  0.17, 'sea',   'Bar, Sole, Maquereau'),
  _FishingSpot('Cotentin',           49.35, -1.70, 'sea',   'Bar, Lieu jaune, Daurade'),
  // Mer - Atlantique
  _FishingSpot('Finistère',          48.24, -4.33, 'sea',   'Bar, Lieu jaune, Maquereau'),
  _FishingSpot('Golfe du Morbihan',  47.57, -2.82, 'sea',   'Bar, Daurade, Mulet'),
  _FishingSpot('Baie de Bourgneuf',  46.98, -2.08, 'sea',   'Bar, Sole, Daurade'),
  _FishingSpot('Bassin d\'Arcachon', 44.67, -1.17, 'sea',   'Bar, Mulet, Anguille'),
  _FishingSpot('Pays Basque',        43.48, -1.53, 'sea',   'Bar, Thon rouge, Bonite'),
  // Mer - Méditerranée
  _FishingSpot('Golfe du Lion',      43.12,  3.91, 'sea',   'Daurade, Bar, Rouget'),
  _FishingSpot('Camargue',           43.51,  4.63, 'sea',   'Mulet, Anguille, Bar'),
  _FishingSpot('Côte Bleue (Marseille)',43.36, 5.10,'sea',  'Daurade, Bar, Rouget'),
  _FishingSpot('Var - Côte d\'Azur', 43.23,  6.64, 'sea',   'Daurade, Mérou, Barracuda'),
];

// Zones maritimes approximatives (polygones côtiers)
const _zones = [
  _Zone('Manche',           Color(0xFF0288D1), [
    LatLng(51.0, -1.8), LatLng(51.0, 2.5), LatLng(50.0, 2.5),
    LatLng(49.5, 1.5),  LatLng(49.3, -2.0), LatLng(50.0, -2.2),
  ]),
  _Zone('Atlantique Nord',  Color(0xFF00897B), [
    LatLng(48.8, -4.8), LatLng(48.8, -1.5), LatLng(47.3, -1.5),
    LatLng(46.0, -1.2), LatLng(46.0, -4.0), LatLng(47.5, -5.5),
  ]),
  _Zone('Atlantique Sud',   Color(0xFF43A047), [
    LatLng(46.0, -1.2), LatLng(46.0, -4.0), LatLng(43.5, -4.5),
    LatLng(43.2, -1.7), LatLng(43.5, -0.5), LatLng(44.5, -1.0),
  ]),
  _Zone('Méditerranée',     Color(0xFF1565C0), [
    LatLng(43.8, 3.0),  LatLng(43.8, 7.6),  LatLng(43.0, 7.6),
    LatLng(42.4, 3.3),  LatLng(43.0, 3.0),
  ]),
];

class _Zone {
  final String name;
  final Color color;
  final List<LatLng> points;
  const _Zone(this.name, this.color, this.points);
}

Color _typeColor(String type) {
  switch (type) {
    case 'river': return FishdexTheme.primary;
    case 'lake':  return FishdexTheme.mint;
    case 'sea':   return const Color(0xFF1565C0);
    default:      return FishdexTheme.textTertiary;
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'river': return 'Rivière';
    case 'lake':  return 'Lac';
    case 'sea':   return 'Mer';
    default:      return type;
  }
}

class FishingMapScreen extends StatefulWidget {
  const FishingMapScreen({super.key});
  @override
  State<FishingMapScreen> createState() => _FishingMapScreenState();
}

class _FishingMapScreenState extends State<FishingMapScreen> {
  _FishingSpot? _selected;
  final _mapController = MapController();
  String _filter = 'all'; // 'all' | 'river' | 'lake' | 'sea'

  List<_FishingSpot> get _filtered =>
      _filter == 'all' ? _spots : _spots.where((s) => s.type == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // Carte
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(46.5, 2.5),
            initialZoom: 5.2,
            minZoom: 4.0,
            maxZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fishdex.app',
            ),
            // Zones côtières
            PolygonLayer(polygons: _zones.map((z) => Polygon(
              points: z.points,
              color: z.color.withOpacity(0.18),
              borderColor: z.color,
              borderStrokeWidth: 1.5,
            )).toList()),
            // Cercles autour des spots
            CircleLayer(circles: _filtered.map((s) => CircleMarker(
              point: LatLng(s.lat, s.lng),
              radius: 18000,
              useRadiusInMeter: true,
              color: _typeColor(s.type).withOpacity(0.12),
              borderColor: _typeColor(s.type).withOpacity(0.5),
              borderStrokeWidth: 1,
            )).toList()),
            // Marqueurs
            MarkerLayer(markers: _filtered.map((s) {
              final isSelected = _selected?.name == s.name;
              return Marker(
                point: LatLng(s.lat, s.lng),
                width:  isSelected ? 44 : 32,
                height: isSelected ? 44 : 32,
                child: GestureDetector(
                  onTap: () => setState(() =>
                    _selected = _selected?.name == s.name ? null : s),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _typeColor(s.type),
                      border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                      boxShadow: [BoxShadow(
                        color: _typeColor(s.type).withOpacity(0.4),
                        blurRadius: isSelected ? 12 : 6)],
                    ),
                    child: Center(child: Text(
                      s.type == 'sea' ? '🌊' : s.type == 'lake' ? '🏞️' : '🏄',
                      style: TextStyle(fontSize: isSelected ? 20 : 14))),
                  ),
                ),
              );
            }).toList()),
          ],
        ),

        // App bar flottant
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Back + titre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12)]),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.chevron_back, color: FishdexTheme.primary, size: 20)),
                const SizedBox(width: 8),
                const Text('Carte des spots de pêche',
                  style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _mapController.move(const LatLng(46.5, 2.5), 5.2),
                  child: const Icon(CupertinoIcons.location, color: FishdexTheme.primary, size: 18)),
              ]),
            ),
            const SizedBox(height: 8),
            // Filtres
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('Tout',      'all',   FishdexTheme.textPrimary),
                const SizedBox(width: 6),
                _filterChip('Rivières',  'river', FishdexTheme.primary),
                const SizedBox(width: 6),
                _filterChip('Lacs',      'lake',  FishdexTheme.mint),
                const SizedBox(width: 6),
                _filterChip('Mer',       'sea',   const Color(0xFF1565C0)),
              ]),
            ),
            // Légende zones
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _zones.map((z) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: z.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: z.color.withOpacity(0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: z.color)),
                    const SizedBox(width: 4),
                    Text(z.name, style: TextStyle(color: z.color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )).toList()),
            ),
          ]),
        )),

        // Popup spot sélectionné
        if (_selected != null)
          Positioned(
            left: 12, right: 12, bottom: 24,
            child: _spotCard(_selected!),
          ),
      ]),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? color : Colors.black.withOpacity(0.10)),
          boxShadow: sel ? [] : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]),
        child: Text(label, style: TextStyle(
          color: sel ? Colors.white : FishdexTheme.textSecondary,
          fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _spotCard(_FishingSpot spot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _typeColor(spot.type).withOpacity(0.12)),
          child: Center(child: Text(
            spot.type == 'sea' ? '🌊' : spot.type == 'lake' ? '🏞️' : '🏄',
            style: const TextStyle(fontSize: 24)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(spot.name,
            style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _typeColor(spot.type).withOpacity(0.10),
                borderRadius: BorderRadius.circular(6)),
              child: Text(_typeLabel(spot.type),
                style: TextStyle(color: _typeColor(spot.type), fontSize: 10, fontWeight: FontWeight.w600))),
            const SizedBox(width: 6),
            Expanded(child: Text(spot.fish,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 11))),
          ]),
        ])),
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(spot.name + " pêche France")}');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
          child: Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: FishdexTheme.primary),
            child: const Icon(CupertinoIcons.map_fill, color: Colors.white, size: 16)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _selected = null),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.06)),
            child: const Icon(CupertinoIcons.xmark, color: FishdexTheme.textSecondary, size: 14)),
        ),
      ]),
    );
  }
}
