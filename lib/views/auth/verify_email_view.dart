import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import '../main_navigation_view.dart';

class VerifyEmailView extends StatefulWidget {
  final String email;

  const VerifyEmailView({super.key, required this.email});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _cooldown = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6 || code.length > 8) {
      _snack('Masukkan 8 digit kode verifikasi dari email Anda', AppColors.danger);
      return;
    }
    setState(() => _isLoading = true);
    final res = await AuthService.verifyEmail(widget.email, code);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationView()),
        (route) => false,
      );
    } else {
      _snack(res['message'] ?? 'Verifikasi gagal', AppColors.danger);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final ok = await AuthService.resendVerification(widget.email);
    if (!mounted) return;
    _snack(
      ok ? 'Kode baru telah dikirim ke ${widget.email}' : 'Gagal mengirim ulang kode',
      ok ? AppColors.success : AppColors.danger,
    );
    if (!ok) return;
    setState(() => _cooldown = 60);
    while (mounted && _cooldown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _cooldown--);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        elevation: 0,
        title: const Text('Verifikasi Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.cardBgLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentAmber, width: 2),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      size: 40, color: AppColors.accentAmber),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Aktifkan Akun Anda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Kami telah mengirim kode 8 digit ke\n${widget.email}\nMasukkan kode tersebut untuk mengaktifkan akun.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.slate400, height: 1.5),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
                decoration: const InputDecoration(counterText: '', hintText: '--------'),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slate950),
                      )
                    : const Text('Verifikasi & Masuk'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _cooldown > 0 ? null : _resend,
                child: Text(
                  _cooldown > 0 ? 'Kirim ulang kode ($_cooldown dtk)' : 'Kirim ulang kode',
                  style: TextStyle(
                    color: _cooldown > 0 ? AppColors.slate400 : AppColors.accentAmber,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kode berlaku 15 menit. Periksa juga folder spam.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
