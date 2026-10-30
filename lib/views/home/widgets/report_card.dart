import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/report_model.dart';
import '../../reports/report_detail_view.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isHilang = report.isHilang;
    final badgeColor = isHilang ? AppColors.accentAmber : AppColors.accentBlue;
    final badgeText = isHilang ? "HILANG" : "TEMUAN";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailView(report: report),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBgLight.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 86,
                height: 86,
                color: AppColors.cardBgNavy,
                child: report.fullFotoUrl != null
                    ? Image.network(
                        report.fullFotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderIcon(isHilang),
                      )
                    : _buildPlaceholderIcon(isHilang),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (report.category != null)
                        Text(
                          report.category!.namaCategory,
                          style: const TextStyle(
                            color: AppColors.slate400,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.namaBarang,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.campus != null ? "${report.campus!.namaKampus} • ${report.lokasi}" : report.lokasi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        report.tanggalKejadian,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isHilang) {
    return Center(
      child: Icon(
        isHilang ? Icons.warning_amber_rounded : Icons.search_rounded,
        size: 32,
        color: (isHilang ? AppColors.accentAmber : AppColors.accentBlue).withValues(alpha: 0.5),
      ),
    );
  }
}

/// Vertical Box Card used for the horizontal "Laporan Terkini" carousel on Beranda
class ReportBoxCard extends StatelessWidget {
  final ReportModel report;
  final double width;

  const ReportBoxCard({
    super.key,
    required this.report,
    this.width = 225,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = report.status == 'completed';
    final isHilang = report.isHilang;

    final String pillText;
    final Color pillBgColor;
    final Color pillTextColor;

    if (isCompleted) {
      pillText = "Kembali ke Pemilik";
      pillBgColor = const Color(0xFF334155).withValues(alpha: 0.55);
      pillTextColor = const Color(0xFFCBD5E1);
    } else if (isHilang) {
      pillText = "Hilang";
      pillBgColor = const Color(0xFFEF4444).withValues(alpha: 0.18);
      pillTextColor = const Color(0xFFF87171);
    } else {
      pillText = "Temuan";
      pillBgColor = const Color(0xFF10B981).withValues(alpha: 0.18);
      pillTextColor = const Color(0xFF34D399);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailView(report: report),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.cardBgLight.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image / Search Icon Box
            Container(
              width: double.infinity,
              height: 118,
              color: AppColors.cardBgNavy,
              child: report.fullFotoUrl != null
                  ? Image.network(
                      report.fullFotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildSearchPlaceholder(),
                    )
                  : _buildSearchPlaceholder(),
            ),

            // Card Content Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Title
                    Text(
                      report.namaBarang,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Campus Name
                    if (report.campus != null) ...[
                      Text(
                        "🏢 ${report.campus!.namaKampus}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate300,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],

                    // Location
                    Text(
                      "📍 ${report.lokasi}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate300,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Category · Date
                    Text(
                      "${report.category?.namaCategory ?? 'Tanpa kategori'} · ${report.tanggalKejadian}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.slate400,
                      ),
                    ),

                    const Spacer(),

                    // Bottom Row: Pill Badge + Relative Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pillBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            pillText,
                            style: TextStyle(
                              color: pillTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            report.relativeTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.slate400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPlaceholder() {
    return Center(
      child: Icon(
        Icons.search_rounded,
        size: 42,
        color: AppColors.slate300.withValues(alpha: 0.75),
      ),
    );
  }
}
