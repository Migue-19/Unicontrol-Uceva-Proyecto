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
  late Future<Map<String, dynamic>> _dataFuture;
  String? _cancellingId;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return {'estado': null, 'inscripciones': <InscripcionModel>[]};

    final estado = await _service.getCargaEstado(userId);
    // Cargar inscripciones siempre, independientemente del estado de la carga.
    // isBorrador controla si los botones de cancelar están activos, no si se muestran las materias.
    final inscripciones = await _service.fetchActiveLoadEnrollments(userId);
    return {'estado': estado, 'inscripciones': inscripciones};
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final f = _loadData();
    if (!mounted) return;
    setState(() {
      _dataFuture = f;
    });
    try {
      await f;
    } catch (_) {}
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerListPlaceholder();
            }
            
            final data = snapshot.data ?? {};
            final estado = data['estado'] as String?;
            // El estudiante puede cancelar si la carga está en borrador O si
            // fue rechazada (en ese caso puede editar y reenviar su solicitud).
            final isBorrador = estado == 'borrador' || estado == 'rechazada';
            final inscripciones = (data['inscripciones'] as List<dynamic>?)?.cast<InscripcionModel>() ?? [];

            if (inscripciones.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  EmptyState(
                    title: 'Nada por cancelar',
                    message: estado == null
                        ? 'Aún no tienes materias inscritas en este semestre.'
                        : 'No tienes materias inscritas en la carga académica activa.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                if (!isBorrador)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTheme.warning),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No puedes cancelar materias una vez enviada la solicitud al coordinador.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...inscripciones.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: StaggeredEntrance(
                      index: index + 1,
                      child: isBorrador
                          ? Dismissible(
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
                              child: _buildCardContent(context, item, isBorrador),
                            )
                          : _buildCardContent(context, item, isBorrador),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, InscripcionModel item, bool isBorrador) {
    return AppCard(
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
              if (isBorrador)
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
          if (isBorrador) ...[
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
        ],
      ),
    );
  }
}