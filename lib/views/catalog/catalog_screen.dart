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
  late Future<Map<String, dynamic>> _dataFuture;
  String? _loadingMateriaId;

  // Nuevos estados para filtros
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedSemester;
  int? _selectedCreditos;
  String? _selectedDia;
  String? _selectedDisponibilidad;
  bool? _soloElectivas;
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final auth = context.read<AuthService>();
    final programaId = auth.profile?.programaId ?? '';
    final userId = auth.user?.id;

    final catalog = await _enrollmentService.fetchCatalog(programaId);
    final estado =
        userId != null ? await _enrollmentService.getCargaEstado(userId) : null;

    return {'catalog': catalog, 'estado': estado};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedSemester != null) count++;
    if (_selectedCreditos != null) count++;
    if (_selectedDia != null) count++;
    if (_selectedDisponibilidad != null) count++;
    if (_soloElectivas != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedSemester = null;
      _selectedCreditos = null;
      _selectedDia = null;
      _selectedDisponibilidad = null;
      _soloElectivas = null;
    });
  }

  List<MateriaModel> _applyFilters(List<MateriaModel> all) {
    return all.where((m) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final searchString =
            '${m.nombre} ${m.codigo} ${m.docente ?? ''}'.toLowerCase();
        if (!searchString.contains(query)) return false;
      }
      if (_selectedSemester != null && m.semestre != _selectedSemester) {
        return false;
      }
      if (_selectedCreditos != null && m.creditos != _selectedCreditos) {
        return false;
      }
      if (_selectedDia != null) {
        if (m.diasSemana == null || !m.diasSemana!.contains(_selectedDia)) {
          return false;
        }
      }
      if (_selectedDisponibilidad != null) {
        final total = m.cuposTotales ?? 35;
        final available = m.cuposDisponibles ?? total;
        if (_selectedDisponibilidad == 'disponible' && available <= 0) {
          return false;
        }
        if (_selectedDisponibilidad == 'sin_cupos' && available > 0) {
          return false;
        }
      }
      if (_soloElectivas != null && m.esElectiva != _soloElectivas) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final f = _loadData();
    if (!mounted) return;
    void updateState() { _dataFuture = f; }
    setState(updateState);
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _enroll(MateriaModel materia) async {
    setState(() => _loadingMateriaId = materia.id);
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) {
      if (mounted) {
        showAppSnackBar(context, 'Tu sesión ha expirado.', isError: true);
      }
      setState(() => _loadingMateriaId = null);
      return;
    }

    try {
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMateriaId = null);
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }
      showAppSnackBar(context, msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Catálogo',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
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
                  message:
                      'No se pudo cargar el catálogo: ${snapshot.error}',
                ),
              ],
            );
          }

          final data = snapshot.data ?? {};
          final materias =
              (data['catalog'] as List<dynamic>?)?.cast<MateriaModel>() ?? [];
          final estadoCarga = data['estado'] as String?;
          final isBlocked =
              estadoCarga == 'en_revision' || estadoCarga == 'aprobada';

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

          final filtered = _applyFilters(materias);

          // Computar opciones dinámicas para los filtros
          final semesters =
              materias.map((m) => m.semestre ?? 1).toSet().toList()..sort();
          final creditosList =
              materias.map((m) => m.creditos).toSet().toList()..sort();
          final diasList =
              materias.expand((m) => m.diasSemana ?? []).toSet().toList();
          diasList.sort();

          final totalCredits =
              filtered.fold<int>(0, (sum, m) => sum + m.creditos);
          final creditProgress = (totalCredits / 24).clamp(0.0, 1.0);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                if (isBlocked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppTheme.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tu solicitud está siendo revisada por el coordinador. No puedes agregar materias en este momento.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.warning),
                            ),
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

                // Barra de Búsqueda + Botón de Filtros
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, código o docente…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: _activeFilterCount > 0,
                      backgroundColor: AppTheme.warning,
                      child: IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () {
                          setState(() {
                            _filtersExpanded = !_filtersExpanded;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Panel de Filtros Avanzados
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: !_filtersExpanded
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: AppCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int?>(
                                        value: _selectedSemester,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Semestre'),
                                        items: [
                                          const DropdownMenuItem(
                                              value: null,
                                              child: Text('Todos')),
                                          ...semesters.map((s) =>
                                              DropdownMenuItem(
                                                  value: s,
                                                  child:
                                                      Text('Semestre $s'))),
                                        ],
                                        onChanged: (v) => setState(
                                            () => _selectedSemester = v),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<int?>(
                                        value: _selectedCreditos,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Créditos'),
                                        items: [
                                          const DropdownMenuItem(
                                              value: null,
                                              child: Text('Todos')),
                                          ...creditosList.map((c) =>
                                              DropdownMenuItem(
                                                  value: c,
                                                  child:
                                                      Text('$c créditos'))),
                                        ],
                                        onChanged: (v) => setState(
                                            () => _selectedCreditos = v),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String?>(
                                  value: _selectedDia,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Día de la semana'),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null,
                                        child: Text('Cualquier día')),
                                    ...diasList.map((d) => DropdownMenuItem(
                                        value: d as String, child: Text(d))),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedDia = v),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          DropdownButtonFormField<String?>(
                                        value: _selectedDisponibilidad,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Disponibilidad'),
                                        items: const [
                                          DropdownMenuItem(
                                              value: null,
                                              child: Text('Todas')),
                                          DropdownMenuItem(
                                              value: 'disponible',
                                              child: Text('Con cupos')),
                                          DropdownMenuItem(
                                              value: 'sin_cupos',
                                              child: Text('Sin cupos')),
                                        ],
                                        onChanged: (v) => setState(() =>
                                            _selectedDisponibilidad = v),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<bool?>(
                                        value: _soloElectivas,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Tipo'),
                                        items: const [
                                          DropdownMenuItem(
                                              value: null,
                                              child: Text('Todas')),
                                          DropdownMenuItem(
                                              value: true,
                                              child: Text('Solo electivas')),
                                          DropdownMenuItem(
                                              value: false,
                                              child: Text(
                                                  'Solo obligatorias')),
                                        ],
                                        onChanged: (v) => setState(
                                            () => _soloElectivas = v),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                        '$_activeFilterCount filtro(s) activo(s)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    const Spacer(),
                                    if (_activeFilterCount > 0)
                                      TextButton(
                                        onPressed: _clearAllFilters,
                                        child:
                                            const Text('Limpiar filtros'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // Chips de Filtros Activos
                if (_activeFilterCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                label:
                                    Text('Búsqueda: "$_searchQuery"'),
                                onDeleted: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            ),
                          if (_selectedSemester != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                label:
                                    Text('Semestre $_selectedSemester'),
                                onDeleted: () => setState(
                                    () => _selectedSemester = null),
                              ),
                            ),
                          if (_selectedCreditos != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                label:
                                    Text('$_selectedCreditos créditos'),
                                onDeleted: () => setState(
                                    () => _selectedCreditos = null),
                              ),
                            ),
                          if (_selectedDia != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                label: Text(_selectedDia!),
                                onDeleted: () =>
                                    setState(() => _selectedDia = null),
                              ),
                            ),
                          if (_selectedDisponibilidad != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                label: Text(
                                    _selectedDisponibilidad == 'disponible'
                                        ? 'Con cupos'
                                        : 'Sin cupos'),
                                onDeleted: () => setState(
                                    () => _selectedDisponibilidad = null),
                              ),
                            ),
                          if (_soloElectivas != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                label: Text(_soloElectivas == true
                                    ? 'Solo electivas'
                                    : 'Solo obligatorias'),
                                onDeleted: () => setState(
                                    () => _soloElectivas = null),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Contador de Resultados
                if (materias.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 4),
                    child: Text(
                      '${filtered.length} materia(s) encontrada(s)',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppTheme.mutedForeground,
                          ),
                    ),
                  ),

                const SizedBox(height: 10),

                if (filtered.isEmpty)
                  const EmptyState(
                    title: 'Sin resultados',
                    message:
                        'Ninguna materia coincide con los filtros aplicados.',
                  )
                else
                  ...filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final materia = entry.value;
                    final total = materia.cuposTotales ?? 35;
                    final available = materia.cuposDisponibles ?? total;

                    final sinCupos = materia.cuposDisponibles != null &&
                        materia.cuposDisponibles! <= 0;

                    final stateLabel =
                        sinCupos ? 'Sin cupos' : 'Disponible';
                    final stateColor =
                        sinCupos ? AppTheme.destructive : AppTheme.success;
                    final cupoProgress = total == 0
                        ? 0.0
                        : (available / total).clamp(0.0, 1.0);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: StaggeredEntrance(
                        index: index + 2,
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                                  fontWeight:
                                                      FontWeight.w800),
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
                                          value: materia.horario ??
                                              'Por asignar',
                                        ),
                                        if (materia.semestre != null) ...[
                                          const SizedBox(height: 6),
                                          MetricTile(
                                            icon:
                                                Icons.timeline_outlined,
                                            label: 'Semestre',
                                            value: '${materia.semestre}',
                                          ),
                                        ],
                                        if (materia.docente != null) ...[
                                          const SizedBox(height: 6),
                                          MetricTile(
                                            icon: Icons
                                                .person_outline_rounded,
                                            label: 'Docente',
                                            value: materia.docente!,
                                          ),
                                        ],
                                        if (materia.salon != null) ...[
                                          const SizedBox(height: 6),
                                          MetricTile(
                                            icon: Icons.room_outlined,
                                            label: 'Salón',
                                            value: materia.salon!,
                                          ),
                                        ],
                                        if (materia.diasSemana != null &&
                                            materia
                                                .diasSemana!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          MetricTile(
                                            icon: Icons
                                                .calendar_today_outlined,
                                            label: 'Días',
                                            value: materia.diasSemana!
                                                .join(', '),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
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
                                      if (materia.esElectiva) ...[
                                        const SizedBox(height: 10),
                                        const StatusBadge(
                                          label: 'Electiva',
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Cupos disponibles',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: cupoProgress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(999),
                                backgroundColor:
                                    const Color(0xFFE9F1EC),
                                color: sinCupos
                                    ? AppTheme.destructive
                                    : AppTheme.primary,
                              ),
                              const SizedBox(height: 6),
                              Text('$available de $total cupos',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                              const SizedBox(height: 16),
                              GradientButton(
                                label:
                                    sinCupos ? 'Sin cupos' : 'Inscribir',
                                icon: sinCupos
                                    ? Icons.block_rounded
                                    : Icons.add_task_rounded,
                                isLoading:
                                    _loadingMateriaId == materia.id,
                                onTap: (sinCupos || isBlocked)
                                    ? null
                                    : () => _enroll(materia),
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