import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../models/campus_model.dart';

import '../../models/category_model.dart';
import '../../services/report_service.dart';
import '../../services/supabase_service.dart';
import '../auth/login_view.dart';

class CreateReportView extends StatefulWidget {
  final String initialType;
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
        if (camps.isNotEmpty
 && _selectedCampusId == null) {
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
      debugPrint('Error picking image: $e');
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
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: c.amberText),
                title: Text('Ambil dari Kamera', style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              Divider(height: 1, color: c.cardBorder),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: c.tealText),
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

    Uint8List? imageBytes;
    String? imageName;
    if (_pickedXFile != null) {
      try {
        imageBytes = await _pickedXFile!.readAsBytes();
        imageName = _pickedXFile!.name;
      } catch (e) {
        debugPrint('Error reading picked file bytes: $e');
      }
    } else if (_imageFile != null) {
      try {
        imageBytes = await _imageFile!.readAsBytes();
        imageName = _imageFile!.path.split(Platform.pathSeparator).last;
      } catch (e) {
        debugPrint('Error reading image file bytes: $e');
      }
    }

    final res = await ReportService.createReport(
      categoryId: _selectedCategoryId!,
      campusId: _selectedCampusId,
      jenisLaporan: _jenisLaporan,
      namaBarang: _namaController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      lokasi: _lokasiController.text.trim(),
      tanggalKejadian: _tanggalController.text.trim(),
      imageFile: _imageFile ?? _pickedXFile,
      imageBytes: imageBytes,
      imageName: imageName,
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
          icon: Icon(Icons.pending_actions_rounded, color: c.amberText, size: 50),
          title: Text('Laporan Berhasil Diajukan', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700)),
          content: Text(
            'Laporan barang ${_jenisLaporan == "hilang" ? "kehilangan" : "temuan"} Anda telah disimpan dan berstatus "Menunggu Verifikasi".\n\nAdmin akan memeriksa dan memvalidasi keaslian laporan via dashboard website sebelum dipublikasikan ke beranda publik.',
            style: TextStyle(color: c.textSecondary, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('Ke Laporan Saya'),
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
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      );
    }

    if (!SupabaseService.isLoggedIn) {
      return Scaffold(
        backgroundColor: c.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(c),
              Expanded(
                child: Center(
                  child: StateMessage(
                    icon: Icons.lock_outline_rounded,
                    title: 'Masuk untuk membuat laporan',
                    message:
                        'Laporan barang hilang atau temuan hanya bisa dibuat setelah kamu masuk ke akun.',
                    actionLabel: 'Masuk ke Akun',
                    onAction: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginView()),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(c),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _TypeSegment(
                      value: _jenisLaporan,
                      onChanged: (v) => setState(() => _jenisLaporan = v),
                    ),
                    const SizedBox(height: 16),
                    _buildPhotoPicker(c),
                    const _Label('Nama Barang'),
                    TextFormField(
                      controller: _namaController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyMedium(c.inputText),
                      decoration: const InputDecoration(
                        hintText: 'Misal: Kunci Motor Honda, Helm Bogo Hitam...',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Nama barang wajib diisi'
                          : null,
                    ),
                    const _Label('Kategori'),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      isExpanded: true,
                      hint: Text('Pilih kategori barang',
                          style: AppTypography.body(c.inputHint)),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.iconMuted),
                      style: AppTypography.bodyMedium(c.inputText),
                      dropdownColor: c.sheetBg,
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      items: [
                        for (final cat in _categories)
                          DropdownMenuItem(value: cat.id, child: Text(cat.namaKategori)),
                      ],
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                      validator: (val) => val == null ? 'Pilih kategori barang' : null,
                    ),
                    const _Label('Cabang Kampus'),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCampusId,
                      isExpanded: true,
                      hint: Text('Pilih cabang kampus',
                          style: AppTypography.body(c.inputHint)),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.iconMuted),
                      style: AppTypography.bodyMedium(c.inputText),
                      dropdownColor: c.sheetBg,
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      items: [
                        for (final camp in _campuses)
                          DropdownMenuItem(
                            value: camp.id,
                            child: Text(camp.namaKampus, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (val) => setState(() => _selectedCampusId = val),
                      validator: (val) => val == null ? 'Pilih cabang kampus' : null,
                    ),
                    const _Label('Lokasi'),
                    TextFormField(
                      controller: _lokasiController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyMedium(c.inputText),
                      decoration: const InputDecoration(
                        hintText: 'Misal: Area Parkir Motor, Lab Komputer 3...',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Lokasi wajib diisi'
                          : null,
                    ),
                    const _Label('Tanggal Kejadian'),
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: _selectDate,
                      style: AppTypography.bodyMedium(c.inputText),
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                    ),
                    const _Label('Deskripsi'),
                    TextFormField(
                      controller: _deskripsiController,
                      minLines: 3,
                      maxLines: 5,
                      style: AppTypography.bodyMedium(c.inputText),
                      decoration: const InputDecoration(
                        hintText:
                            'Jelaskan ciri detail seperti warna, nomor seri, gantungan kunci, goresan...',
                        hintMaxLines: 3,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Deskripsi wajib diisi untuk memudahkan identifikasi'
                          : null,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.brandOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Kirim Laporan'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(FinditColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text('Buat Laporan Baru',
                  style: AppTypography.titleMedium(c.textPrimary)),
            ),
          ),
          CircleIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Tutup',
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker(FinditColors c) {
    final hasPhoto = _imageFile != null || (_pickedXFile != null && kIsWeb);
    final preview = _imageFile != null
        ? Image.file(_imageFile!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 160,
            semanticLabel: 'Pratinjau foto barang yang dipilih')
        : _pickedXFile != null && kIsWeb
            ? Image.network(_pickedXFile!.path,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 160,
                semanticLabel: 'Pratinjau foto barang yang dipilih')
            : null;

    return Semantics(
      button: true,
      label: hasPhoto
          ? 'Ganti foto barang'
          : 'Unggah foto barang dari kamera atau galeri',
      excludeSemantics: true,
      child: Material(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _showImageSourceDialog,
          child: CustomPaint(
            foregroundPainter: hasPhoto ? null : _DashedBorderPainter(c.cardBorder),
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: preview ??
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined, size: 24, color: c.iconMuted),
                      const SizedBox(height: 8),
                      Text(
                        'Unggah foto barang dari kamera atau galeri',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption(c.textSecondary),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: AppTypography.label(c.textPrimary)),
    );
  }
}

/// Kontrol segmen Hilang / Temuan: track bg/muted, segmen aktif putih.
class _TypeSegment extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    Widget segment(String key, String label) {
      final selected = value == key;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          excludeSemantics: true,
          label: label,
          child: Material(
            color: selected ? c.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.radiusSm + 2),
            elevation: selected ? 1 : 0,
            shadowColor: Colors.black26,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppColors.radiusSm + 2),
              onTap: () => onChanged(key),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    selected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.mutedBg,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
      ),
      child: Row(
        children: [
          segment('hilang', 'Lapor Barang Hilang'),
          segment('temuan', 'Lapor Barang Temuan'),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppColors.radiusLg),
    ).deflate(0.75);
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
