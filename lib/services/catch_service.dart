import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catch_model.dart';
import 'auth_service.dart';

class CatchService {
  static final _db  = FirebaseFirestore.instance;
  static const _col = 'catches';

  static String get userId   => AuthService.currentUserId;
  static String get userName => AuthService.currentUserName;

  static Future<String> save(FishCatch c) async {
    final ref = await _db.collection(_col).add(c.toFirestore());
    if (AuthService.isLoggedIn) {
      await _db.collection('users').doc(AuthService.currentUserId)
          .update({'catchCount': FieldValue.increment(1)})
          .catchError((_) {});
    }
    return ref.id;
  }

  // merge: true → ne touche pas likedBy/commentsCount
  static Future<void> replace(FishCatch c) =>
      _db.collection(_col).doc(c.id!).set(c.toFirestore(), SetOptions(merge: true));

  static Future<void> update(String id, Map<String, dynamic> fields) =>
      _db.collection(_col).doc(id).update(fields);

  static Future<void> delete(String id) async {
    await _db.collection(_col).doc(id).delete();
    if (AuthService.isLoggedIn) {
      await _db.collection('users').doc(AuthService.currentUserId)
          .update({'catchCount': FieldValue.increment(-1)})
          .catchError((_) {});
    }
  }

  static Future<FishCatch?> getById(String id) async {
    final doc = await _db.collection(_col).doc(id).get();
    if (!doc.exists) return null;
    return FishCatch.fromFirestore(doc.id, doc.data()!);
  }

  // Prises de l'utilisateur courant (tri client)
  static Stream<List<FishCatch>> stream() {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return Stream.value([]);
    return _db
        .collection(_col)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => FishCatch.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  // Dernières prises (pour la home)
  static Stream<List<FishCatch>> recentStream({int limit = 5}) {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return Stream.value([]);
    return _db
        .collection(_col)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => FishCatch.fromFirestore(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list.take(limit).toList();
        });
  }

  // Fil public (isPublished=true ET isPrivate=false)
  static Stream<List<FishCatch>> feedStream() => _db
      .collection(_col)
      .where('isPublished', isEqualTo: true)
      .where('isPrivate',   isEqualTo: false)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => FishCatch.fromFirestore(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });

  // Top pêcheurs par nombre de prises
  static Stream<List<Map<String, dynamic>>> topFishersStream() => _db
      .collection('users')
      .orderBy('catchCount', descending: true)
      .limit(5)
      .snapshots()
      .map((s) => s.docs
          .map((d) => <String, dynamic>{...d.data(), 'uid': d.id})
          .toList());
}
