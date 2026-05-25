import 'package:flutter/material.dart';

import 'app_constants.dart';

class ForumCategories {
  static const String all = 'Tất cả';
  static const String chooseMajor = 'Chọn ngành';
  static const String admission = 'Tuyển sinh & điểm chuẩn';
  static const String examPrep = 'Ôn thi THPT';
  static const String universities = 'Trường đại học';
  static const String studentLife = 'Kinh nghiệm SV';
  static const String other = 'Khác';

  static const List<String> postCategories = [
    chooseMajor,
    admission,
    examPrep,
    universities,
    studentLife,
    other,
  ];

  static const List<String> filterChips = [all, ...postCategories];

  static Color colorFor(String category) {
    switch (category) {
      case chooseMajor:
        return AppColors.primary;
      case admission:
        return AppColors.info;
      case examPrep:
        return AppColors.warning;
      case universities:
        return AppColors.secondary;
      case studentLife:
        return AppColors.success;
      default:
        return AppColors.gray;
    }
  }

  static IconData iconFor(String category) {
    switch (category) {
      case chooseMajor:
        return Icons.school_rounded;
      case admission:
        return Icons.fact_check_rounded;
      case examPrep:
        return Icons.menu_book_rounded;
      case universities:
        return Icons.account_balance_rounded;
      case studentLife:
        return Icons.groups_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}

class NewForumPostDraft {
  final String title;
  final String content;
  final String category;

  const NewForumPostDraft({
    required this.title,
    required this.content,
    required this.category,
  });
}
