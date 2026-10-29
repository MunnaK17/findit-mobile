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

    if (res['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          icon: const Icon(Icons.check_circle_outline, color: AppColors.accentEmerald, size: 50),
          title: const Text('Klaim Berhasil Dikirim!', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Pengajuan klaim Anda telah dicatat. Admin dan penemu barang akan memeriksa informasi yang Anda berikan.',
            style: TextStyle(color: AppColors.slate300),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close claim view
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
    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        elevation: 0,
        title: const Text('Ajukan Klaim Barang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary card of the item
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    if (widget.report.fullFotoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.report.fullFotoUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: AppColors.cardBgLight,
                            child: const Icon(Icons.inventory_2_outlined, color: AppColors.slate400),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: AppColors.accentBlue),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.report.namaBarang,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Lokasi: ${widget.report.lokasi}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Untuk memverifikasi bahwa barang ini milik Anda, jelaskan ciri-ciri khusus (warna, bekas goresan, isi dalam tas/dompet, wallpaper HP, nomor seri, dll).',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.slate300,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Bukti Kepemilikan & Ciri Khusus *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pesanController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Dompet warna coklat tua, ada gantungan kunci huruf A, di dalamnya ada kartu mahasiswa atas nama...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Mohon jelaskan bukti kepemilikan Anda';
                  }
                  if (val.trim().length < 10) {
                    return 'Penjelasan terlalu singkat (minimal 10 karakter)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitClaim,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.slate950),
                      )
                    : const Text('Kirim Pengajuan Klaim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
