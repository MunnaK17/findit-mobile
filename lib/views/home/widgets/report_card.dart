import 'package:flutter/material.dart';
import '../../../core/widgets/findit_widgets.dart';
import '../../../models/report_model.dart';
import '../../reports/report_detail_view.dart';

/// Kartu laporan standar (Beranda, Cari, Semua Laporan). Ketuk untuk detail.
class ReportCard extends StatelessWidget {
  final ReportModel report;

  /// Baris metadata kedua. Default: waktu relatif ("5 jam lalu").
  final String? meta;

  const ReportCard({super.key, required this.report, this.meta});

  @override
  Widget build(BuildContext context) {
    return ReportListCard(
      title: report.namaBarang,
      location: report.lokasi,
      meta: meta ?? report.relativeTime,
      photoUrl: report.fullFotoUrl,
      kind: badgeKindFor(isHilang: report.isHilang, status: report.status),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportDetailView(report: report)),
      ),
    );
  }
}
