import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../auth/login_view.dart';
import '../claims/my_claims_view.dart';
import '../reports/report_detail_view.dart';

/// Halaman Aktivitas: gabungan Laporan Saya dan Klaim Saya.
class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.appDark,
        appBar: AppBar(
          backgroundColor: AppColors.appDark,
          elevation: 0,
          title: const Text('Aktivitas'),
          bottom: const TabBar(
            indicatorColor: AppColors.accentAmber,
            indicatorWeight: 3,
            labelColor: AppColors.accentAmber,
            unselectedLabelColor: AppColors.slate400,
            dividerColor: AppColors.cardBorder,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: 'Laporan Saya'),
              Tab(text: 'Klaim Saya'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MyReportsTab(),
            MyClaimsView(embedded: true),
          ],
        ),
      ),
    );
  }
}

class _MyReportsTab extends StatefulWidget {
  const _MyReportsTab();

  @override
  State<_MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends State<_MyReportsTab>
    with AutomaticKeepAliveClientMixin {
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  bool _loggedIn = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    final reports = user == null ? <ReportModel>[] : await ReportService.getMyReports();
    if (!mounted) return;
    setState(() {
      _loggedIn = user != null;
      _reports = reports;
      _isLoading = false;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      case 'completed':
        return AppColors.accentBlue;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentAmber));
    }

    if (!_loggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.slate400),
              const SizedBox(height: 12),
              const Text(
                'Masuk untuk melihat aktivitas Anda',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginView()),
                ),
                child: const Text('Masuk ke Akun'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accentAmber,
      backgroundColor: AppColors.cardBg,
      child: _reports.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(40),
              children: const [
                SizedBox(height: 80),
                Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.slate400),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'Belum Ada Laporan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Laporan barang hilang atau temuan yang Anda buat akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate400, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: _reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final r = _reports[i];
                final color = r.isHilang ? AppColors.accentAmber : AppColors.accentBlue;
                final sc = _statusColor(r.status);
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReportDetailView(report: r)),
                    );
                    _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(
                            r.isHilang ? Icons.warning_amber_rounded : Icons.search_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.namaBarang,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${r.isHilang ? 'Hilang' : 'Temuan'} • ${r.campus?.namaKampus.replaceAll('UBSI Kampus ', '') ?? r.lokasi}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.slate400),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(r.status),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
