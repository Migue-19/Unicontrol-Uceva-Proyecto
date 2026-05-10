import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/supabase_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/custom_bottom_nav.dart';
import 'package:unicontrol_app/widgets/tutorial_sheet.dart';

class BaseView extends StatelessWidget {
  const BaseView({
    super.key,
    required this.title,
    required this.child,
    this.showBottomNav = true,
    this.floatingActionButton,
    this.actions,
    this.isAdminSection = false,
    this.useGradientBackground = false,
  });

  final String title;
  final Widget child;
  final bool showBottomNav;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final bool isAdminSection;
  final bool useGradientBackground;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final useWideLayout = screenWidth >= 900;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: useGradientBackground
            ? AppTheme.authBackgroundGradient
            : const LinearGradient(
                colors: [AppTheme.background, Color(0xFFEFF7F2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: child,
          ),
        ),
      ),
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: showBottomNav || isAdminSection
          ? AppBar(
              toolbarHeight: 84,
              titleSpacing: 20,
              title: Row(
                children: [
                  const UcevaLogoHero(size: 42, heroTag: 'uceva-appbar'),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('UniControl'),
                      Text(
                        isAdminSection ? 'Panel ADMIN' : title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  if (isAdminSection) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'ADMIN',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isAdminSection && authService.isAuthenticated)
                  const _NotificationAction(),
                if (!isAdminSection)
                  IconButton(
                    tooltip: 'Ver tutorial',
                    onPressed: () => showTutorialSheet(context),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                  ),
                ...?actions,
                const SizedBox(width: 12),
              ],
            )
          : null,
      body: content,
      bottomNavigationBar: showBottomNav && !useWideLayout
          ? CustomBottomNav(isAdminSection: isAdminSection)
          : null,
      floatingActionButton: floatingActionButton ??
          (showBottomNav && !isAdminSection
              ? FloatingActionButton(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  onPressed: () => showChatbotSheet(context),
                  child: const Icon(Icons.smart_toy_outlined),
                )
              : null),
    );
  }
}

class _NotificationAction extends StatelessWidget {
  const _NotificationAction();

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.id;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<int>(
      future: _countUnreadMessages(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (count > 0)
              Positioned(
                top: 14,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.destructive,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // columna corregida: receptor_id (era destinatario_id)
  Future<int> _countUnreadMessages(String userId) async {
    try {
      final result = await SupabaseService.client
          .from('mensajes')
          .select('id')
          .eq('receptor_id', userId)
          .eq('leido', false);
      return (result as List).length;
    } catch (_) {
      return 0;
    }
  }
}
