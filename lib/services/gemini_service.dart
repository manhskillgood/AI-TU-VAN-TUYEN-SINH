import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Lấy key từ --dart-define
  final String _apiKey = const String.fromEnvironment('GEN_AI_KEY');
  late GenerativeModel _model;
  
  final String systemInstruction = 
      'Bạn là một chuyên gia tư vấn hướng nghiệp: đưa ra gợi ý ngành học phù hợp, giải thích ngắn gọn và lịch sự.';

  GeminiService() {
    if (_apiKey.isEmpty) {
      debugPrint('LỖI: GEN_AI_KEY trống! Hãy chạy với --dart-define=GEN_AI_KEY=YOUR_KEY');
    }
    
    // SỬA TÊN MODEL Ở ĐÂY: Dùng 'gemini-1.5-flash' (SDK sẽ tự xử lý tiền tố)
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: _apiKey,
    );
  }

  Future<String> sendMessage(String prompt) async {
    if (_apiKey.isEmpty) return 'Lỗi: Thiếu API Key. Hãy kiểm tra lại cấu hình.';

    try {
      // Bọc prompt với Instruction để AI luôn đóng vai chuyên gia
      final content = [Content.text('$systemInstruction\n\nNgười dùng: $prompt')];
      
      final response = await _model.generateContent(content)
          .timeout(const Duration(seconds: 20));

      return response.text ?? 'AI không có phản hồi.';
    } catch (e) {
      debugPrint('Gemini Error: $e');
      
      // Nếu vẫn báo 'not found', ta sẽ hướng dẫn người dùng đổi sang gemini-pro
      if (e.toString().contains('not found')) {
        return 'Mô hình gemini-1.5-flash hiện không khả dụng với Key này. Hãy thử đổi sang gemini-pro.';
      }
      
      return 'Hệ thống AI đang bận, bạn thử lại sau nhé! (Lỗi: $e)';
    }
  }
}
