import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/gradient_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      final hasToken = ref.read(authTokenProvider) != null;
      context.go(hasToken ? '/dashboard' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GradientLogo(size: 88, showWordmark: false),
              const SizedBox(height: 20),
              Text('Vakil AI', style: AppTextStyles.display(AppColors.onNavyPrimary, size: 34)),
              const SizedBox(height: 10),
              Text(
                'Ishonchli yuridik yordamchingiz',
                style: AppTextStyles.body(AppColors.onNavyMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
