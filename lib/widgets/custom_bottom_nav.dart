import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    this.isAdminSection = false,
  });

  final bool isAdminSection;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = isAdminSection ? _adminItems : _studentItems;
    final currentIndex = items.indexWhere(
      (item) => location.startsWith(item.route),
    );
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420;

    return Padding(
      padding: EdgeInsets.fromLTRB(isCompact ? 10 : 16, 0, isCompact ? 10 : 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120B2415),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          height: isCompact ? 70 : 76,
          labelBehavior: isCompact
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.12),
          selectedIndex: currentIndex < 0 ? 0 : currentIndex,
          onDestinationSelected: (index) => context.go(items[index].route),
          destinations: items
              .map(
                (item) => NavigationDestination(
                  icon: AnimatedSelectionIcon(
                    icon: item.icon,
                    selected: items.indexOf(item) ==
                        (currentIndex < 0 ? 0 : currentIndex),
                  ),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

const List<_NavItem> _studentItems = [
  _NavItem('/dashboard', 'Inicio', Icons.home_rounded),
  _NavItem('/catalog', 'Catalogo', Icons.grid_view_rounded),
  _NavItem('/my-subjects', 'Materias', Icons.menu_book_rounded),
  _NavItem('/messages', 'Mensajes', Icons.chat_bubble_outline_rounded),
  _NavItem('/profile', 'Perfil', Icons.person_outline_rounded),
];

const List<_NavItem> _adminItems = [
  _NavItem('/admin/solicitudes', 'Solicitudes', Icons.rule_folder_outlined),
  _NavItem('/admin/estudiantes', 'Estudiantes', Icons.groups_2_outlined),
  _NavItem('/admin/mensajes', 'Mensajes', Icons.markunread_outlined),
];
