import '../models/claim_model.dart';
import 'supabase_service.dart';

class ClaimService {
  static Future<List<ClaimModel>> getMyClaims() async {
    return await SupabaseService.getMyClaims();
  }

  static Future<bool> hasClaimed(int reportId) async {
    return await SupabaseService.hasClaimed(reportId);
  }

  static Future<Map<String, dynamic>> submitClaim({
    required int reportId,
    required String pesanKlaim,
    String? buktiKepemilikan,
  }) async {
    return await SupabaseService.createClaim(
      reportId: reportId,
      pesanKlaim: pesanKlaim,
      buktiKepemilikan: buktiKepemilikan,
    );
  }
}
