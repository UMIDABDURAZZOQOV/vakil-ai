import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/gradient_logo.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.tr;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const GradientLogo(size: 96, showWordmark: false),
                const SizedBox(height: 32),
                Text(
                  t('welcome_headline'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(AppColors.onNavyPrimary, size: 34),
                ),
                const SizedBox(height: 14),
                Text(
                  t('tagline'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(AppColors.onNavyMuted, size: 16),
                ),
                const Spacer(flex: 3),
                GradientButton(
                  label: t('login_with_telegram'),
                  icon: Icons.send_rounded,
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Tez orada qo\'shiladi'))),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => context.push('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onNavyPrimary,
                    side: const BorderSide(color: AppColors.navyLight, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Text(t('login_with_phone')),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text(t('no_account'), style: AppTextStyles.body(AppColors.onNavyMuted)),
                ),
                const SizedBox(height: 20),
                Text(
                  t('agree_terms'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(AppColors.onNavyMuted),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: Text(t('forgot_password'), style: AppTextStyles.body(AppColors.onNavyMuted)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
