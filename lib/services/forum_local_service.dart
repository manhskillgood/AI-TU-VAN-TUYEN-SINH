import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../constants/forum_constants.dart';
import 'forum_firestore_sync.dart';

class LocalForumPost {
  final String id;
  final String title;
  final String author;
  final String content;
  final String category;
  final int likes;
  final int replyCount;
  final int createdAt;

  LocalForumPost({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    required this.category,
    required this.likes,
    required this.replyCount,
    required this.createdAt,
  });

  DateTime get createdAtDate =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'content': content,
        'category': category,
        'likes': likes,
        'replies': replyCount,
        'createdAt': createdAt,
      };

  static LocalForumPost fromMap(Map<String, Object?> m) => LocalForumPost(
        id: m['id'] as String,
        title: m['title'] as String,
        author: m['author'] as String,
        content: m['content'] as String,
        category: (m['category'] as String?) ?? ForumCategories.other,
        likes: (m['likes'] as int?) ?? 0,
        replyCount: (m['replies'] as int?) ?? 0,
        createdAt: (m['createdAt'] as int?) ?? 0,
      );
}

class LocalForumReply {
  final String id;
  final String postId;
  final String author;
  final String content;
  final int createdAt;

  LocalForumReply({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  DateTime get createdAtDate =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  static LocalForumReply fromMap(Map<String, Object?> m) => LocalForumReply(
        id: m['id'] as String,
        postId: m['postId'] as String,
        author: m['author'] as String,
        content: m['content'] as String,
        createdAt: (m['createdAt'] as int?) ?? 0,
      );
}

class ForumLocalService {
  static final ForumLocalService _instance = ForumLocalService._internal();
  factory ForumLocalService() => _instance;
  ForumLocalService._internal();

  static const _dbVersion = 2;
  Database? _db;
  bool _seeded = false;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'edu_guidance_forum.db');
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    if (!_seeded) {
      await _seedSamplePosts(_db!);
      _seeded = true;
    }
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        likes INTEGER NOT NULL DEFAULT 0,
        replies INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE replies(
        id TEXT PRIMARY KEY,
        postId TEXT NOT NULL,
        author TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE liked_posts(
        postId TEXT PRIMARY KEY
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          "ALTER TABLE posts ADD COLUMN category TEXT DEFAULT '${ForumCategories.other}'",
        );
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS replies(
          id TEXT PRIMARY KEY,
          postId TEXT NOT NULL,
          author TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS liked_posts(
          postId TEXT PRIMARY KEY
        )
      ''');
    }
  }

  Future<void> _seedSamplePosts(Database db) async {
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM posts')) ??
            0;
    if (count > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    const uuid = Uuid();
    final samples = <({String cat, String title, String body, String author})>[
      (
        cat: ForumCategories.chooseMajor,
        title: 'Khối D01 nên chọn Marketing hay QTKD?',
        body:
            'Mình thích giao tiếp, điểm Văn khá. Các bạn cho xin kinh nghiệm thực tế ạ.',
        author: 'Học sinh THPT',
      ),
      (
        cat: ForumCategories.admission,
        title: 'Điểm chuẩn NEU — FTU khối D dự đoán thế nào?',
        body: 'Điểm dự kiến Toán 7, Văn 8, Anh 8. Nên ưu tiên trường nào ở Miền Bắc?',
        author: 'Phụ huynh',
      ),
    ];

    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      await db.insert('posts', {
        'id': uuid.v4(),
        'title': s.title,
        'author': s.author,
        'content': s.body,
        'category': s.cat,
        'likes': 2 + i,
        'replies': 0,
        'createdAt': now - (i + 1) * 3600000,
      });
    }
  }

  Future<List<LocalForumPost>> getPosts({
    String? category,
    String? query,
  }) async {
    final db = await _database;
    final where = <String>[];
    final args = <Object?>[];

    if (category != null &&
        category.isNotEmpty &&
        category != ForumCategories.all) {
      where.add('category = ?');
      args.add(category);
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      where.add('(title LIKE ? OR content LIKE ? OR author LIKE ?)');
      args.addAll([q, q, q]);
    }

    final rows = await db.query(
      'posts',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'createdAt DESC',
    );
    return rows.map(LocalForumPost.fromMap).toList();
  }

  Future<LocalForumPost?> getPostById(String id) async {
    final db = await _database;
    final rows =
        await db.query('posts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return LocalForumPost.fromMap(rows.first);
  }

  Future<String> addPost({
    required String title,
    required String content,
    String category = ForumCategories.other,
    String? author,
    String? userId,
  }) async {
    final db = await _database;
    final id = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final authorName = (author ?? 'Thành viên').trim();
    await db.insert('posts', {
      'id': id,
      'title': title.trim(),
      'author': authorName,
      'content': content.trim(),
      'category': category,
      'likes': 0,
      'replies': 0,
      'createdAt': now,
    });
    if (userId != null && userId.isNotEmpty) {
      try {
        await ForumFirestoreSync.pushPost(
          id: id,
          userId: userId,
          author: authorName,
          title: title.trim(),
          content: content.trim(),
          category: category,
          createdAtMs: now,
        );
      } catch (e) {
        debugPrint('Forum sync post failed: $e');
        rethrow;
      }
    }
    return id;
  }

  Future<List<LocalForumReply>> getReplies(String postId) async {
    final db = await _database;
    final rows = await db.query(
      'replies',
      where: 'postId = ?',
      whereArgs: [postId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(LocalForumReply.fromMap).toList();
  }

  Future<void> addReply({
    required String postId,
    required String content,
    String? author,
    String? userId,
  }) async {
    final db = await _database;
    final replyId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final authorName = (author ?? 'Thành viên').trim();
    await db.insert('replies', {
      'id': replyId,
      'postId': postId,
      'author': authorName,
      'content': content.trim(),
      'createdAt': now,
    });
    await db.rawUpdate(
      'UPDATE posts SET replies = replies + 1 WHERE id = ?',
      [postId],
    );
    if (userId != null && userId.isNotEmpty) {
      try {
        await ForumFirestoreSync.pushReply(
          postId: postId,
          replyId: replyId,
          userId: userId,
          author: authorName,
          content: content.trim(),
          createdAtMs: now,
        );
      } catch (e) {
        debugPrint('Forum sync reply failed: $e');
        rethrow;
      }
    }
  }

  Future<bool> isPostLiked(String postId) async {
    final db = await _database;
    final rows = await db.query(
      'liked_posts',
      where: 'postId = ?',
      whereArgs: [postId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<({bool liked, int likes})> toggleLike(String postId) async {
    final db = await _database;
    final liked = await isPostLiked(postId);
    if (liked) {
      await db.delete('liked_posts', where: 'postId = ?', whereArgs: [postId]);
      await db.rawUpdate(
        'UPDATE posts SET likes = CASE WHEN likes > 0 THEN likes - 1 ELSE 0 END WHERE id = ?',
        [postId],
      );
    } else {
      await db.insert('liked_posts', {'postId': postId});
      await db.rawUpdate(
        'UPDATE posts SET likes = likes + 1 WHERE id = ?',
        [postId],
      );
    }
    final post = await getPostById(postId);
    return (liked: !liked, likes: post?.likes ?? 0);
  }

  Future<void> deletePost(String postId, {bool syncRemote = true}) async {
    final db = await _database;
    await db.delete('liked_posts', where: 'postId = ?', whereArgs: [postId]);
    await db.delete('replies', where: 'postId = ?', whereArgs: [postId]);
    await db.delete('posts', where: 'id = ?', whereArgs: [postId]);
    if (syncRemote) {
      try {
        await ForumFirestoreSync.deletePost(postId);
      } catch (e) {
        debugPrint('Forum remote delete failed: $e');
      }
    }
  }

  Future<void> pullRemotePostsToLocal({int limit = 50}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('forum_posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final db = await _database;
      for (final d in snap.docs) {
        final row = ForumFirestoreSync.postRowFromDoc(d);
        await db.insert(
          'posts',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('pullRemotePostsToLocal: $e');
    }
  }

  Future<void> pullRepliesToLocal(String postId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('forum_posts')
          .doc(postId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .limit(100)
          .get();
      final db = await _database;
      for (final d in snap.docs) {
        final row = ForumFirestoreSync.replyRowFromDoc(d, postId);
        await db.insert(
          'replies',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      final count = snap.docs.length;
      if (count > 0) {
        await db.rawUpdate(
          'UPDATE posts SET replies = ? WHERE id = ?',
          [count, postId],
        );
      }
    } catch (e) {
      debugPrint('pullRepliesToLocal: $e');
    }
  }
}
