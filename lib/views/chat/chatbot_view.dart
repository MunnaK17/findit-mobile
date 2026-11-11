import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/findit_widgets.dart';
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
    'Cara klaim barang',
    'Buat laporan',
    'Bagaimana verifikasi laporan?',
    'Tips agar barang cepat ketemu',
  ];


  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessageModel(
        text: 'Halo! Saya FindBot 👋 Ada barang yang hilang atau kamu temukan di kampus?',

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

  /// URL aksi dikirim Edge Function chatbot (ACTION_* di supabase/functions/chatbot/index.ts).
  void _handleAction(ChatAction action) {
    final Widget? page = switch (action.url) {
      'findit://create-report' => const CreateReportView(),
      'findit://my-claims' => const MyClaimsView(),
      _ => null,
    };
    if (page == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final c = FinditColors.of(context);
    final quickReplies = _messages.isNotEmpty && !_isTyping
        ? _messages.last.quickReplies
        : const <String>[];

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 12),
                  const _BotAvatar(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FindBot', style: AppTypography.titleSmall(c.textPrimary)),
                        Text('Asisten AI FindIT',
                            style: AppTypography.caption(c.successText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.cardBorder),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _buildTyping(c);
                  return _buildMessageItem(c, _messages[index]);
                },
              ),
            ),
            if (quickReplies.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quickReplies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) => FilterPill(
                    label: quickReplies[idx],
                    selected: false,
                    onTap: () => _sendMessage(quickReplies[idx]),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: AppTypography.bodyMedium(c.inputText),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Tanyakan sesuatu seputar barang hilang...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Kirim pesan',
                    child: Material(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        onTap: _isTyping ? null : () => _sendMessage(_textController.text),
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(
                            Icons.send_outlined,
                            color: AppColors.brandOnPrimary,
                            size: 22,
                            semanticLabel: 'Kirim pesan',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping(FinditColors c) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _botBubble(c),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: 8),
            Text('FindBot sedang mengetik...',
                style: AppTypography.caption(c.textSecondary)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _botBubble(FinditColors c) => BoxDecoration(
        color: c.isDark ? c.cardBg : AppColors.bgSubtle,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: c.cardBorder),
      );

  Widget _buildMessageItem(FinditColors c, ChatMessageModel msg) {
    final isUser = msg.isUser;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isUser
                  ? BoxDecoration(
                      color: c.textPrimary,
                      borderRadius: BorderRadius.circular(AppColors.radiusLg),
                    )
                  : _botBubble(c),
              child: Text(
                msg.text,
                style: AppTypography.body(isUser ? c.scaffoldBg : c.textPrimary),
              ),
            ),
          ),
          if (msg.action != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _handleAction(msg.action!),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(msg.action!.label),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.blueText,
                minimumSize: const Size(44, 44),
                side: BorderSide(color: c.cardBorder),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Avatar FindBot: lingkaran biru dengan ikon headset.
class _BotAvatar extends StatelessWidget {
  final double size;
  const _BotAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.actionBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}
