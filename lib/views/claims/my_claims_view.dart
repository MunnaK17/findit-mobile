import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/claim_model.dart';
import '../../services/claim_service.dart';

class MyClaimsView extends StatefulWidget {
  final bool embedded;

  const MyClaimsView({super.key, this.embedded = false});

  @override
  State<MyClaimsView> createState() => _MyClaimsViewState();
}

class _MyClaimsViewState extends State<MyClaimsView> {
  List<ClaimModel> _claims = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() => _isLoading = true);
    final data = await ClaimService.getMyClaims();
    if (mounted) {
      setState(() {
        _claims = data;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Verifikasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: AppColors.appDark,
              elevation: 0,
              title: const Text('Klaim Saya'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentAmber))
          : _claims.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadClaims,
                  color: AppColors.accentAmber,
                  child: ListView(
                    padding: const EdgeInsets.all(40),
                    children: [
                      const SizedBox(height: 80),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.slate400),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Belum Ada Pengajuan Klaim',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Jika Anda mengenali barang milik Anda di daftar temuan, ajukan klaim untuk mengambilnya.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClaims,
                  color: AppColors.accentAmber,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _claims.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final claim = _claims[index];
                      final statusColor = _getStatusColor(claim.statusKlaim);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    claim.report?.namaBarang ?? 'Barang Temuan #${claim.idReport}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    _getStatusLabel(claim.statusKlaim),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (claim.report?.lokasi != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.slate400),
                                  const SizedBox(width: 4),
                                  Text(
                                    claim.report!.lokasi,
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate400),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.appDarker,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bukti yang diajukan:',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate400),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    claim.pesanKlaim,
                                    style: const TextStyle(fontSize: 13, color: AppColors.slate300, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 5),
                                Text(
                                  claim.tanggalKlaim,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
