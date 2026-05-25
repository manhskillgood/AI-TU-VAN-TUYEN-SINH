import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../utils/theme_colors.dart';
import '../../widgets/app_illustrations.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/ai_advisor_panel.dart';
import '../../main.dart'; // provides aiService
import '../chatbot/chatbot_screen.dart';
import '../../models/career_guidance.dart';
import '../../models/guidance_recommend_input.dart';
import '../../providers/career_guidance_provider.dart';
import '../../services/guidance_service.dart';
import '../../services/recommendation_merge_service.dart';
import '../../services/recommender_service.dart';
import '../../services/special_career_service.dart';
import '../../models/special_career_eligibility.dart';
import '../../widgets/special_career_panel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendResultsScreen extends StatefulWidget {
  final GuidanceRecommendInput input;
  final CareerGuidance? localGuidance;
  /// Nhúng trong wizard định hướng — ẩn AppBar để tránh chiếm chỗ + trùng nút dưới.
  final bool embedded;

  const RecommendResultsScreen({
    Key? key,
    required this.input,
    this.localGuidance,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<RecommendResultsScreen> createState() => _RecommendResultsScreenState();
}

class _RecommendResultsScreenState extends State<RecommendResultsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;
  bool _summaryMode = false;
  String? _aiSummary;
  bool _aiSummaryLoading = false;
  final Map<String, String> _aiMajorTexts = {};
  final Set<String> _aiMajorLoading = {};
  SpecialCareerEligibility? _specialEligibility;

  @override
  void initState() {
    super.initState();
    _loadSpecialEligibility();
    _loadRecommendations();
  }

  Future<void> _loadSpecialEligibility() async {
    final input = widget.input;
    final trackId = input.specialTrackId;
    final gender = input.specialGender;
    final h = input.heightCm;
    final w = input.weightKg;
    if (trackId == null || gender == null || h == null || w == null) return;

    await SpecialCareerService.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _specialEligibility = SpecialCareerService.evaluate(
        trackId: trackId,
        gender: gender,
        heightCm: h,
        weightKg: w,
      );
    });
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final local = widget.localGuidance ??
        context.read<CareerGuidanceProvider>().currentGuidance ??
        _buildInlineLocalGuidance();

    Map<String, dynamic>? mlRes = await aiService.getRecommendations(
      profileText: widget.input.profileText,
      examBlock: widget.input.examBlock,
      interests: widget.input.interests,
      strengths: widget.input.strengths,
      region: widget.input.region,
      includeAdvice: true,
    );
    if (mlRes.containsKey('error')) {
      mlRes = null;
    }

    if (mlRes == null && local == null) {
      final fb = await _localFallback();
      if (!fb.containsKey('error')) {
        mlRes = fb;
      }
    }

    final res = RecommendationMergeService.merge(
      mlResponse: mlRes,
      localGuidance: local,
      input: widget.input,
      top: 8,
    );

    if (res['top_majors'] is! List || (res['top_majors'] as List).isEmpty) {
      setState(() {
        _error = 'Không có gợi ý. Kiểm tra kết nối ML hoặc hoàn thành biểu mẫu.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _data = res;
      _isLoading = false;
    });
  }

  /// Tính gợi ý quy tắc ngay trên thiết bị khi chưa lưu Firestore.
  CareerGuidance? _buildInlineLocalGuidance() {
    final slots = widget.input.guidanceSlots;
    final suitability = GuidanceService.computeSuitability(
      mathScore: slots.math,
      literatureScore: slots.literature,
      englishScore: slots.english,
      interests: widget.input.interests,
      strengths: widget.input.strengths,
      region: widget.input.region,
      examBlock: widget.input.examBlock,
    );
    if (suitability.isEmpty) return null;

    final recommended = GuidanceService.recommendMajors(suitability, top: 5);
    final sortedKeys = suitability.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final related = sortedKeys.skip(5).take(5).map((e) => e.key).toList();
    final universities = <String>[];
    for (final m in recommended.take(3)) {
      universities.addAll(
        GuidanceService.suggestUniversities(
          m,
          region: widget.input.region,
          examBlock: widget.input.examBlock,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    return CareerGuidance(
      id: 'inline_${now.millisecondsSinceEpoch}',
      userId: 'anonymous',
      mathScore: slots.math,
      literatureScore: slots.literature,
      englishScore: slots.english,
      interests: widget.input.interests,
      strengths: widget.input.strengths,
      region: widget.input.region,
      recommendedMajors: recommended,
      relatedMajors: related,
      suitableUniversities: universities.toSet().toList(),
      majorSuitability: suitability,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<Map<String, dynamic>> _localFallback() async {
    try {
      final local = RecommenderService();
      final recs = await local.recommend(
        widget.input.interests,
        block: widget.input.examBlock,
        skills: widget.input.strengths,
        limit: 5,
      );
      if (recs.isEmpty) {
        return {'error': 'local_empty'};
      }
      final topMajors = recs.map((r) {
        final conf = (r.score / (recs.first.score + 1e-9)).clamp(0.0, 1.0);
        return {
          'name': r.major,
          'major': r.major,
          'confidence': double.parse(conf.toStringAsFixed(2)),
          'reason': r.reason.isNotEmpty
              ? r.reason
              : 'Gợi ý từ dữ liệu nội bộ (không kết nối được server ML).',
          'universities': <String>[],
        };
      }).toList();
      return {
        'top_majors': topMajors,
        'need_human_support': (topMajors.first['confidence'] as double) < 0.5,
        'support_message': 'Đang dùng gợi ý offline. Bật server ML để kết quả chi tiết hơn.',
        'contact_label': '',
      };
    } catch (e) {
      return {'error': 'local_failed: $e'};
    }
  }

  String _majorName(dynamic item) {
    if (item is Map) {
      return (item['name'] ?? item['major'] ?? '').toString();
    }
    return item.toString();
  }

  Future<void> _onSelectMajor(String major) async {
    await aiService.selectMajor(
      major: major,
      profileText: widget.input.profileText,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chọn $major')),
      );
    }
  }

  Future<void> _openUniversityWebsite(String name) async {
    try {
      final query = Uri.encodeComponent(name);
      final url = Uri.parse('https://www.google.com/search?q=$query');
      await launchUrl(url);
    } catch (_) {}
  }

  Future<void> _loadAiSummary(List<dynamic> topMajors) async {
    if (_aiSummaryLoading || !aiService.hasApiKey) return;
    setState(() => _aiSummaryLoading = true);
    final maps = topMajors.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final text = await aiService.summarizeRecommendationResults(
      input: widget.input,
      topMajors: maps,
    );
    if (!mounted) return;
    setState(() {
      _aiSummary = text;
      _aiSummaryLoading = false;
    });
  }

  Future<void> _explainMajorWithAi({
    required String name,
    required double confidence,
    required String reason,
    String? advice,
    List<String> sources = const [],
  }) async {
    if (_aiMajorLoading.contains(name) || !aiService.hasApiKey) {
      if (!aiService.hasApiKey && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiếu GEN_AI_KEY — chạy app với --dart-define=GEN_AI_KEY=...'),
          ),
        );
      }
      return;
    }
    setState(() => _aiMajorLoading.add(name));
    final text = await aiService.explainMajorRecommendation(
      majorName: name,
      input: widget.input,
      confidence: confidence,
      reason: reason.isNotEmpty ? reason : 'Gợi ý từ hệ thống tổng hợp.',
      advice: advice,
      sources: sources,
    );
    if (!mounted) return;
    setState(() {
      _aiMajorLoading.remove(name);
      _aiMajorTexts[name] = text;
    });
  }

  void _openAiChat(List<dynamic> topMajors) {
    final ctx = aiService.buildChatContextFromResults(
      input: widget.input,
      topMajors: topMajors,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(initialContext: ctx),
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liên hệ tư vấn'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('- Email: support@career.vn'),
            SizedBox(height: 8),
            Text('- Hotline: 0123 456 789'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topMajors =
        (_data != null && _data!['top_majors'] is List) ? List.from(_data!['top_majors']) : <dynamic>[];
    final needHuman = _data != null ? (_data!['need_human_support'] == true) : false;
    final contactLabel = _data != null
        ? (_data!['contact_label'] as String?) ?? 'Liên hệ tư vấn'
        : 'Liên hệ tư vấn';

    String combinedAdvice = '';
    final Set<String> combinedUniversities = {};
    for (final item in topMajors) {
      if (item is Map) {
        final adv = item['advice']?.toString() ?? '';
        if (adv.isNotEmpty) {
          if (combinedAdvice.isNotEmpty) combinedAdvice += '\n\n';
          combinedAdvice += '- ${_majorName(item)}: $adv';
        }
        final unis = item['universities'];
        if (unis is List) {
          for (final u in unis) {
            combinedUniversities.add(u.toString());
          }
        }
      }
    }

    final supportMsg = _data?['support_message']?.toString() ?? '';

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Gợi ý ngành (tổng hợp)'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Tải lại gợi ý',
                  onPressed: _isLoading ? null : _loadRecommendations,
                ),
              ],
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const AppEmptyState(
                  title: 'Đang phân tích...',
                  message: 'Kết hợp quy tắc chuyên gia và ML server.',
                  illustration: AppIllustrationKind.wizardResults,
                  showProgress: true,
                )
              : _error != null
                  ? AppEmptyState(
                      title: 'Không tải được gợi ý',
                      message: _error,
                      illustration: AppIllustrationKind.emptyState,
                      actionLabel: 'Thử lại',
                      onAction: _loadRecommendations,
                    )
                  : topMajors.isEmpty
                      ? AppEmptyState(
                          title: 'Chưa có gợi ý',
                          message: 'Hoàn thành biểu mẫu hoặc bật ML server.',
                          illustration: AppIllustrationKind.emptyState,
                          actionLabel: 'Tải lại',
                          onAction: _loadRecommendations,
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: CustomScrollView(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                            const AiPipelineBanner(),
                            const SizedBox(height: 12),
                            if (_specialEligibility != null) ...[
                              SpecialCareerPanel(eligibility: _specialEligibility!),
                              const SizedBox(height: 12),
                            ],
                            if (!aiService.hasApiKey)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Gemini AI: thêm --dart-define=GEN_AI_KEY để bật giải thích & chat tư vấn.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.tc.textSecondary,
                                  ),
                                ),
                              ),
                            if (supportMsg.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  supportMsg,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: context.tc.textPrimary,
                                  ),
                                ),
                              ),
                            if (aiService.hasApiKey) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _aiSummaryLoading
                                          ? null
                                          : () => _loadAiSummary(topMajors),
                                      icon: const Icon(Icons.summarize_rounded, size: 18),
                                      label: const Text('Tư vấn tổng hợp AI'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _openAiChat(topMajors),
                                      icon: const Icon(Icons.chat_rounded, size: 18),
                                      label: const Text('Hỏi AI'),
                                    ),
                                  ),
                                ],
                              ),
                              if (_aiSummary != null || _aiSummaryLoading) ...[
                                const SizedBox(height: 12),
                                AiGeneratedCard(
                                  title: 'Tư vấn tổng hợp',
                                  body: _aiSummary ?? '',
                                  loading: _aiSummaryLoading,
                                  isLocalFallback: (_aiSummary ?? '').contains('Gemini tạm không'),
                                ),
                              ],
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => setState(() => _summaryMode = !_summaryMode),
                                  child: Text(_summaryMode ? 'Xem chi tiết' : 'Xem tổng hợp'),
                                ),
                              ],
                            ),
                                      ],
                                    ),
                                  ),
                                  if (_summaryMode)
                                    SliverToBoxAdapter(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (combinedAdvice.isNotEmpty) ...[
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Tổng hợp lời khuyên',
                                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  Text(combinedAdvice),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                          if (combinedUniversities.isNotEmpty) ...[
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.background,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Tổng hợp gợi ý trường',
                                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 6,
                                                    children: combinedUniversities
                                                        .map((u) => AppUniversityChip(
                                                              label: u,
                                                              onTap: () => _openUniversityWebsite(u),
                                                            ))
                                                        .toList(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                        final item = topMajors[index];
                                        final name = _majorName(item);
                                        final confidence = (item is Map && item['confidence'] != null)
                                            ? (item['confidence'] is num
                                                ? (item['confidence'] as num).toDouble()
                                                : double.tryParse(item['confidence'].toString()) ?? 0.0)
                                            : 0.0;
                                        final reason = (item is Map && item['reason'] != null)
                                            ? item['reason'].toString()
                                            : '';
                                        final advice = (item is Map && item['advice'] != null)
                                            ? item['advice'].toString()
                                            : '';
                                        final universities = (item is Map && item['universities'] is List)
                                            ? List.from(item['universities'] as List)
                                            : <dynamic>[];
                                        final careers = (item is Map && item['career'] is List)
                                            ? List.from(item['career'] as List)
                                            : <dynamic>[];
                                        final code = (item is Map && item['code'] != null)
                                            ? item['code'].toString()
                                            : '';
                                        final sources = (item is Map && item['sources'] is List)
                                            ? List<String>.from(
                                                (item['sources'] as List).map((e) => e.toString()))
                                            : <String>[];

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: index < topMajors.length - 1 ? 12 : 0,
                                          ),
                                          child: Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(12),
                                            onTap: () => _onSelectMajor(name),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          name,
                                                          style: const TextStyle(
                                                              fontSize: 16, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                      Text(
                                                        '${(confidence * 100).toStringAsFixed(0)}%',
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                  if (code.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Mã ngành: $code',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: context.tc.textPrimary,
                                                      ),
                                                    ),
                                                  ],
                                                  if (sources.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Wrap(
                                                      spacing: 6,
                                                      children: sources
                                                          .map((s) => AppSourceBadge(label: s))
                                                          .toList(),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 12),
                                                  LinearProgressIndicator(
                                                    value: confidence.clamp(0.0, 1.0),
                                                    minHeight: 8,
                                                    color: AppColors.primary,
                                                    backgroundColor: AppColors.borderGray,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  AppResultBodyText(text: reason),
                                                  if (advice.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    const AppResultSectionTitle(text: 'Lời khuyên:'),
                                                    const SizedBox(height: 4),
                                                    AppResultBodyText(text: advice),
                                                  ],
                                              if (careers.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                const AppResultSectionTitle(text: 'Nghề nghiệp gợi ý:'),
                                                const SizedBox(height: 4),
                                                AppResultBodyText(
                                                    text: careers.map((e) => e.toString()).join(', ')),
                                              ],
                                                  if (universities.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                const AppResultSectionTitle(text: 'Gợi ý trường:'),
                                                    const SizedBox(height: 6),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 6,
                                                      children: universities
                                                          .map((u) => AppUniversityChip(
                                                                label: u.toString(),
                                                                onTap: () =>
                                                                    _openUniversityWebsite(u.toString()),
                                                              ))
                                                          .toList(),
                                                    ),
                                                  ],
                                                  if (aiService.hasApiKey) ...[
                                                    const SizedBox(height: 12),
                                                    OutlinedButton.icon(
                                                      onPressed: _aiMajorLoading.contains(name)
                                                          ? null
                                                          : () => _explainMajorWithAi(
                                                                name: name,
                                                                confidence: confidence,
                                                                reason: reason,
                                                                advice: advice.isNotEmpty ? advice : null,
                                                                sources: sources,
                                                              ),
                                                      icon: _aiMajorLoading.contains(name)
                                                          ? const SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child: CircularProgressIndicator(strokeWidth: 2),
                                                            )
                                                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                                                      label: Text(
                                                        _aiMajorTexts.containsKey(name)
                                                            ? 'Xem lại giải thích AI'
                                                            : 'Giải thích bằng AI',
                                                      ),
                                                    ),
                                                    if (_aiMajorTexts[name] != null) ...[
                                                      const SizedBox(height: 8),
                                                      AiGeneratedCard(
                                                        title: 'Giải thích — $name',
                                                        body: _aiMajorTexts[name]!,
                                                        isLocalFallback: _aiMajorTexts[name]!
                                                            .contains('Gemini tạm không'),
                                                      ),
                                                    ],
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        );
                                      },
                                        childCount: topMajors.length,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (needHuman)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _showContactDialog,
                                  child: Text(contactLabel),
                                ),
                              ),
                          ],
                        ),
        ),
      ),
    );
  }
}
