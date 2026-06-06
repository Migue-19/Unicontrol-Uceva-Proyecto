import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/supabase_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class AdminPerfilScreen extends StatefulWidget {
  const AdminPerfilScreen({super.key});

  @override
  State<AdminPerfilScreen> createState() => _AdminPerfilScreenState();
}

class _AdminPerfilScreenState extends State<AdminPerfilScreen> {
  final AdminService _adminService = AdminService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return {'facultadId': null, 'coordinadores': []};

    // Obtener la facultad_id directamente para pasarla a fetchCoordinadoresDeFacultad
    final raw = await SupabaseService.client
        .from('usuarios')
        .select('programas(facultad_id, facultades(nombre))')
        .eq('id', userId)
        .maybeSingle();

    final facultadId =
        (raw?['programas'] as Map<String, dynamic>?)?['facultad_id']
            as String?;

    final coordinadores = facultadId != null
        ? await _adminService.fetchCoordinadoresDeFacultad(facultadId)
        : <Map<String, dynamic>>[];

    return {
      'facultadId': facultadId,
      'coordinadores': coordinadores,
    };
  }

  Future<void> _refresh() async {
    final f = _loadData();
    void _upd() { _dataFuture = f; } setState(_upd);
    await f;
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de UniControl en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.destructive),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<AuthService>().logout();
        if (mounted) {
          showAppSnackBar(context, 'Sesión cerrada exitosamente');
          context.go('/login');
        }
      } catch (_) {
        if (mounted) {
          showAppSnackBar(context, 'Error al cerrar sesión', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.profile;
    final nombre = profile?.nombre ?? auth.user?.email?.split('@').first ?? 'Coordinador';
    final email = auth.user?.email ?? '';
    final codigo = profile?.codigoEstudiantil ?? 'Sin código';
    final programa = profile?.programaNombre ?? 'Sin programa';
    final facultad = profile?.facultadNombre ?? 'Sin facultad';

    return BaseView(
      title: 'Mi Perfil',
      isAdminSection: true,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final data = snapshot.data ?? {};
            final coordinadores =
                (data['coordinadores'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                    [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                // ── Card de perfil personal ──────────────────────────────────
                StaggeredEntrance(
                  index: 0,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              child: Text(
                                initialsFromName(nombre),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style:
                                        Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  Text(
                                    'Coordinador(a)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_outlined,
                                      size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ADMIN',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        MetricTile(
                          icon: Icons.email_outlined,
                          label: 'Correo',
                          value: email,
                        ),
                        const SizedBox(height: 12),
                        MetricTile(
                          icon: Icons.badge_outlined,
                          label: 'Código',
                          value: codigo,
                        ),
                        const SizedBox(height: 12),
                        MetricTile(
                          icon: Icons.school_outlined,
                          label: 'Programa',
                          value: programa,
                        ),
                        const SizedBox(height: 12),
                        MetricTile(
                          icon: Icons.account_balance_outlined,
                          label: 'Facultad',
                          value: facultad,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Sección de coordinadores colegas ─────────────────────────
                StaggeredEntrance(
                  index: 1,
                  child: Text(
                    'Coordinadores de mi Facultad',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),

                if (loading)
                  const ShimmerListPlaceholder()
                else if (coordinadores.isEmpty)
                  const AppCard(
                    child: Text('No hay otros coordinadores registrados en tu facultad.'),
                  )
                else
                  ...coordinadores.asMap().entries.map((entry) {
                    final i = entry.key;
                    final c = entry.value;
                    final cNombre = c['nombre'] as String? ?? 'Coordinador';
                    final cCodigo =
                        c['codigo_estudiantil'] as String? ?? 'Sin código';
                    final cPrograma =
                        (c['programas'] as Map<String, dynamic>?)?['nombre']
                            as String? ??
                        '';
                    final cEmail = c['email'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StaggeredEntrance(
                        index: i + 2,
                        child: AppCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                                child: Text(
                                  initialsFromName(cNombre),
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cNombre,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    if (cPrograma.isNotEmpty)
                                      Text(cPrograma,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    if (cEmail.isNotEmpty)
                                      Text(cEmail,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color:
                                                      AppTheme.mutedForeground)),
                                  ],
                                ),
                              ),
                              // Código — solo lectura
                              Text(
                                cCodigo,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                // ── Botón cerrar sesión ──────────────────────────────────────
                const SizedBox(height: 8),
                StaggeredEntrance(
                  index: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.destructive,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _confirmLogout,
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
            );
          },
        ),
      ),
    );
  }
}