import 'dart:io';
import '../models/campus_model.dart';
import '../models/category_model.dart';
import '../models/report_model.dart';
import 'supabase_service.dart';

class ReportService {
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
  }) async {
    return await SupabaseService.getReports(
      jenis: jenis,
      search: search,
      categoryId: categoryId,
      campusId: campusId,
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
    File? imageFile,
  }) async {
    return await SupabaseService.createReport(
      categoryId: categoryId,
      campusId: campusId,
      jenisLaporan: jenisLaporan,
      namaBarang: namaBarang,
      deskripsi: deskripsi,
      lokasi: lokasi,
      tanggalKejadian: tanggalKejadian,
      imageFile: imageFile,
    );
  }
}
