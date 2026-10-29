import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/chat_message_model.dart';
import '../../services/chatbot_service.dart';
import '../reports/create_report_view.dart';
import '../claims/my_claims_view.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key});

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final List<ChatMessageModel> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<String> _initialSuggestions = [
    'Cara lapor barang hilang?',
    'Cara klaim barang temuan?',
    'Bagaimana verifikasi laporan?',
    'Tips agar barang cepat ketemu',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessageModel(
        text: 'Halo! Saya FindBot, asisten virtual FindIT Kampus 👋\nAda yang bisa saya bantu terkait barang hilang atau temuan di kampus?',
        isUser: false,
        timestamp: DateTime.now(),
        quickReplies: _initialSuggestions,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessageModel(
          text: query,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    final res = await ChatbotService.askQuestion(query);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessageModel(
            text: res['reply'] ?? 'Terima kasih telah bertanya!',
            isUser: false,
            timestamp: DateTime.now(),
            action: res['action'],
            quickReplies: res['quickReplies'] ?? [],
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _handleAction(ChatAction action) {
    final url = action.url.toLowerCase();
    if (url.contains('lapor') || url.contains('report')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateReportView()),
      );
    } else if (url.contains('claim') || url.contains('klaim')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyClaimsView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appDark,
      appBar: AppBar(
        backgroundColor: AppColors.appDark,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.accentAmber,
              child: Icon(Icons.smart_toy_rounded, color: AppColors.slate950, size: 20),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FindBot Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  'Online • Siap membantu',
                  style: TextStyle(fontSize: 11, color: AppColors.accentEmerald, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'FindBot sedang mengetik...',
                    style: TextStyle(color: AppColors.slate400, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Bottom Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF142036),
              border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu pada FindBot...',
                        hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.accentAmber, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.appDark,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.accentAmber,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.slate950, size: 20),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessageModel message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.accentAmber,
                  child: Icon(Icons.smart_toy_rounded, color: AppColors.slate950, size: 17),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.accentAmber : AppColors.cardBgLight,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? AppColors.slate950 : Colors.white,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.cardBgLight,
                  child: Icon(Icons.person, color: AppColors.accentAmber, size: 18),
                ),
              ],
            ],
          ),

          // Action button if available
          if (message.action != null && message.action!.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 40),
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(message.action!),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(message.action!.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentAmber,
                  foregroundColor: AppColors.slate950,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Quick replies
          if (message.quickReplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.quickReplies.map((reply) {
                  return ActionChip(
                    label: Text(
                      reply,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: AppColors.cardBgNavy,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _sendMessage(reply),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
