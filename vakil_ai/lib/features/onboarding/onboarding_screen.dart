import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_locale.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _finish() => context.go('/welcome');

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final t = (String k) => ref.tr(k);
    final pages = [
      _OnboardingPageData(
        illustration: const _RiskGaugeIllustration(),
        title: t('onboarding_title_1'),
        description: t('onboarding_desc_1'),
      ),
      _OnboardingPageData(
        illustration: const _TranslateIllustration(),
        title: t('onboarding_title_2'),
        description: t('onboarding_desc_2'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(t('skip'), style: AppTextStyles.body(AppColors.inkMuted)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (context, i) {
                  final page = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        page.illustration,
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading(AppColors.ink, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(AppColors.inkMuted),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  Row(
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: _page == i ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == i ? AppColors.navy : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_page == pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(_page == pages.length - 1 ? t('get_started') : t('next')),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _LanguagePicker(
                current: locale,
                onChanged: (l) => ref.read(localeProvider.notifier).state = l,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final Widget illustration;
  final String title;
  final String description;
  _OnboardingPageData({required this.illustration, required this.title, required this.description});
}

class _LanguagePicker extends StatelessWidget {
  final AppLocale current;
  final ValueChanged<AppLocale> onChanged;
  const _LanguagePicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: AppLocale.values.map((l) {
        final selected = l == current;
        return GestureDetector(
          onTap: () => onChanged(l),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : Colors.transparent,
              border: Border.all(color: selected ? AppColors.navy : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l.code,
              style: AppTextStyles.label(selected ? Colors.white : AppColors.inkMuted),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RiskGaugeIllustration extends StatelessWidget {
  const _RiskGaugeIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(painter: _GaugePainter(), size: const Size(220, 160)),
    );
  }
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = size.width * 0.36;
    const startAngle = math.pi;
    const sweep = math.pi;

    final gaugePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        colors: [AppColors.riskLow, AppColors.riskMedium, AppColors.riskHigh],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      gaugePaint,
    );

    // Needle
    const needleAngle = math.pi + math.pi * 0.32;
    final needleEnd = Offset(
      center.dx + radius * 0.78 * math.cos(needleAngle),
      center.dy + radius * 0.78 * math.sin(needleAngle),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => false;
}

class _TranslateIllustration extends StatelessWidget {
  const _TranslateIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.navyDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, color: AppColors.onNavyMuted, size: 40),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.emerald, size: 22),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.emeraldDark, size: 26),
          ),
        ],
      ),
    );
  }
}
