import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show rootNavigatorKey;
import '../views/reports/report_detail_view.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

/// Push notification lewat FCM. Pesan dikirim Edge Function notify-email ke token di public.device_tokens.
/// Sengaja memakai registration token (getToken/onTokenRefresh) walau deprecated di firebase_messaging 17:
/// format itu yang pasti diterima field `token` FCM HTTP v1 di Edge Function. Pindah ke register()/onRegistered
/// (Firebase Installation ID) setelah Edge Function diuji dengan FID.
/// Bila Firebase belum dikonfigurasi (google-services.json tidak ada), semua method diam-diam tidak melakukan apa-apa.
class PushService {
  PushService._();

  static bool _ready = false;
  static bool _navReady = false;
  static int? _pendingReportId;

  /// Ambil report_id dari data pesan FCM. Null bila kosong atau bukan angka.
  static int? reportIdFrom(Map<String, dynamic> data) =>
      int.tryParse('${data['report_id'] ?? ''}');

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Push nonaktif (Firebase belum dikonfigurasi): $e');
      return;
    }
    _ready = true;

    final messaging = FirebaseMessaging.instance;
    messaging.onTokenRefresh.listen(_save, onError: (Object e) => debugPrint('Error token refresh: $e'));
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);
    SupabaseService.client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.signedIn) register();
      },
      onError: (Object e) => debugPrint('Error auth state (push): $e'),
    );

    if (SupabaseService.isLoggedIn) await register();
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleOpen(initial);
  }

  /// Minta izin notifikasi lalu simpan token perangkat untuk akun yang sedang login.
  static Future<void> register() async {
    if (!_ready || !SupabaseService.isLoggedIn) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _save(token);
    } catch (e) {
      debugPrint('Error register push: $e');
    }
  }

  static Future<void> _save(String token) async {
    if (!SupabaseService.isLoggedIn) return;
    try {
      await SupabaseService.client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': 'android',
      });
    } catch (e) {
      debugPrint('Error simpan token push: $e');
    }
  }

  /// Panggil sebelum signOut, selagi sesi masih berlaku, supaya HP ini berhenti menerima push akun tersebut.
  static Future<void> unregister() async {
    _navReady = false;
    _pendingReportId = null;
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await SupabaseService.client.rpc('unregister_device_token', params: {'p_token': token});
      }
    } catch (e) {
      debugPrint('Error hapus token push: $e');
    }
  }

  /// Dipanggil MainNavigationView: navigator utama sudah siap, buka laporan dari push yang tertunda.
  static void markNavigationReady() {
    _navReady = true;
    final id = _pendingReportId;
    _pendingReportId = null;
    if (id != null) _openReport(id);
  }

  static void _handleOpen(RemoteMessage message) {
    final id = reportIdFrom(message.data);
    if (id == null) return;
    if (_navReady) {
      _openReport(id);
    } else {
      _pendingReportId = id;
    }
  }

  static Future<void> _openReport(int id) async {
    final report = await NotificationService.loadReport(id);
    final nav = rootNavigatorKey.currentState;
    if (report == null || nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => ReportDetailView(report: report)));
  }
}
