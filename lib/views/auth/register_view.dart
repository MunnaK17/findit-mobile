import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/campus_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../core/constants/prodi_options.dart';
import 'verify_email_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  String _role = 'mahasiswa'; // 'mahasiswa' | 'staff'
  int? _selectedCampusId;
  List<CampusModel> _campuses = [];
  bool _isLoadingCampuses = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _nipController = TextEditingController();
  String? _selectedProdi;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCampuses();
  }

  Future<void> _fetchCampuses() async {
    final list = await ReportService.getCampuses();
    if (mounted) {
      setState(() {
        _campuses = list;
        if (list.isNotEmpty) {
          _selectedCampusId = list.first.id;
        }
        _isLoadingCampuses = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _nipController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCampusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih cabang kampus asal')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmationController.text,
      role: _role,
      nim: _role == 'mahasiswa' && _nimController.text.trim().isNotEmpty
          ? _nimController.text.trim()
          : null,
      nip: _role == 'staff' && _nipController.text.trim().isNotEmpty
          ? _nipController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      idCampus: _selectedCampusId,
      prodiUnit: _selectedProdi,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailView(email: res['email'])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Pendaftaran gagal'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildProdiDropdown() {
    final groups = ProdiOptions.forRole(_role);
    return DropdownButtonFormField<String>(
      key: ValueKey(_role),
      initialValue: _selectedProdi,
      isExpanded: true,
      menuMaxHeight: 360,
      dropdownColor: AppColors.cardBg,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: _role == 'mahasiswa' ? 'Pilih program studi' : 'Pilih unit kerja / prodi',
        prefixIcon: Icon(
          _role == 'mahasiswa' ? Icons.school_outlined : Icons.apartment_outlined,
          color: AppColors.slate400,
        ),
      ),
      items: [
        for (final g in groups.entries)
          for (final p in g.value)
            DropdownMenuItem<String>(
              value: p,
              child: Text(p, overflow: TextOverflow.ellipsis),
            ),
      ],
      onChanged: (val) => setState(() => _selectedProdi = val),
      validator: (val) => val == null ? 'Pilih salah satu' : null,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        elevation: 0,
        title: const Text('Daftar Akun Sivitas UBSI'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Daftarkan diri Anda sebagai Mahasiswa atau Staff/Dosen di seluruh cabang UBSI.',
                  style: TextStyle(fontSize: 13, color: AppColors.slate400),
                ),
                const SizedBox(height: 20),

                // Role Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _role = 'mahasiswa';
                            _selectedProdi = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _role == 'mahasiswa' ? AppColors.accentAmber : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 16,
                                  color: _role == 'mahasiswa' ? AppColors.slate950 : AppColors.slate400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Mahasiswa',
                                  style: TextStyle(
                                    color: _role == 'mahasiswa' ? AppColors.slate950 : AppColors.slate400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _role = 'staff';
                            _selectedProdi = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _role == 'staff' ? AppColors.bsiTeal : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  size: 16,
                                  color: _role == 'staff' ? Colors.white : AppColors.slate400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Staff / Dosen',
                                  style: TextStyle(
                                    color: _role == 'staff' ? Colors.white : AppColors.slate400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Cabang Kampus Utama
                const Text('Cabang Kampus Asal *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 6),
                _isLoadingCampuses
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                    : DropdownButtonFormField<int>(
                        initialValue: _selectedCampusId,
                        dropdownColor: AppColors.cardBg,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.accentAmber),
                        ),
                        items: _campuses.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text("${c.namaKampus} (${c.kota})"),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCampusId = val),
                        validator: (val) => val == null ? 'Pilih cabang kampus asal' : null,
                      ),

                const SizedBox(height: 16),

                // Name
                const Text('Nama Lengkap *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _role == 'mahasiswa' ? 'Misal: Ahmad Fauzi' : 'Misal: Budi Santoso, M.Kom',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.slate400),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                ),

                const SizedBox(height: 16),

                // Email
                const Text('Email BSI (@bsi.ac.id) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'nama@bsi.ac.id',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.slate400),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@\s]+@([a-zA-Z0-9-]+\.)*bsi\.ac\.id$').hasMatch(val.trim())) {
                      return 'Gunakan email resmi BSI (@bsi.ac.id)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // NIM or NIP based on role
                if (_role == 'mahasiswa') ...[
                  const Text('NIM (Nomor Induk Mahasiswa) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nimController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Misal: 19241001',
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.slate400),
                    ),
                    validator: (val) {
                      if (_role == 'mahasiswa' && (val == null || val.trim().isEmpty)) {
                        return 'NIM wajib diisi untuk mahasiswa';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Program Studi *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 6),
                  _buildProdiDropdown(),
                ] else ...[
                  const Text('NIP / NIDN *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nipController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Misal: 0412345678',
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.slate400),
                    ),
                    validator: (val) {
                      if (_role == 'staff' && (val == null || val.trim().isEmpty)) {
                        return 'NIP/NIDN wajib diisi untuk Staff/Dosen';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Unit Kerja / Prodi *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 6),
                  _buildProdiDropdown(),
                ],

                const SizedBox(height: 16),

                // Phone
                const Text('Nomor WhatsApp / HP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Misal: 081234567890',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.slate400),
                  ),
                ),

                const SizedBox(height: 16),

                // Password
                const Text('Kata Sandi *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Minimal 8 karakter',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.slate400),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.slate400,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 8) return 'Kata sandi minimal 8 karakter';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Confirmation
                const Text('Konfirmasi Kata Sandi *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordConfirmationController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Ulangi kata sandi',
                    prefixIcon: Icon(Icons.lock_reset_outlined, color: AppColors.slate400),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) return 'Konfirmasi kata sandi tidak cocok';
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _role == 'mahasiswa' ? AppColors.accentAmber : AppColors.bsiTeal,
                    foregroundColor: _role == 'mahasiswa' ? AppColors.slate950 : Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _role == 'mahasiswa' ? AppColors.slate950 : Colors.white,
                          ),
                        )
                      : Text('Daftar Sebagai ${_role == 'mahasiswa' ? 'Mahasiswa' : 'Staff / Dosen'}'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
