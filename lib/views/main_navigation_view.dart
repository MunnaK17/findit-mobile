import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
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
      floatingActionButton: Semantics(
        button: true,
        label: 'Tanya FindBot Asisten AI',
        child: Tooltip(
          message: 'Tanya FindBot',
          child: Material(
            color: AppColors.actionBlue,
            elevation: 6,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatbotView()),
                );
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 26,
                ),
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
                border: Border(
                  top: BorderSide(color: c.navBarBorder, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    label: 'Beranda',
                    icon: Icons.home_rounded,
                    unselectedIcon: Icons.home_outlined,
                    isSelected: _currentIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  _buildNavItem(
                    label: 'Cari',
                    icon: Icons.search_rounded,
                    unselectedIcon: Icons.search_rounded,
                    isSelected: _currentIndex == 1,
                    onTap: () => _onItemTapped(1),
                  ),
                  const SizedBox(width: 60),
                  _buildNavItem(
                    label: 'Aktivitas',
                    icon: Icons.receipt_long_rounded,
                    unselectedIcon: Icons.receipt_long_outlined,
                    isSelected: _currentIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                  _buildNavItem(
                    label: 'Profil',
                    icon: Icons.person_rounded,
                    unselectedIcon: Icons.person_outline_rounded,
                    isSelected: _currentIndex == 3,
                    onTap: () => _onItemTapped(3),
                  ),
                ],
              ),
            ),

            // Tombol utama pembuatan laporan ditempatkan menonjol di tengah agar dapat dijangkau satu ibu jari.
            Positioned(
              top: -20,
              child: Semantics(
                button: true,
                label: 'Buat Laporan Barang Baru',
                child: Tooltip(
                  message: 'Buat Laporan Baru',
                  child: Material(
                    color: AppColors.accentAmber,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: c.navBarFabBorder,
                        width: 4,
                      ),
                    ),
                    elevation: 4,
                    child: InkWell(
                      onTap: _openCreateReport,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(
                          Icons.add_rounded,
                          size: 28,
                          color: AppColors.slate950,
                        ),
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final c = FinditColors.of(context);
    final activeColor = c.amberText;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? icon : unselectedIcon,
                    size: 22,
                    color: isSelected ? activeColor : c.textMuted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? activeColor : c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
