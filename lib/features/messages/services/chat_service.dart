import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Generate a deterministic chat ID for two users
  static String chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Stream of all chats where current user is a participant
  Stream<QuerySnapshot<Map<String, dynamic>>> getMyChats() {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection(AppConstants.chatsCollection)
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Stream of messages in a chat room
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatRoomId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesSubcollection)
        .orderBy('sentAt', descending: false)
        .snapshots();
  }

  /// Send a text message and update chat metadata
  Future<void> sendMessage({
    required String chatRoomId,
    required String receiverId,
    required String receiverName,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    final senderName =
        (userDoc.data()?['name'] as String?) ?? user.displayName ?? 'Anonymous';

    final batch = _db.batch();

    // 1. Create or update chat room doc
    final chatRef =
        _db.collection(AppConstants.chatsCollection).doc(chatRoomId);
    batch.set(chatRef, {
      'participants': [user.uid, receiverId],
      'participantNames': {user.uid: senderName, receiverId: receiverName},
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': user.uid,
    }, SetOptions(merge: true));

    // 2. Add message document
    final msgRef = chatRef
        .collection(AppConstants.messagesSubcollection)
        .doc();
    batch.set(msgRef, {
      'senderId': user.uid,
      'senderName': senderName,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  /// Mark all messages as read in a chat room
  Future<void> markAllRead(String chatRoomId) async {
    final uid = _auth.currentUser?.uid ?? '';
    final unread = await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(AppConstants.messagesSubcollection)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: uid)
        .get();
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
