import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../../widgets/risk_badge.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = ref.tr;
    final documentsAsync = ref.watch(documentsListProvider);
    final documents = (documentsAsync.valueOrNull ?? const <DocumentAnalysis>[]).where((d) {
      if (_query.isEmpty) return true;
      return d.title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(t('search_history'))),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: t('search_history'),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.inkMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: documentsAsync.isLoading && documents.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : documents.isEmpty
                      ? Center(child: Text(t('search'), style: AppTextStyles.body(AppColors.inkMuted)))
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(documentsListProvider);
                            await ref.read(documentsListProvider.future);
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: documents.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final doc = documents[i];
                              return _HistoryCard(doc: doc, t: t, onTap: () => context.push('/analysis/${doc.id}'));
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scanner'),
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: Text(t('add_new_document')),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DocumentAnalysis doc;
  final String Function(String) t;
  final VoidCallback onTap;

  const _HistoryCard({required this.doc, required this.t, required this.onTap});

  String _riskKey(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return 'risk_high';
      case RiskLevel.medium:
        return 'risk_medium';
      case RiskLevel.low:
        return 'risk_low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.riskColor(doc.riskLevel);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(AppColors.ink, weight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(doc.dateLabel, style: AppTextStyles.caption(AppColors.inkMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RiskBadge(level: doc.riskLevel, label: t(_riskKey(doc.riskLevel))),
                        const SizedBox(width: 8),
                        Text('${t('risk_score')}: ${doc.riskScore.toStringAsFixed(1)}/10',
                            style: AppTextStyles.caption(AppColors.inkMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
