import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await ApiService.saveToken(data['token']);
        final user = UserModel.fromJson(data['user']);
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'needs_verification': data['needs_verification'] == true,
          'email': data['email'] ?? email,
          'message': data['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
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
    try {
      final response = await ApiService.post(ApiConstants.register, {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
        'nim': nim,
        'nip': nip,
        'phone': phone,
        'id_campus': idCampus,
        'prodi_unit': prodiUnit,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'email': data['email'] ?? email, 'message': data['message'] ?? 'Registrasi berhasil'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await ApiService.post(ApiConstants.verifyEmail, {'email': email, 'code': code});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['token'] != null) {
        await ApiService.saveToken(data['token']);
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      }
      return {'success': false, 'message': data['message'] ?? 'Verifikasi gagal'};
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  static Future<bool> resendVerification(String email) async {
    try {
      final response = await ApiService.post(ApiConstants.resendVerification, {'email': email});
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiService.get(ApiConstants.user);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> logout() async {
    try {
      await ApiService.post(ApiConstants.logout, {});
    } catch (_) {}
    await ApiService.clearToken();
    return true;
  }
}
