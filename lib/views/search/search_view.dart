import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/campus_model.dart';
import '../../models/category_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/supabase_service.dart';
import '../home/widgets/report_card.dart';

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

  String _type = 'all';
  int? _categoryId;
  int? _campusId;
  bool _isLoading = true;
  String? _errorMessage;

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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
      if (_all.isEmpty && SupabaseService.lastError != null) {
        _errorMessage = SupabaseService.lastError;
      }
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

  Widget _typeChip(FinditColors c, String value, String label, Color color) {
    final selected = _type == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Filter $label',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _type = value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: selected
                    ? (value == 'temuan' ? Colors.white : AppColors.slate950)
                    : c.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterDropdown<T>({
    required FinditColors c,
    required String hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null ? c.amberText : c.cardBorder,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: c.sheetBg,
          icon: Icon(Icons.arrow_drop_down, color: c.textMuted),
          style: TextStyle(color: c.textPrimary, fontSize: 12),
          hint: Row(
            children: [
              Icon(icon, size: 16, color: c.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textMuted, fontSize: 12),
                ),
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
    final c = FinditColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        title: const Text('Cari Barang'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Semantics(
              label: 'Kolom pencarian nama barang, lokasi, atau ciri',
              child: TextField(
                controller: _controller,
                style: TextStyle(color: c.inputText, fontSize: 14),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari nama barang, lokasi, atau ciri...',
                  prefixIcon: Icon(Icons.search_rounded, color: c.inputHint),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus kata kunci',
                          icon: Icon(Icons.clear, size: 18, color: c.inputHint),
                          onPressed: () => setState(_controller.clear),
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.cardBorder),
              ),
              child: Row(
                children: [
                  _typeChip(c, 'all', 'Semua', AppColors.accentAmberLight),
                  _typeChip(c, 'hilang', 'Barang Hilang', AppColors.accentAmber),
                  _typeChip(c, 'temuan', 'Barang Temuan', AppColors.bsiTeal),
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
                    c: c,
                    hint: 'Kategori',
                    icon: Icons.category_outlined,
                    value: _categoryId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Kategori')),
                      ..._categories.map(
                        (cat) => DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(cat.namaKategori, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _filterDropdown<int?>(
                    c: c,
                    hint: 'Cabang',
                    icon: Icons.location_city_rounded,
                    value: _campusId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua Cabang')),
                      ..._campuses.map(
                        (camp) => DropdownMenuItem<int?>(
                          value: camp.id,
                          child: Text(
                            camp.namaKampus.replaceAll('UBSI Kampus ', ''),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
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
                style: TextStyle(fontSize: 12, color: c.textMuted),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.accentAmber),
                        const SizedBox(height: 12),
                        Text(
                          'Memuat daftar laporan...',
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 48, color: c.dangerText),
                              const SizedBox(height: 12),
                              Text(
                                'Gagal Memuat Pencarian',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: c.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accentAmber,
                        backgroundColor: c.cardBg,
                        child: results.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                children: [
                                  const SizedBox(height: 60),
                                  Icon(Icons.search_off_rounded, size: 52, color: c.textMuted),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'Tidak Ada Barang yang Cocok',
                                      style: TextStyle(
                                        color: c.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Center(
                                    child: Text(
                                      'Ubah kata kunci atau reset filter kategori dan cabang untuk melihat seluruh laporan.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.4),
                                    ),
                                  ),
                                  if (_type != 'all' || _categoryId != null || _campusId != null || _controller.text.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Center(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _controller.clear();
                                            _type = 'all';
                                            _categoryId = null;
                                            _campusId = null;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: c.cardBorder),
                                          foregroundColor: c.textPrimary,
                                        ),
                                        child: const Text('Reset Semua Filter'),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                                itemCount: results.length,
                                itemBuilder: (_, i) => ReportCard(
                                  report: results[i],
                                  isLight: !c.isDark,
                                ),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
