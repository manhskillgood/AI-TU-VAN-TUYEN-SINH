import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_role.dart';
import '../models/user.dart' as app_user;
import '../services/forum_local_service.dart';
import '../services/guidance_service.dart';
import '../services/role_service.dart';
import '../services/user_service.dart';
import '../utils/region_label_utils.dart';

class AdminDashboardStats {
  final int ruleCount;
  final int enabledRules;
  final int forumPosts;
  final int userCount;
  final int adminCount;
  final int regularUserCount;

  const AdminDashboardStats({
    required this.ruleCount,
    required this.enabledRules,
    required this.forumPosts,
    required this.userCount,
    this.adminCount = 0,
    this.regularUserCount = 0,
  });
}

class AdminService {
  final UserService _userService = UserService();
  final ForumLocalService _forum = ForumLocalService();

  Future<AdminDashboardStats> loadDashboardStats({String? idToken}) async {
    await GuidanceService.loadRulesFromPrefs();
    final rules = GuidanceService.getRulesAsMaps();
    final enabled = rules.where((r) => r['enabled'] != false).length;
    final posts = await _forum.getPosts();
    var userCount = 0;
    var adminCount = 0;
    try {
      if (idToken != null && idToken.isNotEmpty) {
        final users = await _userService.listUsers(idToken: idToken);
        userCount = users.length;
        for (final u in users) {
          if (RoleService.resolveRole(user: u) == AppRole.admin) {
            adminCount++;
          }
        }
      }
    } catch (_) {}
    return AdminDashboardStats(
      ruleCount: rules.length,
      enabledRules: enabled,
      forumPosts: posts.length,
      userCount: userCount,
      adminCount: adminCount,
      regularUserCount: userCount > 0 ? userCount - adminCount : 0,
    );
  }

  Future<List<app_user.User>> listUsers({String? idToken}) async {
    return _userService.listUsers(idToken: idToken);
  }

  Future<void> setUserRole({
    required app_user.User user,
    required AppRole role,
    required String idToken,
  }) async {
    await _userService.updateUserRole(
      userId: user.id,
      role: role.value,
      idToken: idToken,
    );
  }

  Future<void> updateUserProfile({
    required app_user.User user,
    required String idToken,
  }) async {
    final normalized = user.copyWith(
      region: RegionLabelUtils.normalize(user.region) ?? user.region,
      updatedAt: DateTime.now(),
    );
    await _userService.updateUser(user: normalized, idToken: idToken);
  }

  Future<void> deleteUser({
    required String userId,
    required String idToken,
  }) async {
    await _userService.deleteUser(userId: userId, idToken: idToken);
  }

  Future<void> deleteForumPost(String postId) async {
    await _forum.deletePost(postId);
    try {
      await FirebaseFirestore.instance
          .collection('forum_posts')
          .doc(postId)
          .delete();
    } catch (_) {}
  }

  Future<void> reloadRulesFromAssets() async {
    await GuidanceService.initializeDataset();
    await GuidanceService.saveRulesToPrefs();
  }

  static bool canAccessAdmin({app_user.User? user}) =>
      RoleService.isAdmin(user: user);
}
