import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
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
  late String _activeOtp;

  @override
  void initState() {
    super.initState();
    _activeOtp = SupabaseService.getOrCreateOtp(widget.email);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _snack('Masukkan 6 digit kode verifikasi', AppColors.danger);
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
    setState(() {
      _activeOtp = SupabaseService.getOrCreateOtp(widget.email);
    });
    _snack(
      ok ? 'Kode OTP baru Anda: $_activeOtp' : 'Gagal mengirim ulang kode',
      ok ? AppColors.success : AppColors.danger,
    );
    if (!ok) return;
    setState(() => _cooldown = 30);
    while (mounted && _cooldown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _cooldown--);
    }
  }

  void _autoFillOtp() {
    setState(() {
      _codeController.text = _activeOtp;
    });
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
              // Banner Kode OTP Instan (Solusi Tanpa SMTP Eksternal)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.bsiTeal.withValues(alpha: 0.6), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bsiTeal.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, color: AppColors.bsiTeal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kode OTP Sivitas BSI Anda:',
                            style: TextStyle(fontSize: 11, color: AppColors.slate300),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activeOtp,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accentAmberLight,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _autoFillOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bsiTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Isi Otomatis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.cardBgLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentAmber, width: 2),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      size: 38, color: AppColors.accentAmber),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Aktifkan Akun Anda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Kami telah membuat kode 6 digit untuk\n${widget.email}\nMasukkan kode tersebut atau ketuk "Isi Otomatis" di atas.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.slate400, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                ),
                decoration: const InputDecoration(counterText: '', hintText: '------'),
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
                  _cooldown > 0 ? 'Kirim ulang kode ($_cooldown dtk)' : 'Kirim ulang / Buat kode baru',
                  style: TextStyle(
                    color: _cooldown > 0 ? AppColors.slate400 : AppColors.accentAmber,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kode berlaku 15 menit.',
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
