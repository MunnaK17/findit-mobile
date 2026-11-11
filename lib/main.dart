import 'dart:async';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/push_service.dart';
import 'services/supabase_service.dart';
import 'views/auth/login_view.dart';
import 'views/splash/splash_view.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  SupabaseService.onSignedOut.listen(
    (_) => rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    ),
    onError: (Object e) => debugPrint('Error auth state: $e'),
  );
  final loggedIn = SupabaseService.isLoggedIn;
  final themeProvider = ThemeProvider();
  runApp(FindITApp(initialLoggedIn: loggedIn, themeProvider: themeProvider));
  unawaited(PushService.init());
}

class FindITApp extends StatelessWidget {
  final bool initialLoggedIn;
  final ThemeProvider? themeProvider;

  const FindITApp({
    super.key,
    required this.initialLoggedIn,
    this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final provider = themeProvider ?? ThemeProvider();
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return _ThemeScope(
          themeProvider: provider,
          child: MaterialApp(
            navigatorKey: rootNavigatorKey,
            title: 'FindIT - Lost & Found Kampus',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
            home: SplashView(loggedIn: initialLoggedIn),
          ),
        );
      },
    );
  }
}

/// InheritedWidget to access [ThemeProvider] from anywhere in the tree
/// without adding a dependency on the provider package.
class _ThemeScope extends InheritedWidget {
  final ThemeProvider themeProvider;

  const _ThemeScope({
    required this.themeProvider,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ThemeScope oldWidget) => true;
}

/// Extension on [BuildContext] to easily access [ThemeProvider].
extension ThemeProviderX on BuildContext {
  ThemeProvider get themeProvider {
    final scope = dependOnInheritedWidgetOfExactType<_ThemeScope>();
    assert(scope != null, 'No _ThemeScope found. Wrap your root widget with _ThemeScope.');
    return scope!.themeProvider;
  }
}
