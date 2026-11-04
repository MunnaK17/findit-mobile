import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/report_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/supabase_service.dart';
import '../auth/login_view.dart';
import '../claims/my_claims_view.dart';
import '../reports/create_report_view.dart';
import '../reports/report_detail_view.dart';

class ActivityView extends StatelessWidget {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.scaffoldBg,
        appBar: AppBar(
          backgroundColor: c.scaffoldBg,
          elevation: 0,
          title: const Text('Aktivitas'),
          bottom: TabBar(
            indicatorColor: c.amberText,
            indicatorWeight: 3,
            labelColor: c.amberText,
            unselectedLabelColor: c.textMuted,
            dividerColor: c.cardBorder,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
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
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final user = await AuthService.getCurrentUser();
    final reports = user == null ? <ReportModel>[] : await ReportService.getMyReports();
    if (!mounted) return;
    setState(() {
      _loggedIn = user != null;
      _reports = reports;
      if (user != null && reports.isEmpty && SupabaseService.lastError != null) {
        _errorMessage = SupabaseService.lastError;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = FinditColors.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accentAmber),
            const SizedBox(height: 12),
            Text(
              'Memuat laporan Anda...',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
          ],
        ),
      );
    }

    if (!_loggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: c.textMuted),
              const SizedBox(height: 12),
              Text(
                'Masuk untuk melihat aktivitas Anda',
                style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
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

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: c.dangerText),
              const SizedBox(height: 12),
              Text(
                'Gagal Memuat Laporan Saya',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accentAmber,
      backgroundColor: c.cardBg,
      child: _reports.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(40),
              children: [
                const SizedBox(height: 60),
                Icon(Icons.inventory_2_outlined, size: 52, color: c.textMuted),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Belum Ada Laporan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Laporan barang hilang atau temuan yang Anda buat akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateReportView()),
                      );
                      if (created == true) _load();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Buat Laporan Baru'),
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
                final typeText = r.isHilang ? c.amberText : c.tealText;
                final typeBg = r.isHilang ? c.amberBg : c.tealBg;
                final statusText = c.statusTextColor(r.status);
                final statusBg = c.statusBgColor(r.status);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
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
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: typeBg,
                          child: Icon(
                            r.isHilang ? Icons.warning_amber_rounded : Icons.search_rounded,
                            color: typeText,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${r.isHilang ? 'Hilang' : 'Temuan'} • ${r.campus?.namaKampus.replaceAll('UBSI Kampus ', '') ?? r.lokasi}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            FinditColors.statusLabel(r.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusText,
                            ),
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
