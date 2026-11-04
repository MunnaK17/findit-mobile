import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/report_model.dart';
import '../../services/claim_service.dart';

class CreateClaimView extends StatefulWidget {
  final ReportModel report;

  const CreateClaimView({super.key, required this.report});

  @override
  State<CreateClaimView> createState() => _CreateClaimViewState();
}

class _CreateClaimViewState extends State<CreateClaimView> {
  final _formKey = GlobalKey<FormState>();
  final _pesanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final res = await ClaimService.submitClaim(
      reportId: widget.report.id,
      pesanKlaim: _pesanController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    final c = FinditColors.of(context);

    if (res['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: c.sheetBg,
          icon: Icon(Icons.check_circle_outline, color: c.successText, size: 50),
          title: Text('Klaim Berhasil Dikirim', style: TextStyle(color: c.textPrimary)),
          content: Text(
            'Pengajuan klaim Anda telah dicatat. Admin dan penemu barang akan memeriksa informasi yang Anda berikan.',
            style: TextStyle(color: c.textSecondary),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengajukan klaim'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        title: Text('Ajukan Klaim Barang', style: TextStyle(color: c.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: c.cardBgLight,
                        child: widget.report.fullFotoUrl != null
                            ? Image.network(
                                widget.report.fullFotoUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                semanticLabel: 'Foto ${widget.report.namaBarang}',
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.inventory_2_outlined,
                                  color: c.textMuted,
                                ),
                              )
                            : Icon(
                                Icons.inventory_2_outlined,
                                color: c.textMuted,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.report.namaBarang,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${widget.report.campus?.namaKampus ?? ''} • ${widget.report.lokasi}",
                            style: TextStyle(fontSize: 12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.cardBgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: c.amberText, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips Verifikasi Klaim',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sebutkan ciri spesifik yang belum tertulis di deskripsi umum (seperti isi dalam dompet, wallpaper HP, stiker casing, atau nota pembelian) untuk membuktikan kepemilikan Anda.',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pesanController,
                maxLines: 6,
                style: TextStyle(color: c.inputText, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Deskripsi Bukti Kepemilikan *',
                  hintText: 'Jelaskan sedetail mungkin bukti bahwa barang ini adalah milik Anda...',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: c.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: c.inputBorder),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Bukti kepemilikan wajib diisi';
                  }
                  if (val.trim().length < 15) {
                    return 'Deskripsi terlalu singkat. Berikan minimal 15 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: AppColors.slate950,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: AppColors.slate950, strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim Pengajuan Klaim',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
