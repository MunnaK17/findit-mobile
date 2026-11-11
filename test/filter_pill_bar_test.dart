import 'package:findit_mobile/core/theme/app_theme.dart';
import 'package:findit_mobile/core/widgets/findit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FilterPillBar mengisi lebar penuh tanpa overflow di layar 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    String selected = 'all';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatefulBuilder(
              builder: (context, setState) => FilterPillBar(
                options: const [
                  ('all', 'Semua'),
                  ('pending', 'Menunggu'),
                  ('approved', 'Disetujui'),
                  ('completed', 'Selesai'),
                ],
                selected: selected,
                onSelected: (k) => setState(() => selected = k),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final first = tester.getTopLeft(find.text('Semua').first);
    final lastPill = find.ancestor(of: find.text('Selesai'), matching: find.byType(Material)).first;
    final firstPill = find.ancestor(of: find.text('Semua'), matching: find.byType(Material)).first;
    expect(tester.getTopLeft(firstPill).dx, 16);
    expect(tester.getTopRight(lastPill).dx, 320 - 16);
    expect(first.dx, greaterThan(16));

    await tester.tap(find.text('Disetujui'));
    await tester.pump();
    expect(selected, 'approved');
  });
}
