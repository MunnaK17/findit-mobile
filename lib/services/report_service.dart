import 'dart:convert';
import 'dart:io';
import '../core/constants/api_constants.dart';
import '../models/campus_model.dart';
import '../models/category_model.dart';
import '../models/report_model.dart';
import 'api_service.dart';

class ReportService {
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await ApiService.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<CampusModel>> getCampuses() async {
    try {
      final response = await ApiService.get(ApiConstants.campuses);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => CampusModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<ReportModel>> getReports({
    String? jenis, // 'hilang' | 'temuan'
    String? search,
    int? categoryId,
    int? campusId,
  }) async {
    try {
      var url = "${ApiConstants.reports}?";
      if (jenis != null) url += "jenis=$jenis&";
      if (search != null && search.isNotEmpty) url += "search=$search&";
      if (categoryId != null) url += "category_id=$categoryId&";
      if (campusId != null) url += "campus_id=$campusId&";

      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List data = decoded is List ? decoded : (decoded['data'] ?? []);
        return data.map((e) => ReportModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<ReportModel>> getMyReports() async {
    try {
      final response = await ApiService.get(ApiConstants.myReports);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List data = decoded is List ? decoded : (decoded['data'] ?? []);
        return data.map((e) => ReportModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
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
    try {
      final fields = {
        'id_category': categoryId.toString(),
        if (campusId != null) 'id_campus': campusId.toString(),
        'jenis_laporan': jenisLaporan,
        'nama_barang': namaBarang,
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'tanggal_kejadian': tanggalKejadian,
      };

      final streamedResponse = await ApiService.postMultipart(
        url: ApiConstants.reports,
        fields: fields,
        imageFile: imageFile,
      );

      final response = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(response);

      if (streamedResponse.statusCode == 201 || streamedResponse.statusCode == 200) {
        return {'success': true, 'message': 'Laporan berhasil dibuat'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal membuat laporan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
