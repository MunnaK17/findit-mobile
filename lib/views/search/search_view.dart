import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/campus_model.dart';
import '../../models/category_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../home/widgets/report_card.dart';

/// Halaman pencarian barang hilang / temuan.
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();

  List<ReportModel> _all = [];
  List<CategoryModel> _categories = [];
  List<CampusModel> _campuses = [];

  String _type = 'all'; // all | hilang | temuan
  int? _categoryId;
  int? _campusId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      ReportService.getReports(),
      ReportService.getCategories(),
      ReportService.getCampuses(),
    ]);
    if (!mounted) return;
    setState(() {
      _all = results[0] as List<ReportModel>;
      _categories = results[1] as List<CategoryModel>;
      _campuses = results[2] as List<CampusModel>;
      _isLoading = false;
    });
  }

  List<ReportModel> get _results {
    final q = _controller.text.trim().toLowerCase();
    return _all.where((r) {
      if (_type == 'hilang' && !r.isHilang) return false;
      if (_type == 'temuan' && !r.isTemuan) return false;
      if (_categoryId != null && r.idCategory != _categoryId) return false;
      if (_campusId != null && r.idCampus != _campusId) return false;
      if (q.isEmpty) return true;
      return r.namaBarang.toLowerCase().contains(q) ||
          r.deskripsi.toLowerCase().contains(q) ||
          r.lokasi.toLowerCase().contains(q) ||
          (r.campus?.namaKampus ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Widget _typeChip(String value, String label, Color color) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected
                  ? (value == 'temuan' ? Colors.white : AppColors.slate950)
                  : AppColors.slate400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterDropdown<T>({
    required String hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null ? AppColors.accentAmber : AppColors.cardBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBg,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.slate400),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          hint: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.slate400),
              const SizedBox(width: 6),
              Flexible(
                child: Text(hint,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
              ),
            ],
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        elevation: 0,
        title: const Text('Cari Barang'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama barang, lokasi, atau ciri...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppColors.slate400),
                        onPressed: () => setState(_controller.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  _typeChip('all', 'Semua', AppColors.accentAmberLight),
                  _typeChip('hilang', 'Barang Hilang', AppColors.accentAmber),
                  _typeChip('temuan', 'Barang Temuan', AppColors.accentBlue),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: _filterDropdown<int?>(
                    hint: 'Kategori',
                    icon: Icons.category_outlined,
                    value: _categoryId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Kategori')),
                      ..._categories.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.namaKategori, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filterDropdown<int?>(
                    hint: 'Cabang',
                    icon: Icons.location_city_rounded,
                    value: _campusId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Cabang')),
                      ..._campuses.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(
                              c.namaKampus.replaceAll('UBSI Kampus ', ''),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (v) => setState(() => _campusId = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} barang ditemukan',
                style: const TextStyle(fontSize: 12, color: AppColors.slate400),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentAmber))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.accentAmber,
                    backgroundColor: AppColors.cardBg,
                    child: results.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Icon(Icons.search_off_rounded, size: 56, color: AppColors.slate400),
                              SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Tidak ada barang yang cocok',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: results.length,
                            itemBuilder: (_, i) => ReportCard(report: results[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
