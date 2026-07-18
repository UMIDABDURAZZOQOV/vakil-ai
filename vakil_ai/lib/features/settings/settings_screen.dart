import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_locale.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/api_exception.dart';
import '../../data/models.dart';

final autoTranslateProvider = StateProvider<bool>((ref) => true);
final riskNotificationsProvider = StateProvider<bool>((ref) => true);
final languageDetectionProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.tr;
    final user = ref.watch(currentUserProvider).valueOrNull ??
        const AppUser(name: '—', role: '', telegramConnected: false, documentsUsed: 0, documentsQuota: 2, isPremium: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.navy,
                  child: Text(user.name.substring(0, 1), style: AppTextStyles.heading(Colors.white, size: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: AppTextStyles.heading(AppColors.ink, size: 18)),
                      Text(user.role, style: AppTextStyles.body(AppColors.inkMuted, size: 13)),
                    ],
                  ),
                ),
                if (!user.isPremium)
                  OutlinedButton(
                    onPressed: () => _showUpgradeSheet(context, ref),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                    ),
                    child: Text(t('upgrade_premium'), style: AppTextStyles.label(AppColors.gold, size: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(t('interface_language'), style: AppTextStyles.heading(AppColors.ink, size: 15)),
            const SizedBox(height: 10),
            const _LanguageSwitcher(),
            const SizedBox(height: 28),
            Text(t('settings'), style: AppTextStyles.heading(AppColors.ink, size: 20)),
            const SizedBox(height: 14),
            _SettingsCard(children: [
              _ToggleTile(
                icon: Icons.translate_rounded,
                label: t('auto_translate'),
                value: ref.watch(autoTranslateProvider),
                onChanged: (v) => ref.read(autoTranslateProvider.notifier).state = v,
              ),
              const Divider(height: 1),
              _ToggleTile(
                icon: Icons.notifications_active_outlined,
                label: t('risk_notifications'),
                value: ref.watch(riskNotificationsProvider),
                onChanged: (v) => ref.read(riskNotificationsProvider.notifier).state = v,
              ),
              const Divider(height: 1),
              _ToggleTile(
                icon: Icons.language_rounded,
                label: t('language_detection'),
                value: ref.watch(languageDetectionProvider),
                onChanged: (v) => ref.read(languageDetectionProvider.notifier).state = v,
              ),
            ]),
            const SizedBox(height: 18),
            _SettingsCard(children: [
              _NavTile(
                icon: Icons.send_rounded,
                iconColor: const Color(0xFF29A9EA),
                label: t('telegram_bot_integration'),
                trailing: _StatusPill(connected: user.telegramConnected, t: t),
                onTap: () => context.push('/settings/telegram'),
              ),
            ]),
            const SizedBox(height: 18),
            _SettingsCard(children: [
              _NavTile(icon: Icons.manage_accounts_outlined, label: t('account_settings'), onTap: () {}),
              const Divider(height: 1),
              _NavTile(icon: Icons.shield_outlined, label: t('privacy'), onTap: () {}),
              const Divider(height: 1),
              _NavTile(icon: Icons.help_outline_rounded, label: t('help'), onTap: () {}),
              const Divider(height: 1),
              _NavTile(
                icon: Icons.logout_rounded,
                label: t('logout'),
                labelColor: AppColors.riskHigh,
                onTap: () async {
                  await ref.read(authTokenProvider.notifier).clear();
                  if (context.mounted) context.go('/welcome');
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

Future<void> _showUpgradeSheet(BuildContext context, WidgetRef ref) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
              Text('Premium tarif',
                  textAlign: TextAlign.center, style: AppTextStyles.heading(AppColors.ink, size: 19)),
              const SizedBox(height: 6),
              Text(
                'Oyiga 49 000 so\'m — cheksiz hujjat tahlili',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(AppColors.inkMuted, size: 13),
              ),
              const SizedBox(height: 24),
              _PaymentCard(
                title: 'Payme',
                subtitle: 'Bank kartasi orqali to\'lash',
                badge: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/brand/payme_logo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                onTap: () => _launchCheckout(sheetContext, ref, 'payme'),
              ),
              const SizedBox(height: 12),
              _PaymentCard(
                title: 'Click',
                subtitle: 'Bank kartasi orqali to\'lash',
                badgeWidth: 92,
                badge: Container(
                  width: 92,
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF0065FF), borderRadius: BorderRadius.circular(14)),
                  child: SvgPicture.asset('assets/brand/click_logo.svg', height: 20),
                ),
                onTap: () => _launchCheckout(sheetContext, ref, 'click'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.inkMuted),
                  const SizedBox(width: 6),
                  Text('Hozircha test rejimi', style: AppTextStyles.caption(AppColors.inkMuted)),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _launchCheckout(BuildContext context, WidgetRef ref, String provider) async {
  Navigator.of(context).pop();
  try {
    final url = await ref.read(paymentsRepositoryProvider).createCheckoutUrl(provider);
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('launch failed');
    }
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('To\'lov sahifasini ochib bo\'lmadi.')));
    }
  }
}

/// Brand-styled selectable payment method card, using each provider's real
/// logo (downloaded from their own official site — assets/brand/). Swapping
/// test credentials for real Payme/Click merchant keys in backend/.env is
/// the only change needed to go live — this UI doesn't change.
class _PaymentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget badge;
  final double badgeWidth;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    this.badgeWidth = 52,
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
              SizedBox(width: badgeWidth, height: 52, child: badge),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body(AppColors.ink, size: 15, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption(AppColors.inkMuted)),
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

class _StatusPill extends StatelessWidget {
  final bool connected;
  final String Function(String) t;
  const _StatusPill({required this.connected, required this.t});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.riskLow : AppColors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(connected ? t('connected') : t('not_connected'), style: AppTextStyles.caption(color)),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

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

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.body(AppColors.ink))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    this.iconColor,
    required this.label,
    this.labelColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.navy, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.body(labelColor ?? AppColors.ink))),
            if (trailing != null) trailing!,
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Three-way segmented language switcher — the app's full interface
/// language, distinct from the "Tilni aniqlash" toggle above (which is
/// about auto-detecting an uploaded document's language, not the UI's).
class _LanguageSwitcher extends ConsumerWidget {
  const _LanguageSwitcher();

  static const _nativeNames = {
    AppLocale.uz: "O'zbek",
    AppLocale.ru: 'Русский',
    AppLocale.en: 'English',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: AppLocale.values.map((locale) {
          final selected = locale == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(localeProvider.notifier).state = locale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [BoxShadow(color: AppColors.navy.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))]
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: AppTextStyles.label(
                    selected ? Colors.white : AppColors.inkMuted,
                    size: 13,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  child: Text(_nativeNames[locale]!, textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
