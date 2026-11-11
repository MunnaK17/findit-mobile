import 'dart:io';

import 'package:findit_mobile/core/constants/campus_photos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Kode kampus di tabel public.campuses (11 cabang).
  const kodeKampus = [
    'SLP', 'KRM', 'MGD', 'BSD', 'KLB', 'FTW',
    'PMD', 'CKG', 'CPT', 'CTM', 'KRW',
  ];

  test('setiap cabang punya foto gedung bawaan', () {
    for (final kode in kodeKampus) {
      expect(campusPhotoAsset(kode), isNotNull, reason: 'foto $kode belum dipetakan');
    }
    expect(campusPhotoAsset('slp'), campusPhotoAssets['SLP']);
    expect(campusPhotoAsset('XXX'), isNull);
  });

  test('semua file foto ada dan berada di folder aset terdaftar', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/images/Kampus/'));
    for (final path in campusPhotoAssets.values) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path tidak ditemukan');
      expect(file.lengthSync(), greaterThan(0));
    }
  });
}
