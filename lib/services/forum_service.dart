import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create forum post
  Future<void> createPost({required ForumPost post}) async {
    try {
      await _firestore.collection('forum_posts').doc(post.id).set(post.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Get all forum posts
  Stream<List<ForumPost>> getPostsStream() {
    try {
      return _firestore
          .collection('forum_posts')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ForumPost.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get post by ID
  Future<ForumPost?> getPostById({required String postId}) async {
    try {
      final doc = await _firestore.collection('forum_posts').doc(postId).get();
      if (doc.exists) {
        return ForumPost.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Add reply to post
  Future<void> addReply({
    required String postId,
    required ForumReply reply,
  }) async {
    try {
      await _firestore
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .doc(reply.id)
          .set(reply.toJson());

      // Update reply count
      await _firestore.collection('forum_posts').doc(postId).update({
        'replies': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get replies for post
  Stream<List<ForumReply>> getRepliesStream({required String postId}) {
    try {
      return _firestore
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ForumReply.fromJson(doc.data()))
            .toList();
      });
    } catch (e) {
      rethrow;
    }
  }

  // Like post
  Future<void> likePost({required String postId}) async {
    try {
      await _firestore.collection('forum_posts').doc(postId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Unlike post
  Future<void> unlikePost({required String postId}) async {
    try {
      await _firestore.collection('forum_posts').doc(postId).update({
        'likes': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost({required String postId}) async {
    try {
      await _firestore.collection('forum_posts').doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
