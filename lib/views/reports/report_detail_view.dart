import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/report_model.dart';
import '../claims/create_claim_view.dart';

class ReportDetailView extends StatelessWidget {
  final ReportModel report;

  const ReportDetailView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isHilang = report.isHilang;
    final badgeColor = isHilang ? AppColors.accentAmber : AppColors.accentBlue;

    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        elevation: 0,
        title: Text(report.namaBarang),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            if (report.fullFotoUrl != null)
              Image.network(
                report.fullFotoUrl!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.cardBgNavy,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 60, color: AppColors.slate400),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                color: AppColors.cardBgNavy,
                child: Center(
                  child: Icon(
                    isHilang ? Icons.warning_amber_rounded : Icons.search_rounded,
                    size: 80,
                    color: badgeColor.withValues(alpha: 0.5),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          isHilang ? 'Barang Hilang' : 'Barang Temuan',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusLabel(report.status),
                          style: TextStyle(
                            color: _getStatusColor(report.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    report.namaBarang,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Info list container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        if (report.campus != null) ...[
                          _buildInfoTile(
                            icon: Icons.domain_rounded,
                            label: 'Cabang Kampus',
                            value: "${report.campus!.namaKampus} (${report.campus!.kota})",
                          ),
                          const Divider(height: 16, color: AppColors.cardBorder),
                        ],
                        _buildInfoTile(
                          icon: Icons.category_outlined,
                          label: 'Kategori',
                          value: report.category?.namaKategori ?? 'Umum',
                        ),
                        const Divider(height: 16, color: AppColors.cardBorder),
                        _buildInfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal Kejadian',
                          value: report.tanggalKejadian,
                        ),
                        const Divider(height: 16, color: AppColors.cardBorder),
                        _buildInfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: report.lokasi,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Deskripsi
                  const Text(
                    'Deskripsi / Ciri Khusus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      report.deskripsi.isNotEmpty
                          ? report.deskripsi
                          : 'Tidak ada deskripsi tambahan.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.slate300,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Pelapor
                  if (report.user != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Informasi Pelapor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.accentAmber.withValues(alpha: 0.15),
                            child: const Icon(Icons.person, color: AppColors.accentAmber),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      report.user!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: report.user!.isStaff
                                            ? AppColors.bsiTeal.withValues(alpha: 0.15)
                                            : AppColors.accentAmber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        report.user!.roleLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: report.user!.isStaff ? AppColors.bsiTeal : AppColors.accentAmber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (report.user!.nip != null && report.user!.nip!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "NIP: ${report.user!.nip}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ] else if (report.user!.nim != null && report.user!.nim!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "NIM: ${report.user!.nim}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Claim button if eligible
                  if (report.canBeClaimed)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateClaimView(report: report),
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentAmber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.accentEmerald;
      case 'completed':
        return AppColors.accentBlue;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.accentAmber;
    }
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
