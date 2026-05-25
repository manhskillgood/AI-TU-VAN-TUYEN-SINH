import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recommender_provider.dart';
import '../models/recommendation.dart';

class RecommenderDemoScreen extends StatefulWidget {
  const RecommenderDemoScreen({Key? key}) : super(key: key);

  @override
  State<RecommenderDemoScreen> createState() => _RecommenderDemoScreenState();
}

class _RecommenderDemoScreenState extends State<RecommenderDemoScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load majors when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RecommenderProvider>();
      try {
        await provider.loadMajors(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi load danh sách ngành: $e')),
          );
        }
      }
    });
  }

  void _onSuggest() async {
    final provider = context.read<RecommenderProvider>();
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    // simple split on commas or semicolon or newline
    final List<String> interests = input.split(RegExp(r'[;,\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    await provider.fetch(interests);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Gợi ý ngành')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập profile / sở thích (ngăn cách bằng dấu phẩy):'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: lập trình, AI, toán, thiết kế',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _onSuggest,
                  child: const Text('Gợi ý ngành'),
                ),
                const SizedBox(width: 12),
                Consumer<RecommenderProvider>(builder: (context, prov, _) {
                  if (prov.loading) return const CircularProgressIndicator();
                  return const SizedBox.shrink();
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Kết quả:'),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<RecommenderProvider>(builder: (context, prov, _) {
                if (prov.recommendations.isEmpty) {
                  return const Center(child: Text('Chưa có kết quả.'));
                }
                return ListView.separated(
                  itemCount: prov.recommendations.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final Recommendation r = prov.recommendations[index];
                    final confidence = (r.score).toStringAsFixed(1);
                    return ListTile(
                      title: Text(r.major),
                      subtitle: Text(r.reason.isNotEmpty ? r.reason : '—'),
                      trailing: Text('Score: $confidence'),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
