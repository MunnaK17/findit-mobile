import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../models/campus_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/supabase_service.dart';
import '../notifications/notification_bell.dart';
import '../reports/create_report_view.dart';
import 'all_reports_view.dart';
import 'widgets/campus_picker_sheet.dart';
import 'widgets/report_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

const _previewLimit = 5;

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();

  List<ReportModel> _allReports = [];
  List<ReportModel> _filteredReports = [];
  List<CampusModel> _campuses = [];

  CampusModel? _selectedCampus;
  String _activeFilter = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ReportService.changes.addListener(_loadAllData);
    _loadAllData();
  }

  @override
  void dispose() {
    ReportService.changes.removeListener(_loadAllData);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final results = await Future.wait([
      ReportService.getCampuses(),
      // Beranda hanya pratinjau; daftar lengkap berpaginasi ada di tab Cari.
      ReportService.getReports(campusId: _selectedCampus?.id, limit: 50),
    ]);

    if (!mounted) return;
    final reports = results[1] as List<ReportModel>;
    setState(() {
      _campuses = results[0] as List<CampusModel>;
      _allReports = reports;
      _errorMessage = reports.isEmpty ? SupabaseService.lastError : null;
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredReports = _allReports.where((rep) {
        if (_selectedCampus != null && rep.idCampus != _selectedCampus!.id) {
          return false;
        }
        final done = rep.status == 'completed';
        if (_activeFilter == 'hilang' && (!rep.isHilang || done)) return false;
        if (_activeFilter == 'temuan' && (!rep.isTemuan || done)) return false;
        if (_activeFilter == 'completed' && !done) return false;
        if (query.isNotEmpty) {
          final haystack = [
            rep.namaBarang,
            rep.deskripsi,
            rep.lokasi,
            rep.campus?.namaKampus ?? '',
          ].join(' ').toLowerCase();
          if (!haystack.contains(query)) return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _pickCampus() async {
    final result = await showCampusPicker(
      context,
      campuses: _campuses,
      selected: _selectedCampus,
    );
    if (result == null || !mounted) return;
    setState(() => _selectedCampus = result.campus);
    _loadAllData();
  }

  void _openCreate(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReportView(
          initialType: type,
          initialCampusId: _selectedCampus?.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final isSearching = _searchController.text.trim().isNotEmpty;
    final visible = isSearching
        ? _filteredReports
        : _filteredReports.take(_previewLimit).toList();

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          color: AppColors.brandPrimary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppColors.space4, AppColors.space5, AppColors.space4, 0),
                sliver: SliverList.list(
                  children: [
                    _buildHeader(c),
                    const SizedBox(height: AppColors.space5),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilters(),
                      textInputAction: TextInputAction.search,
                      style: AppTypography.bodyMedium(c.inputText),
                      decoration: InputDecoration(
                        hintText: 'Cari kunci, KTM, helm, lokasi...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: isSearching
                            ? IconButton(
                                tooltip: 'Hapus pencarian',
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppColors.space4),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            title: 'Lapor Hilang',
                            subtitle: 'Barang saya hilang',
                            icon: Icons.search_rounded,
                            image: 'assets/images/lapor_hilang.jpg',
                            // Warna amber gambar; teks gelap 7.97:1 di atasnya.
                            scrim: const Color(0xFFE2A04F),
                            textColor: AppColors.textPrimaryLight,
                            iconColor: AppColors.statusLostText,
                            onTap: () => _openCreate('hilang'),
                          ),
                        ),
                        const SizedBox(width: AppColors.space3),
                        Expanded(
                          child: _ActionCard(
                            title: 'Lapor Temuan',
                            subtitle: 'Saya temukan barang',
                            icon: Icons.inventory_2_outlined,
                            image: 'assets/images/lapor_temuan.jpg',
                            // Warna biru gambar; teks putih 6.73:1 di atasnya.
                            scrim: const Color(0xFF1F55C0),
                            textColor: Colors.white,
                            iconColor: AppColors.actionBlue,
                            onTap: () => _openCreate('temuan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppColors.space4),
                    FilterPillBar(
                      options: const [
                        ('all', 'Semua'),
                        ('hilang', 'Hilang'),
                        ('temuan', 'Temuan'),
                        ('completed', 'Kembali'),
                      ],
                      selected: _activeFilter,
                      onSelected: (key) {
                        setState(() => _activeFilter = key);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: AppColors.space5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isSearching ? 'Hasil Pencarian' : 'Laporan Terbaru',
                            style: AppTypography.titleMedium(c.textPrimary),
                          ),
                        ),
                        if (!isSearching && _filteredReports.length > _previewLimit)
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AllReportsView(
                                  reports: _filteredReports,
                                  campus: _selectedCampus,
                                ),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: c.amberText,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            child: Text('Lihat semua',
                                style: AppTypography.label(c.amberText)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppColors.space3),
                  ],
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brandPrimary),
                  ),
                )
              else if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: StateMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Gagal memuat laporan',
                    message: _errorMessage,
                    actionLabel: 'Coba Lagi',
                    onAction: _loadAllData,
                  ),
                )
              else if (visible.isEmpty)
                SliverToBoxAdapter(
                  child: StateMessage(
                    icon: Icons.inbox_outlined,
                    title: _selectedCampus != null
                        ? 'Belum ada laporan di ${_selectedCampus!.namaKampus}'
                        : 'Belum ada laporan yang cocok',
                    message:
                        'Buat laporan baru jika kamu kehilangan atau menemukan barang di kampus.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.space4),
                  sliver: SliverList.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppColors.space4),
                    itemBuilder: (_, i) => ReportCard(report: visible[i]),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FinditColors c) {
    final campusName = _selectedCampus?.namaKampus ?? 'Semua Cabang UBSI';
    return Row(
      children: [
        const CampusLogo(size: 48),
        const SizedBox(width: AppColors.space3),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Pilih cabang kampus, saat ini $campusName',
            excludeSemantics: true,
            child: InkWell(
              onTap: _pickCampus,
              borderRadius: BorderRadius.circular(AppColors.radiusSm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, selamat datang',
                        style: AppTypography.caption(c.textSecondary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            campusName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium(c.textPrimary)
                                .copyWith(fontSize: 18),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: c.textPrimary, size: 22),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppColors.space2),
        const NotificationBell(),
      ],
    );
  }
}

/// Kartu aksi Lapor Hilang / Lapor Temuan dengan ilustrasi sebagai latar.
/// Objek ilustrasi ada di sisi kanan; gradasi [scrim] di bawah menjaga
/// kontras teks tetap AA berapa pun potongan gambarnya.
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String image;
  final Color scrim;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    required this.scrim,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: scrim,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 156,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  image,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  cacheWidth: 540,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [scrim, scrim.withValues(alpha: 0.85), scrim.withValues(alpha: 0)],
                      stops: const [0, 0.35, 0.62],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppColors.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: iconColor),
                      ),
                      const Spacer(),
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall(textColor)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(textColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
