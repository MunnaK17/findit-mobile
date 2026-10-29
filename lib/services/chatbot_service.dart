import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../models/chat_message_model.dart';
import 'api_service.dart';

class ChatbotService {
  static Future<Map<String, dynamic>> askQuestion(String message) async {
    try {
      final response = await ApiService.post(ApiConstants.chatbot, {
        'message': message,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ChatAction? action;
        if (data['action'] != null) {
          action = ChatAction.fromJson(data['action']);
        }
        final List<String> quickReplies = [];
        if (data['quickReplies'] != null) {
          for (var item in data['quickReplies']) {
            if (item is Map) {
              quickReplies.add(item['label'] ?? item['value'] ?? '');
            } else {
              quickReplies.add(item.toString());
            }
          }
        }
        return {
          'success': true,
          'reply': data['reply'] ?? 'Tidak ada respon.',
          'action': action,
          'quickReplies': quickReplies,
        };
      } else {
        return {
          'success': false,
          'reply': 'Maaf, terjadi gangguan pada server asisten AI.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'reply': 'Gagal terhubung ke server asisten AI: $e',
      };
    }
  }
}
