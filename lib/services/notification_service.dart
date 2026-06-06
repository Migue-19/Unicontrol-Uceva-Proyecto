import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/services/supabase_service.dart';

/// Servicio de notificaciones con polling periódico (más estable en web
/// que el stream de Realtime que sufre timeouts en Chrome).
class NotificationService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;

  Timer? _pollingTimer;
  String? _currentUserId;
  bool _isAdmin = false;

  // Último mensaje no leído detectado
  Map<String, dynamic>? lastUnreadMessage;

  // IDs ya notificados para no repetir el snackbar
  final Set<String> _shownMessageIds = {};

  // Número de solicitudes en_revision para el admin
  int newSolicitudesCount = 0;

  // ── Estudiante: polling de mensajes nuevos ─────────────────────────────────
  void listenForNewMessages(String userId) {
    if (_currentUserId == userId && !_isAdmin && _pollingTimer != null) return;

    _currentUserId = userId;
    _isAdmin = false;
    _cancelTimer();

    // Primer chequeo inmediato
    _pollMessages(userId);

    // Luego cada 15 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollMessages(userId);
    });

    debugPrint('[NotificationService] Polling mensajes de $userId (cada 15s)');
  }

  Future<void> _pollMessages(String userId) async {
    try {
      final data = await _client
          .from('mensajes')
          .select('id, asunto, leido')
          .eq('receptor_id', userId)
          .eq('leido', false);

      final unread = (data as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((m) => !_shownMessageIds.contains(m['id'] as String?))
          .toList();

      if (unread.isNotEmpty) {
        final newest = unread.last;
        lastUnreadMessage = newest;
        _shownMessageIds.add(newest['id'] as String);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationService] _pollMessages error: $e');
    }
  }

  // ── Admin: polling de solicitudes en_revision ──────────────────────────────
  void listenForNewSolicitudes() {
    if (_currentUserId == '__admin__' && _isAdmin && _pollingTimer != null) {
      return;
    }

    _currentUserId = '__admin__';
    _isAdmin = true;
    _cancelTimer();

    _pollSolicitudes();

    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollSolicitudes();
    });

    debugPrint('[NotificationService] Polling solicitudes admin (cada 15s)');
  }

  Future<void> _pollSolicitudes() async {
    try {
      final data = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('estado', 'en_revision');

      final count = (data as List).length;
      if (count != newSolicitudesCount) {
        newSolicitudesCount = count;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationService] _pollSolicitudes error: $e');
    }
  }

  // ── Limpiar al borrar un mensaje (para que no vuelva a notificar) ──────────
  void onMessageDeleted(String messageId) {
    _shownMessageIds.add(messageId);
    if (lastUnreadMessage?['id'] == messageId) {
      lastUnreadMessage = null;
      notifyListeners();
    }
  }

  // ── Limpiar al cerrar sesión ───────────────────────────────────────────────
  void stopListening() {
    _cancelTimer();
    _currentUserId = null;
    lastUnreadMessage = null;
    _shownMessageIds.clear();
    newSolicitudesCount = 0;
    debugPrint('[NotificationService] Polling detenido');
  }

  void _cancelTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}