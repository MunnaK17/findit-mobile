import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return await SupabaseService.login(email, password);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'mahasiswa',
    String? nim,
    String? nip,
    String? phone,
    int? idCampus,
    String? prodiUnit,
  }) async {
    if (password != passwordConfirmation) {
      return {'success': false, 'message': 'Konfirmasi kata sandi tidak cocok'};
    }

    return await SupabaseService.register(
      name: name,
      email: email,
      password: password,
      role: role,
      nim: nim,
      nip: nip,
      phone: phone,
      idCampus: idCampus,
      prodiUnit: prodiUnit,
    );
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    return await SupabaseService.verifyEmail(email, code);
  }

  static Future<bool> resendVerification(String email) async {
    return await SupabaseService.resendVerification(email);
  }

  static Future<UserModel?> getCurrentUser() async {
    return await SupabaseService.getCurrentUser();
  }

  static Future<bool> logout() async {
    return await SupabaseService.logout();
  }
}
