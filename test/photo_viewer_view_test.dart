import 'package:findit_mobile/views/reports/photo_viewer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PhotoViewerView bisa dibuka dan ditutup', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PhotoViewerView(
                  url: 'https://example.invalid/foto.jpg',
                  heroTag: 'report-photo-1',
                  title: 'Buku journal',
                ),
              ),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(find.text('Buku journal'), findsOneWidget);
    expect(find.byTooltip('Tutup foto'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    // Foto harus mengisi layar, bukan tampil sebesar ukuran pikselnya.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getSize(find.byType(Image)), screen);
    // Judul & tombol tutup tetap di bagian atas layar.
    expect(tester.getTopLeft(find.byTooltip('Tutup foto')).dy, lessThan(80));

    await tester.tap(find.byTooltip('Tutup foto'));
    await tester.pumpAndSettle();

    expect(find.text('buka'), findsOneWidget);
    expect(find.byType(PhotoViewerView), findsNothing);
  });
}
