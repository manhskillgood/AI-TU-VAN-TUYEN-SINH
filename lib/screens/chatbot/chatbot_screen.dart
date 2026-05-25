import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_constants.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../services/advisor_chat_history_service.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/app_ui.dart';

class ChatbotScreen extends StatefulWidget {
  /// Ngữ cảnh từ màn kết quả định hướng (ML + quy tắc).
  final String? initialContext;

  const ChatbotScreen({super.key, this.initialContext});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _history = AdvisorChatHistoryService();
  final _uuid = const Uuid();

  late final String _sessionKey;
  List<StoredChatMessage> _messages = [];
  bool _isLoading = false;
  bool _bootstrapping = true;

  static const List<String> _quickPrompts = [
    'Khối A01 nên học ngành gì?',
    'So sánh CNTT và KTPM',
    'Điểm 24 nên chọn ngành nào?',
    'Gợi ý trường miền Bắc',
  ];

  @override
  void initState() {
    super.initState();
    _sessionKey = _history.sessionKeyFromContext(widget.initialContext);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapChat());
  }

  List<StoredChatMessage> _buildIntroMessages() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final intro = widget.initialContext != null &&
            widget.initialContext!.isNotEmpty
        ? 'Xin chào! Tôi là trợ lý AI tư vấn tuyển sinh. '
            'Tôi đã nắm kết quả gợi ý ngành của bạn — hãy hỏi thêm về ngành, trường hoặc lộ trình ôn thi.'
        : 'Xin chào! Tôi là trợ lý AI (Gemini). '
            'Hãy hỏi về sở thích, điểm số, khối thi hoặc ngành bạn đang cân nhắc.';
    final list = <StoredChatMessage>[
      StoredChatMessage(
        id: _uuid.v4(),
        text: intro,
        isAi: true,
        createdAtMs: now,
      ),
    ];
    if (widget.initialContext != null &&
        widget.initialContext!.trim().isNotEmpty) {
      list.add(
        StoredChatMessage(
          id: _uuid.v4(),
          text: 'Ngữ cảnh gợi ý: ${widget.initialContext}',
          isAi: true,
          createdAtMs: now + 1,
        ),
      );
    }
    return list;
  }

  String? get _userId =>
      context.read<auth.AuthProvider>().currentUser?.id;

  Future<void> _bootstrapChat() async {
    final loaded = await _history.load(
      sessionKey: _sessionKey,
      userId: _userId,
    );
    if (!mounted) return;
    setState(() {
      _messages = loaded.isNotEmpty ? loaded : _buildIntroMessages();
      _bootstrapping = false;
    });
    if (loaded.isEmpty) {
      await _persist();
    }
    _scrollToBottom();
  }

  Future<void> _persist() async {
    await _history.saveAll(
      sessionKey: _sessionKey,
      messages: _messages,
      userId: _userId,
    );
  }

  StoredChatMessage _msg(String text, bool isAi) => StoredChatMessage(
        id: _uuid.v4(),
        text: text,
        isAi: isAi,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _clearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử chat?'),
        content: const Text(
          'Toàn bộ tin nhắn trong phiên này sẽ bị xóa trên máy '
          'và trên tài khoản (nếu đã đăng nhập).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _history.clear(sessionKey: _sessionKey, userId: _userId);
    setState(() {
      _messages = _buildIntroMessages();
    });
    await _persist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa lịch sử chat')),
      );
    }
  }

  Future<void> _sendMessage([String? preset]) async {
    final userMessage = (preset ?? _messageController.text).trim();
    if (userMessage.isEmpty || _isLoading) return;

    setState(() {
      _messages = [..._messages, _msg(userMessage, false)];
      _isLoading = true;
    });
    _messageController.clear();
    await _persist();
    _scrollToBottom();

    try {
      var prompt = userMessage;
      if (widget.initialContext != null &&
          widget.initialContext!.isNotEmpty) {
        prompt =
            'Bối cảnh học sinh: ${widget.initialContext}\n\nCâu hỏi: $userMessage';
      }
      final aiResponse = await aiService.sendMessage(
        message: prompt,
        useAdvisorPersona: true,
        timeout: const Duration(seconds: 20),
        maxRetries: 0,
      );

      if (!mounted) return;
      setState(() {
        _messages = [..._messages, _msg(aiResponse, true)];
        _isLoading = false;
      });
      await _persist();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages,
          _msg(
            'Xin lỗi, hiện tôi không thể trả lời. Kiểm tra mạng hoặc GEN_AI_KEY rồi thử lại.',
            true,
          ),
        ];
        _isLoading = false;
      });
      await _persist();
      _scrollToBottom();
    }
  }

  bool get _showQuickPrompts =>
      !_bootstrapping && _messages.length <= 3 && !_isLoading;

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<auth.AuthProvider>().isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat AI tư vấn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              aiService.hasApiKey
                  ? (loggedIn
                      ? 'Gemini · Đã lưu lịch sử'
                      : 'Gemini · Lưu trên máy')
                  : 'Chưa bật API',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: context.tc.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Xóa lịch sử',
            onPressed: _bootstrapping || _isLoading ? null : _clearHistory,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Lưu ý',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Lưu ý'),
                  content: const Text(
                    'Câu trả lời mang tính tham khảo. Điểm chuẩn và học phí '
                    'cần xem thông báo tuyển sinh chính thức từng trường.\n\n'
                    'Lịch sử được lưu trên máy; khi đăng nhập còn đồng bộ '
                    'Firestore (tối đa 40 tin gần nhất).',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đã hiểu'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _bootstrapping
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!aiService.hasApiKey)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: AppColors.warning.withValues(alpha: 0.12),
                    child: Row(
                      children: [
                        Icon(Icons.key_off_rounded,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thiếu GEN_AI_KEY — chạy app với --dart-define=GEN_AI_KEY=...',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMd,
                      vertical: AppDimensions.paddingSm,
                    ),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const AppChatBubble(
                          text: '',
                          isAi: true,
                          isTyping: true,
                        );
                      }
                      final message = _messages[index];
                      return AppChatBubble(
                        text: message.text,
                        isAi: message.isAi,
                      );
                    },
                  ),
                ),
                if (_showQuickPrompts)
                  AppChatQuickPrompts(
                    prompts: _quickPrompts,
                    enabled: aiService.hasApiKey && !_isLoading,
                    onSelected: _sendMessage,
                  ),
                AppChatInputBar(
                  controller: _messageController,
                  isLoading: _isLoading,
                  onSend: () => _sendMessage(),
                ),
              ],
            ),
    );
  }
}
