import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../models/claim_model.dart';
import 'api_service.dart';

class ClaimService {
  static Future<List<ClaimModel>> getMyClaims() async {
    try {
      final response = await ApiService.get(ApiConstants.myClaims);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List data = decoded is List ? decoded : (decoded['data'] ?? []);
        return data.map((e) => ClaimModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> submitClaim({
    required int reportId,
    required String pesanKlaim,
  }) async {
    try {
      final response = await ApiService.post("${ApiConstants.claims}/$reportId", {
        'pesan_klaim': pesanKlaim,
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Klaim berhasil diajukan!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Pengajuan klaim gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  static Future<bool> cancelClaim(int claimId) async {
    try {
      final response = await ApiService.delete("${ApiConstants.claims}/$claimId");
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
