import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/catalog_major.dart';
import '../../services/admin_catalog_service.dart';
import '../../widgets/admin_ui.dart';

class AdminMajorsScreen extends StatefulWidget {
  const AdminMajorsScreen({super.key});

  @override
  State<AdminMajorsScreen> createState() => _AdminMajorsScreenState();
}

class _AdminMajorsScreenState extends State<AdminMajorsScreen> {
  final _catalog = AdminCatalogService();
  final _search = TextEditingController();
  List<CatalogMajor> _all = [];
  List<CatalogMajor> _visible = [];
  bool _loading = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await _catalog.listMajors();
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
        : _all
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.code.toLowerCase().contains(q))
            .toList();
  }

  Future<void> _seed() async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Nhập từ assets',
      message: 'Ghi đè/gộp ${122} ngành từ majors_catalog.json lên Firestore?',
      confirmLabel: 'Nhập',
    );
    if (!ok) return;
    final n = await _catalog.seedMajorsFromAssets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã nhập $n ngành')));
    await _load();
  }

  Future<void> _applyEngine() async {
    final n = await _catalog.applyMajorsToGuidanceEngine();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã áp dụng $n ngành vào engine gợi ý')),
    );
  }

  Future<void> _edit([CatalogMajor? existing]) async {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final familyCtrl = TextEditingController(text: existing?.family ?? 'it');
    final blocksCtrl = TextEditingController(
      text: existing?.examBlocks.join(', ') ?? 'A00',
    );
    final scoreCtrl = TextEditingController(
      text: existing?.referenceScore.toString() ?? '21',
    );
    final trendCtrl = TextEditingController(text: existing?.jobTrends ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Thêm ngành' : 'Sửa ngành'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Mã ngành (TT09)'),
                enabled: existing == null,
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên ngành')),
              TextField(controller: familyCtrl, decoration: const InputDecoration(labelText: 'Nhóm (family)')),
              TextField(
                controller: blocksCtrl,
                decoration: const InputDecoration(labelText: 'Khối thi (A00, D01...)'),
              ),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Điểm tham chiếu'),
              ),
              TextField(controller: trendCtrl, decoration: const InputDecoration(labelText: 'Xu hướng việc làm')),
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

    final major = CatalogMajor(
      code: codeCtrl.text.trim(),
      name: nameCtrl.text.trim(),
      family: familyCtrl.text.trim(),
      examBlocks: blocksCtrl.text
          .split(',')
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toList(),
      referenceScore: double.tryParse(scoreCtrl.text) ?? 21,
      jobTrends: trendCtrl.text.trim(),
    );
    await _catalog.saveMajor(major);
    if (!mounted) return;
    await _load();
  }

  Future<void> _delete(CatalogMajor m) async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Xóa ngành',
      message: 'Xóa "${m.name}" (${m.code})?',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    await _catalog.deleteMajor(m.code);
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
        title: const Text('Quản lý ngành học'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.cloud_sync), onPressed: _applyEngine, tooltip: 'Áp dụng engine'),
          IconButton(icon: const Icon(Icons.download), onPressed: _seed, tooltip: 'Nhập assets'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ngành'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm tên hoặc mã ngành',
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
                        icon: Icons.menu_book_outlined,
                        title: 'Chưa có dữ liệu',
                        message: 'Nhấn biểu tượng tải xuống để nhập từ assets.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _visible.length,
                          itemBuilder: (_, i) {
                            final m = _visible[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${m.code} · ${m.examBlocks.join(", ")} · ${m.jobTrends}'),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(m);
                                    if (v == 'del') _delete(m);
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
