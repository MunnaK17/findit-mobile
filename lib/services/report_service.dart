import 'dart:typed_data';
import 'package:flutter/foundation.dart' show ValueNotifier;
import '../models/campus_model.dart';
import '../models/category_model.dart';
import '../models/report_model.dart';
import 'supabase_service.dart';

class ReportService {
  /// Naik setiap laporan dibuat, diubah, atau dihapus agar tab yang sudah termuat ikut memuat ulang.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<List<CategoryModel>> getCategories() async {
    return await SupabaseService.getCategories();
  }

  static Future<List<CampusModel>> getCampuses() async {
    return await SupabaseService.getCampuses();
  }

  static Future<List<ReportModel>> getReports({
    String? jenis, // 'hilang' | 'temuan'
    String? search,
    int? categoryId,
    int? campusId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
    int offset = 0,
  }) async {
    return await SupabaseService.getReports(
      jenis: jenis,
      search: search,
      categoryId: categoryId,
      campusId: campusId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
      offset: offset,
    );
  }

  static Future<List<ReportModel>> getMyReports() async {
    return await SupabaseService.getMyReports();
  }

  static Future<Map<String, dynamic>> createReport({
    required int categoryId,
    int? campusId,
    required String jenisLaporan,
    required String namaBarang,
    required String deskripsi,
    required String lokasi,
    required String tanggalKejadian,
    dynamic imageFile,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final res = await SupabaseService.createReport(
      categoryId: categoryId,
      campusId: campusId,
      jenisLaporan: jenisLaporan,
      namaBarang: namaBarang,
      deskripsi: deskripsi,
      lokasi: lokasi,
      tanggalKejadian: tanggalKejadian,
      imageFile: imageFile,
      imageBytes: imageBytes,
      imageName: imageName,
    );
    if (res['success'] == true) changes.value++;
    return res;
  }

  static Future<Map<String, dynamic>> updateReport({
    required int id,
    required String namaBarang,
    required String deskripsi,
    required String lokasi,
    required String tanggalKejadian,
    int? categoryId,
    int? campusId,
    bool requireReverification = false,
    Uint8List? newPhotoBytes,
    String? newPhotoName,
    String? oldPhotoUrl,
  }) async {
    final res = await SupabaseService.updateReport(
      id: id,
      namaBarang: namaBarang,
      deskripsi: deskripsi,
      lokasi: lokasi,
      tanggalKejadian: tanggalKejadian,
      categoryId: categoryId,
      campusId: campusId,
      requireReverification: requireReverification,
      newPhotoBytes: newPhotoBytes,
      newPhotoName: newPhotoName,
      oldPhotoUrl: oldPhotoUrl,
    );
    if (res['success'] == true) changes.value++;
    return res;
  }

  static Future<Map<String, dynamic>> markReportCompleted(int id) async {
    final res = await SupabaseService.markReportCompleted(id);
    if (res['success'] == true) changes.value++;
    return res;
  }

  static Future<Map<String, dynamic>> extendReport(int id) async {
    final res = await SupabaseService.extendReport(id);
    if (res['success'] == true) changes.value++;
    return res;
  }

  static Future<Map<String, dynamic>> deleteReport(int id) async {
    final res = await SupabaseService.deleteReport(id);
    if (res['success'] == true) changes.value++;
    return res;
  }
}
