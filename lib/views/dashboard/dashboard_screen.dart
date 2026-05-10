import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/enrollment_service.dart';
import 'package:unicontrol_app/services/jwt_auth_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  late Future<int> _enrollmentsCountFuture;

  @override
  void initState() {
    super.initState();
    // Intentar con AuthService primero, si no con JwtAuthService
    final userId = context.read<AuthService>().user?.id;
    _enrollmentsCountFuture = _loadEnrollmentCount(userId);
  }

  Future<int> _loadEnrollmentCount(String? userId) async {
    if (userId == null) return 0;
    final enrollments = await _enrollmentService.fetchEnrollments(userId);
    return enrollments.length;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final jwtService = context.watch<JwtAuthService>(); // ✅ escuchar JWT también

    // ✅ Resolver nombre: prioridad AuthService (Google/Supabase SDK),
    //    fallback JwtAuthService (login con email/password)
    final profile = authService.profile;
    final name = profile?.nombre ??
        authService.user?.email?.split('@').first ??
        jwtService.user?.nombre ?? // ✅ fallback JWT
        'Estudiante';

    // ✅ Resolver si es admin: AuthService tiene el rol real del SDK
    final isAdmin = authService.isAdmin ||
        jwtService.user?.role == 'admin'; // ✅ fallback JWT

    final cards = [
      const _DashboardShortcut(
        title: 'Catálogo',
        subtitle: 'Busca materias por semestre',
        icon: Icons.grid_view_rounded,
        color: Color(0xFF1B7A3E),
        route: '/catalog',
      ),
      const _DashboardShortcut(
        title: 'Mis materias',
        subtitle: 'Revisa tu carga actual',
        icon: Icons.menu_book_rounded,
        color: Color(0xFF2563EB),
        route: '/my-subjects',
      ),
      const _DashboardShortcut(
        title: 'Cancelar',
        subtitle: 'Gestiona retiros de asignaturas',
        icon: Icons.delete_outline_rounded,
        color: Color(0xFFDC2626),
        route: '/cancel-subjects',
      ),
      const _DashboardShortcut(
        title: 'Mensajes',
        subtitle: 'Consulta notificaciones y avisos',
        icon: Icons.forum_outlined,
        color: Color(0xFFF59E0B),
        route: '/messages',
      ),
      if (isAdmin) // ✅ usa la variable unificada
        const _DashboardShortcut(
          title: 'Panel admin',
          subtitle: 'Aprueba solicitudes y mensajes',
          icon: Icons.shield_outlined,
          color: Color(0xFF7C3AED),
          route: '/admin/solicitudes',
        ),
    ];

    return BaseView(
      title: 'Inicio',
      child: FutureBuilder<int>(
        future: _enrollmentsCountFuture,
        builder: (context, snapshot) {
          final enrolledCount = snapshot.data ?? 0;
          final progress = (enrolledCount / 8).clamp(0.0, 1.0);

          // ✅ Perfil completo: AuthService si tiene sesión SDK, sino JWT
          final hasCompletedProfile = authService.hasCompletedProfile ||
              (jwtService.isAuthenticated &&
                  jwtService.user?.programaNombre != null);

          return RefreshIndicator(
            onRefresh: () async {
              final userId = context.read<AuthService>().user?.id;
              setState(() {
                _enrollmentsCountFuture = _loadEnrollmentCount(userId);
              });
              await _enrollmentsCountFuture;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                StaggeredEntrance(
                  index: 0,
                  child: Text(
                    '¡Hola, $name! 👋',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                StaggeredEntrance(
                  index: 1,
                  child: Text(
                    'Así va tu actividad académica para este periodo en UniControl.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 18),
                StaggeredEntrance(
                  index: 2,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progreso de créditos',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$enrolledCount materias activas registradas',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(
                              label: hasCompletedProfile
                                  ? 'Perfil completo'
                                  : 'Perfil pendiente',
                              color: hasCompletedProfile
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 700),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(999),
                              backgroundColor: const Color(0xFFE8F2EC),
                              color: AppTheme.primary,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(progress * 100).round()}% de tu objetivo sugerido del semestre',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final item = cards[index];
                    return StaggeredEntrance(
                      index: index + 3,
                      child: HoverScaleCard(
                        onTap: () => context.go(item.route),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color:
                                      item.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child:
                                    Icon(item.icon, color: item.color),
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.subtitle,
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardShortcut {
  const _DashboardShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}