import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/findit_widgets.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import 'notifications_view.dart';

/// Lonceng di header Beranda dengan badge jumlah notifikasi belum dibaca (realtime).
/// Tidak tampil untuk tamu.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  Stream<int>? _unread;

  @override
  void initState() {
    super.initState();
    if (SupabaseService.isLoggedIn) _unread = NotificationService.watchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    if (_unread == null) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: _unread,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Semantics(
          label: count > 0 ? 'Notifikasi, $count belum dibaca' : 'Notifikasi',
          button: true,
          excludeSemantics: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifikasi',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsView()),
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: IgnorePointer(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.feedbackDanger,
                        borderRadius: BorderRadius.circular(AppColors.radiusFull),
                        border: Border.all(
                          color: FinditColors.of(context).scaffoldBg,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
