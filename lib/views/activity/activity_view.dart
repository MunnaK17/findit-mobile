import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Semantics(
                  header: true,
                  child: Text('Aktivitas',
                      style: AppTypography.titleLarge(c.textPrimary)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  indicatorColor: AppColors.brandPrimary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: c.textPrimary,
                  unselectedLabelColor: c.textMuted,
                  dividerColor: c.cardBorder,
                  labelStyle: AppTypography.bodyMedium(c.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                  unselectedLabelStyle: AppTypography.bodyMedium(c.textMuted)
                      .copyWith(fontSize: 15),
                  tabs: const [
                    Tab(text: 'Laporan Saya'),
                    Tab(text: 'Klaim Saya'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    _MyReportsTab(),
                    MyClaimsView(embedded: true),
                  ],
                ),
              ),
            ],
          ),
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
  String _status = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    ReportService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    ReportService.changes.removeListener(_load);
    super.dispose();
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

  /// Baris waktu di kartu: status verifikasi lalu waktu relatif.
  String _metaFor(ReportModel r) => switch (r.status) {
        'pending' => 'Menunggu verifikasi',
        'approved' when r.isExpired => 'Kedaluwarsa · buka untuk memperpanjang',
        'approved' => 'Disetujui · ${r.relativeTime}',
        'completed' => 'Selesai · ${r.relativeTime}',
        'rejected' => 'Ditolak · ${r.relativeTime}',
        _ => r.relativeTime,
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      );
    }

    if (!_loggedIn) {
      return Center(
        child: StateMessage(
          icon: Icons.lock_outline_rounded,
          title: 'Masuk untuk melihat aktivitasmu',
          message: 'Laporan dan klaim yang kamu buat akan tampil di sini.',
          actionLabel: 'Masuk ke Akun',
          onAction: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginView()),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Gagal memuat laporan',
          message: _errorMessage,
          actionLabel: 'Coba Lagi',
          onAction: _load,
        ),
      );
    }

    final visible = _status == 'all'
        ? _reports
        : _reports.where((r) => r.status == _status).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          FilterPillBar(
            options: const [
              ('all', 'Semua'),
              ('pending', 'Menunggu'),
              ('approved', 'Disetujui'),
              ('completed', 'Selesai'),
            ],
            selected: _status,
            onSelected: (key) => setState(() => _status = key),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            StateMessage(
              icon: Icons.inventory_2_outlined,
              title: _reports.isEmpty ? 'Belum ada laporan' : 'Tidak ada laporan di filter ini',
              message: _reports.isEmpty
                  ? 'Laporan barang hilang atau temuan yang kamu buat akan muncul di sini.'
                  : null,
              actionLabel: _reports.isEmpty ? 'Buat Laporan Baru' : null,
              onAction: _reports.isEmpty
                  ? () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateReportView()),
                      );
                      if (created == true) _load();
                    }
                  : null,
            )
          else
            for (final r in visible) ...[
              ReportListCard(
                title: r.namaBarang,
                location: r.lokasi,
                meta: _metaFor(r),
                photoUrl: r.fullFotoUrl,
                kind: badgeKindFor(isHilang: r.isHilang, status: r.status),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportDetailView(report: r)),
                  );
                  _load();
                },
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}
