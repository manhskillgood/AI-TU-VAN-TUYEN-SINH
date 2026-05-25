import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Một tin nhắn chat AI đã lưu.
class StoredChatMessage {
  final String id;
  final String text;
  final bool isAi;
  final int createdAtMs;

  const StoredChatMessage({
    required this.id,
    required this.text,
    required this.isAi,
    required this.createdAtMs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isAi': isAi,
        'createdAtMs': createdAtMs,
      };

  factory StoredChatMessage.fromJson(Map<String, dynamic> json) {
    return StoredChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isAi: json['isAi'] as bool? ?? false,
      createdAtMs: json['createdAtMs'] as int? ?? 0,
    );
  }
}

/// Lịch sử chat AI: local (mọi user) + Firestore (đã đăng nhập).
class AdvisorChatHistoryService {
  static const _maxStored = 40;
  static const _threadId = 'default';

  String _localKey(String sessionKey) => 'advisor_chat_v1_$sessionKey';

  String sessionKeyFromContext(String? initialContext) {
    if (initialContext == null || initialContext.trim().isEmpty) {
      return 'general';
    }
    return 'ctx_${initialContext.hashCode}';
  }

  Future<List<StoredChatMessage>> load({
    required String sessionKey,
    String? userId,
  }) async {
    final local = await _loadLocal(sessionKey);
    if (userId == null || userId.isEmpty) return local;

    try {
      final remote = await _loadFirestore(userId);
      if (remote.isEmpty) return local;
      if (local.isEmpty) {
        await _saveLocal(sessionKey, remote);
        return remote;
      }
      // Ưu tiên bản có nhiều tin hơn (thường là local mới nhất).
      return local.length >= remote.length ? local : remote;
    } catch (e) {
      if (kDebugMode) debugPrint('AdvisorChatHistory load remote: $e');
      return local;
    }
  }

  Future<void> saveAll({
    required String sessionKey,
    required List<StoredChatMessage> messages,
    String? userId,
  }) async {
    final trimmed = _trim(messages);
    await _saveLocal(sessionKey, trimmed);
    if (userId == null || userId.isEmpty) return;
    try {
      await _replaceFirestore(userId, trimmed);
    } catch (e) {
      if (kDebugMode) debugPrint('AdvisorChatHistory save remote: $e');
    }
  }

  Future<void> append({
    required String sessionKey,
    required StoredChatMessage message,
    String? userId,
    List<StoredChatMessage>? current,
  }) async {
    final base = current ?? await load(sessionKey: sessionKey, userId: userId);
    final next = _trim([...base, message]);
    await saveAll(sessionKey: sessionKey, messages: next, userId: userId);
  }

  Future<void> clear({
    required String sessionKey,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localKey(sessionKey));
    if (userId == null || userId.isEmpty) return;
    try {
      final col = _messagesCol(userId);
      final snap = await col.limit(100).get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AdvisorChatHistory clear remote: $e');
    }
  }

  List<StoredChatMessage> _trim(List<StoredChatMessage> messages) {
    if (messages.length <= _maxStored) return messages;
    return messages.sublist(messages.length - _maxStored);
  }

  Future<List<StoredChatMessage>> _loadLocal(String sessionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey(sessionKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => StoredChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocal(
    String sessionKey,
    List<StoredChatMessage> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_localKey(sessionKey), encoded);
  }

  CollectionReference<Map<String, dynamic>> _messagesCol(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('advisor_chat_threads')
        .doc(_threadId)
        .collection('messages');
  }

  Future<List<StoredChatMessage>> _loadFirestore(String userId) async {
    final snap = await _messagesCol(userId)
        .orderBy('createdAt', descending: false)
        .limit(_maxStored)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      final ts = data['createdAt'];
      int ms = DateTime.now().millisecondsSinceEpoch;
      if (ts is Timestamp) ms = ts.millisecondsSinceEpoch;
      return StoredChatMessage(
        id: d.id,
        text: data['text'] as String? ?? '',
        isAi: data['isAi'] as bool? ?? false,
        createdAtMs: ms,
      );
    }).toList();
  }

  Future<void> _replaceFirestore(
    String userId,
    List<StoredChatMessage> messages,
  ) async {
    final col = _messagesCol(userId);
    final existing = await col.limit(100).get();
    for (final d in existing.docs) {
      await d.reference.delete();
    }
    for (final m in messages) {
      await col.doc(m.id.isEmpty ? const Uuid().v4() : m.id).set({
        'text': m.text,
        'isAi': m.isAi,
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(m.createdAtMs),
      });
    }
  }
}
