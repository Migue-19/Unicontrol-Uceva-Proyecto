import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/models/inscripcion_model.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/enrollment_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class MySubjectsScreen extends StatefulWidget {
  const MySubjectsScreen({super.key});

  @override
  State<MySubjectsScreen> createState() => _MySubjectsScreenState();
}

class _MySubjectsScreenState extends State<MySubjectsScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) {
      return {'estado': null, 'comentario': null, 'inscripciones': <InscripcionModel>[]};
    }

    final cargaInfo = await _enrollmentService.getCargaInfo(userId);
    final inscripciones = await _enrollmentService.fetchActiveLoadEnrollments(userId);
    return {
      'estado': cargaInfo['estado'],
      'comentario': cargaInfo['comentario'],
      'inscripciones': inscripciones,
    };
  }

  Future<void> _refresh() async {
    final f = _loadData();
    void _upd() { _dataFuture = f; } setState(_upd);
    await f;
  }

  Future<void> _confirmLoad() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirmar carga académica'),
        content: const Text(
          '¿Deseas confirmar tu selección actual de materias para continuar con el proceso?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return;

    final ok = await _enrollmentService.submitCargaAcademica(userId);

    if (!mounted) return;
    showAppSnackBar(
      context,
      ok
          ? 'Tu solicitud fue enviada correctamente y está pendiente de revisión.'
          : 'No fue posible enviar la solicitud. Verifica que tengas materias inscritas y un semestre activo.',
      isError: !ok,
    );

    if (ok) _refresh();
  }

  Future<void> _resetRechazada() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Editar solicitud rechazada'),
        content: const Text(
          'Tu carga volverá al estado de borrador para que puedas modificar tu lista de materias y enviarla nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return;

    final ok = await _enrollmentService.resetCargaRechazada(userId);

    if (!mounted) return;
    showAppSnackBar(
      context,
      ok
          ? 'Puedes editar y volver a enviar tu carga académica.'
          : 'No fue posible reactivar la solicitud. Intenta de nuevo.',
      isError: !ok,
    );

    if (ok) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Mis materias',
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerListPlaceholder();
            }
            final data = snapshot.data ?? {};
            final estado = data['estado'] as String?;
            final comentarioAdmin = data['comentario'] as String?;
            final inscripciones = (data['inscripciones'] as List<dynamic>?)?.cast<InscripcionModel>() ?? [];

            final totalCredits = inscripciones.fold<int>(
              0,
              (sum, item) => sum + (item.materia?.creditos ?? 0),
            );

            final isBorrador = estado == 'borrador';
            final isRechazada = estado == 'rechazada';
            final hasSubjects = inscripciones.isNotEmpty;
            final isCreditsOk = totalCredits <= 21;
            final canConfirm = isBorrador && hasSubjects && isCreditsOk;
            
            String tooltipMessage = '';
            if (!hasSubjects) {
              tooltipMessage = 'Agrega materias antes de confirmar';
            } else if (!isCreditsOk) {
              tooltipMessage = 'No puedes exceder 21 créditos';
            } else if (!isBorrador) {
              tooltipMessage = 'La solicitud ya fue enviada';
            }

            if (inscripciones.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  EmptyState(
                    title: 'Tu carga está vacía',
                    message:
                        'Aún no tienes materias inscritas. Explora el catálogo para comenzar.',
                    action: SizedBox(
                      width: 220,
                      child: GradientButton(
                        label: 'Ver catálogo',
                        onTap: () => context.go('/catalog'),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                if (isRechazada)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  color: AppTheme.destructive),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tu solicitud fue rechazada',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: AppTheme.destructive),
                                ),
                              ),
                            ],
                          ),
                          if (comentarioAdmin != null &&
                              comentarioAdmin.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Motivo: $comentarioAdmin',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 14),
                          GradientButton(
                            label: 'Editar mi solicitud',
                            icon: Icons.edit_outlined,
                            onTap: _resetRechazada,
                          ),
                        ],
                      ),
                    ),
                  ),
                StaggeredEntrance(
                  index: 0,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Carga actual',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            StatusBadge(
                              label: '$totalCredits créditos',
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Revisa tu selección antes de confirmar la carga académica.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...inscripciones.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final materia = item.materia;
                  final isConfirmed = item.estado.toLowerCase() == 'confirmada';
                  final badgeColor =
                      isConfirmed ? AppTheme.success : AppTheme.warning;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: StaggeredEntrance(
                      index: index + 1,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    materia?.nombre ?? 'Materia desconocida',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                StatusBadge(
                                  label: item.estado,
                                  color: badgeColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MetricTile(
                              icon: Icons.badge_outlined,
                              label: 'Código',
                              value: materia?.codigo.isNotEmpty == true
                                  ? materia!.codigo
                                  : 'Pendiente',
                            ),
                            const SizedBox(height: 8),
                            MetricTile(
                              icon: Icons.star_outline_rounded,
                              label: 'Créditos',
                              value: '${materia?.creditos ?? 0}',
                            ),
                            const SizedBox(height: 8),
                            MetricTile(
                              icon: Icons.schedule_rounded,
                              label: 'Registrada',
                              value: formatShortDate(item.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                StaggeredEntrance(
                  index: inscripciones.length + 2,
                  child: Tooltip(
                    message: tooltipMessage,
                    triggerMode: TooltipTriggerMode.tap,
                    child: PulseActionWrapper(
                      enabled: canConfirm,
                      child: GradientButton(
                        label: 'Confirmar carga',
                        icon: Icons.send_rounded,
                        onTap: canConfirm ? _confirmLoad : null,
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