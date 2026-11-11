import 'package:findit_mobile/models/report_model.dart';
import 'package:findit_mobile/views/reports/report_detail_view.dart';
import 'package:findit_mobile/views/search/search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ReportModel _report({
  String jenis = 'hilang',
  String status = 'approved',
  DateTime? expiresAt,
  String deskripsi = 'Warna hitam, ada stiker kucing',
}) =>
    ReportModel(
      id: 1,
      idUser: 'u1',
      idCategory: 1,
      jenisLaporan: jenis,
      namaBarang: 'Kunci Motor Honda',
      deskripsi: deskripsi,
      lokasi: 'Parkiran Motor',
      tanggalKejadian: '2026-11-07',
      status: status,
      expiresAt: expiresAt,
    );

void main() {
  group('masa berlaku', () {
    test('laporan lewat expires_at dianggap kedaluwarsa dan tidak bisa diklaim', () {
      final r = _report(jenis: 'temuan', expiresAt: DateTime.now().subtract(const Duration(days: 1)));
      expect(r.isExpired, isTrue);
      expect(r.canBeClaimed, isFalse);
    });

    test('laporan aktif bisa diklaim', () {
      final r = _report(jenis: 'temuan', expiresAt: DateTime.now().add(const Duration(days: 10)));
      expect(r.isExpired, isFalse);
      expect(r.canBeClaimed, isTrue);
      expect(r.daysUntilExpiry, inInclusiveRange(9, 10));
    });

    test('copyWith hanya mengubah field yang diberikan', () {
      final r = _report();
      final done = r.copyWith(status: 'completed');
      expect(done.status, 'completed');
      expect(done.namaBarang, r.namaBarang);
      expect(done.deskripsi, r.deskripsi);
    });
  });

  group('teks bagikan', () {
    test('laporan hilang mengajak orang memberi kabar', () {
      final text = buildShareText(_report());
      expect(text, startsWith('[BARANG HILANG] Kunci Motor Honda'));
      expect(text, contains('Lokasi: Parkiran Motor'));
      expect(text, contains('Ciri: Warna hitam'));
      expect(text, contains('Pernah melihat barang ini?'));
    });

    test('laporan temuan mengajak pemilik mengklaim, deskripsi panjang dipotong', () {
      final text = buildShareText(_report(jenis: 'temuan', deskripsi: 'a' * 300));
      expect(text, startsWith('[BARANG TEMUAN]'));
      expect(text, contains('Ajukan klaim'));
      expect(text, contains('${'a' * 200}...'));
      expect(text, isNot(contains('a' * 201)));
    });
  });

  group('filter tanggal', () {
    test('preset 7 hari mencakup hari ini dan 6 hari sebelumnya', () {
      final now = DateTime(2026, 11, 9, 15, 30);
      final week = DateFilter.presets(now).firstWhere((p) => p.label == '7 hari terakhir');
      expect(week.from, DateTime(2026, 11, 3));
      expect(week.to, DateTime(2026, 11, 9));
      expect(DateFilter.all.isAll, isTrue);
    });

    test('rentang kustom diberi label tanggal', () {
      final f = DateFilter.custom(
        DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 5)),
      );
      expect(f.label, '1 Nov - 5 Nov');
      expect(f.isAll, isFalse);
    });
  });
}
