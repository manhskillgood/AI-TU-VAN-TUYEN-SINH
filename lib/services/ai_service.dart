import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../config/recommender_config.dart';
import '../models/guidance_recommend_input.dart';
import 'recommender_service.dart';

/// URL ML mặc định — override bằng `--dart-define=RECOMMENDER_URL=...`
String get kRecommenderUrl => RecommenderConfig.defaultUrl;
class AIService {
  final String _apiKey;
  String? _lastWorkingModel;
  List<String>? _discoveredModels;

  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Ưu tiên model lite (ít quota) rồi bản đầy đủ.
  static const List<String> modelFallbacks = [
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-001',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static const String advisorSystemInstruction =
      'Bạn là chuyên gia tư vấn hướng nghiệp và tuyển sinh đại học tại Việt Nam. '
      'Trả lời ngắn gọn (3–6 câu), tiếng Việt, thực tế. '
      'Không bịa điểm chuẩn cụ thể nếu không có trong dữ liệu đầu vào.';

  AIService({required String apiKey, String? preferredModel}) : _apiKey = apiKey {
    if (preferredModel != null && preferredModel.isNotEmpty) {
      _lastWorkingModel = preferredModel;
    }
  }

  GenerativeModel _modelFor(String modelName, {bool advisor = false}) {
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      systemInstruction: advisor
          ? Content.system(advisorSystemInstruction)
          : null,
    );
  }

  bool _isModelNotFound(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('not found') ||
        s.contains('not supported') ||
        s.contains('is not found for api');
  }

  bool _isQuotaOrRateLimit(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('quota') ||
        s.contains('rate limit') ||
        s.contains('resource_exhausted') ||
        s.contains('limit: 0');
  }

  bool _isRetryableServer(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('503') ||
        s.contains('unavailable') ||
        s.contains('high demand') ||
        s.contains('429');
  }

  bool _looksLikeAiError(String text) {
    final t = text.trim();
    return t.startsWith('Xin lỗi') ||
        t.startsWith('Model Gemini') ||
        t.startsWith('Chưa cấu hình GEN_AI_KEY') ||
        t.startsWith('Không tìm thấy model');
  }

  Duration? _retryAfterFromError(Object e) {
    final m = RegExp(r'retry in (\d+(?:\.\d+)?)s', caseSensitive: false).firstMatch(e.toString());
    if (m == null) return null;
    final sec = double.tryParse(m.group(1) ?? '');
    if (sec == null) return null;
    return Duration(milliseconds: (sec * 1000).ceil().clamp(1000, 60000));
  }

  Future<List<String>> _loadDiscoveredModels() async {
    if (_discoveredModels != null) return _discoveredModels!;
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) {
        debugPrint('ListModels HTTP ${resp.statusCode}');
        _discoveredModels = [];
        return _discoveredModels!;
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final raw = body['models'] as List<dynamic>? ?? [];
      final ids = <String>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final methods = item['supportedGenerationMethods'] as List<dynamic>? ?? [];
        if (!methods.any((m) => m.toString().contains('generateContent'))) continue;
        var name = item['name']?.toString() ?? '';
        if (name.startsWith('models/')) name = name.substring(7);
        if (name.isEmpty) continue;
        if (name.contains('embedding') || name.contains('aqa') || name.contains('tts')) {
          continue;
        }
        ids.add(name);
      }
      ids.sort((a, b) => _modelPriority(a).compareTo(_modelPriority(b)));
      _discoveredModels = ids;
      debugPrint('AIService discovered ${ids.length} models, first=${ids.isNotEmpty ? ids.first : "none"}');
    } catch (e) {
      debugPrint('AIService discover models error: $e');
      _discoveredModels = [];
    }
    return _discoveredModels!;
  }

  int _modelPriority(String name) {
    final n = name.toLowerCase();
    if (n.contains('flash-lite')) return 0;
    if (n.contains('2.5-flash') && !n.contains('lite')) return 2;
    if (n.contains('2.0-flash')) return 3;
    if (n.contains('flash')) return 4;
    return 10;
  }

  Future<List<String>> _modelsToTryList({bool discoverIfNeeded = true}) async {
    final ordered = <String>[];
    void add(String m) {
      if (m.isNotEmpty && !ordered.contains(m)) ordered.add(m);
    }

    if (_lastWorkingModel != null) add(_lastWorkingModel!);
    for (final m in modelFallbacks) {
      add(m);
    }
    // Chỉ gọi ListModels khi chưa có model thành công — tránh chờ 10–12s mỗi tin nhắn.
    if (discoverIfNeeded && _lastWorkingModel == null && ordered.length < 4) {
      for (final m in await _loadDiscoveredModels()) {
        add(m);
      }
    }
    return ordered;
  }

  Future<String> _generateText(
    String userMessage, {
    bool advisor = false,
    Duration timeout = const Duration(seconds: 25),
    int maxRetries = 2,
  }) async {
    Object? lastError;

    // Đường nhanh: model vừa dùng thành công (chat thường < 5s).
    if (_lastWorkingModel != null) {
      try {
        final model = _modelFor(_lastWorkingModel!, advisor: advisor);
        final response = await model
            .generateContent([Content.text(userMessage)])
            .timeout(timeout);
        debugPrint('AIService fast path OK model=$_lastWorkingModel');
        return response.text ?? 'Không có phản hồi';
      } catch (e) {
        lastError = e;
        debugPrint('AIService fast path failed: $e');
      }
    }

    final models = await _modelsToTryList(discoverIfNeeded: _lastWorkingModel == null);

    for (final modelName in models) {
      if (modelName == _lastWorkingModel) continue;
      for (var attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          final model = _modelFor(modelName, advisor: advisor);
          final response = await model
              .generateContent([Content.text(userMessage)])
              .timeout(timeout);
          _lastWorkingModel = modelName;
          debugPrint('AIService OK model=$modelName');
          return response.text ?? 'Không có phản hồi';
        } catch (e, st) {
          lastError = e;
          debugPrint('AIService model=$modelName attempt=$attempt error: $e');

          if (e is TimeoutException ||
              e.toString().toLowerCase().contains('timeout')) {
            continue;
          }
          if (_isModelNotFound(e)) break;

          if (_isQuotaOrRateLimit(e) || _isRetryableServer(e)) {
            final wait = _retryAfterFromError(e);
            if (wait != null && attempt < maxRetries) {
              await Future.delayed(wait);
              continue;
            }
            break;
          }

          if (attempt >= maxRetries) break;
          await Future.delayed(Duration(milliseconds: 800 * (attempt + 1)));
        }
      }
    }

    if (lastError != null && _isQuotaOrRateLimit(lastError)) {
      return '__AI_QUOTA__';
    }
    if (lastError != null && _isModelNotFound(lastError)) {
      return '__AI_MODEL_NOT_FOUND__';
    }
    return '__AI_FAILED__';
  }

  String _localExplainMajor({
    required String majorName,
    required GuidanceRecommendInput input,
    required double confidence,
    required String reason,
    String? advice,
    List<String> sources = const [],
  }) {
    final pct = (confidence * 100).toStringAsFixed(0);
    final src = sources.isEmpty ? 'quy tắc + ML' : sources.join(' & ');
    final buf = StringBuffer()
      ..writeln('Ngành $majorName phù hợp khoảng $pct% với hồ sơ của bạn (khối ${input.examBlock}, khu vực ${input.region}).')
      ..writeln()
      ..writeln(reason.isNotEmpty ? reason : 'Gợi ý dựa trên điểm, sở thích và khối xét tuyển.')
      ..writeln()
      ..writeln('Nguồn: $src.');
    if (advice != null && advice.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(advice);
    }
    buf
      ..writeln()
      ..writeln('Bước tiếp: xem điểm chuẩn, chương trình đào tạo và trường trong miền bạn chọn.');
    return buf.toString().trim();
  }

  String _localSummarize({
    required GuidanceRecommendInput input,
    required List<Map<String, dynamic>> topMajors,
  }) {
    final buf = StringBuffer()
      ..writeln('Tóm tắt từ hệ thống (ML + quy tắc) cho khối ${input.examBlock}:')
      ..writeln();
    for (var i = 0; i < topMajors.length && i < 5; i++) {
      final m = topMajors[i];
      final name = (m['name'] ?? m['major'] ?? '').toString();
      final conf = m['confidence'];
      final pct = conf is num ? (conf * 100).toStringAsFixed(0) : '?';
      buf.writeln('${i + 1}. $name — $pct% phù hợp');
    }
    if (topMajors.isNotEmpty) {
      final top = (topMajors.first['name'] ?? topMajors.first['major'] ?? '').toString();
      buf
        ..writeln()
        ..writeln('Nên ưu tiên tìm hiểu sâu ngành $top, so sánh điểm chuẩn và cơ hội nghề trong 2–3 năm tới.');
    }
    return buf.toString().trim();
  }

  String _wrapLocalFallback(String body, {required String geminiNote}) {
    return '$body\n\n—\n📌 $geminiNote';
  }

  /// Send a message to the AI and return the plain text response.
  Future<String> sendMessage({
    required String message,
    int maxRetries = 1,
    Duration timeout = const Duration(seconds: 25),
    bool useAdvisorPersona = false,
  }) async {
    if (!hasApiKey) {
      return 'Chưa cấu hình GEN_AI_KEY. Chạy app với --dart-define=GEN_AI_KEY=<khóa Google AI>.';
    }

    final raw = await _generateText(
      message,
      advisor: useAdvisorPersona,
      timeout: timeout,
      maxRetries: maxRetries,
    );
    if (raw == '__AI_QUOTA__') {
      return 'API Gemini đã hết hạn mức miễn phí hoặc bị giới hạn. '
          'Vào https://aistudio.google.com/apikey để tạo key mới hoặc bật billing, rồi chạy lại app.';
    }
    if (raw == '__AI_MODEL_NOT_FOUND__') {
      return 'Không tìm thấy model Gemini cho key này. Kiểm tra key tại Google AI Studio.';
    }
    if (raw == '__AI_FAILED__') {
      return 'Gemini tạm thời không phản hồi. Vui lòng thử lại sau vài phút.';
    }
    return raw;
  }

  /// Request career guidance from AI.
  ///
  /// The AI is instructed to return ONLY a valid JSON object with the
  /// following structure (no surrounding text):
  /// {
  ///   "top_majors": [],
  /// Returns the decoded JSON as `Map<String, dynamic>` on success.
  /// If the model returns non-JSON or parsing fails, returns:
  /// { "error": "JSON không hợp lệ", "raw": <text> }
  Future<Map<String, dynamic>> getCareerGuidance({
    required double mathScore,
    required double literatureScore,
    required double englishScore,
    required List<String> interests,
    required List<String> strengths,
    required String region,
  }) async {
    try {
      final prompt = '''
You are a helpful academic/career advisor. Return ONLY a single valid JSON object
with the exact structure below (do NOT add any explanatory text):

{
  "top_majors": [],
  "scores": [],
  "related_majors": [],
  "universities": [],
  "advice": ""
}

Input data:
- math: $mathScore
- literature: $literatureScore
- english: $englishScore
- interests: ${interests.join(', ')}
- strengths: ${strengths.join(', ')}
- region: $region

Please strictly follow the JSON format above and return only JSON.
''';

      final text = await _generateText(prompt, timeout: const Duration(seconds: 30));

      try {
        final decoded = jsonDecode(text);

        if (decoded is Map<String, dynamic>) {
          return decoded;
        }

        // If decoded JSON is not an object, return as invalid JSON.
        return {
          'error': 'JSON không hợp lệ',
          'raw': text,
        };
      } catch (e, st) {
        // Parsing failed — return raw text for debugging.
        debugPrint('AIService.getCareerGuidance JSON parse error: $e');
        debugPrint(st.toString());
        return {
          'error': 'JSON không hợp lệ',
          'raw': text,
        };
      }
    } catch (e, st) {
      // Any other error from request/timeout/etc — do not crash app.
      debugPrint('AIService.getCareerGuidance request error: $e');
      debugPrint(st.toString());
      return {
        'error': 'AI service failed',
        'details': e.toString(),
      };
    }
  }

  /// Helper to list available models from Google Generative API.
  /// Returns a list of model descriptors (may be empty on failure).
  /// This is a debug helper — do not expose API keys in logs.
  Future<List<dynamic>> listAvailableModels() async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final models = body['models'] as List<dynamic>?;
        return models ?? [];
      }

      debugPrint('ListModels failed: ${resp.statusCode} ${resp.body}');
      return [];
    } catch (e, st) {
      debugPrint('listAvailableModels error: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  /// Gọi server recommender để nhận danh sách ngành gợi ý.
  /// Trả về danh sách chuỗi tên ngành (top-k). Mặc định server local
  /// chạy trên `http://10.0.2.2:8000` (Android emulator -> host machine).
  Future<List<String>> recommendMajorsFromProfile({
    required double mathScore,
    required double literatureScore,
    required double englishScore,
    required List<String> interests,
    required List<String> strengths,
    String? serverUrl,
    int timeoutSeconds = 10,
  }) async {
    try {
      // Build a compact profile text from the structured inputs and call the new getRecommendations
      final profileText = 'Toán:${mathScore.toString()}; Văn:${literatureScore.toString()}; Tiếng Anh:${englishScore.toString()}; Sở thích: ${interests.join(', ')}; Ưu điểm: ${strengths.join(', ')}';
      final full = await getRecommendations(profileText: profileText, serverUrl: serverUrl, timeoutSeconds: timeoutSeconds);
      final top = full['top_majors'] as List<dynamic>? ?? [];
      if (top.isEmpty) {
        debugPrint('Remote recommender returned empty top_majors, falling back to local recommender');
        try {
          final local = RecommenderService();
          final recs = await local.recommend(interests);
          return recs.map((r) => r.major).toList();
        } catch (e) {
          debugPrint('Local recommender fallback failed: $e');
        }
      }
      return top.map((e) {
        if (e is Map && e['name'] != null) return e['name'].toString();
        return e.toString();
      }).toList();
    } catch (e, st) {
      debugPrint('recommendMajorsFromProfile error: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  /// Gọi API /recommend và trả về toàn bộ JSON đã decode để UI có thể dùng
  /// các trường mới như `confidence`, `reason`, `advice`, `need_human_support`, `contact_label`.
  Future<Map<String, dynamic>> getRecommendations({
    required String profileText,
    String? examBlock,
    List<String>? interests,
    List<String>? strengths,
    String? region,
    bool includeAdvice = false,
    String? serverUrl,
    int timeoutSeconds = 10,
  }) async {
    final candidates = RecommenderConfig.candidateUrls(override: serverUrl);

    final payload = <String, dynamic>{
      'profile_text': profileText,
      if (examBlock != null && examBlock.isNotEmpty) 'block': examBlock,
      if (interests != null && interests.isNotEmpty) 'interests': interests,
      if (strengths != null && strengths.isNotEmpty) 'skills': strengths,
      if (region != null && region.isNotEmpty) 'region': region,
      if (includeAdvice) 'include_advice': true,
    };

    final useStructured = examBlock != null &&
        examBlock.isNotEmpty &&
        ((interests != null && interests.isNotEmpty) ||
            (strengths != null && strengths.isNotEmpty));

    for (final base in candidates) {
      try {
        final url = Uri.parse('$base/recommend');
        final resp = await http
            .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
            .timeout(Duration(seconds: timeoutSeconds));

        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          return _normalizeRecommendResponse(body);
        }

        debugPrint('getRecommendations failed on $base: ${resp.statusCode} ${resp.body}');
      } catch (e) {
        debugPrint('getRecommendations error on $base: $e');
      }
    }

    if (!useStructured) {
      return {'error': 'all_endpoints_failed'};
    }

    // Retry text-only if structured request failed on all hosts
    final textPayload = {'profile_text': profileText};
    for (final base in candidates) {
      try {
        final url = Uri.parse('$base/recommend');
        final resp = await http
            .post(url,
                headers: {'Content-Type': 'application/json'}, body: jsonEncode(textPayload))
            .timeout(Duration(seconds: timeoutSeconds));
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as Map<String, dynamic>;
          return _normalizeRecommendResponse(body);
        }
      } catch (e) {
        debugPrint('getRecommendations text fallback error on $base: $e');
      }
    }

    return {'error': 'all_endpoints_failed'};
  }

  /// Chuẩn hóa trường `name` / `major` từ ML server.
  Map<String, dynamic> _normalizeRecommendResponse(Map<String, dynamic> body) {
    final top = body['top_majors'];
    if (top is! List) return body;
    final normalized = <Map<String, dynamic>>[];
    for (final item in top) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final n = (m['name'] ?? m['major'] ?? '').toString();
        if (n.isNotEmpty) {
          m['name'] = n;
          m['major'] = n;
        }
        normalized.add(m);
      }
    }
    return {...body, 'top_majors': normalized};
  }

  /// Gọi endpoint /select_major để log lựa chọn người dùng (dùng cho feedback/train sau này)
  Future<bool> selectMajor({
    required String major,
    required String profileText,
    String userId = 'demo_user',
    String? serverUrl,
    int timeoutSeconds = 5,
  }) async {
    final candidates = RecommenderConfig.candidateUrls(override: serverUrl);

    final payload = {
      'user_id': userId,
      'selected_major': major,
      'profile_text': profileText,
    };

    for (final base in candidates) {
      try {
        final url = Uri.parse('$base/select_major');
        final resp = await http
            .post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
            .timeout(Duration(seconds: timeoutSeconds));

        if (resp.statusCode == 200) return true;
        debugPrint('selectMajor failed on $base: ${resp.statusCode} ${resp.body}');
      } catch (e, st) {
        debugPrint('selectMajor error on $base: $e');
      }
    }

    return false;
  }

  /// Gemini giải thích vì sao một ngành phù hợp (luồng tư vấn chính).
  Future<String> explainMajorRecommendation({
    required String majorName,
    required GuidanceRecommendInput input,
    required double confidence,
    required String reason,
    String? advice,
    List<String> sources = const [],
  }) async {
    final pct = (confidence * 100).toStringAsFixed(0);
    final src = sources.isEmpty ? 'hệ thống' : sources.join(', ');
    final prompt = '''
Học sinh cần giải thích ngành "$majorName".

Hồ sơ:
${input.profileText}

Độ phù hợp hệ thống: $pct%
Nguồn gợi ý: $src
Lý do từ hệ thống: $reason
${advice != null && advice.isNotEmpty ? 'Lời khuyên có sẵn: $advice' : ''}

Hãy giải thích (3–5 câu): vì sao ngành này phù hợp, nên chuẩn bị gì, lưu ý khi xét tuyển khối ${input.examBlock}.
''';
    final ai = await sendMessage(message: prompt, useAdvisorPersona: true, timeout: const Duration(seconds: 25));
    if (!_looksLikeAiError(ai) && !ai.startsWith('__AI_')) return ai;

    const note =
        'Gemini tạm không phản hồi (hết quota / server bận). Tạo key mới tại aistudio.google.com hoặc thử lại sau.';
    return _wrapLocalFallback(
      _localExplainMajor(
        majorName: majorName,
        input: input,
        confidence: confidence,
        reason: reason,
        advice: advice,
        sources: sources,
      ),
      geminiNote: note,
    );
  }

  /// Gemini tóm tắt toàn bộ top ngành sau khi ML + quy tắc đã gộp.
  Future<String> summarizeRecommendationResults({
    required GuidanceRecommendInput input,
    required List<Map<String, dynamic>> topMajors,
  }) async {
    final lines = <String>[];
    for (var i = 0; i < topMajors.length && i < 5; i++) {
      final m = topMajors[i];
      final name = (m['name'] ?? m['major'] ?? '').toString();
      final conf = m['confidence'];
      final pct = conf is num ? (conf * 100).toStringAsFixed(0) : '?';
      lines.add('${i + 1}. $name ($pct%)');
    }
    final prompt = '''
Tóm tắt tư vấn hướng nghiệp cho học sinh.

Hồ sơ: ${input.profileText}

Top ngành từ hệ thống (ML embedding + quy tắc nghiệp vụ):
${lines.join('\n')}

Viết 1 đoạn ngắn (4–7 câu): xu hướng chung, nên ưu tiên ngành nào, bước tiếp theo (ôn thi, tìm hiểu trường).
''';
    final ai = await sendMessage(message: prompt, useAdvisorPersona: true, timeout: const Duration(seconds: 30));
    if (!_looksLikeAiError(ai) && !ai.startsWith('__AI_')) return ai;

    const note =
        'Gemini tạm không phản hồi (hết quota / server bận). Đây là tóm tắt từ ML + quy tắc; thử lại AI sau vài phút.';
    return _wrapLocalFallback(
      _localSummarize(input: input, topMajors: topMajors),
      geminiNote: note,
    );
  }

  /// Ngữ cảnh để mở Chat AI sau khi xem kết quả gợi ý.
  String buildChatContextFromResults({
    required GuidanceRecommendInput input,
    required List<dynamic> topMajors,
  }) {
    final names = topMajors
        .take(5)
        .map((e) => e is Map ? (e['name'] ?? e['major'] ?? '').toString() : e.toString())
        .where((s) => s.isNotEmpty)
        .join(', ');
    return 'Học sinh vừa hoàn thành định hướng. Khối: ${input.examBlock}. '
        'Khu vực: ${input.region}. Top ngành gợi ý: $names. '
        'Hồ sơ: ${input.profileText}';
  }
}