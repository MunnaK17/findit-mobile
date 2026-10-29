import 'campus_model.dart';

class UserModel {
  final dynamic id;
  final String name;
  final String email;
  final String? nim;
  final String? nip;
  final String? phone;
  final String role; // 'mahasiswa' | 'staff' | 'admin'
  final int? idCampus;
  final String? prodiUnit;
  final CampusModel? campus;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.nim,
    this.nip,
    this.phone,
    required this.role,
    this.idCampus,
    this.prodiUnit,
    this.campus,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isMahasiswa => role == 'mahasiswa';

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'staff':
        return 'Staff / Dosen';
      default:
        return 'Mahasiswa';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      nim: json['nim'],
      nip: json['nip'],
      phone: json['phone'],
      role: json['role'] ?? 'mahasiswa',
      idCampus: json['id_campus'],
      prodiUnit: json['prodi_unit'],
      campus: json['campus'] != null ? CampusModel.fromJson(json['campus']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nim': nim,
      'nip': nip,
      'phone': phone,
      'role': role,
      'id_campus': idCampus,
      'prodi_unit': prodiUnit,
      'campus': campus?.toJson(),
    };
  }
}
