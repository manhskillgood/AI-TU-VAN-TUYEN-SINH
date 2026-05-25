import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../models/admission_record.dart';
import '../../services/admin_catalog_service.dart';
import '../../widgets/admin_ui.dart';

class AdminAdmissionsScreen extends StatefulWidget {
  const AdminAdmissionsScreen({super.key});

  @override
  State<AdminAdmissionsScreen> createState() => _AdminAdmissionsScreenState();
}

class _AdminAdmissionsScreenState extends State<AdminAdmissionsScreen> {
  final _catalog = AdminCatalogService();
  final _search = TextEditingController();
  List<AdmissionRecord> _all = [];
  List<AdmissionRecord> _visible = [];
  bool _loading = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await _catalog.listAdmissions();
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
            .where((a) =>
                a.universityName.toLowerCase().contains(q) ||
                a.majorName.toLowerCase().contains(q))
            .toList();
  }

  Future<void> _edit([AdmissionRecord? existing]) async {
    final uniCtrl = TextEditingController(text: existing?.universityName ?? '');
    final majorCtrl = TextEditingController(text: existing?.majorName ?? '');
    final codeCtrl = TextEditingController(text: existing?.majorCode ?? '');
    final yearCtrl = TextEditingController(text: '${existing?.year ?? 2025}');
    final scoreCtrl = TextEditingController(text: '${existing?.minScore ?? 0}');
    final quotaCtrl = TextEditingController(text: '${existing?.quota ?? 0}');
    final tuitionCtrl = TextEditingController(text: '${existing?.tuition ?? 0}');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Thêm tuyển sinh' : 'Sửa tuyển sinh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: uniCtrl, decoration: const InputDecoration(labelText: 'Tên trường')),
              TextField(controller: majorCtrl, decoration: const InputDecoration(labelText: 'Tên ngành')),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Mã ngành')),
              TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Năm')),
              TextField(controller: scoreCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Điểm chuẩn')),
              TextField(controller: quotaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Chỉ tiêu')),
              TextField(controller: tuitionCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Học phí (triệu/năm)')),
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

    await _catalog.saveAdmission(AdmissionRecord(
      id: existing?.id ?? '',
      universityName: uniCtrl.text.trim(),
      majorName: majorCtrl.text.trim(),
      majorCode: codeCtrl.text.trim(),
      year: int.tryParse(yearCtrl.text) ?? 2025,
      minScore: double.tryParse(scoreCtrl.text) ?? 0,
      quota: int.tryParse(quotaCtrl.text) ?? 0,
      tuition: double.tryParse(tuitionCtrl.text) ?? 0,
    ));
    if (!mounted) return;
    await _load();
  }

  Future<void> _delete(AdmissionRecord a) async {
    final ok = await adminConfirmDialog(
      context,
      title: 'Xóa bản ghi',
      message: 'Xóa ${a.majorName} @ ${a.universityName}?',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    await _catalog.deleteAdmission(a.id);
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
        title: const Text('Dữ liệu tuyển sinh'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm bản ghi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm trường hoặc ngành',
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
                        icon: Icons.school_outlined,
                        title: 'Chưa có dữ liệu tuyển sinh',
                        message: 'Thêm điểm chuẩn, chỉ tiêu, học phí theo trường–ngành.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _visible.length,
                          itemBuilder: (_, i) {
                            final a = _visible[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                title: Text(a.majorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${a.universityName}\nNăm ${a.year} · ĐC ${a.minScore} · CT ${a.quota} · HP ${a.tuition} tr',
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _edit(a);
                                    if (v == 'del') _delete(a);
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
