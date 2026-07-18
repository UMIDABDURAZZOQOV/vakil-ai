import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/api/api_exception.dart';
import '../../widgets/gradient_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
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
    if (identifier.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telefon/email va kamida 6 belgili parol kiriting")),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final token = await ref.read(authRepositoryProvider).register(identifier: identifier, password: password);
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
                t('create_account_title'),
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
                    : Text(t('register')),
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text('${t('already_have_account')} ', style: AppTextStyles.body(AppColors.inkMuted)),
                    GestureDetector(
                      onTap: () => context.push('/login'),
                      child: Text(
                        t('log_in'),
                        style: AppTextStyles.body(AppColors.navy, weight: FontWeight.w600)
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(t('or_continue_with'), style: AppTextStyles.caption(AppColors.inkMuted)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Tez orada qo\'shiladi'))),
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 26, color: AppColors.ink),
                      label: const Text('Google'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Tez orada qo\'shiladi'))),
                      icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF29A9EA)),
                      label: const Text('Telegram'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.navyDark,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.onNavyMuted),
            const SizedBox(width: 8),
            Text(t('secured_by'), style: AppTextStyles.caption(AppColors.onNavyMuted)),
          ],
        ),
      ),
    );
  }
}
