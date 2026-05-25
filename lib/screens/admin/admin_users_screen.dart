import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../models/app_role.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/role_service.dart';
import '../../utils/birth_date_utils.dart';
import '../../utils/region_label_utils.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/admin_ui.dart';

enum _UserSort { name, email, newest }

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _admin = AdminService();
  final _searchCtrl = TextEditingController();
  List<User> _users = [];
  List<User> _filtered = [];
  bool _loading = true;
  String? _error;
  int _roleFilter = 0; // 0 all, 1 admin, 2 user
  _UserSort _sort = _UserSort.name;

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
    var list = List<User>.from(_users);

    if (_roleFilter == 1) {
      list = list.where((u) => RoleService.resolveRole(user: u) == AppRole.admin).toList();
    } else if (_roleFilter == 2) {
      list = list.where((u) => RoleService.resolveRole(user: u) == AppRole.user).toList();
    }

    if (q.isNotEmpty) {
      list = list
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              RegionLabelUtils.display(u.region).toLowerCase().contains(q))
          .toList();
    }

    switch (_sort) {
      case _UserSort.name:
        list.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case _UserSort.email:
        list.sort((a, b) => a.email.compareTo(b.email));
        break;
      case _UserSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    _filtered = list;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.ensureFirestoreSession();
      final token = auth.idToken;
      var users = await _admin.listUsers(idToken: token);

      final me = auth.currentUser;
      if (me != null && !users.any((u) => u.id == me.id)) {
        users = [me, ...users];
      }

      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
      _applyFilter();
      setState(() {});
    } catch (e) {
      final me = context.read<AuthProvider>().currentUser;
      if (!mounted) return;
      setState(() {
        _error =
            'Không tải được danh sách người dùng từ Firestore.\n'
            '$e\n\n'
            '• Đăng xuất rồi đăng nhập lại bằng email admin.\n'
            '• Deploy rules: firebase deploy --only firestore:rules\n'
            '• Email admin phải có trong firestore.rules và AppConfig.adminEmails.';
        _loading = false;
        if (me != null) _users = [me];
      });
      _applyFilter();
      setState(() {});
    }
  }

  Future<void> _setRole(User user, AppRole next) async {
    final auth = context.read<AuthProvider>();
    if (user.id == auth.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đổi quyền tài khoản đang đăng nhập')),
      );
      return;
    }
    final ok = await adminConfirmDialog(
      context,
      title: 'Đổi quyền',
      message: 'Đặt "${user.fullName}" (${user.email})\nthành ${next.label}?',
    );
    if (!ok) return;

    final token = auth.idToken;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu token — đăng xuất rồi đăng nhập lại')),
      );
      return;
    }
    try {
      await _admin.setUserRole(user: user, role: next, idToken: token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật: ${user.email} → ${next.label}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    }
  }

  Future<void> _editRegion(User user) async {
    final auth = context.read<AuthProvider>();
    final token = auth.idToken;
    if (token == null || token.isEmpty) return;

    var selected = RegionLabelUtils.normalize(user.region) ?? RegionLabelUtils.mienBac;
    if (!RegionLabelUtils.options.contains(selected)) {
      selected = RegionLabelUtils.mienBac;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Sửa khu vực'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Khu vực'),
            items: RegionLabelUtils.options
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) {
              if (v != null) setDlg(() => selected = v);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    try {
      await _admin.updateUserProfile(
        user: user.copyWith(region: selected),
        idToken: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật khu vực')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    final auth = context.read<AuthProvider>();
    if (user.id == auth.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa tài khoản đang đăng nhập')),
      );
      return;
    }
    final ok = await adminConfirmDialog(
      context,
      title: 'Xóa người dùng',
      message: 'Xóa vĩnh viễn "${user.fullName}" (${user.email}) khỏi Firestore?',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;

    final token = auth.idToken;
    if (token == null || token.isEmpty) return;

    try {
      await _admin.deleteUser(userId: user.id, idToken: token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa người dùng')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được: $e')),
      );
    }
  }

  void _showUserDetail(User u) {
    final role = RoleService.resolveRole(user: u);
    final isMe = u.id == context.read<AuthProvider>().currentUser?.id;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.fullName + (isMe ? ' (bạn)' : ''),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AdminRoleChip(role: role),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(ctx, Icons.email_outlined, u.email),
            _detailRow(ctx, Icons.phone_outlined, u.phoneNumber.isNotEmpty ? u.phoneNumber : '—'),
            _detailRow(ctx, Icons.place_outlined, RegionLabelUtils.display(u.region)),
            _detailRow(
              ctx,
              Icons.calendar_today_outlined,
              BirthDateUtils.formatVi(u.dateOfBirth),
            ),
            const SizedBox(height: 16),
            if (!isMe) ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setRole(u, AppRole.admin);
                },
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: const Text('Đặt làm Quản trị viên'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _setRole(u, AppRole.user);
                },
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Đặt làm Người dùng'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _editRegion(u);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Sửa khu vực'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _deleteUser(u);
                },
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Xóa tài khoản'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    final tc = context.tc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tc.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: tc.textStyleBody())),
        ],
      ),
    );
  }

  int get _adminCount =>
      _users.where((u) => RoleService.resolveRole(user: u) == AppRole.admin).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionHeader(
                title: 'Người dùng',
                subtitle: 'Firestore collection `users` · chạm thẻ để chi tiết',
              ),
              if (!_loading && _users.isNotEmpty)
                Text(
                  '${_users.length} tài khoản · $_adminCount quản trị',
                  style: context.tc.textStyleCaption(weight: FontWeight.w600),
                ),
              const SizedBox(height: 10),
              AdminSearchField(
                controller: _searchCtrl,
                hint: 'Tìm tên, email, khu vực...',
                onChanged: (_) {
                  _applyFilter();
                  setState(() {});
                },
                onClear: () {
                  _applyFilter();
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              AdminFilterChipRow(
                labels: const ['Tất cả', 'Quản trị', 'Người dùng'],
                selectedIndex: _roleFilter,
                onSelected: (i) {
                  setState(() {
                    _roleFilter = i;
                    _applyFilter();
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Sắp xếp:', style: context.tc.textStyleCaption()),
                  const SizedBox(width: 8),
                  DropdownButton<_UserSort>(
                    value: _sort,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: _UserSort.name, child: Text('Tên')),
                      DropdownMenuItem(value: _UserSort.email, child: Text('Email')),
                      DropdownMenuItem(value: _UserSort.newest, child: Text('Mới nhất')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _sort = v;
                        _applyFilter();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AdminErrorBanner(message: _error!, onRetry: _load),
          ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filtered.isEmpty) {
      return AdminEmptyState(
        icon: Icons.people_outline_rounded,
        title: _users.isEmpty ? 'Chưa có người dùng' : 'Không có kết quả',
        message: _users.isEmpty
            ? 'Người dùng được tạo khi đăng ký trong app.\n'
                'Cần deploy firestore.rules và đăng nhập bằng email admin.'
            : 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.',
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
          final u = _filtered[i];
          final tc = context.tc;
          final role = RoleService.resolveRole(user: u);
          final isAdminRole = role == AppRole.admin;
          final isMe = u.id == context.read<AuthProvider>().currentUser?.id;
          return Material(
            color: tc.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _showUserDetail(u),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isMe ? AppColors.primary.withValues(alpha: 0.4) : tc.border,
                  ),
                  boxShadow: isMe ? AppColors.softShadow : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          isAdminRole ? AppColors.primaryLight : tc.chipBackground,
                      child: Text(
                        u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isAdminRole ? AppColors.primaryDark : tc.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.fullName + (isMe ? ' (bạn)' : ''),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AdminRoleChip(role: role),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            u.email,
                            style: tc.textStyleCaption(),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            RegionLabelUtils.display(u.region),
                            style: tc.textStyleCaption(size: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAdminRole,
                      onChanged: isMe
                          ? null
                          : (v) => _setRole(u, v ? AppRole.admin : AppRole.user),
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
