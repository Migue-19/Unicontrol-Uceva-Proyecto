import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/models/inscripcion_model.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/enrollment_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class CancelSubjectsScreen extends StatefulWidget {
  const CancelSubjectsScreen({super.key});

  @override
  State<CancelSubjectsScreen> createState() => _CancelSubjectsScreenState();
}

class _CancelSubjectsScreenState extends State<CancelSubjectsScreen> {
  final EnrollmentService _service = EnrollmentService();
  late Future<List<InscripcionModel>> _enrollmentsFuture;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _enrollmentsFuture = _loadEnrollments();
  }

  Future<List<InscripcionModel>> _loadEnrollments() {
    final userId = context.read<AuthService>().user?.id;
    return userId != null
        ? _service.fetchEnrollments(userId)
        : Future.value([]);
  }

  Future<void> _refresh() async {
    setState(() => _enrollmentsFuture = _loadEnrollments());
    await _enrollmentsFuture;
  }

  Future<bool> _confirmAndCancel(InscripcionModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Cancelar materia'),
        content: Text(
            '¿Seguro que deseas cancelar ${item.materia?.nombre ?? 'esta materia'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.destructive),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final userId = context.read<AuthService>().user?.id;
    if (userId == null) {
      if (mounted)
        showAppSnackBar(context, 'Usuario no autenticado', isError: true);
      return false;
    }

    setState(() => _cancellingId = item.id);
    final result = await _service.cancelInscripcion(item.id, userId);
    if (!mounted) return false;
    setState(() => _cancellingId = null);

    showAppSnackBar(
      context,
      result ? 'Inscripción cancelada' : 'No se pudo cancelar la inscripción',
      isError: !result,
    );
    if (result) await _refresh();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Cancelar materias',
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<InscripcionModel>>(
          future: _enrollmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerListPlaceholder();
            }
            final inscripciones = snapshot.data ?? [];
            if (inscripciones.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'Nada por cancelar',
                    message:
                        'Tus materias activas no muestran inscripciones cancelables en este momento.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: inscripciones.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: StaggeredEntrance(
                    index: index,
                    child: Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmAndCancel(item),
                      background: Container(
                        decoration: BoxDecoration(
                            color: AppTheme.destructive,
                            borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                      ),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.materia?.nombre ?? 'Materia desconocida',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const StatusBadge(
                                    label: 'Cancelable',
                                    color: AppTheme.destructive),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MetricTile(
                              icon: Icons.badge_outlined,
                              label: 'Código',
                              value: item.materia?.codigo.isNotEmpty == true
                                  ? item.materia!.codigo
                                  : 'Pendiente',
                            ),
                            const SizedBox(height: 8),
                            MetricTile(
                              icon: Icons.info_outline_rounded,
                              label: 'Estado',
                              value: item.estado,
                            ),
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                  color: AppTheme.destructive,
                                  borderRadius: BorderRadius.circular(16)),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _cancellingId == item.id
                                      ? null
                                      : () => _confirmAndCancel(item),
                                  child: SizedBox(
                                    height: 54,
                                    child: Center(
                                      child: _cancellingId == item.id
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                    Icons.delete_outline_rounded,
                                                    color: Colors.white),
                                                const SizedBox(width: 10),
                                                Text('Cancelar',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w700)),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
