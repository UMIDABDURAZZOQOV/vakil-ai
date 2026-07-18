import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models.dart';

final instantNotificationsProvider = StateProvider<bool>((ref) => true);
final autoTranslateSyncProvider = StateProvider<bool>((ref) => true);
final cloudArchiveProvider = StateProvider<bool>((ref) => true);

class TelegramSettingsScreen extends ConsumerWidget {
  const TelegramSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.tr;
    final user = ref.watch(currentUserProvider).valueOrNull ??
        const AppUser(name: '—', role: '', telegramConnected: false, documentsUsed: 0, documentsQuota: 2, isPremium: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vakil AI')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Color(0xFF29A9EA), shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(t('telegram_bot_integration'), style: AppTextStyles.heading(AppColors.ink, size: 16)),
                const SizedBox(height: 4),
                Text('@VakilAI_Bot', style: AppTextStyles.body(AppColors.inkMuted)),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${t('connected')}: ', style: AppTextStyles.body(AppColors.inkMuted, size: 13)),
                    Icon(
                      user.telegramConnected ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: user.telegramConnected ? AppColors.riskLow : AppColors.riskHigh,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(t('notifications'), style: AppTextStyles.heading(AppColors.ink, size: 16)),
          const SizedBox(height: 12),
          _Card(children: [
            _Toggle(
              label: t('instant_notifications'),
              value: ref.watch(instantNotificationsProvider),
              onChanged: (v) => ref.read(instantNotificationsProvider.notifier).state = v,
            ),
            const Divider(height: 1),
            _Toggle(
              label: t('auto_translate'),
              value: ref.watch(autoTranslateSyncProvider),
              onChanged: (v) => ref.read(autoTranslateSyncProvider.notifier).state = v,
            ),
            const Divider(height: 1),
            _Toggle(
              label: t('cloud_archive'),
              value: ref.watch(cloudArchiveProvider),
              onChanged: (v) => ref.read(cloudArchiveProvider.notifier).state = v,
            ),
          ]),
          const SizedBox(height: 26),
          Text(t('sync_options'), style: AppTextStyles.heading(AppColors.ink, size: 16)),
          const SizedBox(height: 12),
          _Card(children: [
            _NavRow(label: t('sync_history'), onTap: () {}),
            const Divider(height: 1),
            _NavRow(label: t('sync_documents'), onTap: () {}),
          ]),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.riskHigh,
                side: const BorderSide(color: AppColors.riskHigh),
              ),
              child: Text(t('unlink_telegram')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body(AppColors.ink))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.body(AppColors.ink))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
