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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentAmber,
              onPrimary: AppColors.slate950,
              surface: AppColors.cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori barang')),
      );
      return;
    }
    if (_selectedCampusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih cabang kampus UBSI')),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          icon: const Icon(Icons.check_circle_outline, color: AppColors.accentEmerald, size: 50),
          title: const Text('Laporan Berhasil Dibuat!', style: TextStyle(color: Colors.white)),
          content: Text(
            _jenisLaporan == 'hilang'
                ? 'Laporan barang hilang Anda telah berhasil dipublikasikan. Anda akan menerima notifikasi jika ada yang menemukan atau mengklaim.'
                : 'Terima kasih atas kejujuran Anda! Laporan temuan barang telah dicatat dan menunggu pemilik yang sah mengklaim.',
            style: const TextStyle(color: AppColors.slate300),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context, true); // return to home with success
              },
              child: const Text('Kembali ke Beranda'),
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
    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        elevation: 0,
        title: Text(_jenisLaporan == 'hilang' ? 'Lapor Barang Hilang' : 'Lapor Barang Temuan'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentAmber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toggle Jenis Laporan
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
                              onTap: () => setState(() => _jenisLaporan = 'hilang'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _jenisLaporan == 'hilang' ? AppColors.accentAmber : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Barang Hilang',
                                  style: TextStyle(
                                    color: _jenisLaporan == 'hilang' ? AppColors.slate950 : AppColors.slate400,
                                    fontWeight: FontWeight.bold,
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
                                  color: _jenisLaporan == 'temuan' ? AppColors.accentBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Barang Temuan',
                                  style: TextStyle(
                                    color: _jenisLaporan == 'temuan' ? Colors.white : AppColors.slate400,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Cabang Kampus UBSI
                    const Text('Cabang Kampus UBSI *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
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
                      validator: (val) => val == null ? 'Pilih cabang kampus' : null,
                    ),

                    const SizedBox(height: 18),

                    // Nama Barang
                    const Text('Nama Barang *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Misal: Kunci Motor Honda, Laptop Asus Vivobook',
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Nama barang wajib diisi' : null,
                    ),

                    const SizedBox(height: 18),

                    // Kategori
                    const Text('Kategori *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      dropdownColor: AppColors.cardBg,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(),
                      items: _categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.namaKategori),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),

                    const SizedBox(height: 18),

                    // Tanggal Kejadian
                    const Text('Tanggal Kejadian *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: _selectDate,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.calendar_month_outlined, color: AppColors.slate400),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Lokasi Spesifik
                    const Text('Lokasi Spesifik / Ruangan *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lokasiController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Misal: Lab Komputer 3 Lt. 2, Kantin Depan, Parkiran Motor',
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Lokasi spesifik wajib diisi' : null,
                    ),

                    const SizedBox(height: 18),

                    // Deskripsi
                    const Text('Deskripsi & Ciri-Ciri *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Jelaskan warna, stiker, gantungan, merk, kondisi, dll.',
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),

                    const SizedBox(height: 20),

                    // Foto Barang
                    const Text('Foto Barang (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),

                    if (_pickedXFile != null)
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: kIsWeb
                                  ? Image.network(_pickedXFile!.path, fit: BoxFit.cover)
                                  : Image.file(_imageFile!, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _pickedXFile = null;
                                    _imageFile = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.accentAmber),
                              label: const Text('Kamera', style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.cardBorder),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined, color: AppColors.accentAmber),
                              label: const Text('Galeri', style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.cardBorder),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 32),

                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _jenisLaporan == 'hilang' ? AppColors.accentAmber : AppColors.accentBlue,
                        foregroundColor: _jenisLaporan == 'hilang' ? AppColors.slate950 : Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _jenisLaporan == 'hilang' ? AppColors.slate950 : Colors.white,
                              ),
                            )
                          : Text('Publikasikan Laporan ${_jenisLaporan == 'hilang' ? 'Kehilangan' : 'Temuan'}'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
