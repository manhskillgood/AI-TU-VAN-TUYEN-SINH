import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/university_record.dart';
import '../../services/admin_catalog_service.dart';
import '../../widgets/admin_ui.dart';

class AdminUniversitiesScreen extends StatefulWidget {
  const AdminUniversitiesScreen({super.key});

  @override
  State<AdminUniversitiesScreen> createState() => _AdminUniversitiesScreenState();
}

class _AdminUniversitiesScreenState extends State<AdminUniversitiesScreen> {
  final _catalog = AdminCatalogService();
  final _search = TextEditingController();
  List<UniversityRecord> _all = [];
  List<UniversityRecord> _visible = [];
  bool _loading = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await _catalog.listUniversities();
      _applyFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    _visible = q.isEmpty
        ? List.from(_all)
        : _all.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _seed() async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Nhập từ assets',
      message: 'Đẩy danh sách trường từ universities_registry.json?',
      confirmLabel: 'Nhập',
    );
    if (!ok) return;
    final n = await _catalog.seedUniversitiesFromAssets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã nhập $n trường')));
    await _load();
  }

  Future<void> _edit([UniversityRecord? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final regionsCtrl = TextEditingController(text: existing?.regions.join(', ') ?? 'north');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final webCtrl = TextEditingController(text: existing?.website ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Thêm trường' : 'Sửa trường'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên trường')),
              TextField(
                controller: regionsCtrl,
                decoration: const InputDecoration(labelText: 'Vùng (north, south, central)'),
              ),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ')),
              TextField(controller: webCtrl, decoration: const InputDecoration(labelText: 'Website')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (saved != true) return;

    await _catalog.saveUniversity(UniversityRecord(
      id: existing?.id ?? '',
      name: nameCtrl.text.trim(),
      regions: regionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      location: locCtrl.text.trim(),
      website: webCtrl.text.trim(),
      description: descCtrl.text.trim(),
    ));
    if (!mounted) return;
    await _load();
  }

  Future<void> _delete(UniversityRecord u) async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Xóa trường',
      message: 'Xóa "${u.name}"?',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    await _catalog.deleteUniversity(u.id);
    await _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý trường ĐH'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _seed, tooltip: 'Nhập assets'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm trường'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm tên trường',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(_applyFilter),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _visible.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.account_balance_outlined,
                        title: 'Chưa có trường',
                        message: 'Nhập từ assets hoặc thêm thủ công.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _visible.length,
                          itemBuilder: (_, i) {
                            final u = _visible[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${u.regions.join(", ")} · ${u.location}'),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(u);
                                    if (v == 'del') _delete(u);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                    PopupMenuItem(value: 'del', child: Text('Xóa')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
