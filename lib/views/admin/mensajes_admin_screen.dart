import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/models/mensaje_model.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class MensajesAdminScreen extends StatefulWidget {
  const MensajesAdminScreen({super.key});

  @override
  State<MensajesAdminScreen> createState() => _MensajesAdminScreenState();
}

class _MensajesAdminScreenState extends State<MensajesAdminScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<MensajeModel>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _adminService.fetchMensajesAdmin();
  }

  Future<void> _refresh() async {
    setState(() => _messagesFuture = _adminService.fetchMensajesAdmin());
    await _messagesFuture;
  }

  Future<void> _openComposer() async {
    final destinatarioController = TextEditingController();
    final asuntoController = TextEditingController();
    final contenidoController = TextEditingController();

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFD5E5DA),
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Nuevo mensaje',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 14),
            TextField(
              controller: destinatarioController,
              decoration: const InputDecoration(
                labelText: 'ID destinatario (UUID del usuario)',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: asuntoController,
              decoration: const InputDecoration(
                labelText: 'Asunto',
                prefixIcon: Icon(Icons.subject_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contenidoController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Enviar',
              icon: Icons.send_rounded,
              onTap: () async {
                final emisorId =
                    context.read<AuthService>().user?.id;
                if (emisorId == null ||
                    destinatarioController.text.trim().isEmpty ||
                    asuntoController.text.trim().isEmpty ||
                    contenidoController.text.trim().isEmpty) {
                  if (ctx.mounted) Navigator.of(ctx).pop(false);
                  return;
                }
                final ok = await _adminService.sendMensaje(
                  emisorId,
                  destinatarioController.text.trim(),
                  asuntoController.text.trim(),
                  contenidoController.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop(ok);
              },
            ),
          ],
        ),
      ),
    );

    destinatarioController.dispose();
    asuntoController.dispose();
    contenidoController.dispose();

    if (!mounted) return;
    showAppSnackBar(
      context,
      sent == true ? 'Mensaje enviado' : 'No fue posible enviar el mensaje',
      isError: sent != true,
    );
    if (sent == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Mensajes',
      isAdminSection: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _openComposer,
        child: const Icon(Icons.add_comment_outlined),
      ),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MensajeModel>>(
          future: _messagesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerListPlaceholder();
            }
            final mensajes = snapshot.data ?? [];
            if (mensajes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'Sin mensajes administrativos',
                    message:
                        'Usa el botón flotante para enviar el primer mensaje institucional.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: mensajes.asMap().entries.map((entry) {
                final index = entry.key;
                final m = entry.value;
                final dest = m.receptorNombre ??
                    m.receptorId.substring(0, 6);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: StaggeredEntrance(
                    index: index,
                    child: AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                              radius: 24,
                              child: Text(initialsFromName(dest))),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.asunto,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text('Para: $dest',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                                const SizedBox(height: 6),
                                Text(
                                  m.mensaje,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
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
