import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
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

  // 0: Home, 1: Search, 2: MyClaims, 3: Profile
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
    return Scaffold(
      backgroundColor: AppColors.appDark,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Background Bar
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF142036).withValues(alpha: 0.98),
              border: const Border(
                top: BorderSide(color: Color(0xFF263753), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home
                _buildNavItem(
                  icon: Icons.home_rounded,
                  unselectedIcon: Icons.home_outlined,
                  isSelected: _currentIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),

                // 2. Search / Chat
                _buildNavItem(
                  icon: Icons.search_rounded,
                  unselectedIcon: Icons.search_rounded,
                  isSelected: _currentIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),

                // Spacer for Center Floating Action Button
                const SizedBox(width: 56),

                // 4. Claims / History
                _buildNavItem(
                  icon: Icons.receipt_long_rounded,
                  unselectedIcon: Icons.receipt_long_outlined,
                  isSelected: _currentIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),

                // 5. Profile
                _buildNavItem(
                  icon: Icons.person_rounded,
                  unselectedIcon: Icons.person_outline_rounded,
                  isSelected: _currentIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
              ],
            ),
          ),

          // Centered Floating Add (+) Action Button from Stitch Design
          Positioned(
            top: -24,
            child: GestureDetector(
              onTap: _openCreateReport,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentAmber,
                  border: Border.all(
                    color: const Color(0xFF10192B),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentAmber.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: AppColors.slate950,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData unselectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Icon(
          isSelected ? icon : unselectedIcon,
          size: 24,
          color: isSelected ? Colors.white : AppColors.slate400,
          shadows: isSelected
              ? [
                  Shadow(
                    color: AppColors.accentAmber.withValues(alpha: 0.8),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
