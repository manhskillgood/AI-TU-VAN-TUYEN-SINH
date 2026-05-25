import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../constants/forum_constants.dart';
import '../../services/admin_service.dart';
import '../../services/forum_local_service.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/forum_widgets.dart';

class AdminForumModerationScreen extends StatefulWidget {
  const AdminForumModerationScreen({super.key});

  @override
  State<AdminForumModerationScreen> createState() =>
      _AdminForumModerationScreenState();
}

class _AdminForumModerationScreenState extends State<AdminForumModerationScreen> {
  final _forum = ForumLocalService();
  final _admin = AdminService();
  final _searchCtrl = TextEditingController();
  List<LocalForumPost> _posts = [];
  List<LocalForumPost> _filtered = [];
  bool _loading = true;
  String _categoryFilter = ForumCategories.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = List<LocalForumPost>.from(_posts);
    if (_categoryFilter != ForumCategories.all) {
      list = list.where((p) => p.category == _categoryFilter).toList();
    }
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.author.toLowerCase().contains(q) ||
              p.content.toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _filtered = list;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _forum.pullRemotePostsToLocal();
    } catch (_) {}
    final posts = await _forum.getPosts();
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
    });
    _applyFilter();
    setState(() {});
  }

  Future<void> _deletePost(LocalForumPost post) async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Xóa bài đăng',
      message: 'Xóa "${post.title}"? Hành động không hoàn tác.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    await _admin.deleteForumPost(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa bài')),
    );
    await _load();
  }

  void _showPostDetail(LocalForumPost p) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: ListView(
            controller: scroll,
            children: [
              ForumCategoryBadge(category: p.category),
              const SizedBox(height: 10),
              Text(
                p.title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${p.author} · ${DateFormat('dd/MM/yyyy HH:mm').format(p.createdAtDate)}',
                style: ctx.tc.textStyleCaption(),
              ),
              const SizedBox(height: 12),
              Text(p.content, style: ctx.tc.textStyleBody()),
              const SizedBox(height: 12),
              Text(
                '${p.likes} thích · ${p.replyCount} bình luận',
                style: ctx.tc.textStyleCaption(weight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () {
                  Navigator.pop(ctx);
                  _deletePost(p);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Xóa bài viết'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                title: 'Kiểm duyệt diễn đàn',
                subtitle: '${_posts.length} bài (đã đồng bộ Firestore → local)',
                trailing: IconButton(
                  tooltip: 'Tải lại',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              AdminSearchField(
                controller: _searchCtrl,
                hint: 'Tìm tiêu đề, tác giả, nội dung...',
                onChanged: (_) {
                  _applyFilter();
                  setState(() {});
                },
                onClear: () {
                  _applyFilter();
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ForumCategories.filterChips.map((cat) {
                    final sel = _categoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11),
                        ),
                        selected: sel,
                        onSelected: (_) {
                          setState(() {
                            _categoryFilter = cat;
                            _applyFilter();
                          });
                        },
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return AdminEmptyState(
        icon: Icons.forum_outlined,
        title: _posts.isEmpty ? 'Không có bài viết' : 'Không có kết quả',
        message: _posts.isEmpty
            ? 'Bài diễn đàn được lưu cục bộ trên thiết bị này.'
            : 'Thử đổi danh mục hoặc từ khóa tìm kiếm.',
        actionLabel: 'Tải lại',
        onAction: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = _filtered[i];
          final tc = context.tc;
          return Material(
            color: tc.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _showPostDetail(p),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tc.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ForumCategoryBadge(category: p.category),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Xóa nhanh',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _deletePost(p),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.author} · ${DateFormat('dd/MM HH:mm').format(p.createdAtDate)}',
                      style: tc.textStyleCaption(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tc.textStyleBody(size: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${p.likes} thích · ${p.replyCount} BL',
                      style: tc.textStyleCaption(weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
