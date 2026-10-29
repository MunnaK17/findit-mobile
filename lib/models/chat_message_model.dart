class ChatAction {
  final String label;
  final String url;

  ChatAction({required this.label, required this.url});

  factory ChatAction.fromJson(Map<String, dynamic> json) {
    return ChatAction(
      label: json['label'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatAction? action;
  final List<String> quickReplies;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
    this.quickReplies = const [],
  });
}
