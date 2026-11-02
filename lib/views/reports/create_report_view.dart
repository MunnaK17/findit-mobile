import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../models/campus_model.dart';
import '../../models/category_model.dart';
import '../../services/report_service.dart';

class CreateReportView extends StatefulWidget {
  final String initialType; // 'hilang' | 'temuan'
  final int? initialCampusId;

  const CreateReportView({
    super.key,
    this.initialType = 'hilang',
    this.initialCampusId,
  });

  @override
  State<CreateReportView> createState() => _CreateReportViewState();
}

class _CreateReportViewState extends State<CreateReportView> {
  final _formKey = GlobalKey<FormState>();

  late String _jenisLaporan;
  int? _selectedCategoryId;
  int? _selectedCampusId;
  List<CategoryModel> _categories = [];
  List<CampusModel> _campuses = [];

  final _namaController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _tanggalController = TextEditingController();

  File? _imageFile;
  XFile? _pickedXFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _jenisLaporan = widget.initialType;
    _selectedCampusId = widget.initialCampusId;
    _tanggalController.text = DateTime.now().toString().split(' ')[0];
    _fetchInitialData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoadingData = true);
    final results = await Future.wait([
      ReportService.getCategories(),
      ReportService.getCampuses(),
    ]);

    if (mounted) {
      final cats = results[0] as List<CategoryModel>;
      final camps = results[1] as List<CampusModel>;
      setState(() {
        _categories = cats;
        _campuses = camps;
        if (cats.isNotEmpty && _selectedCategoryId == null) {
          _selectedCategoryId = cats.first.id;
        }
        if (camps.isNotEmpty && _selectedCampusId == null) {
          _selectedCampusId = camps.first.id;
        }
        _isLoadingData = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _pickedXFile = picked;
          if (!kIsWeb) {
            _imageFile = File(picked.path);
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceDialog() {
    final c = FinditColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Unggah Foto Barang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accentAmber),
                title: Text('Ambil dari Kamera', style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              Divider(height: 1, color: c.cardBorder),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.accentBlue),
                title: Text('Pilih dari Galeri', style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final c = FinditColors.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accentAmber,
              brightness: c.isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori barang terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final res = await ReportService.createReport(
      categoryId: _selectedCategoryId!,
      campusId: _selectedCampusId,
      jenisLaporan: _jenisLaporan,
      namaBarang: _namaController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      tanggalKejadian: _tanggalController.text.trim(),
      imageFile: _imageFile,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (res['success'] == true) {
      final c = FinditColors.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: c.sheetBg,
          icon: const Icon(Icons.check_circle_outline, color: AppColors.accentEmerald, size: 50),
          title: Text('Laporan Berhasil Dibuat!', style: TextStyle(color: c.textPrimary)),
          content: Text(
            'Laporan barang ${_jenisLaporan == "hilang" ? "kehilangan" : "temuan"} Anda telah disimpan dan langsung aktif di daftar laporan kampus.',
            style: TextStyle(color: c.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('Lihat Laporan'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal membuat laporan'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: c.scaffoldBg,
        body: const Center(child: CircularProgressIndicator(color: AppColors.accentAmber)),
      );
    }

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        title: Text('Buat Laporan Baru', style: TextStyle(color: c.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle Hilang vs Temuan
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _jenisLaporan = 'hilang'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _jenisLaporan == 'hilang'
                                ? AppColors.accentAmber
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Barang Hilang',
                            style: TextStyle(
                              color: _jenisLaporan == 'hilang'
                                  ? AppColors.slate950
                                  : c.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _jenisLaporan = 'temuan'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _jenisLaporan == 'temuan'
                                ? AppColors.accentBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Barang Temuan',
                            style: TextStyle(
                              color: _jenisLaporan == 'temuan'
                                  ? Colors.white
                                  : c.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Image upload preview box
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.cardBorder,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : _pickedXFile != null && kIsWeb
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(_pickedXFile!.path, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: c.cardBgLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add_a_photo_outlined, size: 28, color: c.textMuted),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Unggah Foto Barang (Opsional)',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format JPG/PNG maks. 5MB',
                                  style: TextStyle(color: c.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 20),

              // Nama Barang
              TextFormField(
                controller: _namaController,
                style: TextStyle(color: c.inputText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nama Barang *',
                  hintText: 'Misal: Kunci Motor Honda, Helm Bogo Hitam...',
                  prefixIcon: const Icon(Icons.label_outline, color: AppColors.accentAmber),
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama barang wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Cabang Kampus Dropdown
              DropdownButtonFormField<int>(
                value: _selectedCampusId,
                dropdownColor: c.sheetBg,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Cabang Kampus UBSI *',
                  prefixIcon: const Icon(Icons.apartment_rounded, color: AppColors.bsiTeal),
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                ),
                items: _campuses.map((camp) {
                  return DropdownMenuItem<int>(
                    value: camp.id,
                    child: Text(camp.namaKampus, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCampusId = val),
                validator: (val) => val == null ? 'Pilih cabang kampus' : null,
              ),

              const SizedBox(height: 16),

              // Kategori Dropdown
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                dropdownColor: c.sheetBg,
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Kategori Barang *',
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.accentAmber),
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.namaKategori),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),

              const SizedBox(height: 16),

              // Lokasi Spesifik
              TextFormField(
                controller: _lokasiController,
                style: TextStyle(color: c.inputText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Lokasi Spesifik *',
                  hintText: 'Misal: Area Parkir Motor, Lab Komputer 3, Kantin...',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.accentAmber),
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lokasi spesifik wajib diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Tanggal Kejadian
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                onTap: _selectDate,
                style: TextStyle(color: c.inputText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Tanggal Kejadian *',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.accentAmber),
                  suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.slate400),
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                ),
              ),

              const SizedBox(height: 16),

              // Deskripsi / Ciri Khusus
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                style: TextStyle(color: c.inputText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Deskripsi / Ciri Khusus *',
                  hintText: 'Jelaskan ciri detail seperti warna, nomor seri, gantungan kunci, goresan...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.inputBorder)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Deskripsi wajib diisi untuk memudahkan identifikasi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // Tombol Submit
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: AppColors.slate950,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: AppColors.slate950, strokeWidth: 2),
                      )
                    : Text(
                        "Kirim Laporan ${_jenisLaporan == 'hilang' ? 'Kehilangan' : 'Temuan'}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
