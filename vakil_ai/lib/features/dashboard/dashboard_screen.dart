import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_locale.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';
import '../../widgets/risk_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.tr;
    final userAsync = ref.watch(currentUserProvider);
    final documentsAsync = ref.watch(documentsListProvider);
    final locale = ref.watch(localeProvider);
    final user = userAsync.valueOrNull ??
        const AppUser(name: '—', role: '', telegramConnected: false, documentsUsed: 0, documentsQuota: 2, isPremium: false);
    final documents = documentsAsync.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(documentsListProvider);
            await ref.read(documentsListProvider.future);
          },
          child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: AppLocale.values.map((l) {
                            final selected = l == locale;
                            return GestureDetector(
                              onTap: () => ref.read(localeProvider.notifier).state = l,
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.emerald : Colors.transparent,
                                  border: Border.all(color: selected ? AppColors.emerald : AppColors.navyLight),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(l.code,
                                    style: AppTextStyles.label(selected ? AppColors.navyDarkest : AppColors.onNavyMuted, size: 11)),
                              ),
                            );
                          }).toList(),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.navyLight,
                            child: Text(user.name.substring(0, 1),
                                style: AppTextStyles.heading(AppColors.onNavyPrimary, size: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(user.name, style: AppTextStyles.heading(AppColors.onNavyPrimary, size: 20)),
                    Text(user.role, style: AppTextStyles.body(AppColors.onNavyMuted, size: 13)),
                    const SizedBox(height: 16),
                    if (user.telegramConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(t('telegram_synced'), style: AppTextStyles.label(Colors.white)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    _QuotaBar(user: user, t: t),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t('recent_documents'), style: AppTextStyles.heading(AppColors.ink, size: 18)),
                        GestureDetector(
                          onTap: () => context.push('/history'),
                          child: Text(t('see_all'), style: AppTextStyles.body(AppColors.navy, size: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (documentsAsync.isLoading && documents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (documents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          t('add_new_document'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(AppColors.inkMuted),
                        ),
                      )
                    else
                      ...documents.map((doc) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DocumentCard(
                              title: doc.title,
                              date: doc.dateLabel,
                              riskLevel: doc.riskLevel,
                              riskLabel: t(_riskKey(doc.riskLevel)),
                              onTap: () => context.push('/analysis/${doc.id}'),
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

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
}

class _QuotaBar extends StatelessWidget {
  final AppUser user;
  final String Function(String) t;
  const _QuotaBar({required this.user, required this.t});

  @override
  Widget build(BuildContext context) {
    if (user.isPremium) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(Icons.bolt_rounded, size: 14, color: AppColors.gold),
        const SizedBox(width: 6),
        Text(
          '${t('free_tier_badge').split(':').first}: ${user.documentsQuota - user.documentsUsed}/${user.documentsQuota}',
          style: AppTextStyles.caption(AppColors.onNavyMuted),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String date;
  final RiskLevel riskLevel;
  final String riskLabel;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.title,
    required this.date,
    required this.riskLevel,
    required this.riskLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.riskSoftColor(riskLevel),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_rounded, color: AppColors.riskColor(riskLevel), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body(AppColors.ink, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(date, style: AppTextStyles.caption(AppColors.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RiskBadge(level: riskLevel, label: riskLabel),
            ],
          ),
        ),
      ),
    );
  }
}
