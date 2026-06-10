import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catch_model.dart';

class CatchService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'catches';
  static const userId = 'demo_user';
  static const userName = 'Alex Pêcheur';

  static Future<String> save(FishCatch c) async {
    final ref = await _db.collection(_col).add(c.toFirestore());
    return ref.id;
  }

  /// Remplace tous les champs d'une prise existante
  static Future<void> replace(FishCatch c) =>
      _db.collection(_col).doc(c.id!).set(c.toFirestore());

  /// Met à jour des champs partiels
  static Future<void> update(String id, Map<String, dynamic> fields) =>
      _db.collection(_col).doc(id).update(fields);

  static Future<void> delete(String id) =>
      _db.collection(_col).doc(id).delete();

  /// Stream des prises de l'utilisateur (tri côté client — pas d'index composite)
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

  /// Stream du fil public (toutes les prises publiées et non privées)
  static Stream<List<FishCatch>> feedStream() => _db
      .collection(_col)
      .where('isPublished', isEqualTo: true)
      .where('isPrivate', isEqualTo: false)
      .snapshots()
      .map((s) {
        final list = s.docs
            .map((d) => FishCatch.fromFirestore(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });
}
