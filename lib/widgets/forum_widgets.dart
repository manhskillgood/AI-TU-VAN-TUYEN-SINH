import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../utils/theme_colors.dart';
import '../constants/forum_constants.dart';
import '../services/forum_local_service.dart';

class ForumCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ForumCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    final color = label == ForumCategories.all
        ? AppColors.primary
        : ForumCategories.colorFor(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: context.isDarkTheme ? 0.35 : 0.18),
      checkmarkColor: color,
      backgroundColor: tc.chipBackground,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? color : tc.textPrimary,
      ),
      side: BorderSide(color: selected ? color : tc.border),
    );
  }
}

class ForumCategoryBadge extends StatelessWidget {
  final String category;

  const ForumCategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final color = ForumCategories.colorFor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ForumCategories.iconFor(category), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            category,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ForumPostCard extends StatelessWidget {
  final LocalForumPost post;
  final bool isLiked;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const ForumPostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onTap,
    required this.onLike,
  });

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Material(
      color: tc.surface,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: tc.border),
            boxShadow: tc.softShadow,
          ),
          padding: const EdgeInsets.all(AppDimensions.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ForumCategoryBadge(category: post.category),
                  const Spacer(),
                  Text(
                    _timeAgo(post.createdAtDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: tc.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: tc.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tc.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    post.author,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tc.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: isLiked ? AppColors.error : tc.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: TextStyle(color: tc.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${post.replyCount}',
                    style: TextStyle(color: tc.textSecondary),
                  ),
                  Icon(Icons.chevron_right_rounded, color: tc.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForumEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const ForumEmptyState({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.forum_outlined,
              size: 64, color: tc.textMuted.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            'Chưa có bài đăng',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tc.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đặt câu hỏi về chọn ngành, điểm chuẩn hoặc trường ĐH.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: tc.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Đăng bài đầu tiên'),
          ),
        ],
      ),
    );
  }
}
