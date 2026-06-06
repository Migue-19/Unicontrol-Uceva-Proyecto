import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/models/inscripcion_model.dart';
import 'package:unicontrol_app/models/materia_model.dart';
import 'package:unicontrol_app/services/supabase_service.dart';

class EnrollmentService {
  final SupabaseClient _client = SupabaseService.client;

  // ── Semestre activo ─────────────────────────────────────────────────────────
  Future<String?> _getSemestreActivoId() async {
    try {
      final result = await _client
          .from('semestres_academicos')
          .select('id')
          .eq('activo', true)
          .maybeSingle();
      return result?['id'] as String?;
    } catch (e) {
      debugPrint('[EnrollmentService] _getSemestreActivoId error: $e');
      return null;
    }
  }

  // ── Catálogo ────────────────────────────────────────────────────────────────
  Future<List<MateriaModel>> fetchCatalog(String programaId) async {
    try {
      final semestreId = await _getSemestreActivoId();

      final List<dynamic> result;
      if (semestreId != null) {
        result = await _client
            .from('materias')
            .select(
                'id, nombre, codigo, creditos, semestre, horario, cupos_totales, cupos_disponibles, docente, dias_semana, hora_inicio, hora_fin, salon, es_electiva, es_compartida')
            .eq('activa', true)
            .eq('programa_id', programaId)
            .eq('semestre_academico_id', semestreId)
            .order('semestre')
            .order('nombre');
      } else {
        result = await _client
            .from('materias')
            .select(
                'id, nombre, codigo, creditos, semestre, horario, cupos_totales, cupos_disponibles, docente, dias_semana, hora_inicio, hora_fin, salon, es_electiva, es_compartida')
            .eq('activa', true)
            .eq('programa_id', programaId)
            .order('semestre')
            .order('nombre');
      }

      return result
          .map((raw) => MateriaModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EnrollmentService] fetchCatalog error: $e');
      return [];
    }
  }

  // ── Carga académica activa ──────────────────────────────────────────────────
  Future<String?> _getOrCreateCargaId(String userId) async {
    try {
      final semestreId = await _getSemestreActivoId();
      if (semestreId == null) {
        debugPrint('[EnrollmentService] No hay semestre académico activo');
        return null;
      }

      // Busca carga editable: borrador o rechazada (el estudiante puede modificar ambas)
      final existing = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .inFilter('estado', ['borrador', 'rechazada'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existing != null) return existing['id'] as String;

      final created = await _client
          .from('cargas_academicas')
          .insert({
            'usuario_id': userId,
            'semestre_id': semestreId,
            'estado': 'borrador',
          })
          .select('id')
          .single();

      return created['id'] as String;
    } catch (e) {
      debugPrint('[EnrollmentService] _getOrCreateCargaId error: $e');
      return null;
    }
  }

  Future<String?> getCargaEstado(String userId) async {
    try {
      final semestreId = await _getSemestreActivoId();
      if (semestreId == null) return null;

      final result = await _client
          .from('cargas_academicas')
          .select('estado')
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return result?['estado'] as String?;
    } catch (e) {
      debugPrint('[EnrollmentService] getCargaEstado error: $e');
      return null;
    }
  }

  /// Devuelve el estado y el comentario del admin para la carga más reciente
  /// del semestre activo. Útil para mostrar el motivo de un rechazo.
  Future<Map<String, String?>> getCargaInfo(String userId) async {
    try {
      final semestreId = await _getSemestreActivoId();
      if (semestreId == null) return {'estado': null, 'comentario': null};

      final result = await _client
          .from('cargas_academicas')
          .select('estado, comentario_admin')
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return {
        'estado': result?['estado'] as String?,
        'comentario': result?['comentario_admin'] as String?,
      };
    } catch (e) {
      debugPrint('[EnrollmentService] getCargaInfo error: $e');
      return {'estado': null, 'comentario': null};
    }
  }

  /// Cambia una carga rechazada de vuelta a borrador para que el estudiante
  /// pueda modificar su lista de materias y volver a enviarla.
  Future<bool> resetCargaRechazada(String userId) async {
    try {
      final semestreId = await _getSemestreActivoId();
      if (semestreId == null) return false;

      await _client
          .from('cargas_academicas')
          .update({
            'estado': 'borrador',
            'comentario_admin': null,
            'fecha_solicitud': null,
            'fecha_respuesta': null,
            'numero_orden': null,
            'admin_id': null,
          })
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .eq('estado', 'rechazada');

      debugPrint('[EnrollmentService] resetCargaRechazada OK');
      return true;
    } catch (e) {
      debugPrint('[EnrollmentService] resetCargaRechazada error: $e');
      return false;
    }
  }

  Future<List<InscripcionModel>> fetchActiveLoadEnrollments(
      String userId) async {
    try {
      final semestreId = await _getSemestreActivoId();
      if (semestreId == null) return [];

      final carga = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (carga == null) return [];

      final cargaId = carga['id'] as String;

      final result = await _client
          .from('inscripciones')
          .select('id, estado, tipo, carga_id, materia_id, created_at, materias(*)')
          .eq('carga_id', cargaId)
          .order('created_at', ascending: false);

      return (result as List<dynamic>)
          .map((raw) => InscripcionModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EnrollmentService] fetchActiveLoadEnrollments error: $e');
      return [];
    }
  }

  // ── Inscripciones del usuario ───────────────────────────────────────────────
  Future<List<InscripcionModel>> fetchEnrollments(String userId) async {
    try {
      final cargas = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('usuario_id', userId);

      if ((cargas as List).isEmpty) return [];

      final cargaIds = cargas.map((c) => c['id'] as String).toList();

      final result = await _client
          .from('inscripciones')
          .select('id, estado, tipo, carga_id, materia_id, created_at, materias(*)')
          .inFilter('carga_id', cargaIds)
          .order('created_at', ascending: false);

      return (result as List<dynamic>)
          .map((raw) => InscripcionModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EnrollmentService] fetchEnrollments error: $e');
      return [];
    }
  }

  Future<List<InscripcionModel>> fetchBorradorEnrollments(
      String userId) async {
    try {
      final semestreId = await _getSemestreActivoId();
      if (semestreId == null) return [];

      final carga = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .inFilter('estado', ['borrador', 'rechazada'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (carga == null) return [];
      final cargaId = carga['id'] as String;

      final result = await _client
          .from('inscripciones')
          .select('id, estado, tipo, carga_id, materia_id, created_at, materias(*)')
          .eq('carga_id', cargaId)
          .order('created_at', ascending: false);

      return (result as List<dynamic>)
          .map((raw) => InscripcionModel.fromJson(raw as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EnrollmentService] fetchBorradorEnrollments error: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Helpers para validación de horario ────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  /// Convierte un string de hora de Supabase a minutos desde medianoche.
  /// Acepta formatos: "HH:mm", "HH:mm:ss", "HH:mm:ss.ffffff"
  /// Retorna null si el string es inválido o nulo.
  int? _parseToMinutes(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      // Tomar solo HH:mm ignorando segundos y microsegundos
      final parts = raw.split(':');
      if (parts.length < 2) return null;
      final horas = int.parse(parts[0].trim());
      final minutos = int.parse(parts[1].trim());
      if (horas < 0 || horas > 23 || minutos < 0 || minutos > 59) return null;
      return horas * 60 + minutos;
    } catch (_) {
      return null;
    }
  }

  /// Determina si dos rangos de tiempo [inicioA, finA) y [inicioB, finB)
  /// se solapan. Incluye el caso de horarios exactamente iguales.
  ///
  /// Lógica: dos intervalos se solapan si  inicioA < finB  &&  inicioB < finA
  /// Esto cubre: parcial, total, exactamente iguales y uno contenido en otro.
  bool _horariosSeChoca(int inicioA, int finA, int inicioB, int finB) {
    return inicioA < finB && inicioB < finA;
  }

  // ── Inscribir materia ───────────────────────────────────────────────────────
  Future<bool> enrollMateria(String userId, String materiaId) async {
    try {
      final cargaId = await _getOrCreateCargaId(userId);
      if (cargaId == null) return false;

      // ── 1. Verificar si ya está inscrito ──────────────────────────────────
      final existing = await _client
          .from('inscripciones')
          .select('id')
          .eq('carga_id', cargaId)
          .eq('materia_id', materiaId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Ya estás inscrito en esta materia.');
      }

      // ── 2. Traer datos de la materia nueva ────────────────────────────────
      final nuevaMateriaRaw = await _client
          .from('materias')
          .select('nombre, dias_semana, hora_inicio, hora_fin, creditos')
          .eq('id', materiaId)
          .maybeSingle();

      if (nuevaMateriaRaw == null) {
        throw Exception('No se encontró la materia seleccionada.');
      }

      final nuevosCreditos = (nuevaMateriaRaw['creditos'] as int?) ?? 0;
      final diasNueva =
          List<String>.from(nuevaMateriaRaw['dias_semana'] ?? []);
      final inicioNuevaMin = _parseToMinutes(
          nuevaMateriaRaw['hora_inicio'] as String?);
      final finNuevaMin =
          _parseToMinutes(nuevaMateriaRaw['hora_fin'] as String?);
      final nombreNueva =
          nuevaMateriaRaw['nombre'] as String? ?? 'la materia seleccionada';

      // ── 3. Traer materias ya inscritas en la carga actual ─────────────────
      final activasRaw = await _client
          .from('inscripciones')
          .select('materias(nombre, dias_semana, hora_inicio, hora_fin, creditos)')
          .eq('carga_id', cargaId);

      int totalCreditos = 0;

      for (final activa in (activasRaw as List<dynamic>)) {
        final materiaActiva = activa['materias'] as Map<String, dynamic>?;
        if (materiaActiva == null) continue;

        totalCreditos += (materiaActiva['creditos'] as int?) ?? 0;

        final nombreActiva =
            materiaActiva['nombre'] as String? ?? 'otra materia';
        final diasActiva =
            List<String>.from(materiaActiva['dias_semana'] ?? []);
        final inicioActivaMin = _parseToMinutes(
            materiaActiva['hora_inicio'] as String?);
        final finActivaMin =
            _parseToMinutes(materiaActiva['hora_fin'] as String?);

        // ── CORRECCIÓN: validación robusta de choque de horario ────────────
        //
        // Solo validamos si AMBAS materias tienen días Y horario completo.
        // Si alguna no tiene horario definido, no podemos detectar el choque
        // y dejamos pasar (el coordinador lo revisará manualmente).
        //
        // Casos cubiertos:
        //   • Horarios exactamente iguales          → choca ✓
        //   • Solapamiento parcial                  → choca ✓
        //   • Uno contenido dentro del otro         → choca ✓
        //   • Horario de nueva termina cuando activa empieza (adyacente) → NO choca ✓
        //   • Días distintos, mismo horario         → NO choca ✓
        //   • Materia sin hora_inicio / hora_fin    → se omite validación ✓

        final nuevaTieneHorario = diasNueva.isNotEmpty &&
            inicioNuevaMin != null &&
            finNuevaMin != null;
        final activaTieneHorario = diasActiva.isNotEmpty &&
            inicioActivaMin != null &&
            finActivaMin != null;

        if (nuevaTieneHorario && activaTieneHorario) {
          // Verificar si comparten al menos un día
          final compartenDia =
              diasNueva.any((d) => diasActiva.contains(d));

          if (compartenDia) {
            if (_horariosSeChoca(
              inicioNuevaMin!,
              finNuevaMin!,
              inicioActivaMin!,
              finActivaMin!,
            )) {
              // Construir mensaje descriptivo con horas para facilitar la comprensión
              final inicioNuevaStr =
                  nuevaMateriaRaw['hora_inicio'] as String? ?? '';
              final finNuevaStr =
                  nuevaMateriaRaw['hora_fin'] as String? ?? '';
              final inicioActivaStr =
                  materiaActiva['hora_inicio'] as String? ?? '';
              final finActivaStr =
                  materiaActiva['hora_fin'] as String? ?? '';

              final diasCruce = diasNueva
                  .where((d) => diasActiva.contains(d))
                  .join(', ');

              throw Exception(
                'Choque de horario: "$nombreNueva" '
                '(${_formatHora(inicioNuevaStr)}–${_formatHora(finNuevaStr)}) '
                'y "$nombreActiva" '
                '(${_formatHora(inicioActivaStr)}–${_formatHora(finActivaStr)}) '
                'coinciden el/los día(s): $diasCruce.',
              );
            }
          }
        }
      }

      // ── 4. Validar límite de créditos ─────────────────────────────────────
      if (totalCreditos + nuevosCreditos > 21) {
        throw Exception(
          'No puedes superar 21 créditos por semestre. '
          'Llevas $totalCreditos créditos y esta materia agrega $nuevosCreditos.',
        );
      }

      // ── 5. Insertar inscripción ───────────────────────────────────────────
      await _client.from('inscripciones').insert({
        'carga_id': cargaId,
        'materia_id': materiaId,
        'estado': 'tentativa',
        'tipo': 'inscripcion',
      });

      debugPrint('[EnrollmentService] enrollMateria OK: $materiaId');
      return true;
    } catch (e) {
      debugPrint('[EnrollmentService] enrollMateria error: $e');
      rethrow;
    }
  }

  /// Formatea "07:00:00" → "07:00" para mostrar en mensajes de error.
  String _formatHora(String raw) {
    if (raw.isEmpty) return raw;
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }

  // ── Cancelar inscripción ────────────────────────────────────────────────────
  Future<bool> cancelInscripcion(String inscripcionId, String userId) async {
    try {
      // Permite cancelar inscripciones en cargas con estado 'borrador' o 'rechazada'
      final cargas = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('usuario_id', userId)
          .inFilter('estado', ['borrador', 'rechazada']);

      final cargaIds =
          (cargas as List).map((c) => c['id'] as String).toList();
      if (cargaIds.isEmpty) {
        debugPrint(
            '[EnrollmentService] cancelInscripcion: no hay carga en borrador');
        return false;
      }

      final inscripcion = await _client
          .from('inscripciones')
          .select('id, carga_id')
          .eq('id', inscripcionId)
          .inFilter('carga_id', cargaIds)
          .maybeSingle();

      if (inscripcion == null) {
        debugPrint(
            '[EnrollmentService] cancelInscripcion: no encontrada o no es borrador');
        return false;
      }

      await _client.from('inscripciones').delete().eq('id', inscripcionId);

      debugPrint('[EnrollmentService] cancelInscripcion OK');
      return true;
    } catch (e) {
      debugPrint('[EnrollmentService] cancelInscripcion error: $e');
      return false;
    }
  }

  // ── Enviar carga a revisión ─────────────────────────────────────────────────
  Future<bool> submitCargaAcademica(String userId) async {
    try {
      final semestreId = await _getSemestreActivoId();
      if (semestreId == null) return false;

      final maxOrdenRaw = await _client
          .from('cargas_academicas')
          .select('numero_orden')
          .eq('semestre_id', semestreId)
          .order('numero_orden', ascending: false)
          .limit(1)
          .maybeSingle();
      final nuevoOrden =
          ((maxOrdenRaw?['numero_orden'] as int?) ?? 0) + 1;

      await _client
          .from('cargas_academicas')
          .update({
            'estado': 'en_revision',
            'fecha_solicitud': DateTime.now().toIso8601String(),
            'numero_orden': nuevoOrden,
          })
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .inFilter('estado', ['borrador', 'rechazada']);
      return true;
    } catch (e) {
      debugPrint('[EnrollmentService] submitCargaAcademica error: $e');
      return false;
    }
  }
}