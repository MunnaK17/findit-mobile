import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
import '../auth/login_view.dart';
import '../main_navigation_view.dart';

/// Layar pembuka: logo kampus, nama layanan, dan "Powered by FindIT".
/// Tampil sebentar lalu menuju Beranda (sudah login) atau Login.
class SplashView extends StatefulWidget {
  final bool loggedIn;
  final Duration delay;

  const SplashView({
    super.key,
    required this.loggedIn,
    this.delay = const Duration(milliseconds: 1400),
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.loggedIn
            ? const MainNavigationView()
            : const LoginView(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: MediaQuery.of(context).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.space6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CampusLogo(size: 120),
                      const SizedBox(height: AppColors.space6),
                      Text(
                        'Lost & Found Kampus',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge(c.textPrimary),
                      ),
                      const SizedBox(height: AppColors.space2),
                      Text(
                        'Universitas Bina Sarana Informatika',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppColors.space6),
              child: PoweredByFindit(),
            ),
          ],
        ),
      ),
    );
  }
}
