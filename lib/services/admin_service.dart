import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/models/mensaje_model.dart';
import 'package:unicontrol_app/models/usuario_model.dart';
import 'package:unicontrol_app/services/aes_service.dart';
import 'package:unicontrol_app/services/rsa_service.dart';
import 'package:unicontrol_app/services/supabase_service.dart';

class AdminService {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<UsuarioModel>> fetchEstudiantes() async {
    try {
      final result = await _client
          .from('usuarios')
          .select('*, programas(nombre, facultades(nombre))')
          .order('nombre');
      // Descifrar cada perfil con RSA
      final futures = (result as List<dynamic>)
          .map((raw) => UsuarioModel.fromJsonDecrypted(raw as Map<String, dynamic>));
      return await Future.wait(futures);
    } catch (_) {
      return [];
    }
  }

  Future<List<UsuarioModel>> fetchEstudiantesDeFacultad(String adminId) async {
    try {
      // 1. Obtener facultad_id del admin
      final adminData = await _client.from('usuarios')
        .select('programas(facultad_id)')
        .eq('id', adminId).maybeSingle();
      final facultadId = adminData?['programas']?['facultad_id'];
      if (facultadId == null) return [];
      
      // 2. Obtener IDs de programas de esa facultad
      final programas = await _client.from('programas')
        .select('id').eq('facultad_id', facultadId);
      final programaIds = (programas as List).map((p) => p['id'] as String).toList();
      
      if (programaIds.isEmpty) return [];

      // 3. Traer usuarios de esos programas
      final result = await _client.from('usuarios')
        .select('*, programas(nombre, facultades(nombre))')
        .inFilter('programa_id', programaIds)
        .order('nombre');
        
      final futures = (result as List<dynamic>)
          .map((raw) => UsuarioModel.fromJsonDecrypted(raw as Map<String, dynamic>));
      return await Future.wait(futures);
    } catch (_) {
      return [];
    }
  }

  Future<UsuarioModel?> fetchEstudianteDetalle(String estudianteId) async {
    try {
      final result = await _client.from('usuarios')
          .select('*, programas(nombre, facultades(nombre))')
          .eq('id', estudianteId)
          .maybeSingle();
      
      if (result == null) return null;
      return await UsuarioModel.fromJsonDecrypted(result);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistorialAcciones(String userId) async {
    try {
      final result = await _client.from('historial_acciones')
          .select()
          .eq('usuario_id', userId)
          .order('created_at', ascending: false);
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistorialAcademico(String userId) async {
    try {
      final result = await _client.from('historial_academico')
          .select('*, materias(nombre, codigo)')
          .eq('usuario_id', userId)
          .order('created_at', ascending: false);
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<String?> fetchFacultadDelAdmin(String userId) async {
    try {
      final usuario = await _client.from('usuarios')
        .select('programas(facultad_id, facultades(nombre))')
        .eq('id', userId).maybeSingle();
      return usuario?['programas']?['facultades']?['nombre'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCoordinadoresDeFacultad(
      String facultadId) async {
    try {
      // 1. Obtener IDs de programas de la facultad
      final programas = await _client
          .from('programas')
          .select('id')
          .eq('facultad_id', facultadId);
      final ids =
          (programas as List).map((p) => p['id'] as String).toList();
      if (ids.isEmpty) return [];

      // 2. Obtener usuarios admin de esos programas
      final admins = await _client
          .from('usuarios')
          .select('*, user_roles!inner(role), programas(nombre)')
          .inFilter('programa_id', ids)
          .eq('user_roles.role', 'admin')
          .order('nombre');

      // 3. Descifrar nombre y código de cada coordinador con RSA
      final futures = (admins as List<dynamic>).map((raw) async {
        final map = Map<String, dynamic>.from(raw as Map<String, dynamic>);
        final rawNombre = map['nombre'] as String? ?? '';
        final rawCodigo = map['codigo_estudiantil'] as String?;
        map['nombre'] = await UniControlRsa.decryptField(rawNombre);
        if (rawCodigo != null) {
          map['codigo_estudiantil'] =
              await UniControlRsa.decryptField(rawCodigo);
        }
        return map;
      });
      return await Future.wait(futures);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSolicitudes() async {
    try {
      final result = await _client
          .from('cargas_academicas')
          .select('*, usuarios(nombre, codigo_estudiantil, programa_id, programas(nombre))')
          .eq('estado', 'en_revision')
          .order('numero_orden', ascending: true);
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSolicitudesPorEstado(String estado) async {
    try {
      final query = _client
          .from('cargas_academicas')
          .select('*, usuarios(nombre, codigo_estudiantil, programa_id, programas(nombre))')
          .eq('estado', estado);

      final result = estado == 'en_revision'
          ? await query.order('numero_orden', ascending: true)
          : await query.order('fecha_solicitud', ascending: false);

      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchInscripcionesDeCarga(String cargaId) async {
    try {
      final result = await _client.from('inscripciones')
        .select('*, materias(nombre, codigo, creditos, semestre, horario, dias_semana, hora_inicio, hora_fin, docente)')
        .eq('carga_id', cargaId)
        .order('created_at', ascending: true);
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> resolverSolicitudDetallada({
    required String cargaId,
    required Map<String, bool> decisionesPorInscripcion,
    required String comentario,
  }) async {
    try {
      // 1. Actualizar cada inscripcion individualmente
      for (final entry in decisionesPorInscripcion.entries) {
        await _client.from('inscripciones')
            .update({'estado': entry.value ? 'aprobada' : 'rechazada'})
            .eq('id', entry.key);
      }
      // 2. Determinar estado final de la carga
      final todasRechazadas =
          decisionesPorInscripcion.values.every((v) => !v);
      final estadoCarga = todasRechazadas ? 'rechazada' : 'aprobada';

      // 3. Actualizar carga academica
      await _client.from('cargas_academicas').update({
        'estado': estadoCarga,
        'comentario_admin': comentario,
        'fecha_respuesta': DateTime.now().toIso8601String(),
      }).eq('id', cargaId);

      return true;
    } catch (_) {
      return false;
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

      // Descifrar cada mensaje con AES
      final futures = (result as List<dynamic>)
          .map((raw) => MensajeModel.fromJsonDecrypted(raw as Map<String, dynamic>));
      return await Future.wait(futures);
    } catch (_) {
      try {
        final fallback = await _client
            .from('mensajes')
            .select()
            .order('created_at', ascending: false);
        final futures = (fallback as List<dynamic>)
            .map((raw) => MensajeModel.fromJsonDecrypted(raw as Map<String, dynamic>));
        return await Future.wait(futures);
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
      // Cifrar con AES-256-GCM antes de guardar
      final asuntoCifrado  = await UniControlMessaging.encryptForUser(plainText: asunto, receptorId: receptorId);
      final mensajeCifrado = await UniControlMessaging.encryptForUser(plainText: mensaje, receptorId: receptorId);

      // Diagnóstico en consola
      UniControlMessaging.printDiagnosticTable(
        campo: 'asunto',
        valorOriginal: asunto,
        valorCifrado: asuntoCifrado,
        valorDescifrado: await UniControlMessaging.decryptMessage(asuntoCifrado),
      );

      await _client.from('mensajes').insert({
        'emisor_id': emisorId,
        'receptor_id': receptorId,
        'asunto': asuntoCifrado,
        'mensaje': mensajeCifrado,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}