import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class Comment {
  final String id, userId, userName, text;
  final DateTime timestamp;
  const Comment({
    required this.id, required this.userId,
    required this.userName, required this.text,
    required this.timestamp,
  });
  factory Comment.fromDoc(String id, Map<String, dynamic> d) => Comment(
    id:        id,
    userId:    d['userId']   as String? ?? '',
    userName:  d['userName'] as String? ?? 'Pêcheur',
    text:      d['text']     as String? ?? '',
    timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class AppNotification {
  final String id, type, fromUserName, catchId, catchName;
  final String? commentText;
  final bool read;
  final DateTime timestamp;
  const AppNotification({
    required this.id, required this.type, required this.fromUserName,
    required this.catchId, required this.catchName,
    this.commentText, required this.read, required this.timestamp,
  });
  factory AppNotification.fromDoc(String id, Map<String, dynamic> d) => AppNotification(
    id:          id,
    type:        d['type']         as String? ?? 'like',
    fromUserName:d['fromUserName'] as String? ?? 'Pêcheur',
    catchId:     d['catchId']      as String? ?? '',
    catchName:   d['catchName']    as String? ?? '',
    commentText: d['text']         as String?,
    read:        d['read']         as bool?   ?? false,
    timestamp:   (d['timestamp']   as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class SocialService {
  static final _db = FirebaseFirestore.instance;

  // ── Likes ──────────────────────────────────────────────────────────
  static Future<void> toggleLike(
      String catchId, String ownerUserId, String catchName) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return;

    final ref = _db.collection('catches').doc(catchId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final likedBy = List<String>.from(snap.data()?['likedBy'] as List? ?? []);
    final wasLiked = likedBy.contains(uid);
    wasLiked ? likedBy.remove(uid) : likedBy.add(uid);
    await ref.update({'likedBy': likedBy});

    if (!wasLiked && uid != ownerUserId) {
      await _db
          .collection('notifications').doc(ownerUserId)
          .collection('items').add({
        'type':         'like',
        'fromUserId':   uid,
        'fromUserName': AuthService.currentUserName,
        'catchId':      catchId,
        'catchName':    catchName,
        'timestamp':    FieldValue.serverTimestamp(),
        'read':         false,
      });
    }
  }

  // ── Commentaires ──────────────────────────────────────────────────
  static Future<void> addComment(
      String catchId, String text,
      {required String ownerUserId, required String catchName}) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty || text.trim().isEmpty) return;
    await _db.collection('catches').doc(catchId).collection('comments').add({
      'userId':    uid,
      'userName':  AuthService.currentUserName,
      'text':      text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _db.collection('catches').doc(catchId)
        .update({'commentsCount': FieldValue.increment(1)});
    if (uid != ownerUserId) {
      await _db
          .collection('notifications').doc(ownerUserId)
          .collection('items').add({
        'type':         'comment',
        'fromUserId':   uid,
        'fromUserName': AuthService.currentUserName,
        'catchId':      catchId,
        'catchName':    catchName,
        'text':         text.trim(),
        'timestamp':    FieldValue.serverTimestamp(),
        'read':         false,
      });
    }
  }

  static Stream<List<Comment>> commentsStream(String catchId) => _db
      .collection('catches').doc(catchId).collection('comments')
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs.map((d) => Comment.fromDoc(d.id, d.data())).toList());

  // ── Notifications ─────────────────────────────────────────────────
  static Stream<int> unreadNotificationsStream() {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return Stream.value(0);
    return _db.collection('notifications').doc(uid).collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  static Stream<List<AppNotification>> notificationsStream() {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return Stream.value([]);
    return _db.collection('notifications').doc(uid).collection('items')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AppNotification.fromDoc(d.id, d.data()))
            .toList());
  }

  static Future<void> markAllRead() async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return;
    final batch = _db.batch();
    final docs = await _db.collection('notifications').doc(uid).collection('items')
        .where('read', isEqualTo: false).get();
    for (final doc in docs.docs) {
      batch.update(doc.reference, {'read': true});
    }
    if (docs.docs.isNotEmpty) await batch.commit();
  }
}
