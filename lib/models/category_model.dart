class CategoryModel {
  final int id;
  final String namaCategory;
  final String priority;

  CategoryModel({
    required this.id,
    required this.namaCategory,
    required this.priority,
  });

  String get namaKategori => namaCategory;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      namaCategory: json['nama_category'] ?? json['nama_kategori'] ?? '',
      priority: json['priority'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_category': namaCategory,
      'priority': priority,
    };
  }
}
