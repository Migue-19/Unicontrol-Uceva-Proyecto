import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return {'solicitudes': 0, 'facultad': null};

    final solicitudes = await _adminService.fetchSolicitudes();
    final facultad = await _adminService.fetchFacultadDelAdmin(userId);
    
    return {
      'solicitudes': solicitudes.length,
      'facultad': facultad,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final profile = authService.profile;
    final name = profile?.nombre ??
        authService.user?.email?.split('@').first ??
        'Coordinador';

    return BaseView(
      title: 'Panel Administrativo',
      isAdminSection: true,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final data = snapshot.data ?? {'solicitudes': 0, 'facultad': null};
          final pendingCount = data['solicitudes'] as int;
          final facultadName = data['facultad'] as String? ?? 'Desconocida';

          final cards = [
            const _DashboardShortcut(
              title: 'Estudiantes de mi Facultad',
              subtitle: 'Ver y gestionar estudiantes de tu facultad',
              icon: Icons.people_rounded,
              color: Color(0xFF1B7A3E),
              route: '/admin/estudiantes',
            ),
            _DashboardShortcut(
              title: 'Solicitudes Pendientes',
              subtitle: 'Aprobar o rechazar cargas académicas',
              icon: Icons.assignment_rounded,
              color: const Color(0xFF2563EB),
              route: '/admin/solicitudes',
              badgeCount: pendingCount,
            ),
            const _DashboardShortcut(
              title: 'Mensajes Enviados',
              subtitle: 'Historial de mensajes a estudiantes',
              icon: Icons.forum_rounded,
              color: Color(0xFFF59E0B),
              route: '/admin/mensajes',
            ),
            const _DashboardShortcut(
              title: 'Mi Perfil y Coordinadores',
              subtitle: 'Tu información y colegas de facultad',
              icon: Icons.badge_rounded,
              color: Color(0xFF7C3AED),
              route: '/admin/perfil',
            ),
          ];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataFuture = _loadData();
              });
              await _dataFuture;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                StaggeredEntrance(
                  index: 0,
                  child: Text(
                    'Bienvenido, $name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                StaggeredEntrance(
                  index: 1,
                  child: Text(
                    'Coordinador — Facultad de $facultadName',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final item = cards[index];
                    return StaggeredEntrance(
                      index: index + 2,
                      child: HoverScaleCard(
                        onTap: () => context.go(item.route),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: item.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(item.icon, color: item.color),
                                  ),
                                  if (item.badgeCount != null && item.badgeCount! > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.destructive,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${item.badgeCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.subtitle,
                                style: Theme.of(context).textTheme.bodySmall,
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
    this.badgeCount,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final int? badgeCount;
}
