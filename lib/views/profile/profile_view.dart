import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../main.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/supabase_service.dart';
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
  String? _reportsError;

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
    setState(() {
      _loadingReports = true;
      _reportsError = null;
    });
    final reports = await ReportService.getMyReports();
    if (mounted) {
      setState(() {
        _myReports = reports;
        if (reports.isEmpty && SupabaseService.lastError != null) {
          _reportsError = SupabaseService.lastError;
        }
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                            color: cs.amberBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.phone_android_rounded,
                            color: cs.amberText,
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
                                  fontWeight: FontWeight.w700,
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
                        prefixIcon: Icon(Icons.phone_outlined, color: cs.amberText),
                        filled: true,
                        fillColor: cs.inputFill,
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
                                borderRadius: BorderRadius.circular(12),
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
                                          content: Text('Nomor HP berhasil diperbarui'),
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
                              foregroundColor: AppColors.slate950,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.slate950,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Nomor HP',
                                    style: TextStyle(fontWeight: FontWeight.w700),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                            color: cs.amberBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            color: cs.amberText,
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
                                  fontWeight: FontWeight.w700,
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
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: cs.amberText),
                        suffixIcon: IconButton(
                          tooltip: obscureNew ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
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
                        prefixIcon: Icon(Icons.lock_clock_outlined, color: cs.amberText),
                        suffixIcon: IconButton(
                          tooltip: obscureConfirm ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
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
                                borderRadius: BorderRadius.circular(12),
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
                                          content: Text('Kata sandi berhasil diperbarui'),
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
                              foregroundColor: AppColors.slate950,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.slate950,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Kata Sandi',
                                    style: TextStyle(fontWeight: FontWeight.w700),
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.accentAmber),
              const SizedBox(height: 12),
              Text(
                'Memuat profil pengguna...',
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
            ],
          ),
        ),
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
                color: c.amberText,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary),
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showHelpCenterSheet,
                  icon: Icon(Icons.help_outline_rounded, size: 18, color: c.tealText),
                  label: Text('Pusat Bantuan & Cara Kerja', style: TextStyle(color: c.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.cardBorder),
                    minimumSize: const Size(200, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final roleTextColor = _user!.isStaff
        ? c.tealText
        : _user!.isAdmin
            ? c.adminText
            : c.amberText;
    final roleBgColor = _user!.isStaff
        ? c.tealBg
        : _user!.isAdmin
            ? c.adminBg
            : c.amberBg;

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
                color: c.amberText,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.mintBg,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: c.mintText,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: roleBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: roleTextColor.withValues(alpha: 0.4),
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
                          color: roleTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _user!.roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: roleTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: c.cardBorder, height: 1),
                  const SizedBox(height: 16),
                  if (_user!.campus != null) ...[
                    _buildInfoRow(
                      c: c,
                      icon: Icons.account_balance_outlined,
                      label: 'Cabang Kampus',
                      value: _user!.campus!.namaKampus,
                      badgeColor: c.tealText,
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
                  _buildInfoRow(
                    c: c,
                    icon: Icons.phone_outlined,
                    label: 'Kontak WhatsApp',
                    value: (_user!.phone != null && _user!.phone!.isNotEmpty)
                        ? _user!.phone!
                        : 'Belum diatur (Ketuk untuk isi)',
                    trailing: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: c.amberText,
                    ),
                    onTap: _showEditPhoneDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.cardBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      c.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: c.amberText,
                    ),
                    title: Text(
                      c.isDark ? 'Night Mode (Mode Gelap)' : 'Light Mode (Mode Terang)',
                      style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      c.isDark
                          ? 'Aktif (Default). Ketuk untuk beralih ke Light Mode'
                          : 'Aktif. Ketuk untuk beralih ke Night Mode',
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                    value: c.isDark,
                    activeThumbColor: AppColors.accentAmber,
                    onChanged: (val) => themeProvider.setDarkMode(val),
                  ),
                  Divider(height: 1, color: c.cardBorder),
                  ListTile(
                    leading: Icon(Icons.inventory_2_outlined, color: c.amberText),
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
                    leading: Icon(Icons.phone_outlined, color: c.amberText),
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
                    leading: Icon(Icons.lock_outline_rounded, color: c.amberText),
                    title: Text('Ganti Kata Sandi', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('Perbarui keamanan kata sandi akun', style: TextStyle(fontSize: 12, color: c.textMuted)),
                    trailing: Icon(Icons.chevron_right, color: c.textMuted),
                    onTap: _showChangePasswordDialog,
                  ),
                  Divider(height: 1, color: c.cardBorder),
                  ListTile(
                    leading: Icon(Icons.help_outline_rounded, color: c.tealText),
                    title: Text('Pusat Bantuan & Cara Kerja', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                    subtitle: Text('Panduan lapor, klaim, dan tanya jawab (FAQ)', style: TextStyle(fontSize: 12, color: c.textMuted)),
                    trailing: Icon(Icons.chevron_right, color: c.textMuted),
                    onTap: _showHelpCenterSheet,
                  ),
                  Divider(height: 1, color: c.cardBorder),
                  ListTile(
                    leading: Icon(Icons.logout, color: c.dangerText),
                    title: Text(
                      'Keluar dari Akun',
                      style: TextStyle(color: c.dangerText, fontWeight: FontWeight.w700),
                    ),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    tooltip: 'Muat ulang laporan saya',
                    icon: Icon(Icons.refresh, size: 20, color: c.textMuted),
                    onPressed: _loadMyReports,
                  ),
                ],
              ),
            ),
            if (_loadingReports)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.accentAmber),
                    const SizedBox(height: 10),
                    Text(
                      'Memuat laporan Anda...',
                      style: TextStyle(fontSize: 12, color: c.textMuted),
                    ),
                  ],
                ),
              )
            else if (_reportsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      _reportsError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.dangerText, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loadMyReports,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (_myReports.isEmpty)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'Anda belum membuat laporan apa pun.',
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
                  final typeText = isHilang ? c.amberText : c.tealText;
                  final typeBg = isHilang ? c.amberBg : c.tealBg;
                  final statusText = c.statusTextColor(rep.status);
                  final statusBg = c.statusBgColor(rep.status);

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
                            backgroundColor: typeBg,
                            child: Icon(
                              isHilang ? Icons.warning_amber_rounded : Icons.search_rounded,
                              color: typeText,
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
                                    fontWeight: FontWeight.w700,
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
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              FinditColors.statusLabel(rep.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusText,
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
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: badgeColor ?? c.amberText),
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
      return Semantics(
        button: true,
        label: '$label: $value. Ketuk untuk mengubah.',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: content,
        ),
      );
    }
    return content;
  }

  void _showHelpCenterSheet() {
    final c = FinditColors.of(context);
    final faqs = [
      {
        'q': '1. Bagaimana cara melaporkan barang hilang atau temuan?',
        'a': 'Ketuk tombol "Lapor Hilang" / "Lapor Temuan" di beranda atau tombol (+) di tengah navigasi bawah. Isi lokasi spesifik, ciri barang, dan foto jika ada.',
      },
      {
        'q': '2. Bagaimana cara mengajukan klaim barang temuan?',
        'a': 'Buka detail laporan berstatus "Barang Temuan", lalu ketuk "Klaim Barang Ini". Jelaskan ciri spesifik barang sebagai bukti kepemilikan.',
      },
      {
        'q': '3. Bagaimana serah terima barang dilakukan?',
        'a': 'Seluruh serah terima barang temuan wajib dilakukan melalui Resepsionis / Admin cabang kampus UBSI terkait. Pemilik datang langsung untuk verifikasi identitas dan penandatanganan Berita Acara.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cs = FinditColors.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pusat Bantuan & Cara Kerja',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Panduan singkat penggunaan aplikasi FindIT Kampus UBSI',
                  style: TextStyle(fontSize: 12, color: cs.textMuted),
                ),
                const SizedBox(height: 16),
                ...faqs.map((f) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.cardBgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f['q']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          f['a']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
