import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  List<Map<String, dynamic>> _activeUsers = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  List<Map<String, dynamic>> get activeUsers => _activeUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Listen to messages
  void listenToMessages({required String roomId}) {
    try {
      _chatService.getMessagesStream(roomId: roomId).listen((messages) {
        _messages = messages;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Listen to active users
  void listenToActiveUsers({required String roomId}) {
    try {
      _chatService.getActiveUsersStream(roomId: roomId).listen((users) {
        _activeUsers = users;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String? senderAvatar,
    required String content,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final message = ChatMessage(
        id: const Uuid().v4(),
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        timestamp: DateTime.now(),
        isAI: false,
      );

      await _chatService.sendMessage(roomId: roomId, message: message);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark user online
  Future<void> markUserOnline({
    required String roomId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _chatService.markUserOnline(
        roomId: roomId,
        userId: userId,
        userName: userName,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mark user offline
  Future<void> markUserOffline({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _chatService.markUserOffline(roomId: roomId, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
