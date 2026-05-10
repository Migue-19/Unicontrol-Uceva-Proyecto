import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/models/mensaje_model.dart';
import 'package:unicontrol_app/models/usuario_model.dart';
import 'package:unicontrol_app/services/supabase_service.dart';

class AdminService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<UsuarioModel>> fetchEstudiantes() async {
    try {
      final result = await _client
          .from('usuarios')
          .select('*, programas(nombre, facultades(nombre))')
          .order('nombre');
      return (result as List<dynamic>)
          .map((raw) => UsuarioModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSolicitudes() async {
    try {
      final result = await _client
          .from('cargas_academicas')
          .select('*, usuarios(nombre, codigo_estudiantil)')
          .order('fecha_solicitud', ascending: false);
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> resolverSolicitud(String cargaId, bool aprobado,
      {String comentario = ''}) async {
    try {
      await _client.from('cargas_academicas').update({
        'estado': aprobado ? 'aprobada' : 'rechazada',
        'fecha_respuesta': DateTime.now().toIso8601String(),
        'comentario_admin': comentario,
      }).eq('id', cargaId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<MensajeModel>> fetchMensajesAdmin() async {
    try {
      final result = await _client
          .from('mensajes')
          .select(
            '*, emisor:usuarios!mensajes_emisor_id_fkey(nombre), '
            'receptor:usuarios!mensajes_receptor_id_fkey(nombre)',
          )
          .order('created_at', ascending: false);
      return (result as List<dynamic>)
          .map((raw) => MensajeModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (_) {
      try {
        final fallback = await _client
            .from('mensajes')
            .select()
            .order('created_at', ascending: false);
        return (fallback as List<dynamic>)
            .map((raw) => MensajeModel.fromJson(raw as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<bool> sendMensaje(
    String emisorId,
    String receptorId,
    String asunto,
    String mensaje,
  ) async {
    try {
      await _client.from('mensajes').insert({
        'emisor_id': emisorId,
        'receptor_id': receptorId,
        'asunto': asunto,
        'mensaje': mensaje,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
