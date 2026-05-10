import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/models/mensaje_model.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/supabase_service.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<MensajeModel>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  Future<List<MensajeModel>> _loadMessages() async {
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return [];
    try {
      final response = await SupabaseService.client
          .from('mensajes')
          .select(
            '*, emisor:usuarios!mensajes_emisor_id_fkey(nombre), '
            'receptor:usuarios!mensajes_receptor_id_fkey(nombre)',
          )
          .or('receptor_id.eq.$userId,emisor_id.eq.$userId')
          .order('created_at', ascending: false);
      return (response as List<dynamic>)
          .map((raw) => MensajeModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final fallback = await SupabaseService.client
            .from('mensajes')
            .select()
            .or('receptor_id.eq.$userId,emisor_id.eq.$userId')
            .order('created_at', ascending: false);
        return (fallback as List<dynamic>)
            .map((raw) => MensajeModel.fromJson(raw as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _messagesFuture = _loadMessages());
    await _messagesFuture;
  }

  Future<void> _markAsRead(MensajeModel mensaje) async {
    try {
      await SupabaseService.client
          .from('mensajes')
          .update({'leido': true}).eq('id', mensaje.id);
      if (mounted) {
        showAppSnackBar(context, 'Mensaje marcado como leído');
        _refresh();
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'No fue posible actualizar el mensaje.',
            isError: true);
      }
    }
  }

  Future<void> _openMessage(MensajeModel mensaje) async {
    final replyController = TextEditingController();
    await showModalBottomSheet<void>(
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
            Text(mensaje.asunto,
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(mensaje.mensaje,
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Text('Fecha: ${formatShortDate(mensaje.createdAt)}',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 18),
            TextField(
              controller: replyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Responder',
                prefixIcon: Icon(Icons.reply_outlined),
              ),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Enviar respuesta',
              icon: Icons.send_rounded,
              onTap: () async {
                final userId = context.read<AuthService>().user?.id;
                final reply = replyController.text.trim();
                if (reply.isEmpty || userId == null) {
                  showAppSnackBar(ctx, 'Escribe una respuesta antes de enviar.',
                      isError: true);
                  return;
                }
                try {
                  await SupabaseService.client.from('mensajes').insert({
                    'emisor_id': userId,
                    'receptor_id': mensaje.emisorId,
                    'asunto': 'Re: ${mensaje.asunto}',
                    'mensaje': reply,
                    'parent_id': mensaje.id,
                  });
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    showAppSnackBar(context, 'Respuesta enviada');
                    _refresh();
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    showAppSnackBar(ctx, 'No fue posible enviar la respuesta.',
                        isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
    replyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Mensajes',
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
                    title: 'Sin mensajes',
                    message:
                        'Cuando recibas notificaciones o respuestas, aparecerán aquí.',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: mensajes.asMap().entries.map((entry) {
                final index = entry.key;
                final m = entry.value;
                final displayName =
                    m.emisorNombre ?? m.emisorId.substring(0, 2).toUpperCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: StaggeredEntrance(
                    index: index,
                    child: Dismissible(
                      key: ValueKey(m.id),
                      direction: DismissDirection.startToEnd,
                      background: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B7A3E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child:
                            const Icon(Icons.done_all_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => _markAsRead(m),
                      child: AppCard(
                        child: InkWell(
                          onTap: () => _openMessage(m),
                          borderRadius: BorderRadius.circular(18),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE4F4EA),
                                child: Text(
                                  initialsFromName(displayName),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color: const Color(0xFF1B7A3E),
                                          fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(m.asunto,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                        ),
                                        if (!m.leido) const PulsingDot(),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(m.mensaje,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    const SizedBox(height: 8),
                                    Text(formatShortDate(m.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
