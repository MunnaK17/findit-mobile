import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/theme/app_theme.dart';
import 'chat/chatbot_view.dart';
import 'home/home_view.dart';
import 'reports/create_report_view.dart';
import 'search/search_view.dart';
import 'activity/activity_view.dart';
import 'profile/profile_view.dart';

class MainNavigationView extends StatefulWidget {
  final int initialIndex;

  const MainNavigationView({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  late int _currentIndex;

  List<Widget> get _pages => const [
    HomeView(),
    SearchView(),
    ActivityView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _openCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateReportView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // FindBot melayang di kanan bawah, di atas navigasi, di semua tab.
      floatingActionButton: Tooltip(
        message: 'Tanya FindBot',
        child: Material(
          color: AppColors.actionBlue,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: AppColors.actionBlue.withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotView()),
            ),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.headset_mic_rounded,
                color: Colors.white,
                size: 26,
                semanticLabel: 'Tanya FindBot',
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: 68,
              decoration: BoxDecoration(
                color: c.navBarBg,
                border: Border(top: BorderSide(color: c.navBarBorder)),
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    label: 'Beranda',
                    icon: Icons.home_rounded,
                    unselectedIcon: Icons.home_outlined,
                    index: 0,
                  ),
                  _buildNavItem(
                    label: 'Cari',
                    icon: Icons.search_rounded,
                    unselectedIcon: Icons.search_rounded,
                    index: 1,
                  ),
                  const SizedBox(width: 72),
                  _buildNavItem(
                    label: 'Aktivitas',
                    icon: Icons.receipt_long_rounded,
                    unselectedIcon: Icons.receipt_long_outlined,
                    index: 2,
                  ),
                  _buildNavItem(
                    label: 'Profil',
                    icon: Icons.person_rounded,
                    unselectedIcon: Icons.person_outline_rounded,
                    index: 3,
                  ),
                ],
              ),
            ),
            // Tombol buat laporan menonjol di tengah agar terjangkau satu ibu jari.
            Positioned(
              top: -26,
              child: Tooltip(
                message: 'Buat Laporan Baru',
                child: Material(
                  color: AppColors.brandPrimary,
                  shape: CircleBorder(
                    side: BorderSide(color: c.navBarFabBorder, width: 4),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.brandPrimary.withValues(alpha: 0.4),
                  child: InkWell(
                    onTap: _openCreateReport,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 60,
                      height: 60,
                      child: Icon(
                        Icons.add_rounded,
                        size: 30,
                        color: AppColors.brandOnPrimary,
                        semanticLabel: 'Buat laporan baru',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required IconData icon,
    required IconData unselectedIcon,
    required int index,
  }) {
    final c = FinditColors.of(context);
    final isSelected = _currentIndex == index;
    final color = isSelected ? c.textPrimary : c.textMuted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelected ? icon : unselectedIcon, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.caption(color).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
