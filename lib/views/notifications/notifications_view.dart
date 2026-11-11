import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../models/app_notification_model.dart';
import '../../services/notification_service.dart';
import '../reports/report_detail_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late Stream<List<AppNotificationModel>> _stream;
  int? _opening;

  @override
  void initState() {
    super.initState();
    _stream = NotificationService.watchMine();
  }

  void _retry() => setState(() => _stream = NotificationService.watchMine());

  Future<void> _open(AppNotificationModel n) async {
    if (_opening != null) return;
    if (!n.isRead) NotificationService.markRead(n.id);
    final reportId = n.reportId;
    if (reportId == null) return;

    setState(() => _opening = n.id);
    final report = await NotificationService.loadReport(reportId);
    if (!mounted) return;
    setState(() => _opening = null);
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan ini sudah tidak tersedia.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportDetailView(report: report)),
    );
  }

  Future<void> _markAll() async {
    final ok = await NotificationService.markAllRead();
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal menandai notifikasi. Coba lagi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: StreamBuilder<List<AppNotificationModel>>(
          stream: _stream,
          builder: (context, snap) {
            final items = snap.data ?? const <AppNotificationModel>[];
            final hasUnread = items.any((n) => !n.isRead);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Kembali',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text('Notifikasi',
                              style: AppTypography.titleMedium(c.textPrimary)),
                        ),
                      ),
                      if (hasUnread)
                        TextButton(
                          onPressed: _markAll,
                          style: TextButton.styleFrom(foregroundColor: c.amberText),
                          child: Text('Tandai dibaca',
                              style: AppTypography.label(c.amberText)),
                        ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody(c, snap, items)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    FinditColors c,
    AsyncSnapshot<List<AppNotificationModel>> snap,
    List<AppNotificationModel> items,
  ) {
    if (snap.hasError) {
      return Center(
        child: StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Gagal memuat notifikasi',
          message: 'Periksa koneksi internet lalu coba lagi.',
          actionLabel: 'Coba Lagi',
          onAction: _retry,
        ),
      );
    }
    if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: StateMessage(
          icon: Icons.notifications_none_rounded,
          title: 'Belum ada notifikasi',
          message: 'Kabar soal laporan dan klaimmu akan muncul di sini.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _NotificationTile(
        item: items[i],
        loading: _opening == items[i].id,
        onTap: () => _open(items[i]),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel item;
  final bool loading;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.loading,
    required this.onTap,
  });

  (IconData, Color, Color) _style(FinditColors c) => switch (item.event) {
        'report_approved' || 'claim_approved' => (Icons.check_circle_outline_rounded, c.successText, c.successBg),
        'report_rejected' || 'claim_rejected' => (Icons.highlight_off_rounded, c.dangerText, c.dangerBg),
        'report_completed' => (Icons.volunteer_activism_outlined, c.successText, c.successBg),
        'claim_created' => (Icons.front_hand_outlined, c.blueText, c.blueBg),
        _ => (Icons.notifications_none_rounded, c.textSecondary, c.mutedBg),
      };

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final (icon, fg, bg) = _style(c);
    final unread = !item.isRead;
    return Semantics(
      button: true,
      label: '${unread ? 'Belum dibaca. ' : ''}${item.title}. ${item.body}. ${item.relativeTime}',
      excludeSemantics: true,
      child: Material(
        color: unread ? (c.isDark ? c.cardBgLight : AppColors.bgSubtle) : c.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          side: BorderSide(color: c.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(icon, size: 20, color: fg),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.titleSmall(c.textPrimary).copyWith(
                          fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(c.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(item.relativeTime, style: AppTypography.caption(c.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.brandPrimary),
                  )
                else if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
