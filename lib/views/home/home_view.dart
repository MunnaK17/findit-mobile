import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../main.dart';
import '../../models/campus_model.dart';
import '../../models/category_model.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/supabase_service.dart';
import '../chat/chatbot_view.dart';
import '../reports/create_report_view.dart';
import 'widgets/report_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();

  UserModel? _currentUser;
  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  List<CategoryModel> _categories = [];
  List<CampusModel> _campuses = [];

  CampusModel? _selectedCampus;
  int? _selectedCategoryId;
  String _activeFilter = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  int _lostCount = 0;
  int _foundCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final results = await Future.wait([
      AuthService.getCurrentUser(),
      ReportService.getCategories(),
      ReportService.getCampuses(),
      ReportService.getReports(campusId: _selectedCampus?.id),
    ]);

    final user = results[0] as UserModel?;
    final categories = results[1] as List<CategoryModel>;
    final campuses = results[2] as List<CampusModel>;
    final reports = results[3] as List<ReportModel>;

    if (mounted) {
      setState(() {
        _currentUser = user;
        _categories = categories;
        _campuses = campuses;
        _allReports = reports;
        _errorMessage = reports.isEmpty ? SupabaseService.lastError : null;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredReports = _allReports.where((rep) {
        if (_selectedCampus != null && rep.idCampus != _selectedCampus!.id) {
          return false;
        }
        if (_selectedCategoryId != null && rep.idCategory != _selectedCategoryId) {
          return false;
        }
        if (_activeFilter == 'hilang' && (!rep.isHilang || rep.status == 'completed')) {
          return false;
        }
        if (_activeFilter == 'temuan' && (!rep.isTemuan || rep.status == 'completed')) {
          return false;
        }
        if (_activeFilter == 'completed' && rep.status != 'completed') {
          return false;
        }
        if (query.isNotEmpty) {
          final title = rep.namaBarang.toLowerCase();
          final desc = rep.deskripsi.toLowerCase();
          final loc = rep.lokasi.toLowerCase();
          final campusName = (rep.campus?.namaKampus ?? '').toLowerCase();
          if (!title.contains(query) &&
              !desc.contains(query) &&
              !loc.contains(query) &&
              !campusName.contains(query)) {
            return false;
          }
        }
        return true;
      }).toList();

      int lost = 0;
      int found = 0;
      int completed = 0;

      for (final r in _allReports) {
        if (_selectedCampus != null && r.idCampus != _selectedCampus!.id) {
          continue;
        }
        if (r.status == 'completed') {
          completed++;
        } else if (r.isHilang) {
          lost++;
        } else if (r.isTemuan) {
          found++;
        }
      }

      _lostCount = lost;
      _foundCount = found;
      _completedCount = completed;
    });
  }

  void _selectCampus(CampusModel? campus) {
    setState(() {
      _selectedCampus = campus;
      _applyFilters();
    });
    if (mounted) {
      final c = FinditColors.of(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            campus != null
                ? 'Menampilkan laporan di ${campus.namaKampus}'
                : 'Menampilkan laporan di Semua Cabang UBSI',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: c.snackbarBg,
        ),
      );
    }
  }

  void _setFilter(String filter) {
    setState(() {
      _activeFilter = _activeFilter == filter ? 'all' : filter;
      _applyFilters();
    });
  }

  void _showCampusSelector() {
    final c = FinditColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
      backgroundColor: c.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cs = FinditColors.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Pilih Cabang Kampus UBSI',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: cs.textPrimary,
                        ),
                      ),
                    ),
                    if (_selectedCampus != null)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _selectCampus(null);
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          foregroundColor: cs.amberText,
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Filter laporan berdasarkan lokasi cabang kampus UBSI',
                  style: TextStyle(fontSize: 12, color: cs.textMuted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _campuses.length + 1,
                    separatorBuilder: (_, __) => Divider(color: cs.cardBorderLight, height: 1),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = _selectedCampus == null;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelected ? AppColors.accentAmber : cs.cardBgLight,
                            child: Icon(
                              Icons.apartment_rounded,
                              size: 18,
                              color: isSelected ? AppColors.slate950 : cs.slate300Adaptive,
                            ),
                          ),
                          title: Text(
                            'Semua Cabang UBSI',
                            style: TextStyle(
                              color: isSelected ? cs.amberText : cs.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Tampilkan seluruh laporan dari 11 cabang',
                            style: TextStyle(color: cs.textMuted, fontSize: 11.5),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: cs.amberText)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            _selectCampus(null);
                          },
                        );
                      }

                      final campus = _campuses[index - 1];
                      final isSelected = _selectedCampus?.id == campus.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected ? AppColors.accentAmber : cs.tealBg,
                          child: Text(
                            campus.kodeKampus,
                            style: TextStyle(
                              color: isSelected ? AppColors.slate950 : cs.tealText,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        title: Text(
                          campus.namaKampus,
                          style: TextStyle(
                            color: isSelected ? cs.amberText : cs.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${campus.kota} • ${campus.alamat ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.textMuted, fontSize: 11.5),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: cs.amberText)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _selectCampus(campus);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser != null && _currentUser!.name.isNotEmpty
        ? _currentUser!.name.split(' ').first
        : 'Sobat BSI';
    final c = FinditColors.of(context);

    final isFiltering = _activeFilter != 'all' ||
        _selectedCategoryId != null ||
        _searchController.text.trim().isNotEmpty;

    final urgentLostReports = _allReports
        .where((r) =>
            r.isHilang &&
            r.status != 'completed' &&
            (_selectedCampus == null || r.idCampus == _selectedCampus!.id))
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          color: AppColors.accentAmber,
          backgroundColor: c.cardBg,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildMobileDashboardHeader(userName, c),
              ),
              if (!isFiltering && urgentLostReports.isNotEmpty && !_isLoading)
                SliverToBoxAdapter(
                  child: _buildUrgentLostCarousel(urgentLostReports, c),
                ),
              SliverToBoxAdapter(
                child: _buildFeedFilterHeader(c, isFiltering),
              ),
              if (_isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.accentAmber),
                          const SizedBox(height: 12),
                          Text(
                            'Memuat laporan kampus...',
                            style: TextStyle(color: c.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: _buildErrorCard(c),
                )
              else if (_filteredReports.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyCard(c),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList.builder(
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) => ReportCard(
                      report: _filteredReports[index],
                      isLight: !c.isDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDashboardHeader(String userName, FinditColors c) {
    final totalActive = _lostCount + _foundCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: c.heroSectionBg,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.mintBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.mintText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Halo, $userName',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        if (_currentUser != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _currentUser!.isStaff ? c.tealBg : c.amberBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentUser!.roleLabel,
                              style: TextStyle(
                                color: _currentUser!.isStaff ? c.tealText : c.amberText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      button: true,
                      label: 'Pilih Cabang Kampus, saat ini ${_selectedCampus?.namaKampus ?? "Semua Cabang UBSI"}',
                      child: InkWell(
                        onTap: _showCampusSelector,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded, size: 13, color: c.tealText),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _selectedCampus?.namaKampus ?? 'Semua Cabang UBSI',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: c.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.actionBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Tanya FindBot',
                  icon: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatbotView()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.cardBorder),
                ),
                child: IconButton(
                  tooltip: c.isDark ? 'Mode Terang' : 'Mode Gelap',
                  icon: Icon(
                    c.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: c.amberText,
                    size: 20,
                  ),
                  onPressed: () => context.themeProvider.toggleTheme(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: c.inputText, fontSize: 13.5),
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Cari kunci, KTM, helm, atau lokasi kampus...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: Icon(Icons.search_rounded, color: c.inputHint, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: Icon(Icons.clear_rounded, color: c.inputHint, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Buat laporan barang hilang',
                  child: Material(
                    color: AppColors.accentAmber,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateReportView(
                              initialType: 'hilang',
                              initialCampusId: _selectedCampus?.id,
                            ),
                          ),
                        ).then((_) => _loadAllData());
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 46),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.slate950),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Lapor Hilang',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate950,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Buat laporan barang temuan',
                  child: Material(
                    color: AppColors.bsiTeal,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateReportView(
                              initialType: 'temuan',
                              initialCampusId: _selectedCampus?.id,
                            ),
                          ),
                        ).then((_) => _loadAllData());
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 46),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_task_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Lapor Temuan',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatFilterPill(
                c: c,
                filterKey: 'all',
                label: 'Semua',
                count: totalActive,
                activeColor: c.textPrimary,
                activeBg: c.cardBgLight,
              ),
              const SizedBox(width: 6),
              _buildStatFilterPill(
                c: c,
                filterKey: 'hilang',
                label: 'Hilang',
                count: _lostCount,
                activeColor: c.amberText,
                activeBg: c.amberBg,
              ),
              const SizedBox(width: 6),
              _buildStatFilterPill(
                c: c,
                filterKey: 'temuan',
                label: 'Temuan',
                count: _foundCount,
                activeColor: c.tealText,
                activeBg: c.tealBg,
              ),
              const SizedBox(width: 6),
              _buildStatFilterPill(
                c: c,
                filterKey: 'completed',
                label: 'Kembali',
                count: _completedCount,
                activeColor: c.successText,
                activeBg: c.successBg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatFilterPill({
    required FinditColors c,
    required String filterKey,
    required String label,
    required int count,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isSelected = _activeFilter == filterKey;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Filter $label, $count laporan',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _activeFilter = filterKey;
              _applyFilters();
            });
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : c.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : c.statCardInactiveBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? activeColor : c.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? activeColor : c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentLostCarousel(List<ReportModel> urgentReports, FinditColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.priority_high_rounded, size: 16, color: c.amberText),
                    const SizedBox(width: 6),
                    Text(
                      'Dicari Segera (Kehilangan Terbaru)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _setFilter('hilang'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: c.amberText,
                  ),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 268,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: urgentReports.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => ReportBoxCard(
                report: urgentReports[index],
                isLight: !c.isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedFilterHeader(FinditColors c, bool isFiltering) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isAll = _selectedCategoryId == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Semua Kategori'),
                      selected: isAll,
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = null);
                        _applyFilters();
                      },
                      backgroundColor: c.chipBg,
                      selectedColor: AppColors.accentAmber,
                      checkmarkColor: AppColors.slate950,
                      labelStyle: TextStyle(
                        color: isAll ? AppColors.slate950 : c.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isAll ? AppColors.accentAmber : c.chipBorder,
                        ),
                      ),
                    ),
                  );
                }

                final cat = _categories[index - 1];
                final isSelected = _selectedCategoryId == cat.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.namaCategory),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryId = isSelected ? null : cat.id;
                      });
                      _applyFilters();
                    },
                    backgroundColor: c.chipBg,
                    selectedColor: AppColors.accentAmber,
                    checkmarkColor: AppColors.slate950,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.slate950 : c.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentAmber : c.chipBorder,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _activeFilter == 'hilang'
                      ? 'Daftar Barang Hilang'
                      : _activeFilter == 'temuan'
                          ? 'Daftar Barang Temuan'
                          : _activeFilter == 'completed'
                              ? 'Barang Berhasil Kembali'
                              : 'Aktivitas Laporan Terkini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (isFiltering)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategoryId = null;
                            _activeFilter = 'all';
                            _searchController.clear();
                            _applyFilters();
                          });
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: c.amberText,
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    Text(
                      '${_filteredReports.length} laporan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(FinditColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.dangerText),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: c.dangerText),
          const SizedBox(height: 12),
          Text(
            'Gagal Memuat Laporan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(FinditColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.cardBgLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.inbox_outlined, size: 28, color: c.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedCampus != null
                ? 'Belum ada laporan di ${_selectedCampus!.namaKampus}.'
                : 'Belum ada laporan yang cocok.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buat laporan baru jika Anda kehilangan atau menemukan barang di area kampus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
