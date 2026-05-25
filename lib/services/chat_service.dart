import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send message to forum chat
  Future<void> sendMessage({
    required String roomId,
    required ChatMessage message,
  }) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc(message.id)
          .set(message.toJson());

      // Update chat room last message
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp,
        'lastMessageSender': message.senderName,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get messages stream
  Stream<List<ChatMessage>> getMessagesStream({required String roomId}) {
    try {
      return _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get active users in chat room
  Stream<List<Map<String, dynamic>>> getActiveUsersStream({
    required String roomId,
  }) {
    try {
      return _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('active_users')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark user as online
  Future<void> markUserOnline({
    required String roomId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('active_users')
          .doc(userId)
          .set({
        'userId': userId,
        'userName': userName,
        'joinedAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark user as offline
  Future<void> markUserOffline({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('active_users')
          .doc(userId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
