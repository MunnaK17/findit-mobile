import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../claims/create_claim_view.dart';

class ReportDetailView extends StatefulWidget {
  final ReportModel report;

  const ReportDetailView({super.key, required this.report});

  @override
  State<ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends State<ReportDetailView> {
  late ReportModel _report;
  bool _isOwnerOrAdmin = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isOwnerOrAdmin = user != null &&
            (user.isAdmin || (user.id == _report.idUser));
      });
    }
  }

  Future<void> _launchWhatsApp(String phone, String itemName) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('62')) {
      cleanPhone = '62$cleanPhone';
    }

    final message = Uri.encodeComponent(
      'Halo, saya melihat laporan di aplikasi FindIT terkait barang: *$itemName*. Apakah barang tersebut masih ada / sudah bisa dikoordinasikan?',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka WhatsApp'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka WhatsApp: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: _report.namaBarang);
    final descController = TextEditingController(text: _report.deskripsi);
    final locController = TextEditingController(text: _report.lokasi);
    final dateController = TextEditingController(text: _report.tanggalKejadian);
    final formKey = GlobalKey<FormState>();

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
                    Text(
                      'Edit Laporan Barang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      style: TextStyle(color: cs.inputText, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        filled: true,
                        fillColor: cs.inputFill,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama barang wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locController,
                      style: TextStyle(color: cs.inputText, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Lokasi',
                        filled: true,
                        fillColor: cs.inputFill,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      style: TextStyle(color: cs.inputText, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Deskripsi / Ciri Khusus',
                        filled: true,
                        fillColor: cs.inputFill,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: cs.cardBorder),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Batal', style: TextStyle(color: cs.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(ctx);
                              final res = await ReportService.updateReport(
                                id: _report.id,
                                namaBarang: titleController.text.trim(),
                                deskripsi: descController.text.trim(),
                                lokasi: locController.text.trim(),
                                tanggalKejadian: dateController.text.trim(),
                                categoryId: _report.idCategory,
                                campusId: _report.idCampus,
                              );
                              if (!mounted) return;
                              if (res['success'] == true) {
                                setState(() {
                                  _report = ReportModel(
                                    id: _report.id,
                                    idUser: _report.idUser,
                                    idCategory: _report.idCategory,
                                    idCampus: _report.idCampus,
                                    namaBarang: titleController.text.trim(),
                                    deskripsi: descController.text.trim(),
                                    lokasi: locController.text.trim(),
                                    tanggalKejadian: dateController.text.trim(),
                                    fotoBarang: _report.fotoBarang,
                                    status: _report.status,
                                    jenisLaporan: _report.jenisLaporan,
                                    campus: _report.campus,
                                    category: _report.category,
                                    user: _report.user,
                                    createdAt: _report.createdAt,
                                  );
                                });
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Laporan berhasil diperbarui'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Gagal memperbarui'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentAmber,
                              foregroundColor: AppColors.slate950,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Future<void> _handleMarkCompleted() async {
    final c = FinditColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        title: Text('Konfirmasi Selesai', style: TextStyle(color: c.textPrimary)),
        content: Text(
          'Tandai barang ini telah berhasil dikembalikan ke pemilik aslinya?',
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
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tandai Selesai'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final res = await ReportService.markReportCompleted(_report.id);
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _report = ReportModel(
            id: _report.id,
            idUser: _report.idUser,
            idCategory: _report.idCategory,
            idCampus: _report.idCampus,
            namaBarang: _report.namaBarang,
            deskripsi: _report.deskripsi,
            lokasi: _report.lokasi,
            tanggalKejadian: _report.tanggalKejadian,
            fotoBarang: _report.fotoBarang,
            status: 'completed',
            jenisLaporan: _report.jenisLaporan,
            campus: _report.campus,
            category: _report.category,
            user: _report.user,
            createdAt: _report.createdAt,
          );
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diubah menjadi Selesai / Dikembalikan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final c = FinditColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.sheetBg,
        title: Text('Hapus Laporan', style: TextStyle(color: c.textPrimary)),
        content: Text(
          'Apakah Anda yakin ingin menghapus laporan ini secara permanen?',
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final res = await ReportService.deleteReport(_report.id);
      if (!mounted) return;
      if (res['success'] == true) {
        navigator.pop(true);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final isHilang = _report.isHilang;
    final badgeText = isHilang ? c.amberText : c.tealText;
    final badgeBg = isHilang ? c.amberBg : c.tealBg;
    final statusText = c.statusTextColor(_report.status);
    final statusBg = c.statusBgColor(_report.status);
    final contactPhone = _report.user?.phone;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        title: Text(_report.namaBarang, style: TextStyle(color: c.textPrimary)),
        actions: [
          if (_isOwnerOrAdmin)
            PopupMenuButton<String>(
              tooltip: 'Opsi laporan',
              icon: Icon(Icons.more_vert_rounded, color: c.textPrimary),
              color: c.sheetBg,
              onSelected: (val) {
                if (val == 'edit') _showEditDialog();
                if (val == 'complete') _handleMarkCompleted();
                if (val == 'delete') _handleDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: c.textPrimary),
                      const SizedBox(width: 8),
                      Text('Edit Laporan', style: TextStyle(color: c.textPrimary)),
                    ],
                  ),
                ),
                if (_report.status != 'completed')
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: c.successText),
                        const SizedBox(width: 8),
                        Text('Tandai Selesai', style: TextStyle(color: c.successText)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: c.dangerText),
                      const SizedBox(width: 8),
                      Text('Hapus Laporan', style: TextStyle(color: c.dangerText)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_report.fullFotoUrl != null)
              Image.network(
                _report.fullFotoUrl!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: 'Foto barang ${_report.namaBarang}',
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: c.cardBgLight,
                  child: Center(
                    child: Icon(Icons.broken_image, size: 60, color: c.textMuted),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                color: c.cardBgLight,
                child: Center(
                  child: Icon(
                    isHilang ? Icons.warning_amber_rounded : Icons.search_rounded,
                    size: 72,
                    color: badgeText.withValues(alpha: 0.5),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeText.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          isHilang ? 'Barang Hilang' : 'Barang Temuan',
                          style: TextStyle(
                            color: badgeText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(_report.status),
                          style: TextStyle(
                            color: statusText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _report.namaBarang,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Column(
                      children: [
                        if (_report.campus != null) ...[
                          _buildInfoTile(
                            c: c,
                            icon: Icons.domain_rounded,
                            label: 'Cabang Kampus',
                            value: '${_report.campus!.namaKampus} (${_report.campus!.kota})',
                          ),
                          Divider(height: 16, color: c.cardBorder),
                        ],
                        _buildInfoTile(
                          c: c,
                          icon: Icons.category_outlined,
                          label: 'Kategori',
                          value: _report.category?.namaKategori ?? 'Umum',
                        ),
                        Divider(height: 16, color: c.cardBorder),
                        _buildInfoTile(
                          c: c,
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal Kejadian',
                          value: _report.tanggalKejadian,
                        ),
                        Divider(height: 16, color: c.cardBorder),
                        _buildInfoTile(
                          c: c,
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: _report.lokasi,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Deskripsi / Ciri Khusus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Text(
                      _report.deskripsi.isNotEmpty
                          ? _report.deskripsi
                          : 'Tidak ada deskripsi tambahan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (_report.user != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Informasi Pelapor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: c.mintBg,
                                child: Icon(Icons.person, color: c.mintText),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _report.user!.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: c.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _report.user!.isStaff ? c.tealBg : c.amberBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _report.user!.roleLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: _report.user!.isStaff ? c.tealText : c.amberText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_report.user!.nip != null && _report.user!.nip!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'NIP: ${_report.user!.nip}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.textMuted,
                                        ),
                                      ),
                                    ] else if (_report.user!.nim != null && _report.user!.nim!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'NIM: ${_report.user!.nim}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (contactPhone != null && contactPhone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Divider(height: 1, color: c.cardBorder),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _launchWhatsApp(contactPhone, _report.namaBarang),
                                icon: const Icon(Icons.chat_rounded, color: AppColors.slate950, size: 18),
                                label: const Text('Hubungi via WhatsApp (Pelapor)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusReturned,
                                  foregroundColor: AppColors.slate950,
                                  minimumSize: const Size.fromHeight(48),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_report.canBeClaimed) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateClaimView(report: _report),
                          ),
                        );
                      },
                      icon: const Icon(Icons.verified_user_rounded, color: AppColors.slate950),
                      label: const Text('Klaim Barang Ini'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentAmber,
                        foregroundColor: AppColors.slate950,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_isOwnerOrAdmin && _report.status != 'completed') ...[
                    OutlinedButton.icon(
                      onPressed: _handleMarkCompleted,
                      icon: Icon(Icons.check_circle_outline, color: c.successText),
                      label: const Text('Tandai Barang Berhasil Kembali ke Pemilik'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.successText,
                        side: BorderSide(color: c.successText),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required FinditColors c,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.amberText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Terverifikasi';
      case 'completed':
        return 'Selesai / Dikembalikan';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Verifikasi';
    }
  }
}
