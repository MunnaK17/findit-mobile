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

  // Track expanded FAQ index
  int? _expandedFaqIndex;

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

      // Recalculate stats for the selected campus
      int lost = 0;
      int found = 0;
      int completed = 0;

      for (var r in _allReports) {
        if (_selectedCampus != null && r.idCampus != _selectedCampus!.id) {
          continue;
        }
        if (r.status == 'completed') {
          completed++;
        }
        if (r.isHilang) {
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            campus != null
                ? "Menampilkan barang di ${campus.namaKampus}"
                : "Menampilkan barang di Semua Cabang UBSI",
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.cardBgLight,
        ),
      );
    }
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
                              Navigator.pop(context);
                              _selectCampus(null);
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
                      "Pilih salah satu dari 11 cabang kampus UBSI",
                      style: TextStyle(fontSize: 12, color: AppColors.slate400),
                    ),
                    const SizedBox(height: 14),

                    // List of 11 Campuses
                    Expanded(
                      child: ListView.separated(
                        itemCount: _campuses.length + 1,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorderLight, height: 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isSelected = _selectedCampus == null;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected ? AppColors.accentAmber : AppColors.cardBgLight,
                                child: Icon(
                                  Icons.apartment_rounded,
                                  size: 18,
                                  color: isSelected ? AppColors.slate950 : AppColors.slate300,
                                ),
                              ),
                              title: Text(
                                "Semua Cabang UBSI",
                                style: TextStyle(
                                  color: isSelected ? AppColors.accentAmber : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: const Text(
                                "Tampilkan seluruh laporan di 11 kampus",
                                style: TextStyle(color: AppColors.slate400, fontSize: 11),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppColors.accentAmber)
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: CircleAvatar(
                              radius: 18,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser != null && _currentUser!.name.isNotEmpty
        ? _currentUser!.name.split(' ').first
        : 'Sobat BSI';

    return Scaffold(
      backgroundColor: AppColors.appDark, // Base Dark Navy
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.accentAmber,
              backgroundColor: AppColors.cardBg,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ==========================================
                    // 1. SECTION 1: HERO SECTION (BIRU NAVY)
                    // ==========================================
                    _buildHeroSection(userName),

                    // ==========================================
                    // 2. SECTION 2: FEED LAPORAN (PUTIH / LIGHT)
                    // ==========================================
                    _buildWhiteFeedSection(),

                    // ==========================================
                    // 3. SECTION 3: KISAH SUKSES (BIRU NAVY)
                    // ==========================================
                    _buildNavyCommunitySection(),

                    // ==========================================
                    // 4. SECTION 4: ALUR & PANDUAN (PUTIH / LIGHT)
                    // ==========================================
                    _buildWhiteGuideSection(),

                    // Bottom Spacer for BottomNavigationBar & Chatbot FAB
                    const SizedBox(height: 96),
                  ],
                ),
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

  // =========================================================================
  // SECTION 1: HERO SECTION (BIRU NAVY)
  // =========================================================================
  Widget _buildHeroSection(String userName) {
    return Container(
      color: AppColors.appDark,
      child: Stack(
        children: [
          // Ambient Radial Glows (Amber & Blue)
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentAmber.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Brand Find.It, Campus Selector Pill, Notification Bell
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Find.",
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: "It",
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accentAmberLight,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Campus Selector Pill
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showCampusSelector,
                        borderRadius: BorderRadius.circular(20),
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
                                constraints: const BoxConstraints(maxWidth: 110),
                                child: Text(
                                  _selectedCampus?.namaKampus.replaceAll('UBSI Kampus ', '') ?? "SEMUA CABANG",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _selectedCampus != null ? AppColors.accentAmber : AppColors.slate300,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, color: AppColors.slate400, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Notification Icon
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

                const SizedBox(height: 18),

                // Greeting & Hero Title (matching web "Temukan Barangmu yang Hilang")
                Row(
                  children: [
                    Text(
                      "Halo, $userName!",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (_currentUser != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _currentUser!.isStaff
                              ? AppColors.bsiTeal.withValues(alpha: 0.2)
                              : AppColors.accentAmber.withValues(alpha: 0.2),
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
                const SizedBox(height: 6),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(text: "Temukan Barangmu yang "),
                      TextSpan(
                        text: "Hilang",
                        style: TextStyle(color: AppColors.accentAmberLight),
                      ),
                      TextSpan(text: " & Pulihkan Kepercayaan"),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCampus != null
                      ? "Menampilkan laporan di ${_selectedCampus!.namaKampus}."
                      : "Platform Lost & Found terpadu seluruh 11 cabang UBSI.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate400,
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar (Navy Input)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBgLight.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: "Cari nama barang, ciri-ciri, atau lokasi...",
                      hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 12.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.slate400, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Action Buttons (like web hero: Temuan, Hilang, + Buat Laporan)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setFilter('temuan'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _activeFilter == 'temuan'
                              ? AppColors.bsiTeal.withValues(alpha: 0.25)
                              : AppColors.cardBgLight.withValues(alpha: 0.6),
                          side: BorderSide(
                            color: _activeFilter == 'temuan' ? AppColors.bsiTeal : AppColors.cardBorder,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          "Barang Temuan",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _activeFilter == 'temuan' ? AppColors.accentEmerald : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _setFilter('hilang'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _activeFilter == 'hilang'
                              ? AppColors.accentAmber.withValues(alpha: 0.25)
                              : AppColors.cardBgLight.withValues(alpha: 0.6),
                          side: BorderSide(
                            color: _activeFilter == 'hilang' ? AppColors.accentAmber : AppColors.cardBorder,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          "Barang Hilang",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _activeFilter == 'hilang' ? AppColors.accentAmber : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentAmber,
                        foregroundColor: AppColors.slate950,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Lapor",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Statistics Action Cards (matching web hero layout)
                Row(
                  children: [
                    // Card 1: Barang Hilang (Amber Gradient)
                    Expanded(
                      child: InkWell(
                        onTap: () => _setFilter('hilang'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 136,
                          padding: const EdgeInsets.all(14),
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
                            borderRadius: BorderRadius.circular(20),
                            border: _activeFilter == 'hilang'
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentAmber.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.slate950,
                                  size: 16,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$_lostCount",
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.slate950,
                                      height: 1.0,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "BARANG HILANG",
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Card 2: Barang Temuan (Navy Blue Translucent)
                    Expanded(
                      child: InkWell(
                        onTap: () => _setFilter('temuan'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 136,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgNavy,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _activeFilter == 'temuan' ? AppColors.accentBlue : AppColors.cardBorder,
                              width: _activeFilter == 'temuan' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.accentBlue,
                                  size: 16,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$_foundCount",
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.0,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    "BARANG TEMUAN",
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate400,
                                      letterSpacing: 0.6,
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

                const SizedBox(height: 12),

                // Card 3: Berhasil Kembali ke Pemilik
                InkWell(
                  onTap: () => _setFilter('completed'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgNavy,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _activeFilter == 'completed' ? AppColors.accentEmerald : AppColors.cardBorder,
                        width: _activeFilter == 'completed' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.accentEmerald.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accentEmerald.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.accentEmerald,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$_completedCount",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "BERHASIL KEMBALI KE PEMILIK",
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Avatar stack preview (like web)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            "RA • SW • +${_completedCount > 3 ? _completedCount : 3}",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 2: FEED LAPORAN (PUTIH / LIGHT)
  // =========================================================================
  Widget _buildWhiteFeedSection() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightBg, // Clean Crisp White Background (#F8FAFC)
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sheet Top Drag / Indicator Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Category Chips Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Kategori Barang",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
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
                      "Reset Filter",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentAmberDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Horizontal Category Pills (Light Theme)
          SizedBox(
            height: 36,
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
                      label: const Text("Semua"),
                      selected: isAll,
                      onSelected: (_) {
                        setState(() => _selectedCategoryId = null);
                        _applyFilters();
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.accentAmber,
                      checkmarkColor: AppColors.slate950,
                      labelStyle: TextStyle(
                        color: isAll ? AppColors.slate950 : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isAll ? AppColors.accentAmber : const Color(0xFFE2E8F0),
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
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.accentAmber,
                    checkmarkColor: AppColors.slate950,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.slate950 : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppColors.accentAmber : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 22),

          // Section Title: Laporan Terkini (matching web headline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeFilter == 'hilang'
                            ? "Barang Hilang Terbaru"
                            : _activeFilter == 'temuan'
                                ? "Barang Temuan Terbaru"
                                : _activeFilter == 'completed'
                                    ? "Barang Berhasil Kembali"
                                    : "Barang Temuan & Hilang Terbaru",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.lightTextPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Barang yang baru dilaporkan di lingkungan kampus",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    "${_filteredReports.length} barang",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Horizontal Box Cards Carousel (Clean Light Cards)
          _isLoading
              ? const SizedBox(
                  height: 270,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accentAmber),
                  ),
                )
              : _filteredReports.isEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.inbox_outlined,
                              size: 32,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectedCampus != null
                                ? "Belum ada laporan di ${_selectedCampus!.namaKampus}."
                                : "Belum ada laporan barang.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Jadilah yang pertama melaporkan kehilangan atau temuan barang.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Buat Laporan Baru"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentAmber,
                              foregroundColor: AppColors.slate950,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredReports.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => ReportBoxCard(
                          report: _filteredReports[index],
                          isLight: true, // Clean White Card on Light Background!
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 3: KISAH SUKSES KOMUNITAS (BIRU NAVY)
  // =========================================================================
  Widget _buildNavyCommunitySection() {
    final stories = [
      {
        'initials': 'RA',
        'name': 'Rizky A.',
        'role': 'Mahasiswa Sistem Informasi',
        'rating': 5,
        'story': 'Kunci motor saya jatuh di area parkiran. Berkat Find.It, hanya butuh 2 jam sampai seseorang melapor dan mengembalikannya.',
      },
      {
        'initials': 'SW',
        'name': 'Siska W.',
        'role': 'Mahasiswa Manajemen',
        'rating': 5,
        'story': 'iPad saya tertinggal di mushola kampus. Sempat pasrah, tapi ternyata ada rekan mahasiswa yang jujur melapor di Find.It.',
      },
      {
        'initials': 'BT',
        'name': 'Budi T.',
        'role': 'Staff / Dosen UBSI',
        'rating': 5,
        'story': 'Menemukan kartu identitas mahasiswa di kantin. Pemilik langsung kontak dan terverifikasi cepat di pos kampus.',
      },
    ];

    return Container(
      color: AppColors.appDark, // Deep Navy Section
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.4), width: 0.8),
            ),
            child: const Text(
              "★ KISAH SUKSES KOMUNITAS",
              style: TextStyle(
                color: AppColors.accentAmberLight,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          const Text(
            "Karena Kejujuran Itu Menular",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Melihat barang kembali ke pemiliknya adalah alasan kami hadir. Bangun integritas kampus UBSI bersama-sama.",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.slate400,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          // Story Cards (Horizontal Scroll)
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, idx) {
                final s = stories[idx];
                return Container(
                  width: 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.bsiTeal,
                            child: Text(
                              s['initials'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  s['role'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.slate400,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (_) => const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFBBF24)),
                        ),
                      ),
                      Text(
                        "\"${s['story']}\"",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate300,
                          fontSize: 11.5,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "✓ Status: Dikembalikan",
                          style: TextStyle(
                            color: AppColors.accentEmerald,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECTION 4: ALUR & PANDUAN (PUTIH / LIGHT)
  // =========================================================================
  Widget _buildWhiteGuideSection() {
    final faqs = [
      {
        'q': 'Bagaimana cara melaporkan barang temuan?',
        'a': 'Klik tombol "+ Lapor" di atas atau tombol tengah (+). Pilih jenis "Saya Menemukan", isi detail barang, lokasi, dan unggah foto. Laporan akan diverifikasi admin sebelum tampil.',
      },
      {
        'q': 'Apakah data kontak WhatsApp saya aman?',
        'a': 'Sangat aman! Data pribadi seperti nomor HP tidak dipublikasikan secara umum. Kontak hanya dibagikan secara terenkripsi saat pengajuan klaim telah disetujui admin.',
      },
      {
        'q': 'Berapa lama proses verifikasi klaim?',
        'a': 'Verifikasi klaim biasanya diproses maksimal 1x24 jam oleh admin atau petugas satpam kampus terkait.',
      },
    ];

    return Container(
      color: Colors.white, // Clean Crisp White (#FFFFFF)
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "💡 PANDUAN CEPAT",
              style: TextStyle(
                color: Color(0xFF059669),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          const Text(
            "Cara Kerja Find.It",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.lightTextPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "3 langkah mudah menemukan kembali barang berharga Anda",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightTextMuted,
            ),
          ),

          const SizedBox(height: 18),

          // 3 Steps
          _buildStepRow(
            number: "1",
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFEFF6FF),
            title: "Laporkan Barang",
            desc: "Isi formulir laporan kehilangan atau temuan barang dengan deskripsi dan lokasi akurat.",
          ),
          const SizedBox(height: 12),
          _buildStepRow(
            number: "2",
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFECFDF5),
            title: "Verifikasi Kampus",
            desc: "Admin kampus UBSI memeriksa keabsahan laporan agar terhindar dari spam atau klaim palsu.",
          ),
          const SizedBox(height: 12),
          _buildStepRow(
            number: "3",
            icon: Icons.handshake_outlined,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFFFBEB),
            title: "Serah Terima Aman",
            desc: "Ambil barang di pos satpam kampus atau hubungi penemu yang telah terverifikasi resmi.",
          ),

          const SizedBox(height: 28),

          const Divider(color: Color(0xFFE2E8F0)),

          const SizedBox(height: 16),

          // FAQ Accordion
          const Text(
            "Pertanyaan Umum (FAQ)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          ...List.generate(faqs.length, (idx) {
            final f = faqs[idx];
            final isExpanded = _expandedFaqIndex == idx;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key("faq_$idx"),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (exp) {
                    setState(() {
                      _expandedFaqIndex = exp ? idx : null;
                    });
                  },
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  title: Text(
                    f['q']!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Text(
                        f['a']!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.lightTextSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.lightTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
