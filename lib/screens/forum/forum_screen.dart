import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/forum_constants.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../services/forum_local_service.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/forum_widgets.dart';
import 'create_post_sheet.dart';
import 'forum_post_detail_screen.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _service = ForumLocalService();
  final _searchController = TextEditingController();

  List<LocalForumPost> _posts = [];
  final Map<String, bool> _likedMap = {};
  String _selectedCategory = ForumCategories.all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  String _authorName() {
    final user = context.read<auth.AuthProvider>().currentUser;
    if (user != null && user.fullName.trim().isNotEmpty) {
      return user.fullName.trim();
    }
    return 'Thành viên';
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      await _service.pullRemotePostsToLocal();
    } catch (_) {}
    final posts = await _service.getPosts(
      category: _selectedCategory,
      query: _searchController.text,
    );
    final liked = <String, bool>{};
    for (final p in posts) {
      liked[p.id] = await _service.isPostLiked(p.id);
    }
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _likedMap
        ..clear()
        ..addAll(liked);
      _loading = false;
    });
  }

  String? _userId() => context.read<auth.AuthProvider>().currentUser?.id;

  Future<void> _openCreatePost() async {
    if (!context.read<auth.AuthProvider>().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập để đăng bài lên cộng đồng (đồng bộ Firebase).'),
        ),
      );
      Navigator.of(context).pushNamed('/login');
      return;
    }

    final draft = await showModalBottomSheet<NewForumPostDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreatePostSheet(),
    );

    if (!mounted || draft == null) return;

    try {
      await _service.addPost(
        title: draft.title,
        content: draft.content,
        category: draft.category,
        author: _authorName(),
        userId: _userId(),
      );
      await _loadPosts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đăng bài — đồng bộ lên cộng đồng.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu trên máy nhưng chưa đồng bộ Firebase. Kiểm tra đăng nhập và thử lại.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      await _loadPosts();
    }
  }

  Future<void> _onLike(LocalForumPost post) async {
    final result = await _service.toggleLike(post.id);
    if (!mounted) return;
    setState(() {
      _likedMap[post.id] = result.liked;
      final i = _posts.indexWhere((p) => p.id == post.id);
      if (i >= 0) {
        _posts[i] = LocalForumPost(
          id: post.id,
          title: post.title,
          author: post.author,
          content: post.content,
          category: post.category,
          likes: result.likes,
          replyCount: post.replyCount,
          createdAt: post.createdAt,
        );
      }
    });
  }

  Future<void> _openPost(LocalForumPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForumPostDetailScreen(postId: post.id),
      ),
    );
    if (mounted) await _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.forum,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _loadPosts,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Đăng bài'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _loading && _posts.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                children: [
                  const AppHeroBanner(
                    title: 'Cộng đồng tuyển sinh',
                    subtitle:
                        'Trao đổi chọn ngành, điểm chuẩn, ôn thi và trường ĐH.',
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadPosts(),
                    decoration: InputDecoration(
                      hintText: 'Tìm bài viết...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: _loadPosts,
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ForumCategories.filterChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = ForumCategories.filterChips[i];
                        return ForumCategoryChip(
                          label: cat,
                          selected: _selectedCategory == cat,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _loadPosts();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_loading && _posts.isEmpty)
                    ForumEmptyState(onCreate: _openCreatePost)
                  else
                    ..._posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ForumPostCard(
                          post: post,
                          isLiked: _likedMap[post.id] ?? false,
                          onTap: () => _openPost(post),
                          onLike: () => _onLike(post),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
