import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';
import 'package:unicontrol_app/widgets/firma_dialog.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AdminService _adminService = AdminService();

  late Future<List<Map<String, dynamic>>> _pendientesFuture;
  late Future<List<Map<String, dynamic>>> _aprobadasFuture;
  late Future<List<Map<String, dynamic>>> _rechazadasFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  void _loadAll() {
    _pendientesFuture = _adminService.fetchSolicitudesPorEstado('en_revision');
    _aprobadasFuture = _adminService.fetchSolicitudesPorEstado('aprobada');
    _rechazadasFuture = _adminService.fetchSolicitudesPorEstado('rechazada');
  }

  Future<void> _refresh() async {
    setState(() => _loadAll());
    await Future.wait([_pendientesFuture, _aprobadasFuture, _rechazadasFuture]);
  }

  void _openReviewSheet(Map<String, dynamic> sol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        sol: sol,
        adminService: _adminService,
        onSuccess: _refresh,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Solicitudes',
      isAdminSection: true,
      child: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _pendientesFuture,
                builder: (context, snap) {
                  final count = snap.data?.length ?? 0;
                  return TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.mutedForeground,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Pendientes'),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.destructive,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Aprobadas'),
                      const Tab(text: 'Rechazadas'),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SolicitudesList(
                  future: _pendientesFuture,
                  isPending: true,
                  onRefresh: _refresh,
                  onTap: _openReviewSheet,
                ),
                _SolicitudesList(
                  future: _aprobadasFuture,
                  isPending: false,
                  onRefresh: _refresh,
                  onTap: null,
                ),
                _SolicitudesList(
                  future: _rechazadasFuture,
                  isPending: false,
                  onRefresh: _refresh,
                  onTap: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista de solicitudes ──────────────────────────────────────────────────────

class _SolicitudesList extends StatelessWidget {
  const _SolicitudesList({
    required this.future,
    required this.isPending,
    required this.onRefresh,
    required this.onTap,
  });

  final Future<List<Map<String, dynamic>>> future;
  final bool isPending;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>)? onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ShimmerListPlaceholder();
        }
        final solicitudes = snapshot.data ?? [];
        if (solicitudes.isEmpty) {
          return ListView(
            children: [
              const SizedBox(height: 100),
              EmptyState(
                title: isPending ? 'Sin solicitudes pendientes' : 'Sin registros',
                message: isPending
                    ? 'Las nuevas cargas académicas aparecerán aquí para revisión.'
                    : 'No hay solicitudes en este estado.',
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final sol = solicitudes[index];
              return _SolicitudCard(
                sol: sol,
                isPending: isPending,
                onTap: onTap != null ? () => onTap!(sol) : null,
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Card de solicitud ────────────────────────────────────────────────────────

class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({
    required this.sol,
    required this.isPending,
    required this.onTap,
  });

  final Map<String, dynamic> sol;
  final bool isPending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final estado = sol['estado']?.toString().toLowerCase() ?? '';
    final usuario = sol['usuarios'] as Map<String, dynamic>?;
    final nombre = usuario?['nombre'] as String? ?? 'Estudiante';
    final codigo = usuario?['codigo_estudiantil'] as String? ?? '';
    final programa =
        (usuario?['programas'] as Map<String, dynamic>?)?['nombre'] as String? ?? '';
    final creditos = sol['total_creditos']?.toString() ?? '0';
    final fecha = sol['fecha_solicitud']?.toString().split('T').first ??
        sol['created_at']?.toString().split('T').first ??
        'Sin fecha';
    final orden = sol['numero_orden'];

    final Color accentColor = switch (estado) {
      'aprobada' => AppTheme.success,
      'rechazada' => AppTheme.destructive,
      'en_revision' => AppTheme.warning,
      _ => AppTheme.mutedForeground,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: StaggeredEntrance(
        index: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 160,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(20)),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombre,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                if (codigo.isNotEmpty)
                                  Text(codigo,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                if (programa.isNotEmpty)
                                  Text(programa,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.mutedForeground,
                                          )),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (orden != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: accentColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    'Solicitud #$orden',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              StatusBadge(
                                  label: estado.replaceAll('_', ' '),
                                  color: accentColor),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$creditos créditos  ·  $fecha',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.touch_app_rounded,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text('Toca para revisar y decidir',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.primary)),
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
      ),
    );
  }
}

// ─── Bottom Sheet de revisión ─────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({
    required this.sol,
    required this.adminService,
    required this.onSuccess,
  });

  final Map<String, dynamic> sol;
  final AdminService adminService;
  final Future<void> Function() onSuccess;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late Future<List<Map<String, dynamic>>> _inscripcionesFuture;
  final Map<String, bool> _decisiones = {};
  final TextEditingController _mensajeCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final cargaId = widget.sol['id']?.toString() ?? '';
    _inscripcionesFuture = widget.adminService
        .fetchInscripcionesDeCarga(cargaId)
        .then((list) {
      // Por defecto, todas aprobadas
      for (final i in list) {
        _decisiones[i['id']?.toString() ?? ''] = true;
      }
      return list;
    });
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar(List<Map<String, dynamic>> inscripciones) async {
    final mensaje = _mensajeCtrl.text.trim();
    if (mensaje.isEmpty) {
      showAppSnackBar(context, 'Debes escribir un mensaje al estudiante.',
          isError: true);
      return;
    }
    if (_decisiones.isEmpty) return;

    final firmaValida = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const FirmaValidacionDialog(),
    );

    if (firmaValida != true) return;

    setState(() => _isSubmitting = true);

    final cargaId = widget.sol['id']?.toString() ?? '';
    final usuario = widget.sol['usuarios'] as Map<String, dynamic>?;
    final estudianteId = widget.sol['usuario_id']?.toString() ?? '';
    final nombreEstudiante = usuario?['nombre'] as String? ?? 'Estudiante';

    // Construir resumen para el mensaje
    final aprobadas = inscripciones
        .where((i) => _decisiones[i['id']?.toString()] == true)
        .map((i) =>
            (i['materias'] as Map<String, dynamic>?)?['nombre'] ?? 'Materia')
        .join(', ');
    final rechazadas = inscripciones
        .where((i) => _decisiones[i['id']?.toString()] == false)
        .map((i) =>
            (i['materias'] as Map<String, dynamic>?)?['nombre'] ?? 'Materia')
        .join(', ');

    final todasRechazadas = _decisiones.values.every((v) => !v);
    final estadoFinal = todasRechazadas ? 'RECHAZADA' : 'APROBADA (parcial o total)';

    final cuerpoMensaje = [
      'Estimado/a $nombreEstudiante,',
      '',
      'Tu solicitud de carga académica ha sido procesada con el siguiente resultado:',
      '',
      if (aprobadas.isNotEmpty) '✅ Materias aprobadas: $aprobadas',
      if (rechazadas.isNotEmpty) '❌ Materias rechazadas: $rechazadas',
      '',
      'Estado final de la carga: $estadoFinal',
      '',
      'Comentario del coordinador:',
      mensaje,
    ].join('\n');

    final adminId =
        (context.mounted ? context.read<AuthService>().user?.id : null) ?? '';

    final ok = await widget.adminService.resolverSolicitudDetallada(
      cargaId: cargaId,
      decisionesPorInscripcion: _decisiones,
      comentario: mensaje,
    );

    if (!ok) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        showAppSnackBar(context, 'No fue posible procesar la solicitud.',
            isError: true);
      }
      return;
    }

    // Enviar mensaje al estudiante si hay ID
    if (estudianteId.isNotEmpty && adminId.isNotEmpty) {
      await widget.adminService.sendMensaje(
        adminId,
        estudianteId,
        'Resultado de tu solicitud de carga académica',
        cuerpoMensaje,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      showAppSnackBar(context, 'Solicitud procesada correctamente.');
      await widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.sol['usuarios'] as Map<String, dynamic>?;
    final nombre = usuario?['nombre'] as String? ?? 'Estudiante';
    final codigo = usuario?['codigo_estudiantil'] as String? ?? '';
    final programa =
        (usuario?['programas'] as Map<String, dynamic>?)?['nombre'] as String? ?? '';
    final fecha = widget.sol['fecha_solicitud']?.toString().split('T').first ??
        widget.sol['created_at']?.toString().split('T').first ??
        'Sin fecha';
    final orden = widget.sol['numero_orden'];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _inscripcionesFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final inscripciones = snapshot.data ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Revisar solicitud',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall),
                                  const SizedBox(height: 4),
                                  Text(nombre,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  if (codigo.isNotEmpty)
                                    Text(codigo,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  if (programa.isNotEmpty)
                                    Text(programa,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color:
                                                    AppTheme.mutedForeground)),
                                ],
                              ),
                            ),
                            if (orden != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color:
                                          AppTheme.warning.withOpacity(0.4)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '#$orden',
                                      style: TextStyle(
                                        color: AppTheme.warning,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text('en espera',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.warning)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Fecha de solicitud: $fecha',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 20),
                        Text('Materias solicitadas',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (loading)
                          const Center(child: CircularProgressIndicator())
                        else if (inscripciones.isEmpty)
                          const Text('No hay materias en esta solicitud.')
                        else
                          ...inscripciones.map((insc) {
                            final id = insc['id']?.toString() ?? '';
                            final materia = insc['materias']
                                as Map<String, dynamic>?;
                            final matNombre =
                                materia?['nombre'] as String? ?? 'Materia';
                            final matCodigo =
                                materia?['codigo'] as String? ?? '';
                            final creditos =
                                materia?['creditos']?.toString() ?? '-';
                            final docente =
                                materia?['docente'] as String? ?? '';
                            final isAprobada = _decisiones[id] ?? true;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: (isAprobada
                                          ? AppTheme.success
                                          : AppTheme.destructive)
                                      .withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: (isAprobada
                                            ? AppTheme.success
                                            : AppTheme.destructive)
                                        .withOpacity(0.25),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(matNombre,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                            if (matCodigo.isNotEmpty)
                                              Text('Cód: $matCodigo  · $creditos cr.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall),
                                            if (docente.isNotEmpty)
                                              Text('Docente: $docente',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: AppTheme
                                                              .mutedForeground)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            isAprobada ? 'Aprobar' : 'Rechazar',
                                            style: TextStyle(
                                              color: isAprobada
                                                  ? AppTheme.success
                                                  : AppTheme.destructive,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Switch(
                                            value: isAprobada,
                                            onChanged: (v) {
                                              setState(
                                                  () => _decisiones[id] = v);
                                            },
                                            activeColor: AppTheme.success,
                                            inactiveThumbColor:
                                                AppTheme.destructive,
                                            inactiveTrackColor: AppTheme
                                                .destructive
                                                .withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                        Text('Mensaje al estudiante *',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _mensajeCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Escribe un comentario para el estudiante (obligatorio)...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: AppTheme.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // Botón de confirmar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: GradientButton(
                    label: 'Confirmar decisión',
                    icon: Icons.check_circle_rounded,
                    isLoading: _isSubmitting,
                    onTap: (loading || _isSubmitting)
                        ? null
                        : () => _confirmar(inscripciones),
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