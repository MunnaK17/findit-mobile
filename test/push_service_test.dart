import 'package:findit_mobile/services/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushService.reportIdFrom', () {
    test('membaca report_id angka dari data FCM', () {
      expect(PushService.reportIdFrom({'report_id': '42'}), 42);
    });

    test('null bila kosong, hilang, atau bukan angka', () {
      expect(PushService.reportIdFrom({}), isNull);
      expect(PushService.reportIdFrom({'report_id': ''}), isNull);
      expect(PushService.reportIdFrom({'report_id': 'abc'}), isNull);
    });
  });
}
