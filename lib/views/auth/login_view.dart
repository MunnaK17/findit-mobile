import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../main_navigation_view.dart';
import 'register_view.dart';
import 'verify_email_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    var rawInput = _emailController.text.trim();
    if (!rawInput.contains('@')) {
      rawInput = '$rawInput@bsi.ac.id';
    }

    final res = await AuthService.login(
      rawInput,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationView()),
      );
    } else if (res['needs_verification'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailView(email: res['email'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Login gagal, periksa email dan kata sandi'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final themeProvider = context.themeProvider;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              c.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: c.amberText,
              size: 20,
            ),
            tooltip: c.isDark ? 'Beralih ke Mode Terang' : 'Beralih ke Mode Gelap',
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 38,
                        color: AppColors.slate950,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Find.',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'It',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: c.amberText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: ' Kampus',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Platform Lapor Barang Hilang & Temuan UBSI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Email Mahasiswa / Username',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: c.inputText),
                    decoration: InputDecoration(
                      hintText: 'nama@bsi.ac.id atau username',
                      prefixIcon: Icon(Icons.email_outlined, color: c.inputHint),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email atau username wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Kata Sandi',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: c.inputText),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline, color: c.inputHint),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: c.inputHint,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentAmber,
                      foregroundColor: AppColors.slate950,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slate950),
                          )
                        : const Text('Masuk ke Akun'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum punya akun?', style: TextStyle(fontSize: 13, color: c.textMuted)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterView()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: c.amberText,
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: Divider(color: c.cardBorder)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('atau', style: TextStyle(color: c.textMuted, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: c.cardBorder)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _continueAsGuest,
                    icon: Icon(Icons.person_outline, color: c.textSecondary),
                    label: Text('Masuk Sebagai Tamu', style: TextStyle(color: c.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.cardBorder),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
