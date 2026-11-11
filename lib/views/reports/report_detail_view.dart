import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../models/report_model.dart';

import '../../services/auth_service.dart';
import '../../services/claim_service.dart';
import '../../services/report_service.dart';
import '../claims/create_claim_view.dart';
import 'photo_viewer_view.dart';

class ReportDetailView extends StatefulWidget {
  final ReportModel report;

  const ReportDetailView({super.key, required this.report});

  @override
  State<ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends State<ReportDetailView> {
  late ReportModel _report;
  bool _isOwnerOrAdmin = false;
  bool _isAdmin = false;
  bool _hasClaimed = false;
  bool _isOwner = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final user = await AuthService.getCurrentUser();
    bool claimed = false;
    if (user != null && _report.canBeClaimed) {
      claimed = await ClaimService.hasClaimed(_report.id);
    }
    if (mounted) {
      setState(() {
        _isOwnerOrAdmin = user != null &&
            (user.isAdmin || (user.id == _report.idUser));
        _isAdmin = user?.isAdmin ?? false;
        _isOwner = user != null && user.id == _report.idUser;
        _hasClaimed = claimed;
      });
    }
  }

  void _showEditDialog() {
    final titleController = TextEditingController(text: _report.namaBarang);
    final descController = TextEditingController(text: _report.deskripsi);
    final locController = TextEditingController(text: _report.lokasi);
    final formKey = GlobalKey<FormState>();
    // Isi laporan publik yang diubah pemiliknya harus diverifikasi ulang oleh admin.
    final requireReverification = !_isAdmin && _report.status == 'approved';
    Uint8List? newPhoto;
    String? newPhotoName;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final cs = FinditColors.of(context);

          Future<void> pickPhoto(ImageSource source) async {
            try {
              final picked = await ImagePicker().pickImage(
                source: source,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
              );
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              setModalState(() {
                newPhoto = bytes;
                newPhotoName = picked.name;
              });
            } catch (e) {
              debugPrint('Error picking image: $e');
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setModalState(() => saving = true);
            final messenger = ScaffoldMessenger.of(this.context);
            final res = await ReportService.updateReport(
              id: _report.id,
              namaBarang: titleController.text.trim(),
              deskripsi: descController.text.trim(),
              lokasi: locController.text.trim(),
              tanggalKejadian: _report.tanggalKejadian,
              categoryId: _report.idCategory,
              campusId: _report.idCampus,
              requireReverification: requireReverification,
              newPhotoBytes: newPhoto,
              newPhotoName: newPhotoName,
              oldPhotoUrl: _report.fullFotoUrl,
            );
            if (!mounted) return;
            if (res['success'] != true) {
              setModalState(() => saving = false);
              messenger.showSnackBar(SnackBar(
                content: Text(res['message'] ?? 'Gagal memperbarui'),
                backgroundColor: AppColors.danger,
              ));
              return;
            }
            if (ctx.mounted) Navigator.pop(ctx);
            setState(() {
              _report = _report.copyWith(
                namaBarang: titleController.text.trim(),
                deskripsi: descController.text.trim(),
                lokasi: locController.text.trim(),
                fotoBarang: res['foto_barang'] as String?,
                status: requireReverification ? 'pending' : null,
              );
            });
            messenger.showSnackBar(SnackBar(
              content: Text(requireReverification
                  ? 'Laporan diperbarui dan menunggu verifikasi admin'
                  : 'Laporan berhasil diperbarui'),
            ));
          }

          final currentUrl = _report.fullFotoUrl;
          final Widget photo = newPhoto != null
              ? Image.memory(newPhoto!,
                  width: 96, height: 96, fit: BoxFit.cover, semanticLabel: 'Foto baru')
              : ReportThumb(url: currentUrl, semanticLabel: 'Foto saat ini', size: 96);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Edit Laporan', style: AppTypography.titleMedium(cs.textPrimary)),
                    if (requireReverification) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Setelah disimpan, laporan kembali menunggu verifikasi admin dan tidak tampil di daftar publik sampai disetujui.',
                        style: AppTypography.caption(cs.textSecondary).copyWith(height: 1.45),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppColors.radiusMd),
                          child: photo,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: saving ? null : () => pickPhoto(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                                label: const Text('Kamera'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: saving ? null : () => pickPhoto(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined, size: 18),
                                label: Text(currentUrl == null && newPhoto == null
                                    ? 'Tambah foto'
                                    : 'Ganti dari galeri'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      style: AppTypography.bodyMedium(cs.inputText),
                      decoration: const InputDecoration(labelText: 'Nama Barang'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nama barang wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: locController,
                      style: AppTypography.bodyMedium(cs.inputText),
                      decoration: const InputDecoration(labelText: 'Lokasi'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descController,
                      minLines: 3,
                      maxLines: 5,
                      style: AppTypography.bodyMedium(cs.inputText),
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi / Ciri Khusus',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: saving ? null : save,
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.brandOnPrimary),
                                  )
                                : const Text('Simpan Perubahan'),
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

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      text: buildShareText(_report),
      subject: '${_report.isHilang ? 'Barang hilang' : 'Barang temuan'}: ${_report.namaBarang}',
      sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  Future<void> _markFound() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Barang sudah ketemu?'),
        content: const Text(
            'Laporan akan ditandai selesai dan tidak lagi muncul sebagai barang hilang. Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, sudah ketemu'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    final res = await ReportService.markReportCompleted(_report.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) _report = _report.copyWith(status: 'completed');
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true
          ? 'Syukurlah! Laporan ditandai selesai.'
          : (res['message'] ?? 'Gagal menandai laporan')),
    ));
  }

  Future<void> _extend() async {
    setState(() => _busy = true);
    final res = await ReportService.extendReport(_report.id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res['success'] == true) {
        _report = _report.copyWith(expiresAt: res['expires_at'] as DateTime);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['success'] == true
          ? 'Laporan diperpanjang sampai ${_formatDay(_report.expiresAt!)}'
          : (res['message'] ?? 'Gagal memperpanjang laporan')),
    ));
  }

  /// Aksi khusus pemilik laporan terverifikasi: masa tayang dan tombol "Barang sudah ketemu".
  List<Widget> _buildOwnerActions(FinditColors c) {
    if (!_isOwner || _report.status != 'approved' || _report.expiresAt == null) return const [];
    final expired = _report.isExpired;
    final days = _report.daysUntilExpiry ?? 0;
    final until = _formatDay(_report.expiresAt!);
    return [
      if (expired)
        _Notice(
          icon: Icons.history_toggle_off_rounded,
          title: 'Laporan sudah kedaluwarsa',
          message: 'Sejak $until laporan ini tidak tampil di daftar publik. Perpanjang bila barang masih dicari.',
          background: c.dangerBg,
          accent: c.dangerText,
        )
      else if (days <= 7)
        _Notice(
          icon: Icons.schedule_rounded,
          title: 'Masa tayang hampir habis',
          message: 'Laporan tampil di daftar publik sampai $until.',
          background: c.amberBg,
          accent: c.amberText,
        )
      else
        _InfoRow(label: 'Tayang sampai', value: until),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _extend,
              icon: const Icon(Icons.update_rounded, size: 18),
              label: const Text('Perpanjang 30 hari'),
            ),
          ),
          if (_report.isHilang) ...[
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _markFound,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Sudah ketemu'),
              ),
            ),
          ],
        ],
      ),
    ];
  }

  String _formatDay(DateTime d) => _formatDate(d.toIso8601String());

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
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menghapus laporan'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _openClaim() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateClaimView(report: _report)),
    );
    if (result == true) _checkOwnership();
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final showClaim = _report.canBeClaimed && !_isOwnerOrAdmin;
    final canManage = _isOwnerOrAdmin && _report.status != 'completed';

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        bottom: !showClaim,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Kembali',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const Spacer(),
                      if (_report.status == 'approved' || _report.status == 'completed')
                        Builder(
                          builder: (btnContext) => CircleIconButton(
                            icon: Icons.share_outlined,
                            tooltip: 'Bagikan laporan',
                            onPressed: () => _share(btnContext),
                          ),
                        ),
                      if (canManage) ...[
                        const SizedBox(width: 8),
                        _buildManageMenu(c),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPhoto(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      StatusBadge(
                        kind: badgeKindFor(
                          isHilang: _report.isHilang,
                          status: _report.status,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '· ${_report.relativeTime}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(c.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      _report.namaBarang,
                      style: AppTypography.titleLarge(c.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _report.deskripsi.isNotEmpty
                        ? _report.deskripsi
                        : 'Tidak ada deskripsi tambahan.',
                    style: AppTypography.body(c.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (_report.status != 'approved' && _report.status != 'completed')
                    _InfoRow(
                      label: 'Status',
                      value: FinditColors.statusLabel(_report.status),
                      valueColor: c.statusTextColor(_report.status),
                    ),
                  _InfoRow(label: 'Lokasi', value: _report.lokasi),
                  _InfoRow(label: 'Tanggal Kejadian', value: _formatDate(_report.tanggalKejadian)),
                  _InfoRow(
                    label: 'Kategori',
                    value: _report.category?.namaKategori ?? 'Umum',
                  ),
                  if (_report.campus != null)
                    _InfoRow(label: 'Cabang Kampus', value: _report.campus!.namaKampus),
                  if (_report.user != null)
                    _InfoRow(
                      label: 'Pelapor',
                      value: '${_report.user!.name} (${_report.user!.roleLabel})',
                    ),
                  ..._buildOwnerActions(c),
                  if (_report.status == 'pending')
                    _Notice(
                      icon: Icons.pending_actions_rounded,
                      title: 'Menunggu verifikasi admin',
                      message:
                          'Laporan ini belum tampil di beranda publik sampai admin memvalidasinya.',
                      background: c.amberBg,
                      accent: c.amberText,
                    ),
                  if (_report.isTemuan && _report.status != 'completed')
                    _Notice(
                      icon: Icons.assignment_outlined,
                      title: 'Pengambilan barang',
                      message:
                          'Serah terima dilakukan di resepsionis atau pos keamanan '
                          '${_report.campus?.namaKampus ?? 'cabang kampus'}. '
                          'Admin mencatatnya di Berita Acara sebagai bukti serah terima.',
                      background: c.mutedBg,
                      accent: c.blueText,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showClaim
          ? Container(
              decoration: BoxDecoration(
                color: c.scaffoldBg,
                border: Border(top: BorderSide(color: c.cardBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _hasClaimed ? null : _openClaim,
                  child: Text(_hasClaimed ? 'Klaim Sudah Diajukan' : 'Klaim Barang Ini'),
                ),
              ),
            )
          : null,
    );
  }

  /// Foto utama; bila ada, ketuk untuk membuka layar penuh yang bisa di-zoom.
  Widget _buildPhoto() {
    final url = _report.fullFotoUrl;
    final heroTag = 'report-photo-${_report.id}';
    final thumb = ReportThumb(
      url: url,
      semanticLabel: 'Foto barang ${_report.namaBarang}',
      size: double.infinity,
      height: 220,
      radius: AppColors.radiusXl,
    );
    if (url == null) return thumb;

    return Semantics(
      button: true,
      label: 'Lihat foto ${_report.namaBarang} layar penuh',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black,
              transitionDuration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              pageBuilder: (_, __, ___) => PhotoViewerView(
                url: url,
                heroTag: heroTag,
                title: _report.namaBarang,
              ),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
          child: Stack(
            children: [
              Hero(tag: heroTag, child: thumb),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppColors.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_out_map_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('Lihat foto', style: AppTypography.caption(Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageMenu(FinditColors c) {
    final canDelete = _report.status == 'pending' || _report.status == 'rejected';
    return Material(
      color: c.isDark ? c.cardBg : AppColors.bgSubtle,
      shape: CircleBorder(side: BorderSide(color: c.cardBorder)),
      child: PopupMenuButton<String>(
        tooltip: 'Opsi laporan',
        icon: Icon(Icons.more_horiz_rounded, color: c.textPrimary, size: 20),
        onSelected: (val) {
          if (val == 'edit') _showEditDialog();
          if (val == 'delete') _handleDelete();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Text('Edit laporan', style: AppTypography.bodyMedium(c.textPrimary)),
          ),
          if (canDelete)
            PopupMenuItem(
              value: 'delete',
              child: Text('Hapus laporan', style: AppTypography.bodyMedium(c.dangerText)),
            ),
        ],
      ),
    );
  }

  /// "2026-11-07" menjadi "7 Nov 2026"; format lain ditampilkan apa adanya.
  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// Teks yang dibagikan lewat share sheet (WhatsApp, dll).
String buildShareText(ReportModel r) {
  final jenis = r.isHilang ? 'BARANG HILANG' : 'BARANG TEMUAN';
  final tempat = [r.lokasi, if (r.campus != null) r.campus!.namaKampus].join(', ');
  final desc = r.deskripsi.trim();
  final ciri = desc.length > 200 ? '${desc.substring(0, 200)}...' : desc;
  final ajakan = r.status == 'completed'
      ? 'Barang ini sudah kembali ke pemiliknya.'
      : r.isHilang
          ? 'Pernah melihat barang ini? Kabari lewat aplikasi FindIT UBSI.'
          : 'Barang ini milikmu? Ajukan klaim lewat aplikasi FindIT UBSI.';
  return [
    '[$jenis] ${r.namaBarang}',
    'Lokasi: $tempat',
    'Tanggal: ${r.tanggalKejadian}',
    if (ciri.isNotEmpty) 'Ciri: $ciri',
    '',
    ajakan,
  ].join('\n');
}

/// Baris label kiri / nilai kanan dengan garis pemisah bawah.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.body(c.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMedium(valueColor ?? c.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color background;
  final Color accent;

  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    required this.background,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.label(c.textPrimary)),
                const SizedBox(height: 2),
                Text(message, style: AppTypography.caption(c.textSecondary)
                    .copyWith(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
