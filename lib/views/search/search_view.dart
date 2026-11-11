import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../models/campus_model.dart';
import '../../models/category_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/supabase_service.dart';
import '../home/widgets/campus_picker_sheet.dart';
import '../home/widgets/report_card.dart';

/// Rentang tanggal kejadian untuk filter Cari.
class DateFilter {
  final String label;
  final DateTime? from;
  final DateTime? to;
  const DateFilter(this.label, {this.from, this.to});

  static const all = DateFilter('Semua Waktu');
  bool get isAll => from == null && to == null;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<DateFilter> presets(DateTime now) {
    final today = _day(now);
    return [
      all,
      DateFilter('Hari ini', from: today, to: today),
      DateFilter('7 hari terakhir', from: today.subtract(const Duration(days: 6)), to: today),
      DateFilter('30 hari terakhir', from: today.subtract(const Duration(days: 29)), to: today),
    ];
  }

  static DateFilter custom(DateTimeRange r) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    String f(DateTime d) => '${d.day} ${m[d.month - 1]}';
    final label = r.start == r.end ? f(r.start) : '${f(r.start)} - ${f(r.end)}';
    return DateFilter(label, from: _day(r.start), to: _day(r.end));
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  static const _pageSize = 20;

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  List<ReportModel> _items = [];
  List<CategoryModel> _categories = [];
  List<CampusModel> _campuses = [];

  int? _categoryId;
  CampusModel? _campus;
  DateFilter _date = DateFilter.all;

  bool _isLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    ReportService.changes.addListener(_reload);
    _scroll.addListener(_onScroll);
    _loadOptions();
    _reload();
  }

  @override
  void dispose() {
    ReportService.changes.removeListener(_reload);
    _debounce?.cancel();
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      ReportService.getCategories(),
      ReportService.getCampuses(),
    ]);
    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<CategoryModel>;
      _campuses = results[1] as List<CampusModel>;
    });
  }

  Future<List<ReportModel>> _fetch(int offset) => ReportService.getReports(
        search: _controller.text.trim(),
        categoryId: _categoryId,
        campusId: _campus?.id,
        dateFrom: _date.from,
        dateTo: _date.to,
        limit: _pageSize,
        offset: offset,
      );

  /// Muat ulang dari halaman pertama. Hasil request lama yang telat datang diabaikan.
  Future<void> _reload() async {
    final id = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final page = await _fetch(0);
    if (!mounted || id != _requestId) return;
    setState(() {
      _items = page;
      _hasMore = page.length == _pageSize;
      _errorMessage = page.isEmpty ? SupabaseService.lastError : null;
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _isLoading) return;
    final id = _requestId;
    setState(() => _loadingMore = true);
    final page = await _fetch(_items.length);
    if (!mounted || id != _requestId) return;
    setState(() {
      _loadingMore = false;
      if (page.isEmpty && SupabaseService.lastError != null) return;
      _items = [..._items, ...page];
      _hasMore = page.length == _pageSize;
    });
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  bool get _hasFilter =>
      _categoryId != null || _campus != null || !_date.isAll || _controller.text.isNotEmpty;

  void _resetFilters() {
    _controller.clear();
    setState(() {
      _categoryId = null;
      _campus = null;
      _date = DateFilter.all;
    });
    _reload();
  }

  Future<void> _pickCampus() async {
    final result = await showCampusPicker(
      context,
      campuses: _campuses,
      selected: _campus,
    );
    if (result == null || !mounted) return;
    setState(() => _campus = result.campus);
    _reload();
  }

  Future<T?> _showOptions<T>({
    required String title,
    required List<(String, T)> options,
    required bool Function(T) isSelected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      builder: (context) {
        final c = FinditColors.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(title, style: AppTypography.titleMedium(c.textPrimary)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final (label, value) in options)
                      ListTile(
                        minTileHeight: 48,
                        title: Text(label, style: AppTypography.bodyMedium(c.textPrimary)),
                        trailing: isSelected(value)
                            ? Icon(Icons.check_rounded, color: c.amberText)
                            : null,
                        selected: isSelected(value),
                        onTap: () => Navigator.pop(context, value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickCategory() async {
    final picked = await _showOptions<({int? id})>(
      title: 'Pilih Kategori',
      options: [
        ('Semua Kategori', (id: null)),
        for (final cat in _categories) (cat.namaCategory, (id: cat.id)),
      ],
      isSelected: (v) => v.id == _categoryId,
    );
    if (picked == null || !mounted) return;
    setState(() => _categoryId = picked.id);
    _reload();
  }

  Future<void> _pickDate() async {
    const customKey = DateFilter('Pilih tanggal...');
    final presets = DateFilter.presets(DateTime.now());
    final picked = await _showOptions<DateFilter>(
      title: 'Tanggal Kejadian',
      options: [
        for (final p in presets) (p.label, p),
        (customKey.label, customKey),
      ],
      isSelected: (v) => v.label == _date.label,
    );
    if (picked == null || !mounted) return;

    if (identical(picked, customKey)) {
      final now = DateTime.now();
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2023),
        lastDate: now,
        initialDateRange: _date.isAll || _date.from == null
            ? null
            : DateTimeRange(start: _date.from!, end: _date.to ?? now),
        helpText: 'Tanggal kejadian',
        saveText: 'Terapkan',
      );
      if (range == null || !mounted) return;
      setState(() => _date = DateFilter.custom(range));
    } else {
      setState(() => _date = picked);
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final categoryLabel = _categoryId == null
        ? 'Semua Kategori'
        : _categories
                .where((k) => k.id == _categoryId)
                .map((k) => k.namaCategory)
                .firstOrNull ??
            'Kategori';
    final campusLabel = _campus == null
        ? 'Semua Cabang'
        : _campus!.namaKampus.replaceAll('UBSI Kampus ', '');

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Semantics(
                header: true,
                child: Text('Cari Barang', style: AppTypography.titleLarge(c.textPrimary)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: TextField(
                controller: _controller,
                style: AppTypography.bodyMedium(c.inputText),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _reload();
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama barang, lokasi, atau ciri...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus kata kunci',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterPill(
                    label: campusLabel,
                    selected: _campus != null,
                    trailingIcon: Icons.keyboard_arrow_down_rounded,
                    onTap: _pickCampus,
                  ),
                  const SizedBox(width: 8),
                  FilterPill(
                    label: categoryLabel,
                    selected: _categoryId != null,
                    trailingIcon: Icons.keyboard_arrow_down_rounded,
                    onTap: _pickCategory,
                  ),
                  const SizedBox(width: 8),
                  FilterPill(
                    label: _date.label,
                    selected: !_date.isAll,
                    trailingIcon: Icons.keyboard_arrow_down_rounded,
                    onTap: _pickDate,
                  ),
                  if (_hasFilter) ...[
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _resetFilters,
                      style: TextButton.styleFrom(foregroundColor: c.amberText),
                      child: Text('Reset', style: AppTypography.label(c.amberText)),
                    ),
                  ],
                ],
              ),
            ),
            if (!_isLoading && _errorMessage == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  _hasMore
                      ? '${_items.length}+ laporan ditemukan'
                      : '${_items.length} laporan ditemukan',
                  style: AppTypography.caption(c.textSecondary),
                ),
              ),
            Expanded(child: _buildResults(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(FinditColors c) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
    }
    if (_errorMessage != null) {
      return Center(
        child: StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Gagal memuat pencarian',
          message: _errorMessage,
          actionLabel: 'Coba Lagi',
          onAction: _reload,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.brandPrimary,
      child: _items.isEmpty
          ? ListView(
              children: [
                StateMessage(
                  icon: Icons.search_off_rounded,
                  title: 'Tidak ada barang yang cocok',
                  message: 'Ubah kata kunci atau reset filter cabang, kategori, dan tanggal.',
                  actionLabel: _hasFilter ? 'Reset Filter' : null,
                  onAction: _hasFilter ? _resetFilters : null,
                ),
              ],
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                if (i == _items.length) {
                  // Daftar yang terlalu pendek untuk di-scroll tetap memuat halaman berikutnya.
                  WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.brandPrimary),
                      ),
                    ),
                  );
                }
                return ReportCard(report: _items[i]);
              },
            ),
    );
  }
}
