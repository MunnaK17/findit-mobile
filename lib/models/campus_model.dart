class CampusModel {
  final int id;
  final String namaKampus;
  final String kodeKampus;
  final String kota;
  final String? alamat;
  final String? kontak;

  CampusModel({
    required this.id,
    required this.namaKampus,
    required this.kodeKampus,
    required this.kota,
    this.alamat,
    this.kontak,
  });

  factory CampusModel.fromJson(Map<String, dynamic> json) {
    return CampusModel(
      id: json['id'] ?? 0,
      namaKampus: json['nama_kampus'] ?? '',
      kodeKampus: json['kode_kampus'] ?? '',
      kota: json['kota'] ?? '',
      alamat: json['alamat'],
      kontak: json['kontak'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kampus': namaKampus,
      'kode_kampus': kodeKampus,
      'kota': kota,
      'alamat': alamat,
      'kontak': kontak,
    };
  }
}
