import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class Conversation {
  final String id, otherUid, otherName, otherHandle, lastMessage;
  final DateTime lastAt;
  final int unread;

  const Conversation({
    required this.id,
    required this.otherUid,
    required this.otherName,
    required this.otherHandle,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  factory Conversation.fromDoc(String currentUid, String id, Map<String, dynamic> d) {
    final participants = List<String>.from(d['participants'] as List? ?? []);
    final otherUid     = participants.firstWhere((p) => p != currentUid, orElse: () => '');
    final userData     = (d['userData'] as Map<String, dynamic>?)?[otherUid] as Map<String, dynamic>? ?? {};
    final unreadMap    = d['unread'] as Map<String, dynamic>? ?? {};
    return Conversation(
      id:          id,
      otherUid:    otherUid,
      otherName:   userData['name']   as String? ?? 'Pêcheur',
      otherHandle: userData['handle'] as String? ?? '',
      lastMessage: d['lastMessage']   as String? ?? '',
      lastAt:      (d['lastAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unread:      (unreadMap[currentUid] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  final String id, senderId, text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromDoc(String id, Map<String, dynamic> d) => ChatMessage(
    id:        id,
    senderId:  d['senderId'] as String? ?? '',
    text:      d['text']     as String? ?? '',
    timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class MessagingService {
  static final _db = FirebaseFirestore.instance;

  static String _convId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  static Future<String> ensureConversation({
    required String otherUid,
    required String otherName,
    required String otherHandle,
  }) async {
    final uid = AuthService.currentUserId;
    final cid = _convId(uid, otherUid);
    final ref = _db.collection('conversations').doc(cid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'participants': [uid, otherUid],
        'userData': {
          uid:      {'name': AuthService.currentUserName,   'handle': AuthService.currentUserHandle},
          otherUid: {'name': otherName, 'handle': otherHandle},
        },
        'lastMessage': '',
        'lastAt':      FieldValue.serverTimestamp(),
        'unread':      {uid: 0, otherUid: 0},
      });
    }
    return cid;
  }

  static Future<String?> sendMessage(
      String convId, String otherUid, String text) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return 'Non connecté';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Message vide';
    try {
      final msgRef = _db.collection('conversations').doc(convId).collection('msgs').doc();
      await msgRef.set({
        'senderId':  uid,
        'text':      trimmed,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _db.collection('conversations').doc(convId).update({
        'lastMessage':        trimmed,
        'lastAt':             FieldValue.serverTimestamp(),
        'unread.$otherUid':   FieldValue.increment(1),
      });
      await _db.collection('notifications').doc(otherUid).collection('items').add({
        'type':         'message',
        'fromUserId':   uid,
        'fromUserName': AuthService.currentUserName,
        'catchId':      convId,
        'catchName':    trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed,
        'timestamp':    FieldValue.serverTimestamp(),
        'read':         false,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> markRead(String convId) async {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return;
    try {
      await _db.collection('conversations').doc(convId).update({'unread.$uid': 0});
    } catch (_) {}
  }

  static Stream<List<Conversation>> conversationsStream() {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return Stream.value([]);
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Conversation.fromDoc(uid, d.id, d.data()))
            .toList())
        .handleError((_) => <Conversation>[]);
  }

  static Stream<List<ChatMessage>> messagesStream(String convId) => _db
      .collection('conversations')
      .doc(convId)
      .collection('msgs')
      .orderBy('timestamp')
      .snapshots()
      .map((s) => s.docs.map((d) => ChatMessage.fromDoc(d.id, d.data())).toList())
      .handleError((_) => <ChatMessage>[]);

  static Stream<int> totalUnreadStream() {
    final uid = AuthService.currentUserId;
    if (uid.isEmpty) return Stream.value(0);
    return _db
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) => s.docs.fold<int>(0, (acc, d) {
              final unread = (d.data()['unread'] as Map?)?[uid];
              return acc + ((unread as num?)?.toInt() ?? 0);
            }))
        .handleError((_) => 0);
  }
}
