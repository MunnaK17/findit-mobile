import 'package:flutter_test/flutter_test.dart';
import 'package:findit_mobile/main.dart';

void main() {
  testWidgets('FindIT App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FindITApp(initialLoggedIn: false));
    expect(find.text('FindIT Kampus'), findsOneWidget);
  });
}
