import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/campus_model.dart';
import '../../models/category_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import 'widgets/report_card.dart';

class AllReportsView extends StatefulWidget {
  final List<ReportModel> reports;

  /// Cabang yang sudah membatasi [reports]. Bila diisi, filter cabang tidak bisa diganti.
  final CampusModel? campus;

  const AllReportsView({super.key, required this.reports, this.campus});

  @override
  State<AllReportsView> createState() => _AllReportsViewState();
}

class _AllReportsViewState extends State<AllReportsView> {
  List<CampusModel> _campuses = [];
  List<CategoryModel> _categories = [];
  int? _campusId;
  String? _jenis;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      ReportService.getCampuses(),
      ReportService.getCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _campuses = results[0] as List<CampusModel>;
      _categories = results[1] as List<CategoryModel>;
    });
  }

  List<ReportModel> get _filtered => widget.reports.where((r) {
        if (_campusId != null && r.idCampus != _campusId) return false;
        if (_jenis != null && r.jenisLaporan != _jenis) return false;
        if (_categoryId != null && r.idCategory != _categoryId) return false;
        return true;
      }).toList();

  bool get _hasFilter => _campusId != null || _jenis != null || _categoryId != null;

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final reports = _filtered;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        title: Text(
          'Aktivitas Laporan Terkini',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: widget.campus != null
                      ? InputDecorator(
                          decoration: const InputDecoration(labelText: 'Cabang', isDense: true),
                          child: Text(
                            widget.campus!.namaKampus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.textPrimary),
                          ),
                        )
                      : DropdownButtonFormField<int?>(
                          isExpanded: true,
                          value: _campusId,
                          decoration: const InputDecoration(labelText: 'Cabang', isDense: true),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Semua Cabang')),
                            ..._campuses.map((k) => DropdownMenuItem<int?>(
                                  value: k.id,
                                  child: Text(k.namaKampus, overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) => setState(() => _campusId = v),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: _jenis,
                    decoration: const InputDecoration(labelText: 'Jenis', isDense: true),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('Semua Jenis')),
                      DropdownMenuItem<String?>(value: 'hilang', child: Text('Hilang')),
                      DropdownMenuItem<String?>(value: 'temuan', child: Text('Temuan')),
                    ],
                    onChanged: (v) => setState(() => _jenis = v),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DropdownButtonFormField<int?>(
              isExpanded: true,
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategori', isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Semua Kategori')),
                ..._categories.map((k) => DropdownMenuItem<int?>(
                      value: k.id,
                      child: Text(k.namaCategory, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${reports.length} laporan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted),
                  ),
                ),
                if (_hasFilter)
                  TextButton(
                    onPressed: () => setState(() {
                      _campusId = null;
                      _jenis = null;
                      _categoryId = null;
                    }),
                    style: TextButton.styleFrom(foregroundColor: c.amberText),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Text(
                      'Tidak ada laporan yang sesuai filter.',
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => ReportCard(report: reports[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
