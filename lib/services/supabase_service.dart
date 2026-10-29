import 'dart:io';
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

  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static bool get isLoggedIn => client.auth.currentUser != null;

  // ================= AUTHENTICATION =================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (res.user != null) {
        final profile = await getCurrentUser();
        return {'success': true, 'user': profile};
      }
      return {'success': false, 'message': 'Login gagal'};
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        return {
          'success': false,
          'needs_verification': true,
          'email': email.trim().toLowerCase(),
          'message': 'Email belum diverifikasi. Silakan masukkan kode verifikasi Anda.',
        };
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
        // Also manually upsert profile in case trigger takes a moment
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
          'email': cleanEmail,
          'message': 'Registrasi berhasil',
        };
      }
      return {'success': false, 'message': 'Gagal mendaftar'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String token) async {
    try {
      final res = await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.signup,
      );

      if (res.user != null) {
        final profile = await getCurrentUser();
        return {'success': true, 'user': profile};
      }
      return {'success': false, 'message': 'Verifikasi gagal'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<bool> resendVerification(String email) async {
    try {
      await client.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<UserModel?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select('*, campus:campuses(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return UserModel.fromJson(data);
      }

      // Fallback from auth user metadata
      return UserModel(
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
    } catch (_) {
      return null;
    }
  }

  static Future<bool> logout() async {
    try {
      await client.auth.signOut();
      return true;
    } catch (_) {
      return false;
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
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await client
          .from('reports')
          .select('*, campus:campuses(*), category:categories(*)')
          .eq('id_user', user.id)
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
    final user = client.auth.currentUser;

    try {
      String? photoUrl;

      // Upload image to Supabase Storage if present
      if (imageFile != null) {
        try {
          final bytes = await imageFile.readAsBytes();
          final ext = imageFile.path.split('.').last;
          final fileName = "${DateTime.now().millisecondsSinceEpoch}_${user?.id ?? 'guest'}.$ext";
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
        'id_user': user?.id,
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
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await client
          .from('claims')
          .select('*, report:reports(*, campus:campuses(*))')
          .eq('id_user', user.id)
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
    final user = client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      final res = await client.from('claims').insert({
        'id_report': reportId,
        'id_user': user.id,
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
