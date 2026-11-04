import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/chat_message_model.dart';
import '../../services/chatbot_service.dart';
import '../claims/my_claims_view.dart';
import '../reports/create_report_view.dart';

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
        text: 'Halo! Saya FindBot, asisten panduan FindIT Kampus.\nAda yang bisa saya bantu terkait barang hilang atau temuan di kampus?',
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
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
    } else if (url.contains('klaim') || url.contains('claim')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyClaimsView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.tealBg,
                border: Border.all(color: c.tealText.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.support_agent_rounded, color: c.tealText, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FindBot Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
                ),
                Text(
                  'Asisten Panduan Lost & Found UBSI',
                  style: TextStyle(fontSize: 11, color: c.textMuted),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageItem(c, msg);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentAmber),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menyiapkan jawaban panduan...',
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_messages.isNotEmpty && _messages.last.quickReplies.isNotEmpty && !_isTyping)
            Container(
              height: 46,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.last.quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final text = _messages.last.quickReplies[idx];
                  return ActionChip(
                    backgroundColor: c.chipBg,
                    side: BorderSide(color: c.chipBorder),
                    label: Text(
                      text,
                      style: TextStyle(fontSize: 12, color: c.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _sendMessage(text),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            decoration: BoxDecoration(
              color: c.cardBg,
              border: Border(top: BorderSide(color: c.cardBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Ketik pertanyaan seputar barang hilang atau temuan',
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.inputBorder),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: TextStyle(color: c.inputText, fontSize: 14),
                          textInputAction: TextInputAction.send,
                          onSubmitted: _sendMessage,
                          decoration: InputDecoration(
                            hintText: 'Tanyakan sesuatu seputar barang hilang...',
                            hintStyle: TextStyle(color: c.inputHint, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.accentAmber,
                    ),
                    child: IconButton(
                      tooltip: 'Kirim pesan',
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

  Widget _buildMessageItem(FinditColors c, ChatMessageModel msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.tealBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.support_agent_rounded, color: c.tealText, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.accentAmber : c.cardBg,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                      bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: isUser ? null : Border.all(color: c.cardBorder),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? AppColors.slate950 : c.textPrimary,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (msg.action != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(msg.action!),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: Text(msg.action!.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bsiTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
