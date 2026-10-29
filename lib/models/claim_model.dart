import 'report_model.dart';
import 'user_model.dart';

class ClaimModel {
  final int id;
  final int idReport;
  final int idUser;
  final String pesanKlaim;
  final String statusKlaim; // 'pending' | 'approved' | 'rejected'
  final String tanggalKlaim;
  final ReportModel? report;
  final UserModel? user;

  ClaimModel({
    required this.id,
    required this.idReport,
    required this.idUser,
    required this.pesanKlaim,
    required this.statusKlaim,
    required this.tanggalKlaim,
    this.report,
    this.user,
  });

  bool get isPending => statusKlaim == 'pending';
  bool get isApproved => statusKlaim == 'approved';
  bool get isRejected => statusKlaim == 'rejected';

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'] ?? 0,
      idReport: json['id_report'] ?? 0,
      idUser: json['id_user'] ?? 0,
      pesanKlaim: json['pesan_klaim'] ?? '',
      statusKlaim: json['status_klaim'] ?? 'pending',
      tanggalKlaim: json['tanggal_klaim'] ?? '',
      report: json['report'] != null ? ReportModel.fromJson(json['report']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
