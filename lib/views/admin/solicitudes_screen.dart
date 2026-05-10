import 'package:flutter/material.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<Map<String, dynamic>>> _solicitudesFuture;

  @override
  void initState() {
    super.initState();
    _solicitudesFuture = _adminService.fetchSolicitudes();
  }

  Future<void> _refresh() async {
    setState(() => _solicitudesFuture = _adminService.fetchSolicitudes());
    await _solicitudesFuture;
  }

  Future<void> _handleDecision(String cargaId, bool approved) async {
    final result = await _adminService.resolverSolicitud(cargaId, approved);
    if (!mounted) return;
    showAppSnackBar(
      context,
      result
          ? (approved ? 'Solicitud aprobada' : 'Solicitud rechazada')
          : 'No fue posible actualizar la solicitud',
      isError: !result,
    );
    if (result) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Solicitudes',
      isAdminSection: true,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _solicitudesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerListPlaceholder();
            }
            final solicitudes = snapshot.data ?? [];
            if (solicitudes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'Sin solicitudes pendientes',
                    message:
                        'Las nuevas cargas académicas aparecerán aquí para revisión.',
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: solicitudes.asMap().entries.map((entry) {
                final index = entry.key;
                final sol = entry.value;
                final id = sol['id']?.toString() ?? '';
                final estado =
                    sol['estado']?.toString().toLowerCase() ?? 'borrador';
                final usuario = sol['usuarios'] as Map<String, dynamic>?;
                final nombre = usuario?['nombre'] as String? ?? 'Estudiante';
                final codigo =
                    usuario?['codigo_estudiantil'] as String? ?? '';
                final creditos = sol['total_creditos']?.toString() ?? '0';
                final fecha =
                    sol['fecha_solicitud']?.toString().split('T').first ??
                        sol['created_at']?.toString().split('T').first ??
                        'Sin fecha';

                final color = switch (estado) {
                  'aprobada' => AppTheme.success,
                  'rechazada' => AppTheme.destructive,
                  'enviada' => AppTheme.warning,
                  _ => const Color(0xFF9E9E9E),
                };

                final isPending = estado == 'enviada';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: StaggeredEntrance(
                    index: index,
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: isPending ? 210 : 140,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(20)),
                          ),
                        ),
                        Expanded(
                          child: AppCard(
                            borderColor: Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(nombre,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          if (codigo.isNotEmpty)
                                            Text(codigo,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(label: estado, color: color),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Créditos: $creditos  ·  Fecha: $fecha',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (isPending) ...[
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _DecisionButton(
                                          label: 'Aprobar',
                                          color: AppTheme.success,
                                          onTap: () =>
                                              _handleDecision(id, true),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _DecisionButton(
                                          label: 'Rechazar',
                                          color: AppTheme.destructive,
                                          onTap: () =>
                                              _handleDecision(id, false),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
