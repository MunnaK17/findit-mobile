import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'services/api_service.dart';
import 'views/auth/login_view.dart';
import 'views/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await ApiService.getToken();
  runApp(FindITApp(initialLoggedIn: token != null));
}

class FindITApp extends StatelessWidget {
  final bool initialLoggedIn;

  const FindITApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindIT - Lost & Found Kampus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialLoggedIn ? const MainNavigationView() : const LoginView(),
    );
  }
}
