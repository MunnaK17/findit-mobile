import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import 'supabase_service.dart';

class ChatbotService {
  /// Memanggil Edge Function `chatbot` (supabase/functions/chatbot) dengan sesi Supabase atau anon key.
  static Future<Map<String, dynamic>> askQuestion(String message) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'chatbot',
        body: {'message': message},
      );

      final data = response.data;
      if (data is! Map) {
        return {'success': false, 'reply': 'Maaf, terjadi gangguan pada server asisten AI.'};
      }

      ChatAction? action;
      if (data['action'] is Map) {
        action = ChatAction.fromJson(Map<String, dynamic>.from(data['action']));
      }
      final List<String> quickReplies = [];
      for (final item in (data['quickReplies'] as List? ?? const [])) {
        if (item is Map) {
          quickReplies.add((item['label'] ?? item['value'] ?? '').toString());
        } else {
          quickReplies.add(item.toString());
        }
      }
      return {
        'success': true,
        'reply': data['reply'] ?? 'Tidak ada respon.',
        'action': action,
        'quickReplies': quickReplies,
      };
    } on FunctionException catch (e) {
      debugPrint('Chatbot function error ${e.status}: ${e.details}');
      return {'success': false, 'reply': 'Maaf, terjadi gangguan pada server asisten AI.'};
    } catch (e) {
      debugPrint('Chatbot request failed: $e');
      return {'success': false, 'reply': 'Gagal terhubung ke asisten AI. Periksa koneksi internet Anda.'};
    }
  }
}
