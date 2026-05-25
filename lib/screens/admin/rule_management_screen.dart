import 'package:flutter/material.dart';
import 'package:education_guidance_app/services/guidance_service.dart';
import '../../widgets/admin_ui.dart';

class RuleManagementScreen extends StatefulWidget {
  /// Khi true: nhúng trong AdminShell (không có AppBar riêng).
  final bool embedded;

  const RuleManagementScreen({super.key, this.embedded = false});

  @override
  State<RuleManagementScreen> createState() => _RuleManagementScreenState();
}

class _RuleManagementScreenState extends State<RuleManagementScreen> {
  List<Map<String, dynamic>> _rules = [];
  final _searchCtrl = TextEditingController();
  int _statusFilter = 0; // 0 all, 1 enabled, 2 disabled

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _visibleRules {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _rules.where((r) {
      final enabled = r['enabled'] == null ? true : (r['enabled'] == true);
      if (_statusFilter == 1 && !enabled) return false;
      if (_statusFilter == 2 && enabled) return false;
      if (q.isEmpty) return true;
      final id = (r['id'] ?? '').toString().toLowerCase();
      final reason = (r['reason'] ?? '').toString().toLowerCase();
      return id.contains(q) || reason.contains(q);
    }).toList();
  }

  void _loadRules() async {
    await GuidanceService.loadRulesFromPrefs();
    final r = GuidanceService.getRulesAsMaps();
    if (mounted) setState(() => _rules = r);
  }

  Future<void> _syncDown() async {
    final ok = await GuidanceService.downloadRulesFromFirestore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã tải quy tắc từ cloud' : 'Tải thất bại')),
    );
    _loadRules();
  }

  Future<void> _syncUp() async {
    if (!GuidanceService.isCurrentUserAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ admin mới đồng bộ lên cloud')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đồng bộ'),
        content: const Text(
          'Đồng bộ tất cả quy tắc lên Firestore? Các rule cùng id sẽ bị ghi đè.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Đồng bộ')),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await GuidanceService.uploadRulesToFirestore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã đồng bộ lên cloud' : 'Đồng bộ thất bại')),
    );
  }

  Future<void> _showExplainDialog(int idx) async {
    final r = Map<String, dynamic>.from(_rules[idx]);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết: ${r['id'] ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lý do: ${r['reason'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Độ tin cậy: ${r['confidence'] ?? ''}'),
              const SizedBox(height: 8),
              Text('Đang bật: ${r['enabled'] ?? true}'),
              const SizedBox(height: 8),
              const Text('Điều kiện:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(r['conditions']?.toString() ?? ''),
              const SizedBox(height: 8),
              const Text('Tăng điểm ngành:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(r['boostMajors']?.toString() ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Future<void> _toggleEnabled(int idx, bool v) async {
    final id = _rules[idx]['id']?.toString() ?? '';
    await GuidanceService.updateRule(id, enabled: v);
    _loadRules();
  }

  Future<void> _addRuleDialog() async {
    final idCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final confCtrl = TextEditingController(text: '0.8');
    final majorCtrl = TextEditingController();
    final boostCtrl = TextEditingController(text: '1.0');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm quy tắc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(labelText: 'Mã quy tắc (id)'),
              ),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Lý do / mô tả'),
                maxLines: 2,
              ),
              TextField(
                controller: confCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Độ tin cậy (0–1)'),
              ),
              TextField(
                controller: majorCtrl,
                decoration: const InputDecoration(labelText: 'Mã ngành boost (tùy chọn)'),
              ),
              TextField(
                controller: boostCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Hệ số nhân'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm')),
        ],
      ),
    );
    if (saved != true) return;

    final major = majorCtrl.text.trim();
    final boosts = major.isNotEmpty
        ? {major: double.tryParse(boostCtrl.text) ?? 1.0}
        : <String, double>{};

    final ok = await GuidanceService.addRule(
      id: idCtrl.text.trim(),
      reason: reasonCtrl.text.trim(),
      confidence: double.tryParse(confCtrl.text) ?? 0.8,
      boostMajors: boosts,
      conditions: {},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã thêm quy tắc' : 'Thêm thất bại (trùng id?)')),
    );
    _loadRules();
  }

  Future<void> _deleteRule(int idx) async {
    final id = _rules[idx]['id']?.toString() ?? '';
    final ok = await adminConfirmDialog(
      context,
      title: 'Xóa quy tắc',
      message: 'Xóa quy tắc "$id"?',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!ok) return;
    final deleted = await GuidanceService.deleteRule(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(deleted ? 'Đã xóa quy tắc' : 'Xóa thất bại')),
    );
    _loadRules();
  }

  Future<void> _editRuleDialog(int idx) async {
    final rule = Map<String, dynamic>.from(_rules[idx]);
    final id = rule['id']?.toString() ?? '';
    final confidenceController =
        TextEditingController(text: rule['confidence']?.toString() ?? '0.0');
    final boostMap = rule['boostMajors'] is Map
        ? Map<String, dynamic>.from(rule['boostMajors'] as Map)
        : <String, dynamic>{};
    final boostMajor = boostMap.keys.isNotEmpty ? boostMap.keys.first.toString() : '';
    final boostController = TextEditingController(
      text: boostMap.isNotEmpty ? boostMap.values.first.toString() : '1.0',
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa quy tắc $id'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lý do: ${rule['reason'] ?? ''}'),
            const SizedBox(height: 8),
            TextField(
              controller: confidenceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Độ tin cậy (0.0 – 1.0)'),
            ),
            if (boostMajor.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextField(
                controller: boostController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Hệ số nhân: $boostMajor'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              final conf =
                  double.tryParse(confidenceController.text) ?? rule['confidence']?.toDouble() ?? 0.0;
              final mult = double.tryParse(boostController.text) ?? 1.0;
              final newBoosts = <String, double>{};
              if (boostMajor.isNotEmpty) newBoosts[boostMajor] = mult;
              await GuidanceService.updateRule(
                id,
                confidence: conf,
                boostMajorsOverride: newBoosts,
              );
              if (context.mounted) Navigator.of(context).pop();
              _loadRules();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_rules.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.tune_outlined,
        title: 'Chưa có quy tắc',
        message: 'Dùng "Nạp lại từ assets" ở tab Tổng quan.',
      );
    }
    final visible = _visibleRules;
    if (visible.isEmpty) {
      return AdminEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không có kết quả',
        message: 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.',
        actionLabel: 'Xóa lọc',
        onAction: () {
          _searchCtrl.clear();
          setState(() => _statusFilter = 0);
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: visible.length,
      itemBuilder: (context, vi) {
        final r = visible[vi];
        final idx = _rules.indexWhere((x) => x['id'] == r['id']);
        if (idx < 0) return const SizedBox.shrink();
        final boostMap = r['boostMajors'] is Map
            ? Map<String, dynamic>.from(r['boostMajors'] as Map)
            : <String, dynamic>{};
        final primary = boostMap.keys.isNotEmpty ? boostMap.keys.first : '';
        final confidence = r['confidence']?.toString() ?? '';
        final enabled = r['enabled'] == null ? true : (r['enabled'] == true);
        return Card(
          child: ListTile(
            title: Text(
              '${r['id']}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            subtitle: Text('${r['reason'] ?? ''}\nNgành: $primary · tin cậy: $confidence'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.shade700,
                  onPressed: () => _deleteRule(idx),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editRuleDialog(idx),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showExplainDialog(idx),
                ),
                Switch(value: enabled, onChanged: (v) => _toggleEnabled(idx, v)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      final enabled = _rules.where((r) => r['enabled'] != false).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminSectionHeader(
                  title: 'Quy tắc tư vấn',
                  subtitle: '${_rules.length} quy tắc · $enabled đang bật',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Thêm quy tắc',
                        onPressed: _addRuleDialog,
                        icon: const Icon(Icons.add_rounded),
                      ),
                      IconButton(
                        tooltip: 'Tải từ cloud',
                        onPressed: _syncDown,
                        icon: const Icon(Icons.cloud_download_outlined),
                      ),
                      IconButton(
                        tooltip: 'Đẩy lên cloud',
                        onPressed: _syncUp,
                        icon: const Icon(Icons.cloud_upload_outlined),
                      ),
                    ],
                  ),
                ),
                AdminSearchField(
                  controller: _searchCtrl,
                  hint: 'Tìm id, lý do quy tắc...',
                  onChanged: (_) => setState(() {}),
                  onClear: () => setState(() {}),
                ),
                const SizedBox(height: 8),
                AdminFilterChipRow(
                  labels: const ['Tất cả', 'Đang bật', 'Đã tắt'],
                  selectedIndex: _statusFilter,
                  onSelected: (i) => setState(() => _statusFilter = i),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý quy tắc'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _syncDown),
          IconButton(icon: const Icon(Icons.upload), onPressed: _syncUp),
        ],
      ),
      body: _buildBody(),
    );
  }
}
