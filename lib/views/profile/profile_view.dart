import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Konfirmasi Keluar', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(color: AppColors.slate300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate400)),
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
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
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
                          color: AppColors.cardBorder,
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubah Nomor HP / WhatsApp',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Nomor kontak untuk koordinasi barang',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate400,
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
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Nomor WhatsApp / HP',
                        hintText: 'Contoh: 085891565501',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.accentAmber),
                        filled: true,
                        fillColor: AppColors.cardBgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
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
                              side: const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Batal', style: TextStyle(color: AppColors.slate300)),
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
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
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
                          color: AppColors.cardBorder,
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ganti Kata Sandi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Gunakan minimal 6 karakter',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate400,
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi Baru',
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.accentAmber),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() => obscureNew = !obscureNew);
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.cardBgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi Baru',
                        hintText: 'Ulangi kata sandi baru',
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.accentAmber),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() => obscureConfirm = !obscureConfirm);
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.cardBgLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
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
                              side: const BorderSide(color: AppColors.cardBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Batal', style: TextStyle(color: AppColors.slate300)),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.appDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentAmber)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.appDark,
        appBar: AppBar(
          backgroundColor: AppColors.appDark,
          title: const Text('Profil Pengguna'),
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
                    color: AppColors.cardBgLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    size: 54,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Anda Masuk Sebagai Tamu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masuk ke akun untuk membuat laporan kehilangan/temuan dan memantau status klaim Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.4),
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
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        title: const Text('Profil Pengguna'),
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
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardBgLight,
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user!.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate400,
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
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 16),

                  // User Info Detail Items (Campus, NIM/NIP, Prodi, Phone)
                  if (_user!.campus != null) ...[
                    _buildInfoRow(
                      icon: Icons.account_balance_outlined,
                      label: 'Cabang Kampus',
                      value: _user!.campus!.namaKampus,
                      badgeColor: AppColors.bsiTeal,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (_user!.nip != null && _user!.nip!.isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'NIP / NIDN',
                      value: _user!.nip!,
                    ),
                    const SizedBox(height: 10),
                  ] else if (_user!.nim != null && _user!.nim!.isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.credit_card_outlined,
                      label: 'NIM',
                      value: _user!.nim!,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (_user!.prodiUnit != null && _user!.prodiUnit!.isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.business_outlined,
                      label: _user!.isStaff ? 'Unit Kerja / Dept' : 'Program Studi',
                      value: _user!.prodiUnit!,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Kontak WhatsApp row (interactive)
                  _buildInfoRow(
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
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: AppColors.accentAmber),
                    title: const Text('Klaim Saya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Pantau status klaim barang temuan', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyClaimsView()),
                      );
                    },
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.accentAmber),
                    title: const Text('Ubah Nomor HP / WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _user!.phone?.isNotEmpty == true ? _user!.phone! : 'Atur nomor kontak aktif',
                      style: const TextStyle(fontSize: 12, color: AppColors.slate400),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
                    onTap: _showEditPhoneDialog,
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: AppColors.accentAmber),
                    title: const Text('Ganti Kata Sandi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Perbarui keamanan kata sandi akun', style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1, color: AppColors.cardBorder),
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
                  const Text(
                    'Laporan Saya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: AppColors.slate400),
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
              const Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'Anda belum membuat laporan apapun.',
                  style: TextStyle(color: AppColors.slate400, fontSize: 13),
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
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${isHilang ? 'Hilang' : 'Temuan'} • ${rep.lokasi}",
                                  style: const TextStyle(fontSize: 12, color: AppColors.slate400),
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
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: badgeColor ?? AppColors.accentAmber),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate400,
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
                color: badgeColor ?? Colors.white,
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
