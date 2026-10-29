import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/campus_model.dart';
import '../../models/category_model.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
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
  String _activeFilter = 'all'; // 'all' | 'hilang' | 'temuan' | 'completed'
  bool _isLoading = true;

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
    setState(() => _isLoading = true);

    final userFuture = AuthService.getCurrentUser();
    final categoriesFuture = ReportService.getCategories();
    final campusesFuture = ReportService.getCampuses();
    final reportsFuture = ReportService.getReports(
      campusId: _selectedCampus?.id,
    );

    final results = await Future.wait([userFuture, categoriesFuture, campusesFuture, reportsFuture]);

    final user = results[0] as UserModel?;
    final categories = results[1] as List<CategoryModel>;
    final campuses = results[2] as List<CampusModel>;
    final reports = results[3] as List<ReportModel>;

    int lost = 0;
    int found = 0;
    int completed = 0;

    for (var r in reports) {
      if (r.status == 'completed') {
        completed++;
      }
      if (r.isHilang) {
        lost++;
      } else if (r.isTemuan) {
        found++;
      }
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _categories = categories;
        _campuses = campuses;
        _allReports = reports;
        _lostCount = lost;
        _foundCount = found;
        _completedCount = completed;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredReports = _allReports.where((rep) {
        // Filter by Campus
        if (_selectedCampus != null && rep.idCampus != _selectedCampus!.id) {
          return false;
        }

        // Filter by category
        if (_selectedCategoryId != null && rep.idCategory != _selectedCategoryId) {
          return false;
        }

        // Filter by status/type
        if (_activeFilter == 'hilang' && !rep.isHilang) {
          return false;
        }
        if (_activeFilter == 'temuan' && !rep.isTemuan) {
          return false;
        }
        if (_activeFilter == 'completed' && rep.status != 'completed') {
          return false;
        }

        // Filter by search query
        if (query.isNotEmpty) {
          final title = rep.namaBarang.toLowerCase();
          final desc = rep.deskripsi.toLowerCase();
          final loc = rep.lokasi.toLowerCase();
          final campusName = (rep.campus?.namaKampus ?? '').toLowerCase();
          if (!title.contains(query) && !desc.contains(query) && !loc.contains(query) && !campusName.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _setFilter(String filter) {
    setState(() {
      if (_activeFilter == filter) {
        _activeFilter = 'all'; // toggle off back to all
      } else {
        _activeFilter = filter;
      }
      _applyFilters();
    });
  }

  void _showCampusSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pilih Cabang Kampus UBSI",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (_selectedCampus != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCampus = null;
                                _applyFilters();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Semua Cabang",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Pilih cabang kampus untuk memfilter barang hilang & temuan.",
                      style: TextStyle(fontSize: 12, color: AppColors.slate400),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _campuses.length + 1,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedCampus == null;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? AppColors.accentAmber : AppColors.cardBgLight,
                                child: Icon(
                                  Icons.domain_rounded,
                                  color: isSelected ? AppColors.slate950 : Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                "Semua Cabang UBSI",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: const Text(
                                "Tampilkan seluruh laporan di semua cabang kampus",
                                style: TextStyle(color: AppColors.slate400, fontSize: 11),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.accentAmber)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedCampus = null;
                                  _applyFilters();
                                });
                                Navigator.pop(context);
                              },
                            );
                          }

                          final campus = _campuses[index - 1];
                          final isSelected = _selectedCampus?.id == campus.id;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? AppColors.accentAmber : AppColors.cardBgLight,
                              child: Text(
                                campus.kodeKampus,
                                style: TextStyle(
                                  color: isSelected ? AppColors.slate950 : AppColors.bsiTeal,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            title: Text(
                              campus.namaKampus,
                              style: TextStyle(
                                color: isSelected ? AppColors.accentAmber : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "${campus.kota} • ${campus.alamat ?? ''}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.accentAmber)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedCampus = campus;
                                _applyFilters();
                              });
                              Navigator.pop(context);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser != null && _currentUser!.name.isNotEmpty
        ? _currentUser!.name.split(' ').first
        : 'User';

    return Scaffold(
      backgroundColor: AppColors.appDark,
      body: Stack(
        children: [
          // Radial Ambient Glows matching CSS custom-decorations
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF223A66).withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentAmber.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.accentAmber,
              backgroundColor: AppColors.cardBg,
              child: CustomScrollView(
                slivers: [
                  // App Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Brand Wordmark Find.It
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: "Find.",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: "It",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accentAmberLight,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Interactive Affiliate Pill: Campus Branch Selector
                          GestureDetector(
                            onTap: _showCampusSelector,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedCampus != null ? AppColors.accentAmber : AppColors.cardBorder,
                                  width: _selectedCampus != null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppColors.bsiTeal,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _selectedCampus?.kodeKampus ?? "BSI",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 120),
                                    child: Text(
                                      _selectedCampus?.namaKampus.replaceAll('UBSI Kampus ', '') ?? "SEMUA CABANG",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _selectedCampus != null ? AppColors.accentAmber : AppColors.slate300,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_drop_down, color: AppColors.slate400, size: 16),
                                ],
                              ),
                            ),
                          ),

                          // Notification Bell
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.accentAmberLight,
                                size: 20,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Belum ada notifikasi baru"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Greeting Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Halo, $userName!",
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (_currentUser != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _currentUser!.isStaff
                                        ? AppColors.bsiTeal.withValues(alpha: 0.15)
                                        : AppColors.accentAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _currentUser!.isStaff ? AppColors.bsiTeal : AppColors.accentAmber,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    _currentUser!.roleLabel,
                                    style: TextStyle(
                                      color: _currentUser!.isStaff ? AppColors.bsiTeal : AppColors.accentAmber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCampus != null
                                ? "Menampilkan barang di ${_selectedCampus!.namaKampus}."
                                : "Selamat datang kembali di platform Lost & Found seluruh cabang UBSI.",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate400,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: (_) => _applyFilters(),
                          decoration: InputDecoration(
                            hintText: "Cari barang hilang atau temuan...",
                            hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.slate400,
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.slate400, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyFilters();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Statistics Action Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top 2 cards: Barang Hilang & Barang Temuan
                          Row(
                            children: [
                              // Card: Barang Hilang (Amber Gradient)
                              Expanded(
                                child: InkWell(
                                  onTap: () => _setFilter('hilang'),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    height: 152,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.accentAmberLight,
                                          AppColors.accentAmber,
                                          AppColors.accentAmberDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: _activeFilter == 'hilang'
                                          ? Border.all(color: Colors.white, width: 2)
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accentAmber.withValues(alpha: 0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: AppColors.slate950,
                                            size: 19,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$_lostCount",
                                              style: const TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.slate950,
                                                height: 1.0,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              "BARANG HILANG",
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.slate900,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Card: Barang Temuan (Navy Blue Translucent)
                              Expanded(
                                child: InkWell(
                                  onTap: () => _setFilter('temuan'),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    height: 152,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBgNavy,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: _activeFilter == 'temuan'
                                            ? AppColors.accentBlue
                                            : AppColors.cardBorder,
                                        width: _activeFilter == 'temuan' ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentBlue.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.accentBlue.withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.search_rounded,
                                            color: AppColors.accentBlue,
                                            size: 18,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$_foundCount",
                                              style: const TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                height: 1.0,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              "BARANG TEMUAN",
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.slate400,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Full-width Bottom Card: Berhasil Kembali ke Pemilik
                          InkWell(
                            onTap: () => _setFilter('completed'),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 124),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgNavy,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _activeFilter == 'completed'
                                      ? AppColors.accentEmerald
                                      : AppColors.cardBorder,
                                  width: _activeFilter == 'completed' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentEmerald.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.accentEmerald.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppColors.accentEmerald,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$_completedCount",
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.0,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "BERHASIL KEMBALI KE PEMILIK",
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.slate400,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Category Filter Chips / Discovery Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Kategori Barang",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (_selectedCategoryId != null || _activeFilter != 'all' || _selectedCampus != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                  _selectedCampus = null;
                                  _activeFilter = 'all';
                                  _applyFilters();
                                });
                              },
                              child: const Text(
                                "Reset Semua Filter",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentAmber,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Horizontal Category Pills
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
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
                                label: const Text("Semua Kategori"),
                                selected: isAll,
                                onSelected: (_) {
                                  setState(() => _selectedCategoryId = null);
                                  _applyFilters();
                                },
                                backgroundColor: AppColors.cardBgLight,
                                selectedColor: AppColors.accentAmber,
                                checkmarkColor: AppColors.slate950,
                                labelStyle: TextStyle(
                                  color: isAll ? AppColors.slate950 : AppColors.slate300,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isAll ? AppColors.accentAmber : AppColors.cardBorder,
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
                              backgroundColor: AppColors.cardBgLight,
                              selectedColor: AppColors.accentAmber,
                              checkmarkColor: AppColors.slate950,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.slate950 : AppColors.slate300,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? AppColors.accentAmber : AppColors.cardBorder,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Section Title: Laporan Terkini
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _activeFilter == 'hilang'
                                    ? "Daftar Barang Hilang"
                                    : _activeFilter == 'temuan'
                                        ? "Daftar Barang Temuan"
                                        : _activeFilter == 'completed'
                                            ? "Barang Berhasil Kembali"
                                            : "Laporan Terkini",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (_selectedCampus != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _selectedCampus!.kodeKampus,
                                    style: const TextStyle(
                                      color: AppColors.accentAmber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            "${_filteredReports.length} barang",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reports List / Empty State
                  _isLoading
                      ? const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.accentAmber),
                          ),
                        )
                      : _filteredReports.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBgLight,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColors.cardBorder),
                                        ),
                                        child: const Icon(
                                          Icons.inbox_outlined,
                                          size: 36,
                                          color: AppColors.slate400,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _selectedCampus != null
                                            ? "Belum ada laporan di ${_selectedCampus!.namaKampus}."
                                            : "Belum ada laporan barang.",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "Jadilah yang pertama melaporkan kehilangan atau temuan barang.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.slate400,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateReportView(
                                                initialCampusId: _selectedCampus?.id,
                                              ),
                                            ),
                                          ).then((_) => _loadAllData());
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text("Buat Laporan Baru"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => ReportCard(
                                    report: _filteredReports[index],
                                  ),
                                  childCount: _filteredReports.length,
                                ),
                              ),
                            ),
                ],
              ),
            ),
          ),

          // Floating Chatbot Mascot Button (Bottom Right)
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotView()),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentAmber,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: AppColors.slate950,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
