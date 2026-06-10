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

  static Stream<List<FishCatch>> stream() => _db
      .collection(_col)
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => FishCatch.fromFirestore(d.id, d.data()))
          .toList());

  static Future<void> delete(String id) =>
      _db.collection(_col).doc(id).delete();
}
