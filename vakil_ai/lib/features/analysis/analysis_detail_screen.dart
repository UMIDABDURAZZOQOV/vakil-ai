import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../../widgets/risk_badge.dart';

class AnalysisDetailScreen extends ConsumerWidget {
  final String documentId;
  const AnalysisDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.tr;
    final docAsync = ref.watch(documentDetailProvider(documentId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
          ),
          title: Text(t('analysis_detail')),
          bottom: TabBar(
            indicatorColor: AppColors.emerald,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.onNavyMuted,
            labelStyle: AppTextStyles.label(Colors.white, size: 13),
            tabs: [
              Tab(text: t('original_text')),
              Tab(text: t('plain_summary')),
            ],
          ),
        ),
        body: docAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$err', style: AppTextStyles.body(AppColors.inkMuted), textAlign: TextAlign.center),
            ),
          ),
          data: (doc) {
            final paragraphs = doc.originalText.split('\n\n');
            return Column(
              children: [
                _DocumentHeader(doc: doc, t: t),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OriginalTextTab(doc: doc, paragraphs: paragraphs),
                      _SummaryTab(doc: doc, t: t),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  final DocumentAnalysis doc;
  final String Function(String) t;
  const _DocumentHeader({required this.doc, required this.t});

  String _riskKey(RiskLevel level) => switch (level) {
        RiskLevel.high => 'risk_high',
        RiskLevel.medium => 'risk_medium',
        RiskLevel.low => 'risk_low',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navyDark,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc.title, style: AppTextStyles.body(Colors.white, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              RiskBadge(level: doc.riskLevel, label: t(_riskKey(doc.riskLevel)), solid: true),
              const SizedBox(width: 10),
              Text(doc.dateLabel, style: AppTextStyles.caption(AppColors.onNavyMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OriginalTextTab extends StatelessWidget {
  final DocumentAnalysis doc;
  final List<String> paragraphs;
  const _OriginalTextTab({required this.doc, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: paragraphs.length,
      itemBuilder: (context, i) {
        final flag = i < doc.flags.length ? doc.flags[i] : null;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: flag != null ? AppColors.riskSoftColor(flag.risk) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: flag != null ? AppColors.riskColor(flag.risk).withValues(alpha: 0.3) : AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (flag != null) ...[
                Icon(Icons.flag_rounded, size: 16, color: AppColors.riskColor(flag.risk)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(paragraphs[i], style: AppTextStyles.body(AppColors.ink, size: 13.5)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final DocumentAnalysis doc;
  final String Function(String) t;
  const _SummaryTab({required this.doc, required this.t});

  @override
  Widget build(BuildContext context) {
    final avgCompliance = doc.complianceScores.values.isEmpty
        ? 0
        : doc.complianceScores.values.reduce((a, b) => a + b) / doc.complianceScores.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: doc.summaryBullets
                .map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(Icons.circle, size: 6, color: AppColors.navy),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(b, style: AppTextStyles.body(AppColors.ink, size: 14))),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        if (doc.keyDates.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(t('key_dates'), style: AppTextStyles.heading(AppColors.ink, size: 16)),
          const SizedBox(height: 10),
          ...doc.keyDates.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, size: 16, color: AppColors.navy),
                    const SizedBox(width: 10),
                    Expanded(child: Text(d, style: AppTextStyles.body(AppColors.ink, size: 13.5))),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Text(t('compliance_score'), style: AppTextStyles.heading(AppColors.ink, size: 16)),
              const SizedBox(height: 16),
              CircularPercentIndicator(
                radius: 74,
                lineWidth: 14,
                percent: (avgCompliance / 100).clamp(0, 1).toDouble(),
                animation: true,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: AppColors.border,
                progressColor: avgCompliance >= 80
                    ? AppColors.riskLow
                    : avgCompliance >= 60
                        ? AppColors.riskMedium
                        : AppColors.riskHigh,
                center: Text('${avgCompliance.toStringAsFixed(0)}%',
                    style: AppTextStyles.heading(AppColors.ink, size: 22)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...doc.complianceScores.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: AppTextStyles.body(AppColors.ink, weight: FontWeight.w600, size: 13)),
                      Text('${e.value}%', style: AppTextStyles.body(AppColors.inkMuted, size: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearPercentIndicator(
                    percent: e.value / 100,
                    lineHeight: 8,
                    barRadius: const Radius.circular(6),
                    animation: true,
                    backgroundColor: AppColors.border,
                    progressColor: AppColors.navy,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            )),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(t('download_pdf')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29A9EA)),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(t('share_telegram')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.navyDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t('powered_by'), style: AppTextStyles.caption(AppColors.onNavyMuted)),
          ),
        ),
      ],
    );
  }
}
