import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/jwt_auth_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cerrar sesión'),
        content:
            const Text('¿Deseas salir de UniControl en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.destructive),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AuthService>().logout();
        await context.read<JwtAuthService>().logout();
        if (context.mounted) {
          showAppSnackBar(context, 'Sesión cerrada exitosamente');
          context.go('/login');
        }
      } catch (_) {
        if (context.mounted) {
          showAppSnackBar(context, 'Error al cerrar sesión', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final jwtService = context.watch<JwtAuthService>();

    final profile = authService.profile;
    final jwtUser = jwtService.user;

    final displayName = profile?.nombre ??
        authService.user?.email?.split('@').first ??
        jwtUser?.nombre ??
        'Usuario';

    final email = profile?.email ??
        authService.user?.email ??
        jwtUser?.email ??
        'Sin sesión';

    final programaNombre =
        profile?.programaNombre ?? jwtUser?.programaNombre;

    final facultadNombre =
        profile?.facultadNombre ?? jwtUser?.facultadNombre;

    final codigoEstudiantil =
        profile?.codigoEstudiantil ?? jwtUser?.codigoEstudiantil;

    final semestre =
        profile?.semestreActual ?? jwtUser?.semestreActual;

    final role = authService.role ?? jwtUser?.role ?? 'estudiante';

    return BaseView(
      title: 'Perfil',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          StaggeredEntrance(
            index: 0,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    initialsFromName(displayName),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          StaggeredEntrance(
            index: 1,
            child: AppCard(
              child: Column(
                children: [
                  _ProfileInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Código estudiantil',
                    value: codigoEstudiantil ?? 'Pendiente',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoRow(
                    icon: Icons.account_balance_outlined,
                    label: 'Facultad',
                    value: facultadNombre ?? 'Pendiente',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoRow(
                    icon: Icons.school_outlined,
                    label: 'Programa académico',
                    value: programaNombre ?? 'Pendiente',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoRow(
                    icon: Icons.timeline_outlined,
                    label: 'Semestre',
                    value: semestre?.toString() ?? 'Pendiente',
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Rol',
                    value: role,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          StaggeredEntrance(
            index: 2,
            child: Center(
              child: TextButton.icon(
                onPressed: () => context.go('/session-info'),
                icon: const Icon(Icons.storage_outlined, size: 16),
                label: const Text('Ver almacenamiento local'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.mutedForeground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          StaggeredEntrance(
            index: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.destructive,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _confirmLogout(context),
                  child: const SizedBox(
                    height: 56,
                    child: Center(
                      child: Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}