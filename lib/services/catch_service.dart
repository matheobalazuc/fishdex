import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catch_model.dart';

class CatchService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'catches';
  static const userId = 'demo_user';

  static Future<String> save(FishCatch c) async {
    final ref = await _db.collection(_col).add(c.toFirestore());
    return ref.id;
  }

  // Tri côté client pour éviter l'index composite Firestore
  static Stream<List<FishCatch>> stream() => _db
      .collection(_col)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => FishCatch.fromFirestore(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });

  static Future<void> delete(String id) =>
      _db.collection(_col).doc(id).delete();

  static Future<void> update(String id, Map<String, dynamic> fields) =>
      _db.collection(_col).doc(id).update(fields);
}
