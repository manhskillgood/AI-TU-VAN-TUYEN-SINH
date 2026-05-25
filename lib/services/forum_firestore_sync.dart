import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../constants/forum_constants.dart';

/// Đồng bộ diễn đàn SQLite ↔ Firestore.
class ForumFirestoreSync {
  ForumFirestoreSync._();
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('forum_posts');

  static Future<void> pushPost({
    required String id,
    required String userId,
    required String author,
    required String title,
    required String content,
    required String category,
    required int createdAtMs,
    int likes = 0,
    int replyCount = 0,
  }) async {
    if (userId.isEmpty) return;
    final now = Timestamp.fromMillisecondsSinceEpoch(createdAtMs);
    await _posts.doc(id).set({
      'id': id,
      'userId': userId,
      'authorUid': userId,
      'userName': author,
      'author': author,
      'title': title,
      'content': content,
      'body': content,
      'category': category,
      'tags': [category],
      'likes': likes,
      'replies': replyCount,
      'createdAt': now,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> pushReply({
    required String postId,
    required String replyId,
    required String userId,
    required String author,
    required String content,
    required int createdAtMs,
  }) async {
    if (userId.isEmpty) return;
    await _posts.doc(postId).collection('replies').doc(replyId).set({
      'id': replyId,
      'postId': postId,
      'userId': userId,
      'authorUid': userId,
      'userName': author,
      'author': author,
      'content': content,
      'body': content,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(createdAtMs),
      'likes': 0,
    });
    await _posts.doc(postId).update({
      'replies': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deletePost(String postId) async {
    try {
      final replies = await _posts.doc(postId).collection('replies').get();
      for (final r in replies.docs) {
        await r.reference.delete();
      }
      await _posts.doc(postId).delete();
    } catch (e) {
      if (kDebugMode) debugPrint('ForumFirestoreSync.deletePost: $e');
      rethrow;
    }
  }

  static int _createdAtMs(Map<String, dynamic> data) {
    final ca = data['createdAt'];
    if (ca is Timestamp) return ca.millisecondsSinceEpoch;
    if (ca is int) return ca;
    if (ca is String) {
      return DateTime.tryParse(ca)?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  static Map<String, Object?> postRowFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final data = d.data();
    final id = (data['id'] as String?)?.isNotEmpty == true ? data['id'] as String : d.id;
    return {
      'id': id,
      'title': data['title'] ?? data['subject'] ?? 'Bài từ cộng đồng',
      'author': data['author'] ?? data['userName'] ?? 'Cộng đồng',
      'content': data['content'] ?? data['body'] ?? '',
      'category': data['category'] ?? ForumCategories.other,
      'likes': data['likes'] is int ? data['likes'] as int : 0,
      'replies': data['replies'] is int ? data['replies'] as int : 0,
      'createdAt': _createdAtMs(data),
    };
  }

  static Map<String, Object?> replyRowFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    String postId,
  ) {
    final data = d.data();
    final id = (data['id'] as String?)?.isNotEmpty == true ? data['id'] as String : d.id;
    return {
      'id': id,
      'postId': postId,
      'author': data['author'] ?? data['userName'] ?? 'Cộng đồng',
      'content': data['content'] ?? data['body'] ?? '',
      'createdAt': _createdAtMs(data),
    };
  }
}
