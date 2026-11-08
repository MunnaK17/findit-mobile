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

  /// Menyimpan pesan galat jaringan/query terakhir agar tampilan dapat merender Error State (R-27).
  static String? lastError;

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

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
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
      if (e.message.toLowerCase().contains('email not confirmed')) {
        try {
          await client.auth.resend(
            type: OtpType.signup,
            email: cleanEmail,
          );
        } catch (_) {}
        return {
          'success': false,
          'needs_verification': true,
          'email': cleanEmail,
          'message': 'Email belum diverifikasi. Kode OTP telah dikirim ke email Anda.',
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
          'requires_verification': res.session == null,
          'email': cleanEmail,
          'message': 'Registrasi berhasil. Kode verifikasi dikirim ke $cleanEmail',
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
    } catch (e) {
      debugPrint("Error resend OTP: $e");
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

  static Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      final res = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (res.user != null) {
        return {'success': true, 'message': 'Kata sandi berhasil diperbarui'};
      }
      return {'success': false, 'message': 'Gagal memperbarui kata sandi'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePhone(String phone) async {
    final user = client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Sesi login tidak ditemukan'};
    }
    final cleanPhone = phone.trim();
    try {
      await client.from('profiles').update({
        'phone': cleanPhone,
      }).eq('id', user.id);

      try {
        await client.auth.updateUser(
          UserAttributes(data: {'phone': cleanPhone}),
        );
      } catch (_) {}

      return {'success': true, 'message': 'Nomor HP berhasil disimpan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui nomor HP: $e'};
    }
  }

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
      lastError = 'Gagal memuat daftar cabang kampus. Periksa koneksi internet Anda.';
      return [];
    }
  }

  static Future<List<CategoryModel>> getCategories() async {
    try {
      final data = await client.from('categories').select().order('id');
      return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getCategories: $e");
      lastError = 'Gagal memuat daftar kategori barang.';
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
      lastError = null;
      var query = client.from('reports').select('''
        *,
        campus:campuses(*),
        category:categories(*),
        user:public_profiles(*)
      ''').inFilter('status', ['approved', 'completed']);

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
        // Nilai dibungkus tanda kutip agar koma, titik, dan kurung dari user tidak dibaca sebagai sintaks filter.
        final pattern = '"%${search.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}%"';
        query = query.or('nama_barang.ilike.$pattern,deskripsi.ilike.$pattern,lokasi.ilike.$pattern');
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List).map((e) => ReportModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getReports: $e");
      lastError = 'Gagal memuat daftar laporan dari server. Periksa koneksi internet Anda.';
      return [];
    }
  }

  static Future<List<ReportModel>> getMyReports() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      lastError = null;
      final data = await client
          .from('reports')
          .select('*, campus:campuses(*), category:categories(*)')
          .eq('id_user', user.id)
          .order('created_at', ascending: false);

      return (data as List).map((e) => ReportModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getMyReports: $e");
      lastError = 'Gagal memuat riwayat laporan Anda. Silakan coba lagi.';
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
    dynamic imageFile,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Silakan masuk terlebih dahulu untuk membuat laporan.'};
    }

    try {
      String? photoUrl;
      final hasPhoto = imageFile != null || (imageBytes != null && imageBytes.isNotEmpty);

      Uint8List? bytesToUpload;
      String rawExt = 'jpg';

      if (imageBytes != null && imageBytes.isNotEmpty) {
        bytesToUpload = imageBytes;
        if (imageName != null && imageName.contains('.')) {
          rawExt = imageName.split('.').last;
        }
      } else if (imageFile != null) {
        if (imageFile is File) {
          bytesToUpload = await imageFile.readAsBytes();
          rawExt = imageFile.path.split('.').last;
        } else {
          try {
            bytesToUpload = await imageFile.readAsBytes();
            final name = imageFile.name ?? imageFile.path ?? '';
            if (name.toString().contains('.')) {
              rawExt = name.toString().split('.').last;
            }
          } catch (e) {
            debugPrint("Error reading image bytes from imageFile: $e");
          }
        }
      }

      if (bytesToUpload != null && bytesToUpload.isNotEmpty) {
        final cleanExt = rawExt.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final safeExt = (cleanExt == 'png' || cleanExt == 'webp' || cleanExt == 'gif')
            ? cleanExt
            : 'jpg';
        final mimeType = safeExt == 'png'
            ? 'image/png'
            : (safeExt == 'webp' ? 'image/webp' : (safeExt == 'gif' ? 'image/gif' : 'image/jpeg'));

        // Nama file unik per user dan milidetik, jadi upload baru tidak perlu upsert (cukup policy INSERT).
        final fileName = "${DateTime.now().millisecondsSinceEpoch}_${user.id}.$safeExt";
        final path = "reports/$fileName";

        try {
          await client.storage.from(SupabaseConstants.reportsBucket).uploadBinary(
                path,
                bytesToUpload,
                fileOptions: FileOptions(contentType: mimeType),
              );
          photoUrl = client.storage.from(SupabaseConstants.reportsBucket).getPublicUrl(path);
        } catch (e) {
          debugPrint("Failed upload image to Supabase: $e");
        }
      }

      // Foto tidak bisa ditambahkan setelah laporan dibuat, jadi laporan tidak disimpan tanpa foto yang dipilih.
      if (hasPhoto && photoUrl == null) {
        return {
          'success': false,
          'message': 'Foto gagal diunggah, laporan belum disimpan. Coba lagi atau hapus foto.',
        };
      }

      final res = await client.from('reports').insert({
        'id_user': user.id,
        'id_category': categoryId,
        'id_campus': campusId,
        'jenis_laporan': jenisLaporan,
        'nama_barang': namaBarang,
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'tanggal_kejadian': tanggalKejadian,
        'foto_barang': photoUrl,
        'status': 'pending',
      }).select().single();

      return {
        'success': true,
        'data': res,
        'message': 'Laporan berhasil dibuat dan sedang menunggu verifikasi admin sebelum dipublikasikan.',
      };
    } catch (e) {
      debugPrint("Error createReport: $e");
      return {'success': false, 'message': 'Gagal membuat laporan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateReport({
    required int id,
    required String namaBarang,
    required String deskripsi,
    required String lokasi,
    required String tanggalKejadian,
    int? categoryId,
    int? campusId,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      final updateData = <String, dynamic>{
        'nama_barang': namaBarang,
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'tanggal_kejadian': tanggalKejadian,
      };
      if (categoryId != null) updateData['id_category'] = categoryId;
      if (campusId != null) updateData['id_campus'] = campusId;

      await client.from('reports').update(updateData).eq('id', id);
      return {'success': true, 'message': 'Laporan berhasil diperbarui'};
    } catch (e) {
      debugPrint("Error updateReport: $e");
      return {'success': false, 'message': 'Gagal memperbarui laporan: $e'};
    }
  }

  static Future<Map<String, dynamic>> markReportCompleted(int id) async {
    final user = client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      // RLS menolak update langsung ke completed, jadi perubahan lewat RPC yang memeriksa pemilik dan status approved.
      final updated = await client.rpc('mark_report_completed', params: {'p_report_id': id});
      if (updated != true) {
        return {'success': false, 'message': 'Hanya laporan terverifikasi milik Anda yang dapat ditandai selesai.'};
      }
      return {'success': true, 'message': 'Laporan ditandai selesai / barang telah kembali'};
    } catch (e) {
      debugPrint("Error markReportCompleted: $e");
      return {'success': false, 'message': 'Gagal mengubah status: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteReport(int id) async {
    final user = client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      await client.from('reports').delete().eq('id', id);
      return {'success': true, 'message': 'Laporan berhasil dihapus'};
    } catch (e) {
      debugPrint("Error deleteReport: $e");
      return {'success': false, 'message': 'Gagal menghapus laporan: $e'};
    }
  }

  static Future<List<ClaimModel>> getMyClaims() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    try {
      lastError = null;
      final data = await client
          .from('claims')
          .select('*, report:reports(*, campus:campuses(*))')
          .eq('id_user', user.id)
          .order('created_at', ascending: false);

      return (data as List).map((e) => ClaimModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error getMyClaims: $e");
      lastError = 'Gagal memuat daftar pengajuan klaim Anda. Silakan coba lagi.';
      return [];
    }
  }

  static Future<bool> hasClaimed(int reportId) async {
    final user = client.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await client
          .from('claims')
          .select('id')
          .eq('id_report', reportId)
          .eq('id_user', user.id)
          .neq('status_klaim', 'rejected')
          .maybeSingle();

      return res != null;
    } catch (e) {
      debugPrint("Error checking hasClaimed: $e");
      return false;
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
      // 1. Cek apakah ini laporan milik sendiri
      final reportRes = await client
          .from('reports')
          .select('id_user')
          .eq('id', reportId)
          .maybeSingle();

      if (reportRes != null && reportRes['id_user']?.toString() == user.id.toString()) {
        return {
          'success': false,
          'message': 'Anda tidak bisa mengklaim laporan milik Anda sendiri.',
        };
      }

      // 2. Cek apakah user sudah pernah mengajukan klaim untuk laporan ini (selain status rejected)
      final existingClaim = await client
          .from('claims')
          .select('id')
          .eq('id_report', reportId)
          .eq('id_user', user.id)
          .neq('status_klaim', 'rejected')
          .maybeSingle();

      if (existingClaim != null) {
        return {
          'success': false,
          'message': 'Anda sudah pernah mengajukan klaim untuk barang ini.',
        };
      }

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
