import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../utils/theme_colors.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../services/forum_local_service.dart';
import '../../widgets/forum_widgets.dart';

class ForumPostDetailScreen extends StatefulWidget {
  final String postId;

  const ForumPostDetailScreen({super.key, required this.postId});

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  final _service = ForumLocalService();
  final _replyController = TextEditingController();

  LocalForumPost? _post;
  List<LocalForumReply> _replies = [];
  bool _liked = false;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _userId() => context.read<auth.AuthProvider>().currentUser?.id;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _service.pullRepliesToLocal(widget.postId);
    } catch (_) {}
    final post = await _service.getPostById(widget.postId);
    final replies = await _service.getReplies(widget.postId);
    final liked = await _service.isPostLiked(widget.postId);
    if (!mounted) return;
    setState(() {
      _post = post;
      _replies = replies;
      _liked = liked;
      _loading = false;
    });
  }

  String _authorName() {
    final user = context.read<auth.AuthProvider>().currentUser;
    if (user != null && user.fullName.trim().isNotEmpty) {
      return user.fullName.trim();
    }
    return 'Thành viên';
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final result = await _service.toggleLike(widget.postId);
    if (!mounted) return;
    setState(() {
      _liked = result.liked;
      _post = LocalForumPost(
        id: _post!.id,
        title: _post!.title,
        author: _post!.author,
        content: _post!.content,
        category: _post!.category,
        likes: result.likes,
        replyCount: _post!.replyCount,
        createdAt: _post!.createdAt,
      );
    });
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sending) return;
    if (!context.read<auth.AuthProvider>().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để bình luận và đồng bộ Firebase.')),
      );
      Navigator.of(context).pushNamed('/login');
      return;
    }
    setState(() => _sending = true);
    try {
      await _service.addReply(
        postId: widget.postId,
        content: text,
        author: _authorName(),
        userId: _userId(),
      );
      _replyController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bình luận chưa đồng bộ: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      await _load();
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết bài đăng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
              ? const Center(child: Text('Không tìm thấy bài đăng.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ForumCategoryBadge(category: _post!.category),
                          const SizedBox(height: 12),
                          Text(
                            _post!.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_post!.author} · ${DateFormat('dd/MM/yyyy HH:mm').format(_post!.createdAtDate)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: context.tc.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _post!.content,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: _toggleLike,
                                icon: Icon(
                                  _liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: _liked ? AppColors.error : null,
                                ),
                              ),
                              Text('${_post!.likes} thích'),
                              const Spacer(),
                              Text('${_post!.replyCount} bình luận'),
                            ],
                          ),
                          const Divider(height: 32),
                          Text(
                            'Bình luận',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_replies.isEmpty)
                            Text(
                              'Chưa có bình luận. Hãy là người đầu tiên!',
                              style: GoogleFonts.plusJakartaSans(color: context.tc.textSecondary),
                            )
                          else
                            ..._replies.map(_replyTile),
                        ],
                      ),
                    ),
                    _replyBar(),
                  ],
                ),
    );
  }

  Widget _replyTile(LocalForumReply r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.author} · ${DateFormat('dd/MM HH:mm').format(r.createdAtDate)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.tc.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(r.content, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _replyBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _sendReply,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
