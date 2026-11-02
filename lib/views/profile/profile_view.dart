import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../auth/login_view.dart';
import '../claims/my_claims_view.dart';
import '../reports/report_detail_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserModel? _user;
  bool _isLoading = true;
  List<ReportModel> _myReports = [];
  bool _loadingReports = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }

    if (user != null) {
      _loadMyReports();
    }
  }

  Future<void> _loadMyReports() async {
    setState(() => _loadingReports = true);
    final reports = await ReportService.getMyReports();
    if (mounted) {
      setState(() {
        _myReports = reports;
        _loadingReports = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final c = FinditColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        title: Text('Konfirmasi Keluar', style: TextStyle(color: c.textPrimary)),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: c.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  void _showEditPhoneDialog() {
    final phoneController = TextEditingController(text: _user?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final cs = FinditColors.of(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: cs.sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: cs.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_android_rounded,
                            color: AppColors.accentAmber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubah Nomor HP / WhatsApp',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cs.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nomor kontak untuk koordinasi barang',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      style: TextStyle(color: cs.inputText, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Nomor WhatsApp / HP',
                        hintText: 'Contoh: 085891565501',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.accentAmber),
                        filled: true,
                        fillColor: cs.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentAmber, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nomor HP tidak boleh kosong';
                        }
                        final clean = val.trim();
                        if (clean.length < 8) {
                          return 'Nomor HP minimal 8 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: cs.cardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text('Batal', style: TextStyle(color: cs.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() => isSaving = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);
                                    final res = await AuthService.updatePhone(phoneController.text.trim());
                                    if (!mounted) return;
                                    setModalState(() => isSaving = false);
                                    if (res['success'] == true) {
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Nomor HP berhasil diperbarui!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      _loadProfile();
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'Gagal memperbarui nomor HP'),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentAmber,
                              foregroundColor: AppColors.appDark,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.appDark,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Nomor HP',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final cs = FinditColors.of(context);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: cs.sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: cs.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.accentAmber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ganti Kata Sandi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cs.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gunakan minimal 6 karakter',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      style: TextStyle(color: cs.inputText, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.accentAmber),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: cs.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() => obscureNew = !obscureNew);
                          },
                        ),
                        filled: true,
                        fillColor: cs.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentAmber, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Kata sandi baru tidak boleh kosong';
                        }
                        if (val.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      style: TextStyle(color: cs.inputText, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                        hintText: 'Ulangi kata sandi baru',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.accentAmber),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: cs.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() => obscureConfirm = !obscureConfirm);
                          },
                        ),
                        filled: true,
                        fillColor: cs.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentAmber, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Konfirmasi kata sandi tidak boleh kosong';
                        }
                        if (val != newPasswordController.text) {
                          return 'Konfirmasi kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: cs.cardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text('Batal', style: TextStyle(color: cs.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() => isSaving = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);
                                    final res = await AuthService.updatePassword(newPasswordController.text);
                                    if (!mounted) return;
                                    setModalState(() => isSaving = false);
                                    if (res['success'] == true) {
                                      navigator.pop();
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Kata sandi berhasil diperbarui!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'Gagal memperbarui kata sandi'),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentAmber,
                              foregroundColor: AppColors.appDark,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.appDark,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Kata Sandi',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final themeProvider = context.themeProvider;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: c.scaffoldBg,
        body: const Center(child: CircularProgressIndicator(color: AppColors.accentAmber)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: c.scaffoldBg,
        appBar: AppBar(
          backgroundColor: c.scaffoldBg,
          title: const Text('Profil Pengguna'),
          actions: [
            IconButton(
              tooltip: c.isDark ? 'Mode Terang' : 'Mode Gelap',
              icon: Icon(
                c.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.accentAmber,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: c.cardBgLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.cardBorder),
                  ),
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 54,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Anda Masuk Sebagai Tamu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke akun untuk membuat laporan kehilangan/temuan dan memantau status klaim Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginView()),
                    );
                  },
                  child: const Text('Masuk ke Akun'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        title: const Text('Profil Pengguna'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: c.isDark ? 'Beralih ke Light Mode' : 'Beralih ke Night Mode',
              icon: Icon(
                c.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: AppColors.accentAmber,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.cardBgLight,
                      border: Border.all(color: AppColors.accentAmber, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accentAmber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _user!.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user!.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _user!.isStaff
                          ? AppColors.bsiTeal.withValues(alpha: 0.18)
                          : _user!.isAdmin
                              ? const Color(0xFFA855F7).withValues(alpha: 0.18)
                              : AppColors.accentAmber.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _user!.isStaff
                            ? AppColors.bsiTeal
                            : _user!.isAdmin
                                ? const Color(0xFFA855F7)
                                : AppColors.accentAmber,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _user!.isStaff
                              ? Icons.badge_rounded
                              : _user!.isAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.school_rounded,
                          size: 14,
                          color: _user!.isStaff
                              ? AppColors.bsiTeal
                              : _user!.isAdmin
                                  ? const Color(0xFFA855F7)
                                  : AppColors.accentAmber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _user!.roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _user!.isStaff
                                ? AppColors.bsiTeal
                                : _user!.isAdmin
                                    ? const Color(0xFFA855F7)
                                    : AppColors.accentAmber,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: c.cardBorder, height: 1),
                  const SizedBox(height: 16),

                  // User Info Detail Items (Campus, NIM/NIP, Prodi, Phone)
                  if (_user!.campus != null) ...[
                    _buildInfoRow(
                      c: c,
                      icon: Icons.account_balance_outlined,
                      label: 'Cabang Kampus',
                      value: _user!.campus!.namaKampus,
                      badgeColor: AppColors.bsiTeal,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (_user!.nip != null && _user!.nip!.isNotEmpty) ...[
                    _buildInfoRow(
                      c: c,
                      icon: Icons.badge_outlined,
                      label: 'NIP / NIDN',
                      value: _user!.nip!,
                    ),
                    const SizedBox(height: 10),
                  ] else if (_user!.nim != null && _user!.nim!.isNotEmpty) ...[
                    _buildInfoRow(
                      c: c,
                      icon: Icons.credit_card_outlined,
                      label: 'NIM',
                      value: _user!.nim!,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (_user!.prodiUnit != null && _user!.prodiUnit!.isNotEmpty) ...[
                    _buildInfoRow(
                      c: c,
                      icon: Icons.business_outlined,
                      label: _user!.isStaff ? 'Unit Kerja / Dept' : 'Program Studi',
                      value: _user!.prodiUnit!,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Kontak WhatsApp row (interactive)
                  _buildInfoRow(
                    c: c,
                    icon: Icons.phone_outlined,
                    label: 'Kontak WhatsApp',
                    value: (_user!.phone != null && _user!.phone!.isNotEmpty)
                        ? _user!.phone!
                        : 'Belum diatur (Ketuk untuk isi)',
                    trailing: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.accentAmber,
                    ),
                    onTap: _showEditPhoneDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick Menu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.cardBorder),
              ),
              child: Column(
                children: [
                  // Night Mode / Light Mode Toggle
                  SwitchListTile(
                    secondary: Icon(
                      c.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.accentAmber,
                    ),
                    title: Text(
                      c.isDark ? 'Night Mode (Mode Gelap)' : 'Light Mode (Mode Terang)',
                      style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      c.isDark
                          ? 'Aktif (Default) — Ketuk untuk beralih ke Light Mode'
                          : 'Aktif — Ketuk untuk beralih ke Night Mode',
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                    value: c.isDark,
                    activeThumbColor: AppColors.accentAmber,
                    onChanged: (val) => themeProvider.setDarkMode(val),
                  ),
                  Divider(height: 1, color: c.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: AppColors.accentAmber),
                    title: Text('Klaim Saya', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('Pantau status klaim barang temuan', style: TextStyle(color: c.textMuted, fontSize: 12)),
                    trailing: Icon(Icons.chevron_right, color: c.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyClaimsView()),
                      );
                    },
                  ),
                  Divider(height: 1, color: c.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.accentAmber),
                    title: Text('Ubah Nomor HP / WhatsApp', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _user!.phone?.isNotEmpty == true ? _user!.phone! : 'Atur nomor kontak aktif',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                    trailing: Icon(Icons.chevron_right, color: c.textMuted),
                    onTap: _showEditPhoneDialog,
                  ),
                  Divider(height: 1, color: c.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: AppColors.accentAmber),
                    title: Text('Ganti Kata Sandi', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('Perbarui keamanan kata sandi akun', style: TextStyle(fontSize: 12, color: c.textMuted)),
                    trailing: Icon(Icons.chevron_right, color: c.textMuted),
                    onTap: _showChangePasswordDialog,
                  ),
                  Divider(height: 1, color: c.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // My Reports Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Laporan Saya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20, color: c.textMuted),
                    onPressed: _loadMyReports,
                  ),
                ],
              ),
            ),

            if (_loadingReports)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.accentAmber),
              )
            else if (_myReports.isEmpty)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Anda belum membuat laporan apapun.',
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _myReports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final rep = _myReports[index];
                  final isHilang = rep.isHilang;
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportDetailView(report: rep)),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.cardBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isHilang
                                ? AppColors.accentAmber.withValues(alpha: 0.15)
                                : AppColors.accentBlue.withValues(alpha: 0.15),
                            child: Icon(
                              isHilang ? Icons.warning_amber_rounded : Icons.search_rounded,
                              color: isHilang ? AppColors.accentAmber : AppColors.accentBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rep.namaBarang,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${isHilang ? 'Hilang' : 'Temuan'} • ${rep.lokasi}",
                                  style: TextStyle(fontSize: 12, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (rep.status == 'approved' ? AppColors.success : AppColors.warning)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rep.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: rep.status == 'approved' ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required FinditColors c,
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: badgeColor ?? AppColors.accentAmber),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor ?? c.textPrimary,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      );
    }
    return content;
  }
}
