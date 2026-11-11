import 'package:findit_mobile/models/campus_model.dart';
import 'package:findit_mobile/views/home/all_reports_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AllReportsView menampilkan cabang yang membatasi daftar', (tester) async {
    final campus = CampusModel(id: 1, namaKampus: 'UBSI Margonda', kodeKampus: 'MGD', kota: 'Depok');

    await tester.pumpWidget(MaterialApp(home: AllReportsView(reports: const [], campus: campus)));
    await tester.pump();

    expect(find.text('UBSI Margonda'), findsOneWidget);
    expect(find.text('Semua Cabang'), findsNothing);
  });

  testWidgets('AllReportsView menawarkan semua cabang bila tidak dibatasi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AllReportsView(reports: [])));
    await tester.pump();

    expect(find.text('Semua Cabang'), findsOneWidget);
  });
}
