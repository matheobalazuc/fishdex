import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/catch_model.dart';
import '../services/auth_service.dart';
import '../services/catch_service.dart';
import '../theme/fishdex_theme.dart';

// ─── Decimal parse + formatter (accepte virgule) ─────────────────────
double? _parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

class _DetailDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    final text = nw.text.replaceAll(',', '.');
    if (text == nw.text) return nw;
    return nw.copyWith(text: text,
      selection: TextSelection.collapsed(offset: text.length));
  }
}

// ─── Labels helpers ───────────────────────────────────────────────
String _weatherLabel(String? key) => const {
  'sunny':  '☀️ Ensoleillé', 'cloudy': '⛅ Nuageux',
  'rainy':  '🌧️ Pluvieux',   'stormy': '⛈️ Orageux', 'foggy': '🌫️ Brumeux',
}[key] ?? '';

String _seaLabel(String? key) => const {
  'calm':   '🟢 Calme',   'slight': '🟡 Légère agitation',
  'rough':  '🟠 Agitée',  'storm':  '🔴 Forte mer',
}[key] ?? '';

const _weatherOptions = [
  (key: 'sunny',  emoji: '☀️', label: 'Ensoleillé'),
  (key: 'cloudy', emoji: '⛅', label: 'Nuageux'),
  (key: 'rainy',  emoji: '🌧️', label: 'Pluvieux'),
  (key: 'stormy', emoji: '⛈️', label: 'Orageux'),
  (key: 'foggy',  emoji: '🌫️', label: 'Brumeux'),
];

const _seaOptions = [
  (key: 'calm',   emoji: '🟢', label: 'Calme'),
  (key: 'slight', emoji: '🟡', label: 'Légère'),
  (key: 'rough',  emoji: '🟠', label: 'Agitée'),
  (key: 'storm',  emoji: '🔴', label: 'Forte'),
];

// ─────────────────────────────────────────────────────────────────
class CatchDetailScreen extends StatefulWidget {
  final FishCatch catch_;
  const CatchDetailScreen({super.key, required this.catch_});
  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  late FishCatch _c;
  bool _editMode     = false;
  bool _saving       = false;
  bool _locating     = false;
  bool _showMapPicker = false;

  late TextEditingController _frenchCtrl;
  late TextEditingController _speciesCtrl;
  late TextEditingController _familyCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _locCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _windCtrl;

  String? _editWeather;
  String? _editSeaState;
  double? _editLat;
  double? _editLng;
  double  _editRadius  = 0;

  Uint8List? _newImageBytes;

  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _c = widget.catch_;
    _frenchCtrl  = TextEditingController();
    _speciesCtrl = TextEditingController();
    _familyCtrl  = TextEditingController();
    _sizeCtrl    = TextEditingController();
    _weightCtrl  = TextEditingController();
    _locCtrl     = TextEditingController();
    _notesCtrl   = TextEditingController();
    _windCtrl    = TextEditingController();
    _initFromCatch();
  }

  void _initFromCatch() {
    _frenchCtrl.text  = _c.frenchName;
    _speciesCtrl.text = _c.species;
    _familyCtrl.text  = _c.family;
    _sizeCtrl.text    = _c.sizecm?.toString()   ?? '';
    _weightCtrl.text  = _c.weightkg?.toString() ?? '';
    _locCtrl.text     = _c.location ?? '';
    _notesCtrl.text   = _c.notes    ?? '';
    _windCtrl.text    = _c.windSpeed?.toString() ?? '';
    _editWeather      = _c.weather;
    _editSeaState     = _c.seaState;
    _editLat          = _c.lat;
    _editLng          = _c.lng;
    _editRadius       = _c.locationRadius ?? 0;
    _showMapPicker    = false;
  }

  @override
  void dispose() {
    for (final c in [_frenchCtrl, _speciesCtrl, _familyCtrl, _sizeCtrl,
                     _weightCtrl, _locCtrl, _notesCtrl, _windCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────
  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) { _showSnack('Service de localisation désactivé'); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _showSnack('Accès à la position refusé'); return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10));
      await _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) { _showSnack('Impossible de localiser'); }
    finally { if (mounted) setState(() => _locating = false); }
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() { _editLat = point.latitude; _editLng = point.longitude; _locating = true; });
    await _reverseGeocode(point.latitude, point.longitude);
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() { _editLat = lat; _editLng = lng; });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&accept-language=fr');
      final resp = await http.get(uri, headers: {'User-Agent': 'Fishdex/1.0'})
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data    = jsonDecode(resp.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        final city    = address?['city'] ?? address?['town'] ?? address?['village'] ?? address?['municipality'];
        final county  = address?['county'] ?? address?['state'];
        final parts   = <String>[];
        if (city   != null) parts.add(city   as String);
        if (county != null) parts.add(county as String);
        if (parts.isNotEmpty) setState(() => _locCtrl.text = parts.join(', '));
      }
    } catch (_) {}
    if (mounted) setState(() => _locating = false);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: FishdexTheme.coral,
        duration: const Duration(seconds: 2)));
  }

  // ── Actions ──────────────────────────────────────────────────────
  Future<void> _pickNewPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 800, maxHeight: 800);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() => _newImageBytes = bytes);
  }

  Future<void> _saveEdits() async {
    if (_c.id == null) return;
    setState(() => _saving = true);
    final newImage  = _newImageBytes != null ? base64Encode(_newImageBytes!) : null;
    final updated   = _c.copyWith(
      frenchName:  _frenchCtrl.text.trim(),
      species:     _speciesCtrl.text.trim(),
      family:      _familyCtrl.text.trim(),
      sizecm:         _parseDecimal(_sizeCtrl.text),
      weightkg:       _parseDecimal(_weightCtrl.text),
      location:       _locCtrl.text.trim().isEmpty  ? null : _locCtrl.text.trim(),
      notes:          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      imageBase64:    newImage,
      weather:        _editWeather,
      seaState:       _editSeaState,
      windSpeed:      _parseDecimal(_windCtrl.text),
      lat:            _editLat,
      lng:            _editLng,
      locationRadius: _editRadius > 0 ? _editRadius : null,
      clearSize:      _sizeCtrl.text.trim().isEmpty,
      clearWeight:    _weightCtrl.text.trim().isEmpty,
      clearLocation:  _locCtrl.text.trim().isEmpty,
      clearNotes:     _notesCtrl.text.trim().isEmpty,
    );
    await CatchService.replace(updated);
    if (!mounted) return;
    setState(() { _c = updated; _editMode = false; _saving = false; _newImageBytes = null; });
  }

  bool get _isOwner => _c.userId == AuthService.currentUserId;

  Future<void> _deleteCatch() async {
    final ok = await _showModernConfirm(context,
      emoji: '🗑️', title: 'Supprimer la prise ?',
      subtitle: '"${_c.frenchName}" sera supprimée définitivement.',
      confirmLabel: 'Supprimer');
    if (!ok) return;
    await CatchService.delete(_c.id!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _togglePublish() async {
    if (_c.id == null) return;
    if (!_c.isPublished) {
      final ok = await _showModernConfirm(context,
        emoji: '📢', title: 'Publier dans le fil ?',
        subtitle: 'Visible de tous les membres Fishdex.',
        confirmLabel: 'Publier', confirmColor: FishdexTheme.primary);
      if (!ok) return;
      await CatchService.update(_c.id!, {'isPublished': true, 'isPrivate': false});
      setState(() => _c = _c.copyWith(isPublished: true, isPrivate: false));
    } else {
      final ok = await _showModernConfirm(context,
        emoji: '👁️', title: 'Retirer du fil ?',
        subtitle: 'La publication ne sera plus visible dans le fil.',
        confirmLabel: 'Retirer', confirmColor: FishdexTheme.golden);
      if (!ok) return;
      await CatchService.update(_c.id!, {'isPublished': false});
      setState(() => _c = _c.copyWith(isPublished: false));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildBody()),
      ],
    ),
  );

  Widget _buildAppBar() => SliverAppBar(
    expandedHeight: 300,
    pinned: true,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    leading: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.35)),
        child: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 18))),
    actions: [
      if (_isOwner) ...[
        if (!_editMode)
          CupertinoButton(
            padding: const EdgeInsets.only(right: 4),
            onPressed: _deleteCatch,
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.35)),
              child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 16))),
        CupertinoButton(
          padding: const EdgeInsets.only(right: 12),
          onPressed: () => setState(() {
            _editMode = !_editMode;
            if (!_editMode) { _initFromCatch(); _newImageBytes = null; }
          }),
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.35)),
            child: Icon(_editMode ? CupertinoIcons.xmark : CupertinoIcons.pencil, color: Colors.white, size: 16))),
      ],
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: GestureDetector(
        onTap: _editMode ? _pickNewPhoto : () => _openFullScreen(context),
        child: Stack(fit: StackFit.expand, children: [
          _buildHeroPhoto(),
          if (_editMode)
            Container(color: Colors.black.withOpacity(0.35),
              child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text('Changer la photo', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ]))),
        ]),
      ),
    ),
  );

  Widget _buildHeroPhoto() {
    if (_newImageBytes != null) return Image.memory(_newImageBytes!, fit: BoxFit.cover);
    if (_c.imageBase64 != null && _c.imageBase64!.isNotEmpty) {
      try { return Image.memory(base64Decode(_c.imageBase64!), fit: BoxFit.cover); } catch (_) {}
    }
    if (_c.fishImageUrl != null) return Image.network(_c.fishImageUrl!, fit: BoxFit.cover);
    return Container(color: FishdexTheme.primary.withOpacity(0.08),
      child: const Center(child: Text('🐟', style: TextStyle(fontSize: 80))));
  }

  void _openFullScreen(BuildContext ctx) {
    Widget? img;
    if (_c.imageBase64 != null && _c.imageBase64!.isNotEmpty) {
      try { img = Image.memory(base64Decode(_c.imageBase64!), fit: BoxFit.contain); } catch (_) { img = null; }
    }
    final Widget? display = img ?? (_c.fishImageUrl != null
        ? Image.network(_c.fishImageUrl!, fit: BoxFit.contain) : null);
    if (display != null) _pushFullScreen(ctx, display);
  }

  void _pushFullScreen(BuildContext ctx, Widget child) =>
      Navigator.push(ctx, PageRouteBuilder(opaque: false,
        pageBuilder: (_, __, ___) => _FullScreenViewer(child: child)));

  // ── Corps ─────────────────────────────────────────────────────────
  Widget _buildBody() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _editMode ? _buildEditForm() : _buildReadView(),
    ]),
  );

  // ── Lecture ───────────────────────────────────────────────────────
  Widget _buildReadView() {
    final hasWeather = _c.weather != null || _c.seaState != null || _c.windSpeed != null;
    final hasLocation = _c.location != null || _c.lat != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Titre
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_c.frenchName,
            style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          Text(_c.species,
            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14, fontStyle: FontStyle.italic)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_formatDate(_c.timestamp),
            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(_formatTime(_c.timestamp),
            style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
        ]),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        _pill(_c.family, FishdexTheme.primary),
        if (!_c.isManualEntry) _pill('${(_c.confidence * 100).toStringAsFixed(1)}%', FishdexTheme.mint),
        if (_c.isPublished) _pill(_c.isPrivate ? '🔒 Privé' : '🌍 Public', FishdexTheme.golden),
      ]),

      // Infos prise
      const SizedBox(height: 20),
      if (_c.sizecm   != null) _infoRow(CupertinoIcons.arrow_left_right, 'Taille',  '${_c.sizecm} cm'),
      if (_c.weightkg != null) _infoRow(CupertinoIcons.chart_bar,        'Poids',   '${_c.weightkg} kg'),
      if (_c.notes    != null) _infoRow(CupertinoIcons.text_alignleft,   'Notes',   _c.notes!),

      // Lieu + carte
      if (hasLocation) ...[
        if (_c.location != null) _infoRow(CupertinoIcons.location_fill, 'Lieu', _c.location!),
        if (_c.lat != null && _c.lng != null) _buildReadMap(),
      ],

      // Météo
      if (hasWeather) _buildWeatherBlock(),

      // Photo Wikipedia
      if (_c.fishImageUrl != null) ...[
        const SizedBox(height: 20),
        _buildWikiCard(),
      ],

      // Confiance + Top 5 (IA only)
      if (!_c.isManualEntry) ...[
        const SizedBox(height: 20),
        _buildConfidence(),
        const SizedBox(height: 16),
        _buildTop5(),
      ],

      if (_isOwner) ...[
        const SizedBox(height: 28),
        _buildPublishButton(),
      ],
    ]);
  }

  Widget _buildWeatherBlock() {
    final parts = <String>[];
    if (_c.weather  != null) parts.add(_weatherLabel(_c.weather!));
    if (_c.seaState != null) parts.add(_seaLabel(_c.seaState!));
    if (_c.windSpeed != null) parts.add('💨 ${_c.windSpeed!.toStringAsFixed(0)} km/h');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.golden.withOpacity(0.08)),
          child: const Icon(CupertinoIcons.cloud_sun, color: FishdexTheme.golden, size: 15)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Conditions météo', style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
          const SizedBox(height: 2),
          Wrap(spacing: 6, runSpacing: 4, children: parts.map((p) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: FishdexTheme.golden.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FishdexTheme.golden.withOpacity(0.2))),
            child: Text(p, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          )).toList()),
        ])),
      ]),
    );
  }

  Widget _buildReadMap() => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Localisation précise',
        style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(height: 160,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(_c.lat!, _c.lng!),
              initialZoom: 13,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fishdex.app'),
              if (_c.locationRadius != null && _c.locationRadius! > 0)
                CircleLayer(circles: [
                  CircleMarker(
                    point: LatLng(_c.lat!, _c.lng!),
                    radius: _c.locationRadius! * 1000,
                    useRadiusInMeter: true,
                    color: FishdexTheme.primary.withOpacity(0.10),
                    borderColor: FishdexTheme.primary.withOpacity(0.45),
                    borderStrokeWidth: 2),
                ]),
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(_c.lat!, _c.lng!),
                  child: const Icon(CupertinoIcons.location_fill, color: FishdexTheme.coral, size: 30)),
              ]),
            ],
          ),
        ),
      ),
      if (_c.locationRadius != null && _c.locationRadius! > 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Périmètre affiché : ${_c.locationRadius!.toStringAsFixed(0)} km',
            style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 10))),
    ]),
  );

  Widget _buildWikiCard() => GestureDetector(
    onTap: () => _pushFullScreen(context, Image.network(_c.fishImageUrl!, fit: BoxFit.contain)),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(children: [
        Image.network(_c.fishImageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
        Positioned(bottom: 8, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(CupertinoIcons.zoom_in, color: Colors.white, size: 11),
              SizedBox(width: 4),
              Text('Photo Wikipedia', style: TextStyle(color: Colors.white, fontSize: 10)),
            ]))),
      ]),
    ),
  );

  Widget _buildConfidence() {
    final pct   = _c.confidence;
    final color = pct > 0.7 ? FishdexTheme.mint : pct > 0.4 ? FishdexTheme.golden : FishdexTheme.coral;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Confiance IA', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
        Text('${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct, minHeight: 6,
          backgroundColor: Colors.black.withOpacity(0.06),
          valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }

  Widget _buildTop5() {
    if (_c.top5.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Top 5 identifications', style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      ...(_c.top5.asMap().entries.map((e) {
        final i  = e.key;
        final sp = e.value['species'] as String? ?? '';
        final sc = (e.value['score'] as num?)?.toDouble() ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(width: 22, height: 22,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: i == 0 ? FishdexTheme.primary.withOpacity(0.1) : Colors.black.withOpacity(0.04)),
              child: Center(child: Text('${i + 1}', style: TextStyle(
                color: i == 0 ? FishdexTheme.primary : FishdexTheme.textTertiary,
                fontSize: 10, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(child: Text(sp, style: TextStyle(
              color: i == 0 ? FishdexTheme.textPrimary : FishdexTheme.textSecondary,
              fontSize: 13, fontStyle: FontStyle.italic,
              fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400))),
            Text('${(sc * 100).toStringAsFixed(0)}%', style: TextStyle(
              color: i == 0 ? FishdexTheme.primary : FishdexTheme.textTertiary,
              fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        );
      })),
    ]);
  }

  Widget _buildPublishButton() {
    final published = _c.isPublished;
    return SizedBox(width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: published ? FishdexTheme.coral.withOpacity(0.12) : FishdexTheme.primary,
        borderRadius: BorderRadius.circular(16),
        onPressed: _togglePublish,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(published ? CupertinoIcons.eye_slash_fill : CupertinoIcons.paperplane_fill,
            color: published ? FishdexTheme.coral : Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            published ? (_c.isPrivate ? 'Publié (privé) · Retirer' : 'Publié (public) · Retirer') : 'Publier dans le fil',
            style: TextStyle(color: published ? FishdexTheme.coral : Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ));
  }

  // ── Édition ───────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Modifier la prise',
        style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Tape sur la photo en haut pour la changer',
        style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 12)),
      const SizedBox(height: 20),

      _sectionLabel('Identification'),
      _field('Nom français',     _frenchCtrl,  'Daurade royale'),
      const SizedBox(height: 10),
      _field('Nom scientifique', _speciesCtrl, 'Sparus aurata', italic: true),
      const SizedBox(height: 10),
      _field('Famille',          _familyCtrl,  'Sparidae'),
      const SizedBox(height: 20),

      _sectionLabel('Ma prise (facultatif)'),
      Row(children: [
        Expanded(child: _field('Taille (cm)', _sizeCtrl, '42',
            type: const TextInputType.numberWithOptions(decimal: true), decimal: true)),
        const SizedBox(width: 12),
        Expanded(child: _field('Poids (kg)', _weightCtrl, '1.8',
            type: const TextInputType.numberWithOptions(decimal: true), decimal: true)),
      ]),
      const SizedBox(height: 10),
      _field('Notes', _notesCtrl, 'Belle prise sur leurre…', maxLines: 3),
      const SizedBox(height: 20),

      // ── Lieu + carte ──────────────────────────────────────────────
      _sectionLabel('Lieu de pêche'),
      Row(children: [
        Expanded(child: _field('Lieu de pêche', _locCtrl, 'Lac de Villefranche…')),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _locating ? null : _detectLocation,
          child: Container(
            height: 42, width: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: FishdexTheme.primary.withOpacity(0.10),
              border: Border.all(color: FishdexTheme.primary.withOpacity(0.25))),
            child: _locating
                ? const Center(child: CupertinoActivityIndicator())
                : const Icon(CupertinoIcons.location_fill, color: FishdexTheme.primary, size: 18))),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() => _showMapPicker = !_showMapPicker),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42, width: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _showMapPicker ? FishdexTheme.primary : FishdexTheme.primary.withOpacity(0.08),
              border: Border.all(color: FishdexTheme.primary.withOpacity(0.3))),
            child: Icon(CupertinoIcons.map_fill,
              color: _showMapPicker ? Colors.white : FishdexTheme.primary, size: 16))),
      ]),

      if (_showMapPicker) ...[
        const SizedBox(height: 8),
        _buildMapPickerWidget(),
      ],
      const SizedBox(height: 20),

      // ── Météo ─────────────────────────────────────────────────────
      _sectionLabel('Conditions météo (facultatif)'),
      _fieldLabel('Météo'),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: _weatherOptions.map((w) {
        final sel = _editWeather == w.key;
        return GestureDetector(
          onTap: () => setState(() => _editWeather = sel ? null : w.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: sel ? FishdexTheme.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
              border: Border.all(
                color: sel ? FishdexTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.07),
                width: sel ? 1.5 : 1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(w.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(w.label, style: TextStyle(
                color: sel ? FishdexTheme.primary : FishdexTheme.textSecondary,
                fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
            ])));
      }).toList()),
      const SizedBox(height: 12),

      _fieldLabel('État de la mer / eau'),
      const SizedBox(height: 6),
      Row(children: _seaOptions.map((s) {
        final sel = _editSeaState == s.key;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _editSeaState = sel ? null : s.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: sel ? FishdexTheme.primary.withOpacity(0.10) : Colors.black.withOpacity(0.03),
              border: Border.all(
                color: sel ? FishdexTheme.primary.withOpacity(0.4) : Colors.black.withOpacity(0.07),
                width: sel ? 1.5 : 1)),
            child: Column(children: [
              Text(s.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 2),
              Text(s.label, style: TextStyle(
                color: sel ? FishdexTheme.primary : FishdexTheme.textSecondary,
                fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
            ]))));
      }).toList()),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(child: _field('Vent (km/h)', _windCtrl, '15',
            type: const TextInputType.numberWithOptions(decimal: true), decimal: true)),
        const Expanded(child: SizedBox()),
      ]),
      const SizedBox(height: 24),

      SizedBox(width: double.infinity,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: FishdexTheme.primary,
          borderRadius: BorderRadius.circular(16),
          onPressed: _saving ? null : _saveEdits,
          child: _saving
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Text('Enregistrer',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
    ]);
  }

  Widget _buildMapPickerWidget() {
    final hasPin = _editLat != null && _editLng != null;
    final center = hasPin ? LatLng(_editLat!, _editLng!) : const LatLng(46.5, 2.5);
    final zoom   = hasPin ? 12.0 : 5.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tap sur la carte pour placer le pin',
        style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(height: 220,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              onTap: (_, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fishdex.app'),
              if (hasPin) ...[
                if (_editRadius > 0)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: LatLng(_editLat!, _editLng!),
                      radius: _editRadius * 1000,
                      useRadiusInMeter: true,
                      color: FishdexTheme.primary.withOpacity(0.10),
                      borderColor: FishdexTheme.primary.withOpacity(0.45),
                      borderStrokeWidth: 2),
                  ]),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_editLat!, _editLng!),
                    child: Stack(alignment: Alignment.center, children: [
                      const Icon(CupertinoIcons.location_fill, color: FishdexTheme.coral, size: 32),
                      if (_locating)
                        Positioned(top: -4, child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary))),
                    ])),
                ]),
              ],
            ],
          ),
        ),
      ),
      if (hasPin) ...[
        const SizedBox(height: 10),
        Row(children: [
          const Icon(CupertinoIcons.circle, color: FishdexTheme.primary, size: 14),
          const SizedBox(width: 6),
          Text('Périmètre : ${_editRadius == 0 ? "Position exacte" : "${_editRadius.toStringAsFixed(0)} km"}',
            style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: FishdexTheme.primary,
            thumbColor: FishdexTheme.primary,
            inactiveTrackColor: FishdexTheme.primary.withOpacity(0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
          child: Slider(
            value: _editRadius, min: 0, max: 20, divisions: 20,
            onChanged: (v) => setState(() => _editRadius = v))),
        const Text('0 = position exacte · glisse pour masquer l\'endroit précis',
          style: TextStyle(color: FishdexTheme.textTertiary, fontSize: 10)),
      ],
    ]);
  }

  // ── Petits helpers ────────────────────────────────────────────────
  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(
      color: FishdexTheme.textSecondary, fontSize: 12,
      fontWeight: FontWeight.w600, letterSpacing: 0.5)));

  Widget _fieldLabel(String t) => Text(t,
    style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500));

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, int maxLines = 1, bool italic = false, bool decimal = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.07))),
        child: TextField(
          controller: ctrl, keyboardType: type, maxLines: maxLines,
          inputFormatters: decimal ? [_DetailDecimalFormatter()] : null,
          style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 14,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)))),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(shape: BoxShape.circle, color: FishdexTheme.primary.withOpacity(0.08)),
        child: Icon(icon, color: FishdexTheme.primary, size: 15)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 11)),
        Text(value, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ]),
  );

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)));

  String _formatDate(DateTime d) {
    const m = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${d.day} ${m[d.month - 1]}. ${d.year}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

// ── Météo/mer dans le feed card (utilisé par home_screen) ──────────
String weatherSummary(FishCatch c) {
  final parts = <String>[];
  if (c.weather != null)   parts.add(_weatherLabel(c.weather!));
  if (c.seaState != null)  parts.add(_seaLabel(c.seaState!));
  if (c.windSpeed != null) parts.add('💨 ${c.windSpeed!.toStringAsFixed(0)} km/h');
  return parts.join(' · ');
}

// ── Helpers globaux ────────────────────────────────────────────────
Future<bool> _showModernConfirm(
  BuildContext context, {
  required String emoji, required String title,
  required String subtitle, required String confirmLabel,
  Color confirmColor = FishdexTheme.coral,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context, backgroundColor: Colors.transparent,
    builder: (_) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(color: FishdexTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(color: FishdexTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Container(height: 52,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('Annuler',
                style: TextStyle(color: FishdexTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)))))),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(height: 52,
              decoration: BoxDecoration(color: confirmColor, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))))),
        ]),
        const SizedBox(height: 4),
      ]),
    ),
  );
  return result ?? false;
}

class _FullScreenViewer extends StatelessWidget {
  final Widget child;
  const _FullScreenViewer({required this.child});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Scaffold(
      backgroundColor: Colors.black.withOpacity(0.92),
      body: SafeArea(child: Stack(children: [
        Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4, child: child)),
        Positioned(top: 12, right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
              child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 18)))),
      ])),
    ),
  );
}
