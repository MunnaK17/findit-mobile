import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationView()),
        (route) => false,
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.space6),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppColors.space8 + 8),
                      const Center(child: CampusLogo(size: 120)),
                      const SizedBox(height: AppColors.space3),
                      Text(
                        'Universitas Bina Sarana Informatika',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium(c.textSecondary),
                      ),
                      const SizedBox(height: AppColors.space8 + 8),
                      Text(
                        'Masuk ke Akun',
                        style: AppTypography.titleLarge(c.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Layanan lapor barang hilang kampus UBSI.',
                        style: AppTypography.body(c.textSecondary),
                      ),
                      const SizedBox(height: AppColors.space6),
                      const _FieldLabel('Email atau Username'),
                      const SizedBox(height: AppColors.space2),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        style: AppTypography.bodyMedium(c.inputText),
                        decoration: InputDecoration(
                          hintText: 'nama@bsi.ac.id atau username',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email atau username wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppColors.space4),
                      const _FieldLabel('Kata Sandi'),
                      const SizedBox(height: AppColors.space2),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                        style: AppTypography.bodyMedium(c.inputText),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppColors.space6),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brandOnPrimary,
                                ),
                              )
                            : const Text('Masuk ke Akun'),
                      ),
                      const SizedBox(height: AppColors.space3),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _continueAsGuest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(color: c.cardBorder),
                        ),
                        child: const Text('Masuk Sebagai Tamu'),
                      ),
                      const Spacer(),
                      const SizedBox(height: AppColors.space6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun?',
                            style: AppTypography.body(c.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterView()),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: c.amberText,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            child: Text(
                              'Daftar',
                              style: AppTypography.label(c.amberText)
                                  .copyWith(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Center(child: PoweredByFindit()),
                      const SizedBox(height: AppColors.space5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Text(text, style: AppTypography.label(c.textPrimary));
  }
}
