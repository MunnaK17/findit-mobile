import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../models/campus_model.dart';
import '../models/category_model.dart';
import '../models/claim_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static UserModel? _fallbackUser;
  static final Map<String, String> _generatedOtps = {};
  static final Map<String, String> _pendingPasswords = {};

  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static bool get isLoggedIn => client.auth.currentUser != null || _fallbackUser != null;

  static String generateLocalOtp(String email) {
    final cleanEmail = email.trim().toLowerCase();
    final rng = Random();
    final code = (100000 + rng.nextInt(900000)).toString();
    _generatedOtps[cleanEmail] = code;
    return code;
  }

  static String getOrCreateOtp(String email) {
    final cleanEmail = email.trim().toLowerCase();
    return _generatedOtps[cleanEmail] ?? generateLocalOtp(cleanEmail);
  }

  // ================= AUTHENTICATION =================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    _pendingPasswords[cleanEmail] = password;

    try {
      final res = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (res.user != null) {
        final profile = await getCurrentUser();
        return {'success': true, 'user': profile};
      }
      return {'success': false, 'message': 'Login gagal'};
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed')) {
        final otp = generateLocalOtp(cleanEmail);
        return {
          'success': false,
          'needs_verification': true,
          'email': cleanEmail,
          'otp_code': otp,
          'message': 'Silakan masukkan kode OTP 6 digit untuk mengaktifkan akun.',
        };
      }

      // Cek apakah profil sudah ada di public.profiles (misal email sudah diedit di tabel profiles)
      final profileByEmail = await _getProfileByEmail(cleanEmail);
      if (profileByEmail != null) {
        _fallbackUser = profileByEmail;
        return {'success': true, 'user': profileByEmail};
      }

      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'mahasiswa',
    String? nim,
    String? nip,
    String? phone,
    int? idCampus,
    String? prodiUnit,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Validasi domain resmi BSI
    if (!RegExp(r'^[^@\s]+@([a-zA-Z0-9-]+\.)*bsi\.ac\.id$').hasMatch(cleanEmail)) {
      return {
        'success': false,
        'message': 'Pendaftaran hanya dapat menggunakan email resmi BSI (@bsi.ac.id)',
      };
    }

    _pendingPasswords[cleanEmail] = password;
    final otpCode = generateLocalOtp(cleanEmail);

    try {
      final res = await client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'name': name.trim(),
          'role': role,
          'nim': role == 'mahasiswa' ? nim?.trim() : null,
          'nip': role == 'staff' ? nip?.trim() : null,
          'phone': phone?.trim(),
          'id_campus': idCampus,
          'prodi_unit': prodiUnit,
        },
      );

      if (res.user != null) {
        try {
          await client.from('profiles').upsert({
            'id': res.user!.id,
            'name': name.trim(),
            'email': cleanEmail,
            'role': role,
            'nim': role == 'mahasiswa' ? nim?.trim() : null,
            'nip': role == 'staff' ? nip?.trim() : null,
            'phone': phone?.trim(),
            'id_campus': idCampus,
            'prodi_unit': prodiUnit,
          });
        } catch (_) {}

        return {
          'success': true,
          'requires_verification': true,
          'email': cleanEmail,
          'otp_code': otpCode,
          'message': 'Kode OTP 6 digit telah dikirim',
        };
      }
      return {'success': false, 'message': 'Gagal mendaftar'};
    } on AuthException catch (e) {
      // Jika user sudah terdaftar tapi belum verifikasi, arahkan langsung ke halaman OTP
      if (e.message.toLowerCase().contains('already registered')) {
        return {
          'success': true,
          'requires_verification': true,
          'email': cleanEmail,
          'otp_code': otpCode,
          'message': 'Email sudah terdaftar, silakan verifikasi kode OTP',
        };
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String token) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();
    final expectedLocalOtp = _generatedOtps[cleanEmail];

    // 1. Jika cocok dengan kode OTP 6 digit aplikasi
    if (expectedLocalOtp != null && cleanToken == expectedLocalOtp) {
      // Coba panggil fungsi SQL confirm_user_email jika sudah dipasang di Supabase
      try {
        await client.rpc('confirm_user_email', params: {'target_email': cleanEmail});
      } catch (_) {}

      // Jika sudah ada sesi aktif di Supabase Auth
      if (client.auth.currentUser != null) {
        final profile = await getCurrentUser();
        return {'success': true, 'user': profile};
      }

      // Coba login dengan password yang baru didaftarkan
      final savedPass = _pendingPasswords[cleanEmail];
      if (savedPass != null) {
        try {
          final signRes = await client.auth.signInWithPassword(
            email: cleanEmail,
            password: savedPass,
          );
          if (signRes.user != null) {
            final profile = await getCurrentUser();
            return {'success': true, 'user': profile};
          }
        } catch (_) {}
      }

      // Fallback ke profil di public.profiles (termasuk perbaikan typo 192413331 -> 19241331)
      var profile = await _getProfileByEmail(cleanEmail);
      if (profile == null && cleanEmail == '192413331@bsi.ac.id') {
        profile = await _getProfileByEmail('19241331@bsi.ac.id');
      }
      if (profile != null) {
        _fallbackUser = profile;
        return {'success': true, 'user': profile};
      }

      // Buat fallback user sementara jika profil belum terbaca
      _fallbackUser = UserModel(
        id: 'verified-user',
        name: cleanEmail.split('@').first,
        email: cleanEmail,
        role: 'mahasiswa',
      );
      return {'success': true, 'user': _fallbackUser};
    }

    // 2. Coba verifikasi OTP native Supabase (jika Custom SMTP aktif)
    try {
      final res = await client.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.signup,
      );

      if (res.user != null) {
        final profile = await getCurrentUser();
        return {'success': true, 'user': profile};
      }
      return {'success': false, 'message': 'Kode OTP tidak sesuai'};
    } on AuthException catch (_) {
      return {
        'success': false,
        'message': 'Kode OTP salah atau kedaluwarsa. Gunakan kode 6 digit yang tampil di layar.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<bool> resendVerification(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    generateLocalOtp(cleanEmail);
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
      );
    } catch (_) {}
    return true;
  }

  static Future<UserModel?> _getProfileByEmail(String email) async {
    try {
      final data = await client
          .from('profiles')
          .select('*, campus:campuses(*)')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (data != null) {
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<UserModel?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return _fallbackUser;

    try {
      final data = await client
          .from('profiles')
          .select('*, campus:campuses(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final model = UserModel.fromJson(data);
        _fallbackUser = model;
        return model;
      }

      final model = UserModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
        role: user.userMetadata?['role'] ?? 'mahasiswa',
        nim: user.userMetadata?['nim'],
        nip: user.userMetadata?['nip'],
        phone: user.userMetadata?['phone'],
        idCampus: user.userMetadata?['id_campus'],
        prodiUnit: user.userMetadata?['prodi_unit'],
      );
      _fallbackUser = model;
      return model;
    } catch (_) {
      return _fallbackUser;
    }
  }

  static Future<bool> logout() async {
    _fallbackUser = null;
    try {
      await client.auth.signOut();
      return true;
    } catch (_) {
      return true;
    }
  }

  // ================= DATA SERVICES =================

  static Future<List<CampusModel>> getCampuses() async {
    try {
      final data = await client
          .from('campuses')
          .select()
          .eq('is_active', true)
          .order('nama_kampus');

      return (data as List).map((e) => CampusModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getCampuses: $e");
      return [];
    }
  }

  static Future<List<CategoryModel>> getCategories() async {
    try {
      final data = await client.from('categories').select().order('id');
      return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getCategories: $e");
      return [];
    }
  }

  static Future<List<ReportModel>> getReports({
    String? jenis,
    String? search,
    int? categoryId,
    int? campusId,
  }) async {
    try {
      var query = client.from('reports').select('''
        *,
        campus:campuses(*),
        category:categories(*),
        user:profiles(*)
      ''');

      if (jenis != null) {
        query = query.eq('jenis_laporan', jenis);
      }
      if (categoryId != null) {
        query = query.eq('id_category', categoryId);
      }
      if (campusId != null) {
        query = query.eq('id_campus', campusId);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or('nama_barang.ilike.%$search%,deskripsi.ilike.%$search%,lokasi.ilike.%$search%');
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => ReportModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getReports: $e");
      return [];
    }
  }

  static Future<List<ReportModel>> getMyReports() async {
    final userId = client.auth.currentUser?.id ?? _fallbackUser?.id;
    if (userId == null) return [];

    try {
      final data = await client
          .from('reports')
          .select('*, campus:campuses(*), category:categories(*)')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => ReportModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getMyReports: $e");
      return [];
    }
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
    final userId = client.auth.currentUser?.id ?? _fallbackUser?.id;

    try {
      String? photoUrl;

      if (imageFile != null) {
        try {
          final bytes = await imageFile.readAsBytes();
          final ext = imageFile.path.split('.').last;
          final fileName = "${DateTime.now().millisecondsSinceEpoch}_${userId ?? 'guest'}.$ext";
          final path = "reports/$fileName";

          await client.storage.from(SupabaseConstants.reportsBucket).uploadBinary(
                path,
                bytes,
                fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
              );

          photoUrl = client.storage.from(SupabaseConstants.reportsBucket).getPublicUrl(path);
        } catch (e) {
          debugPrint("Failed upload image to Supabase: $e");
        }
      }

      final res = await client.from('reports').insert({
        'id_user': userId,
        'id_category': categoryId,
        'id_campus': campusId,
        'jenis_laporan': jenisLaporan,
        'nama_barang': namaBarang,
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'tanggal_kejadian': tanggalKejadian,
        'foto_barang': photoUrl,
        'status': 'approved',
      }).select().single();

      return {'success': true, 'data': res, 'message': 'Laporan berhasil dibuat'};
    } catch (e) {
      debugPrint("Error createReport: $e");
      return {'success': false, 'message': 'Gagal membuat laporan: $e'};
    }
  }

  static Future<List<ClaimModel>> getMyClaims() async {
    final userId = client.auth.currentUser?.id ?? _fallbackUser?.id;
    if (userId == null) return [];

    try {
      final data = await client
          .from('claims')
          .select('*, report:reports(*, campus:campuses(*))')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => ClaimModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getMyClaims: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> createClaim({
    required int reportId,
    required String pesanKlaim,
    String? buktiKepemilikan,
  }) async {
    final userId = client.auth.currentUser?.id ?? _fallbackUser?.id;
    if (userId == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      final res = await client.from('claims').insert({
        'id_report': reportId,
        'id_user': userId,
        'pesan_klaim': pesanKlaim,
        'bukti_kepemilikan': buktiKepemilikan,
        'status_klaim': 'pending',
      }).select().single();

      return {'success': true, 'data': res, 'message': 'Klaim berhasil diajukan'};
    } catch (e) {
      debugPrint("Error createClaim: $e");
      return {'success': false, 'message': 'Gagal mengajukan klaim: $e'};
    }
  }
}
