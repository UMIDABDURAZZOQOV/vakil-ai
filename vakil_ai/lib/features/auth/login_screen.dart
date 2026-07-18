import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/api_exception.dart';
import '../../widgets/gradient_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _idController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final token = await ref.read(authRepositoryProvider).login(identifier: identifier, password: password);
      await ref.read(authTokenProvider.notifier).setToken(token);
      if (mounted) context.go('/dashboard');
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Serverga ulanib bo\'lmadi. Backend ishga tushirilganini tekshiring.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.tr;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: GradientLogo(
                  size: 56,
                  showWordmark: false,
                  gradientColors: [AppColors.navy, AppColors.emerald],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t('log_in'),
                textAlign: TextAlign.center,
                style: AppTextStyles.display(AppColors.ink, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                t('create_account_subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.body(AppColors.inkMuted),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _idController,
                decoration: InputDecoration(hintText: t('phone_or_email')),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: t('password'),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.inkMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(t('log_in')),
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text('${t('no_account')} ', style: AppTextStyles.body(AppColors.inkMuted)),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        t('register'),
                        style: AppTextStyles.body(AppColors.navy, weight: FontWeight.w600)
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
