/// Satu baris public.app_notifications (dibuat Edge Function notify-email).
class AppNotificationModel {
  final int id;
  final String event;
  final int? reportId;
  final int? claimId;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.event,
    required this.reportId,
    required this.claimId,
    required this.title,
    required this.body,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as int,
      event: json['event'] as String? ?? '',
      reportId: json['report_id'] as int?,
      claimId: json['claim_id'] as int?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? '')?.toLocal(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
