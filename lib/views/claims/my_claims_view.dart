import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../models/claim_model.dart';
import '../../services/claim_service.dart';
import '../../services/supabase_service.dart';
import '../reports/report_detail_view.dart';


class MyClaimsView extends StatefulWidget {
  final bool embedded;

  const MyClaimsView({super.key, this.embedded = false});

  @override
  State<MyClaimsView> createState() => _MyClaimsViewState();
}

class _MyClaimsViewState extends State<MyClaimsView> {
  List<ClaimModel> _claims = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final data = await ClaimService.getMyClaims();
    if (mounted) {
      setState(() {
        _claims = data;
        if (data.isEmpty && SupabaseService.lastError != null) {
          _errorMessage = SupabaseService.lastError;
        }
        _isLoading = false;
      });
    }
  }

  String _metaFor(ClaimModel claim) {
    final label = switch (claim.statusKlaim) {
      'approved' => 'Klaim disetujui',
      'rejected' => 'Klaim ditolak',
      _ => 'Klaim menunggu verifikasi',
    };
    return claim.tanggalKlaim.isEmpty ? label : '$label · ${claim.tanggalKlaim}';
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    final Widget body;
    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      );
    } else if (_errorMessage != null) {
      body = Center(
        child: StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Gagal memuat klaim',
          message: _errorMessage,
          actionLabel: 'Coba Lagi',
          onAction: _loadClaims,
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadClaims,
        color: AppColors.brandPrimary,
        child: _claims.isEmpty
            ? ListView(
                children: const [
                  StateMessage(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada pengajuan klaim',
                    message:
                        'Kenali barangmu di daftar temuan? Buka detailnya lalu ketuk "Klaim Barang Ini".',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: _claims.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final claim = _claims[index];
                  final report = claim.report;
                  return ReportListCard(
                    title: report?.namaBarang ?? 'Barang Temuan #${claim.idReport}',
                    location: report?.lokasi ?? '-',
                    meta: _metaFor(claim),
                    photoUrl: report?.fullFotoUrl,
                    kind: report == null
                        ? ReportBadgeKind.temuan
                        : badgeKindFor(isHilang: report.isHilang, status: report.status),
                    onTap: report == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportDetailView(report: report),
                              ),
                            ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: widget.embedded ? null : AppBar(title: const Text('Klaim Saya')),
      body: body,
    );
  }
}
