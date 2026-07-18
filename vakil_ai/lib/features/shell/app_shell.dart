import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../chat/chat_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = ref.tr;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: FloatingActionButton(
          backgroundColor: AppColors.emerald,
          elevation: 4,
          onPressed: () => context.push('/scanner'),
          child: const Icon(Icons.document_scanner_rounded, color: Colors.white),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.navyDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: t('nav_home'), selected: _index == 0, onTap: () => setState(() => _index = 0)),
              _NavItem(icon: Icons.history_rounded, label: t('nav_history'), selected: _index == 1, onTap: () => setState(() => _index = 1)),
              const SizedBox(width: 48),
              _NavItem(icon: Icons.chat_bubble_rounded, label: t('nav_chat'), selected: _index == 2, onTap: () => setState(() => _index = 2)),
              _NavItem(icon: Icons.person_rounded, label: t('nav_profile'), selected: _index == 3, onTap: () => setState(() => _index = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.emerald : AppColors.onNavyMuted;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: AppTextStyles.caption(color, size: 10)),
          ],
        ),
      ),
    );
  }
}
