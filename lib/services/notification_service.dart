import 'package:flutter/foundation.dart';
import '../models/app_notification_model.dart';
import '../models/report_model.dart';
import 'supabase_service.dart';

/// Kotak notifikasi in-app (public.app_notifications). Realtime lewat Supabase stream.
class NotificationService {
  NotificationService._();

  /// Daftar notifikasi milik pengguna yang login, terbaru dulu. Kosong bila belum login.
  static Stream<List<AppNotificationModel>> watchMine({int limit = 50}) {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return Stream.value(const []);
    return SupabaseService.client
        .from('app_notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((rows) => rows.map(AppNotificationModel.fromJson).toList());
  }

  static Stream<int> watchUnreadCount() =>
      watchMine().map((list) => list.where((n) => !n.isRead).length);

  static Future<bool> markRead(int id) async {
    try {
      await SupabaseService.client
          .from('app_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .isFilter('read_at', null);
      return true;
    } catch (e) {
      debugPrint('Error markRead: $e');
      return false;
    }
  }

  static Future<bool> markAllRead() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return false;
    try {
      await SupabaseService.client
          .from('app_notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', user.id)
          .isFilter('read_at', null);
      return true;
    } catch (e) {
      debugPrint('Error markAllRead: $e');
      return false;
    }
  }

  /// Laporan yang dirujuk notifikasi. Null bila sudah dihapus atau tidak boleh dilihat.
  static Future<ReportModel?> loadReport(int id) async {
    try {
      final data = await SupabaseService.client
          .from('reports')
          .select('*, campus:campuses(*), category:categories(*), user:public_profiles(*)')
          .eq('id', id)
          .maybeSingle();
      return data == null ? null : ReportModel.fromJson(data);
    } catch (e) {
      debugPrint('Error loadReport: $e');
      return null;
    }
  }
}
