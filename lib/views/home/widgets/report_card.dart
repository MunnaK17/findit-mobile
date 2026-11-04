import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/report_model.dart';
import '../../reports/report_detail_view.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final bool isLight;

  const ReportCard({
    super.key,
    required this.report,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final isCompleted = report.status == 'completed';
    final isHilang = report.isHilang;

    final Color badgeColor = isCompleted
        ? c.successText
        : (isHilang ? c.amberText : c.tealText);
    final Color badgeBg = isCompleted
        ? c.successBg
        : (isHilang ? c.amberBg : c.tealBg);
    final String badgeText = isCompleted
        ? "SELESAI"
        : (isHilang ? "HILANG" : "TEMUAN");

    return Semantics(
      button: true,
      label: '${report.namaBarang}, status $badgeText, lokasi ${report.lokasi}',
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailView(report: report),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 86,
                  height: 86,
                  color: c.cardBgNavy,
                  child: report.fullFotoUrl != null
                      ? Image.network(
                          report.fullFotoUrl!,
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                          semanticLabel: 'Foto ${report.namaBarang}',
                          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(c, isHilang),
                        )
                      : _buildPlaceholderIcon(c, isHilang),
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
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (report.category != null)
                          Flexible(
                            child: Text(
                              report.category!.namaCategory,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.namaBarang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: c.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.campus != null
                                ? "${report.campus!.namaKampus} • ${report.lokasi}"
                                : report.lokasi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          report.tanggalKejadian,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.textMuted,
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
      ),
    );
  }

  Widget _buildPlaceholderIcon(FinditColors c, bool isHilang) {
    return Center(
      child: Icon(
        isHilang ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
        size: 32,
        color: isHilang ? c.amberText : c.tealText,
      ),
    );
  }
}

/// Kartu vertikal untuk daftar laporan terbaru pada halaman Beranda.
class ReportBoxCard extends StatelessWidget {
  final ReportModel report;
  final double width;
  final bool isLight;

  const ReportBoxCard({
    super.key,
    required this.report,
    this.width = 230,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final isCompleted = report.status == 'completed';
    final isHilang = report.isHilang;

    final String pillText;
    final Color pillBgColor;
    final Color pillTextColor;

    if (isCompleted) {
      pillText = "Kembali ke Pemilik";
      pillBgColor = c.successBg;
      pillTextColor = c.successText;
    } else if (isHilang) {
      pillText = "Hilang";
      pillBgColor = c.amberBg;
      pillTextColor = c.amberText;
    } else {
      pillText = "Temuan";
      pillBgColor = c.tealBg;
      pillTextColor = c.tealText;
    }

    return Semantics(
      button: true,
      label: '${report.namaBarang}, status $pillText, lokasi ${report.lokasi}',
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportDetailView(report: report),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: c.cardBorder,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 118,
                color: c.cardBgNavy,
                child: report.fullFotoUrl != null
                    ? Image.network(
                        report.fullFotoUrl!,
                        width: width,
                        height: 118,
                        fit: BoxFit.cover,
                        semanticLabel: 'Foto ${report.namaBarang}',
                        errorBuilder: (_, __, ___) => _buildSearchPlaceholder(c, isHilang),
                      )
                    : _buildSearchPlaceholder(c, isHilang),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.namaBarang,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (report.campus != null) ...[
                        Row(
                          children: [
                            Icon(Icons.apartment_rounded, size: 13, color: c.tealText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.campus!.namaKampus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: c.tealText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: c.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.lokasi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${report.category?.namaCategory ?? 'Tanpa kategori'} · ${report.tanggalKejadian}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: pillBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pillText,
                              style: TextStyle(
                                color: pillTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              report.relativeTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
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
      ),
    );
  }

  Widget _buildSearchPlaceholder(FinditColors c, bool isHilang) {
    return Center(
      child: Icon(
        isHilang ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
        size: 38,
        color: isHilang ? c.amberText : c.tealText,
      ),
    );
  }
}
