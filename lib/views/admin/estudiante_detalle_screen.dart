import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unicontrol_app/models/usuario_model.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class EstudianteDetalleScreen extends StatefulWidget {
  const EstudianteDetalleScreen({super.key, required this.estudianteId});

  final String estudianteId;

  @override
  State<EstudianteDetalleScreen> createState() =>
      _EstudianteDetalleScreenState();
}

class _EstudianteDetalleScreenState extends State<EstudianteDetalleScreen> {
  final AdminService _adminService = AdminService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final futures = await Future.wait([
      _adminService.fetchEstudianteDetalle(widget.estudianteId),
      _adminService.fetchHistorialAcciones(widget.estudianteId),
      _adminService.fetchHistorialAcademico(widget.estudianteId),
    ]);

    return {
      'estudiante': futures[0] as UsuarioModel?,
      'historialAcciones': futures[1] as List<Map<String, dynamic>>,
      'historialAcademico': futures[2] as List<Map<String, dynamic>>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Detalle del Estudiante',
      isAdminSection: true,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ShimmerListPlaceholder();
          }

          final data = snapshot.data ?? {};
          final estudiante = data['estudiante'] as UsuarioModel?;
          final acciones = data['historialAcciones'] as List<Map<String, dynamic>>? ?? [];
          final academico = data['historialAcademico'] as List<Map<String, dynamic>>? ?? [];

          if (estudiante == null) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                const EmptyState(
                  title: 'Estudiante no encontrado',
                  message: 'No se pudo cargar la información de este usuario.',
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver al listado'),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final f = _loadData();
              setState(() => _dataFuture = f);
              await f;
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 8),
                          Text('Volver', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(context, estudiante),
                      const SizedBox(height: 24),
                      Text(
                        'Historial Académico',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (academico.isEmpty)
                        const AppCard(
                          child: Text('No hay historial académico registrado.'),
                        )
                      else
                        ...academico.map((h) => _buildAcademicoCard(context, h)),
                      const SizedBox(height: 24),
                      Text(
                        'Historial de Acciones',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (acciones.isEmpty)
                        const AppCard(
                          child: Text('No hay historial de acciones registrado.'),
                        )
                      else
                        ...acciones.map((h) => _buildAccionCard(context, h)),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, UsuarioModel estudiante) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  initialsFromName(estudiante.nombre),
                  style: const TextStyle(
                    fontSize: 20,
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
                      estudiante.nombre,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      estudiante.email ?? 'Sin correo',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedForeground,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          MetricTile(
            icon: Icons.badge_outlined,
            label: 'Código Estudiantil',
            value: estudiante.codigoEstudiantil ?? 'Pendiente',
          ),
          const SizedBox(height: 12),
          MetricTile(
            icon: Icons.numbers_rounded,
            label: 'Semestre Actual',
            value: '${estudiante.semestreActual}',
          ),
          const SizedBox(height: 12),
          MetricTile(
            icon: Icons.school_outlined,
            label: 'Programa',
            value: estudiante.programaNombre ?? 'Sin programa',
          ),
          const SizedBox(height: 12),
          MetricTile(
            icon: Icons.account_balance_outlined,
            label: 'Facultad',
            value: estudiante.facultadNombre ?? 'Sin facultad',
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicoCard(BuildContext context, Map<String, dynamic> item) {
    final materias = item['materias'] as Map<String, dynamic>?;
    final materiaNombre = materias?['nombre'] ?? 'Materia desconocida';
    final materiaCodigo = materias?['codigo'] ?? '';
    final estado = item['estado'] ?? 'desconocido';
    final nota = item['nota']?.toString() ?? '-';
    final periodo = item['periodo'] ?? '-';

    Color estadoColor;
    if (estado == 'aprobada') {
      estadoColor = AppTheme.success;
    } else if (estado == 'reprobada') {
      estadoColor = AppTheme.destructive;
    } else {
      estadoColor = AppTheme.mutedForeground;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    materiaNombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                StatusBadge(label: estado.toUpperCase(), color: estadoColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.tag_rounded,
                    label: 'Código',
                    value: materiaCodigo,
                  ),
                ),
                Expanded(
                  child: MetricTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Periodo',
                    value: periodo,
                  ),
                ),
                Expanded(
                  child: MetricTile(
                    icon: Icons.grading_rounded,
                    label: 'Nota',
                    value: nota,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionCard(BuildContext context, Map<String, dynamic> item) {
    final accion = item['accion'] ?? 'Acción desconocida';
    final descripcion = item['descripcion'] ?? 'Sin descripción';
    final fecha = item['created_at'] != null 
        ? DateTime.tryParse(item['created_at']) 
        : null;
    final fechaStr = fecha != null 
        ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
        : 'Fecha desconocida';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.history_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accion,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fechaStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}