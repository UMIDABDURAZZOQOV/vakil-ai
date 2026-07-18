import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  Future<void> _send(String documentId) async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    _inputController.clear();
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).send(documentId, text);
      ref.invalidate(chatHistoryProvider(documentId));
      await ref.read(chatHistoryProvider(documentId).future);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serverga ulanib bo\'lmadi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.tr;
    final documentsAsync = ref.watch(documentsListProvider);
    final documents = documentsAsync.valueOrNull ?? const <DocumentAnalysis>[];

    return Scaffold(
      backgroundColor: AppColors.navyDarkest,
      appBar: AppBar(
        title: Text(t('ai_advisor')),
        backgroundColor: AppColors.navyDark,
      ),
      body: documentsAsync.isLoading && documents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
              ? _EmptyChatState(t: t)
              : _DocumentChat(
                  doc: documents.first,
                  t: t,
                  inputController: _inputController,
                  scrollController: _scrollController,
                  sending: _sending,
                  onSend: () => _send(documents.first.id),
                ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final String Function(String) t;
  const _EmptyChatState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.onNavyMuted, size: 40),
            const SizedBox(height: 16),
            Text(
              t('add_new_document'),
              textAlign: TextAlign.center,
              style: AppTextStyles.body(AppColors.onNavyMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/scanner'),
              child: Text(t('scan')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentChat extends ConsumerWidget {
  final DocumentAnalysis doc;
  final String Function(String) t;
  final TextEditingController inputController;
  final ScrollController scrollController;
  final bool sending;
  final VoidCallback onSend;

  const _DocumentChat({
    required this.doc,
    required this.t,
    required this.inputController,
    required this.scrollController,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(chatHistoryProvider(doc.id));
    final messages = historyAsync.valueOrNull ?? const <ChatMessage>[];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.navyDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.emerald),
              const SizedBox(width: 6),
              Expanded(
                child: Text(t('grounded_notice'), style: AppTextStyles.caption(AppColors.onNavyMuted)),
              ),
            ],
          ),
        ),
        Expanded(
          child: historyAsync.isLoading && messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + 1 + (sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == 0) return _ClauseSummaryCard(doc: doc, t: t);
                    if (i - 1 < messages.length) return _ChatBubble(message: messages[i - 1]);
                    return const _TypingBubble();
                  },
                ),
        ),
        _ChatInputBar(controller: inputController, onSend: onSend, t: t, sending: sending),
      ],
    );
  }
}

class _ClauseSummaryCard extends StatelessWidget {
  final DocumentAnalysis doc;
  final String Function(String) t;
  const _ClauseSummaryCard({required this.doc, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc.title, style: AppTextStyles.label(AppColors.onNavyPrimary, size: 13)),
          const SizedBox(height: 10),
          if (doc.flags.isEmpty)
            Text(t('risk_clear'), style: AppTextStyles.body(AppColors.onNavyMuted, size: 13))
          else
            ...doc.flags.take(3).map((f) => _ClauseTile(flag: f)),
        ],
      ),
    );
  }
}

class _ClauseTile extends StatefulWidget {
  final ClauseFlag flag;
  const _ClauseTile({required this.flag});

  @override
  State<_ClauseTile> createState() => _ClauseTileState();
}

class _ClauseTileState extends State<_ClauseTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.riskColor(widget.flag.risk);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.flag.title, style: AppTextStyles.body(AppColors.onNavyPrimary, size: 13))),
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.onNavyMuted),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(widget.flag.explanation, style: AppTextStyles.body(AppColors.onNavyMuted, size: 12.5)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.emerald : AppColors.navyCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.body(isUser ? Colors.white : AppColors.onNavyPrimary, size: 14),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.navyCard, borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String Function(String) t;
  final bool sending;

  const _ChatInputBar({required this.controller, required this.onSend, required this.t, required this.sending});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.navyDark,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.attach_file_rounded, size: 16, color: AppColors.onNavyMuted),
              label: Text(t('attach_document'), style: AppTextStyles.caption(AppColors.onNavyMuted)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 24)),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.navyCard,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: controller,
                      style: AppTextStyles.body(AppColors.onNavyPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: t('type_question'),
                        hintStyle: AppTextStyles.body(AppColors.onNavyMuted),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.emerald,
                  child: IconButton(
                    onPressed: sending ? null : onSend,
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
