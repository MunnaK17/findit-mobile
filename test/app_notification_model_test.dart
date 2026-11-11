import 'package:findit_mobile/models/app_notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson membaca baris app_notifications dari Supabase', () {
    final n = AppNotificationModel.fromJson({
      'id': 7,
      'event': 'report_approved',
      'report_id': 21,
      'claim_id': null,
      'title': 'Laporan kehilangan "Buku journal" sudah disetujui',
      'body': 'Admin sudah memverifikasi laporanmu.',
      'read_at': null,
      'created_at': DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String(),
    });

    expect(n.id, 7);
    expect(n.reportId, 21);
    expect(n.claimId, isNull);
    expect(n.isRead, isFalse);
    expect(n.relativeTime, '2 jam lalu');
  });

  test('read_at terisi berarti sudah dibaca', () {
    final n = AppNotificationModel.fromJson({
      'id': 1,
      'event': 'claim_rejected',
      'report_id': 3,
      'claim_id': 9,
      'title': 't',
      'body': 'b',
      'read_at': '2026-11-09T05:00:00Z',
      'created_at': '2026-11-09T04:00:00Z',
    });
    expect(n.isRead, isTrue);
    expect(n.claimId, 9);
  });
}
