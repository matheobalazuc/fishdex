import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class FollowService {
  static final _db = FirebaseFirestore.instance;

  static String _id(String a, String b) => '${a}_$b';

  static Future<String?> follow(String targetId) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return 'Non connecté';
    if (uid == targetId) return null;
    try {
      await _db.collection('follows').doc(_id(uid, targetId)).set({
        'followerId': uid,
        'targetId':   targetId,
        'createdAt':  FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> unfollow(String targetId) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return 'Non connecté';
    try {
      await _db.collection('follows').doc(_id(uid, targetId)).delete();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Stream<bool> isFollowingStream(String targetId) {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return Stream.value(false);
    return _db.collection('follows').doc(_id(uid, targetId))
        .snapshots()
        .map((s) => s.exists)
        .handleError((_) => false);
  }

  static Stream<int> followersCountStream(String userId) => _db
      .collection('follows')
      .where('targetId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.size)
      .handleError((_) => 0);

  static Stream<int> followingCountStream(String userId) => _db
      .collection('follows')
      .where('followerId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.size)
      .handleError((_) => 0);
}
