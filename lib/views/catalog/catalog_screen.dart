import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/models/materia_model.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/enrollment_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  late Future<List<MateriaModel>> _catalogFuture;
  int? _selectedSemester;
  String? _loadingMateriaId;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _enrollmentService.fetchCatalog();
  }

  Future<void> _refresh() async {
    setState(() => _catalogFuture = _enrollmentService.fetchCatalog());
    await _catalogFuture;
  }

  Future<void> _enroll(MateriaModel materia) async {
    setState(() => _loadingMateriaId = materia.id);
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) {
      if (mounted) showAppSnackBar(context, 'Tu sesión ha expirado.', isError: true);
      setState(() => _loadingMateriaId = null);
      return;
    }
    final result = await _enrollmentService.enrollMateria(userId, materia.id);
    if (!mounted) return;
    setState(() => _loadingMateriaId = null);
    showAppSnackBar(
      context,
      result
          ? 'Inscripción solicitada para ${materia.nombre}'
          : 'No se pudo inscribir. Verifica que el periodo de inscripción esté activo.',
      isError: !result,
    );
    if (result) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Catálogo',
      child: FutureBuilder<List<MateriaModel>>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ShimmerListPlaceholder();
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                EmptyState(
                  title: 'Error al cargar',
                  message: 'No se pudo cargar el catálogo: ${snapshot.error}',
                ),
              ],
            );
          }

          final materias = snapshot.data ?? [];

          if (materias.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  title: 'Sin materias disponibles',
                  message:
                      'No hay materias activas registradas. Contacta al administrador para verificar que el semestre esté activo y que existan materias cargadas.',
                ),
              ],
            );
          }

          final semesters =
              materias.map((m) => m.semestre ?? 1).toSet().toList()..sort();
          final filtered = _selectedSemester == null
              ? materias
              : materias
                  .where((m) => (m.semestre ?? 1) == _selectedSemester)
                  .toList();
          final totalCredits =
              filtered.fold<int>(0, (sum, m) => sum + m.creditos);
          final creditProgress = (totalCredits / 24).clamp(0.0, 1.0);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                StaggeredEntrance(
                  index: 0,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Créditos disponibles',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('$totalCredits créditos visibles en el catálogo',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: creditProgress),
                          duration: const Duration(milliseconds: 700),
                          builder: (context, value, child) =>
                              LinearProgressIndicator(
                            value: value,
                            minHeight: 9,
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: const Color(0xFFE9F1EC),
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                StaggeredEntrance(
                  index: 1,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedSemester,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Semestre',
                      prefixIcon: Icon(Icons.filter_list_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Todos los semestres')),
                      ...semesters.map((s) => DropdownMenuItem<int?>(
                          value: s, child: Text('Semestre $s'))),
                    ],
                    onChanged: (v) => setState(() => _selectedSemester = v),
                  ),
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  const EmptyState(
                    title: 'Sin resultados',
                    message: 'No hay materias para este semestre.',
                  )
                else
                  ...filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final materia = entry.value;
                    final total = materia.cuposTotales ?? 35;
                    final available = materia.cuposDisponibles ?? total;

                    // ── La materia está disponible si tiene cupos
                    // (si cuposDisponibles es null se asume disponible)
                    final sinCupos = materia.cuposDisponibles != null &&
                        materia.cuposDisponibles! <= 0;

                    final stateLabel = sinCupos ? 'Sin cupos' : 'Disponible';
                    final stateColor =
                        sinCupos ? AppTheme.destructive : AppTheme.success;
                    final cupoProgress =
                        total == 0 ? 0.0 : (available / total).clamp(0.0, 1.0);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: StaggeredEntrance(
                        index: index + 2,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          materia.nombre,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 6),
                                        MetricTile(
                                          icon: Icons.star_outline_rounded,
                                          label: 'Créditos',
                                          value: '${materia.creditos}',
                                        ),
                                        const SizedBox(height: 6),
                                        MetricTile(
                                          icon: Icons.schedule_rounded,
                                          label: 'Horario',
                                          value:
                                              materia.horario ?? 'Por asignar',
                                        ),
                                        if (materia.semestre != null) ...[
                                          const SizedBox(height: 6),
                                          MetricTile(
                                            icon: Icons.timeline_outlined,
                                            label: 'Semestre',
                                            value: '${materia.semestre}',
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      StatusBadge(
                                        label: materia.codigo.isEmpty
                                            ? 'S/C'
                                            : materia.codigo,
                                        color: AppTheme.primary,
                                      ),
                                      const SizedBox(height: 10),
                                      StatusBadge(
                                          label: stateLabel,
                                          color: stateColor),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Cupos disponibles',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: cupoProgress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(999),
                                backgroundColor: const Color(0xFFE9F1EC),
                                color: sinCupos
                                    ? AppTheme.destructive
                                    : AppTheme.primary,
                              ),
                              const SizedBox(height: 6),
                              Text('$available de $total cupos',
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 16),
                              GradientButton(
                                label: sinCupos ? 'Sin cupos' : 'Inscribir',
                                icon: sinCupos
                                    ? Icons.block_rounded
                                    : Icons.add_task_rounded,
                                isLoading: _loadingMateriaId == materia.id,
                                // Solo bloquear si no hay cupos; nunca bloquear por enum
                                onTap:
                                    sinCupos ? null : () => _enroll(materia),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
