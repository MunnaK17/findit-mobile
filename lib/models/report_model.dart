import 'campus_model.dart';
import 'category_model.dart';
import 'user_model.dart';

class ReportModel {
  final int id;
  final dynamic idUser;
  final int idCategory;
  final int? idCampus;
  final String jenisLaporan; // 'hilang' | 'temuan'
  final String namaBarang;
  final String deskripsi;
  final String lokasi;
  final String tanggalKejadian;
  final String? fotoBarang;
  final String status; // 'pending' | 'approved' | 'rejected' | 'completed'
  final String? adminNotes;
  final String? createdAt;
  final CategoryModel? category;
  final CampusModel? campus;
  final UserModel? user;

  ReportModel({
    required this.id,
    required this.idUser,
    required this.idCategory,
    this.idCampus,
    required this.jenisLaporan,
    required this.namaBarang,
    required this.deskripsi,
    required this.lokasi,
    required this.tanggalKejadian,
    this.fotoBarang,
    required this.status,
    this.adminNotes,
    this.createdAt,
    this.category,
    this.campus,
    this.user,
  });

  bool get isHilang => jenisLaporan == 'hilang';
  bool get isTemuan => jenisLaporan == 'temuan';
  bool get canBeClaimed => isTemuan && status == 'approved';

  String get relativeTime {
    final raw = createdAt ?? tanggalKejadian;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return tanggalKejadian;
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return tanggalKejadian;
  }

  String? get fullFotoUrl {
    if (fotoBarang == null || fotoBarang!.trim().isEmpty) return null;
    final clean = fotoBarang!.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) return clean;
    if (clean.startsWith('reports/')) {
      return "https://ulrxqbvccwhcvywssjfb.supabase.co/storage/v1/object/public/reports/$clean";
    }
    return "https://ulrxqbvccwhcvywssjfb.supabase.co/storage/v1/object/public/reports/reports/$clean";
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? 0,
      idUser: json['id_user'] ?? 0,
      idCategory: json['id_category'] ?? 0,
      idCampus: json['id_campus'],
      jenisLaporan: json['jenis_laporan'] ?? 'hilang',
      namaBarang: json['nama_barang'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      lokasi: json['lokasi'] ?? '',
      tanggalKejadian: json['tanggal_kejadian'] ?? '',
      fotoBarang: json['foto_barang'],
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      createdAt: json['created_at']?.toString(),
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
      campus: json['campus'] != null ? CampusModel.fromJson(json['campus']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
