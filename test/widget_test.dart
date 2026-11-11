import 'package:flutter_test/flutter_test.dart';
import 'package:findit_mobile/main.dart';

void main() {
  testWidgets('Splash tampil lalu menuju Login', (WidgetTester tester) async {
    await tester.pumpWidget(const FindITApp(initialLoggedIn: false));
    expect(find.text('Lost & Found Kampus'), findsOneWidget);
    expect(find.text('Powered by'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Masuk Sebagai Tamu'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Powered by'), findsOneWidget);
  });
}
