import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import '../claims/my_claims_view.dart';
import '../notifications/notification_bell.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserModel? _user;
  bool _isLoading = true;

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
                                'Ubah Nomor Telepon',
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
                        labelText: 'Nomor Telepon',
                        hintText: 'Contoh: 085891565501',
                        prefixIcon: Icon(Icons.phone_outlined, color: cs.amberText),
                        filled: true,
                        fillColor: cs.inputFill,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        final clean = val.trim();
                        if (clean.length < 8) {
                          return 'Nomor telepon minimal 8 karakter';
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
                                          content: Text('Nomor telepon berhasil diperbarui'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      _loadProfile();
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'Gagal memperbarui nomor telepon'),
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
                                    'Simpan Nomor Telepon',
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
    // Header gelap (navy) dengan lembar menu membulat di atasnya.
    final headerColor = c.isDark ? AppColors.bgHeader : AppColors.textPrimaryLight;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: c.scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      );
    }

    final user = _user;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.scaffoldBg,
        // Separuh atas gelap agar tarikan ke bawah di bagian atas tetap menyatu dengan header;
        // separuh bawah sewarna lembar menu sehingga tidak ada strip gelap di bawah isi yang pendek.
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [headerColor, headerColor, c.scaffoldBg, c.scaffoldBg],
              stops: const [0, 0.5, 0.5, 1],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeader(headerColor, user),
              Container(
                decoration: BoxDecoration(
                  color: c.scaffoldBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppColors.radiusXl),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: user == null ? _guestMenu(c) : _userMenu(c, user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color headerColor, UserModel? user) {
    const onHeader = Colors.white;
    final initial = (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : null;
    return Container(
      color: headerColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 44),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Profil',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleSmall(onHeader).copyWith(fontSize: 17),
                      ),
                    ),
                  ),
                  // Lonceng hanya muncul untuk pengguna login; tetap pertahankan lebarnya.
                  SizedBox(
                    width: 44,
                    child: user == null ? null : const NotificationBell(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: user == null ? Colors.white.withValues(alpha: 0.12) : AppColors.mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.24), width: 3),
                ),
                alignment: Alignment.center,
                child: initial == null
                    ? const Icon(Icons.person_outline_rounded, size: 40, color: onHeader)
                    : Text(
                        initial,
                        style: AppTypography.titleLarge(AppColors.brandOnPrimary),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'Tamu',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium(onHeader),
              ),
              const SizedBox(height: 4),
              Text(
                user == null ? 'Belum masuk ke akun' : '${user.email} · ${user.roleLabel}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(Colors.white.withValues(alpha: 0.72)),
              ),
              if (user == null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  ),
                  child: const Text('Masuk ke Akun'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _guestMenu(FinditColors c) => [
        _MenuGroup(children: [
          _MenuRow(
            icon: Icons.help_outline_rounded,
            label: 'Pusat Bantuan & Cara Kerja',
            onTap: _showHelpCenterSheet,
          ),
          _buildThemeRow(c),
        ]),
        const SizedBox(height: 24),
        const Center(child: PoweredByFindit()),
      ];

  List<Widget> _userMenu(FinditColors c, UserModel user) => [
        _MenuGroup(children: [
          _MenuRow(
            icon: Icons.badge_outlined,
            label: 'Data Diri',
            onTap: () => _showPersonalDataSheet(user),
          ),
        ]),
        const SizedBox(height: 16),
        _MenuGroup(children: [
          _MenuRow(
            icon: Icons.inventory_2_outlined,
            label: 'Klaim Saya',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyClaimsView()),
            ),
          ),
          _MenuRow(
            icon: Icons.phone_outlined,
            label: 'Ubah Nomor Telepon',
            onTap: _showEditPhoneDialog,
          ),
          _MenuRow(
            icon: Icons.lock_outline_rounded,
            label: 'Ganti Kata Sandi',
            onTap: _showChangePasswordDialog,
          ),
        ]),
        const SizedBox(height: 16),
        _MenuGroup(children: [
          _buildEmailNotifRow(c, user),
          _buildThemeRow(c),
          _MenuRow(
            icon: Icons.help_outline_rounded,
            label: 'Pusat Bantuan & Cara Kerja',
            onTap: _showHelpCenterSheet,
          ),
        ]),
        const SizedBox(height: 16),
        _MenuGroup(children: [
          _MenuRow(
            icon: Icons.logout_rounded,
            label: 'Keluar',
            onTap: _handleLogout,
            danger: true,
          ),
        ]),
        const SizedBox(height: 24),
        const Center(child: PoweredByFindit()),
      ];

  bool? _emailNotif;
  bool _savingEmailNotif = false;

  /// Email dikirim ke email login saat laporan/klaim disetujui, ditolak, atau selesai.
  Widget _buildEmailNotifRow(FinditColors c, UserModel user) {
    final enabled = _emailNotif ?? user.emailNotifications;
    Future<void> toggle(bool value) async {
      if (_savingEmailNotif) return;
      setState(() {
        _emailNotif = value;
        _savingEmailNotif = true;
      });
      final res = await AuthService.updateEmailNotifications(value);
      if (!mounted) return;
      setState(() {
        _savingEmailNotif = false;
        if (res['success'] != true) _emailNotif = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? (value ? 'Notifikasi email diaktifkan' : 'Notifikasi email dimatikan')
              : (res['message'] ?? 'Gagal menyimpan pengaturan')),
        ),
      );
    }

    return _MenuRow(
      icon: Icons.mark_email_unread_outlined,
      label: 'Notifikasi Email',
      onTap: () => toggle(!enabled),
      trailing: Switch(
        value: enabled,
        activeThumbColor: AppColors.brandPrimary,
        onChanged: _savingEmailNotif ? null : toggle,
      ),
    );
  }

  /// Mode gelap tetap tersedia sebagai pilihan; default aplikasi kini terang.
  Widget _buildThemeRow(FinditColors c) {
    final themeProvider = context.themeProvider;
    return _MenuRow(
      icon: c.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      label: 'Mode Gelap',
      onTap: () => themeProvider.setDarkMode(!c.isDark),
      trailing: Switch(
        value: c.isDark,
        activeThumbColor: AppColors.brandPrimary,
        onChanged: themeProvider.setDarkMode,
      ),
    );
  }

  /// Data pribadi hanya tampil saat pengguna membukanya sendiri.
  void _showPersonalDataSheet(UserModel user) {
    final hasNip = user.nip?.isNotEmpty ?? false;
    final hasNim = user.nim?.isNotEmpty ?? false;
    final hasProdi = user.prodiUnit?.isNotEmpty ?? false;
    final hasPhone = user.phone?.isNotEmpty ?? false;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final c = FinditColors.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Data Diri', style: AppTypography.titleMedium(c.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Hanya terlihat olehmu.',
                  style: AppTypography.body(c.textSecondary),
                ),
                const SizedBox(height: 8),
                _ProfileRow(label: 'Email', value: user.email),
                if (hasNip)
                  _ProfileRow(label: 'NIP / NIDN', value: user.nip!)
                else if (hasNim)
                  _ProfileRow(label: 'NIM', value: user.nim!),
                if (hasProdi)
                  _ProfileRow(
                    label: user.isStaff ? 'Unit Kerja' : 'Program Studi',
                    value: user.prodiUnit!,
                  ),
                if (user.campus != null)
                  _ProfileRow(label: 'Cabang Kampus', value: user.campus!.namaKampus),
                _ProfileRow(
                  label: 'Nomor Telepon',
                  value: hasPhone ? user.phone! : 'Belum diatur',
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showEditPhoneDialog();
                  },
                  child: Text(hasPhone ? 'Ubah Nomor Telepon' : 'Atur Nomor Telepon'),
                ),
              ],
            ),
          ),
        );
      },
    );
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

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.cardBorder)),
      ),
      child: Row(
        children: [
          Text(label, style: AppTypography.body(c.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium(c.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pengelompok menu (bg/subtle, sudut 16).
class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Material(
      color: c.isDark ? c.cardBg : AppColors.bgSubtle,
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

/// Satu baris menu: ikon dalam lingkaran, label, lalu chevron atau [trailing] (mis. switch).
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final fg = danger ? c.dangerText : c.textPrimary;
    return Semantics(
      button: trailing == null,
      label: label,
      excludeSemantics: trailing == null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: danger ? c.dangerBg : c.cardBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: danger ? c.dangerText : c.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: AppTypography.bodyMedium(fg)),
                ),
                trailing ??
                    Icon(Icons.chevron_right_rounded,
                        color: danger ? c.dangerText : c.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
