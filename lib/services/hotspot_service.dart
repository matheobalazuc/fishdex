import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class Hotspot {
  final String id, name, fish, userId, userHandle;
  final double rating, lat, lng;
  final double? radius;  // km, null = exact
  final DateTime createdAt;

  const Hotspot({
    required this.id, required this.name, required this.fish,
    required this.userId, required this.userHandle,
    required this.rating, required this.lat, required this.lng,
    this.radius,
    required this.createdAt,
  });

  factory Hotspot.fromDoc(String id, Map<String, dynamic> d) => Hotspot(
    id:         id,
    name:       d['name']       as String? ?? '',
    fish:       d['fish']       as String? ?? '',
    userId:     d['userId']     as String? ?? '',
    userHandle: d['userHandle'] as String? ?? '',
    rating:     (d['rating']    as num?)?.toDouble() ?? 4.0,
    lat:        (d['lat']       as num?)?.toDouble() ?? 0,
    lng:        (d['lng']       as num?)?.toDouble() ?? 0,
    radius:     (d['radius']    as num?)?.toDouble(),
    createdAt:  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class HotspotService {
  static final _db = FirebaseFirestore.instance;

  static Stream<List<Hotspot>> stream() => _db
      .collection('hotspots')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Hotspot.fromDoc(d.id, d.data())).toList())
      .handleError((_) => <Hotspot>[]);

  static Stream<List<Hotspot>> userStream(String userId) => _db
      .collection('hotspots')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Hotspot.fromDoc(d.id, d.data())).toList())
      .handleError((_) => <Hotspot>[]);

  static Future<String?> add({
    required String name,
    required String fish,
    double lat = 0,
    double lng = 0,
    double? radius,
    double rating = 4.0,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return 'Non connecté';
    try {
      await _db.collection('hotspots').add({
        'name':       name,
        'fish':       fish,
        'lat':        lat,
        'lng':        lng,
        if (radius != null && radius > 0) 'radius': radius,
        'rating':     rating,
        'userId':     uid,
        'userHandle': AuthService.currentUserHandle,
        'createdAt':  FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> delete(String id, String ownerId) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return 'Non connecté';
    if (uid != ownerId) return 'Non autorisé';
    try {
      await _db.collection('hotspots').doc(id).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
