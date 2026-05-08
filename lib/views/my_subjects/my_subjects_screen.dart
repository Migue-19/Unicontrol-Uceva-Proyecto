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
  late Future<List<InscripcionModel>> _enrollmentsFuture;

  @override
  void initState() {
    super.initState();
    _enrollmentsFuture = _loadEnrollments();
  }

  Future<List<InscripcionModel>> _loadEnrollments() {
    final userId = context.read<AuthService>().user?.id;
    return userId != null
        ? _enrollmentService.fetchEnrollments(userId)
        : Future.value([]);
  }

  Future<void> _refresh() async {
    setState(() {
      _enrollmentsFuture = _loadEnrollments();
    });
    await _enrollmentsFuture;
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

    if (confirmed == true && mounted) {
      showAppSnackBar(
        context,
        'Tu carga académica quedó marcada como lista para revisión.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Mis materias',
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<InscripcionModel>>(
          future: _enrollmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerListPlaceholder();
            }
            final inscripciones = snapshot.data ?? [];
            final totalCredits = inscripciones.fold<int>(
              0,
              (sum, item) => sum + (item.materia?.creditos ?? 0),
            );

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
                  child: PulseActionWrapper(
                    enabled: inscripciones.isNotEmpty,
                    child: GradientButton(
                      label: 'Confirmar carga',
                      icon: Icons.send_rounded,
                      onTap: _confirmLoad,
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