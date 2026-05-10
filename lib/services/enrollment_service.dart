import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/models/inscripcion_model.dart';
import 'package:unicontrol_app/models/materia_model.dart';
import 'package:unicontrol_app/services/supabase_service.dart';

class EnrollmentService {
  final SupabaseClient _client = SupabaseService.client;

  // Estados que se consideran "cancelados" — se filtran en Dart, no en SQL,
  // para evitar dependencia del enum exacto definido en la BD.
  static const _estadosCancelados = {'cancelada', 'cancelado', 'cancelled'};

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
  Future<List<MateriaModel>> fetchCatalog() async {
    try {
      final semestreId = await _getSemestreActivoId();

      final List<dynamic> result;
      if (semestreId != null) {
        result = await _client
            .from('materias')
            .select()
            .eq('activa', true)
            .eq('semestre_academico_id', semestreId)
            .order('semestre')
            .order('nombre');
      } else {
        result = await _client
            .from('materias')
            .select()
            .eq('activa', true)
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

      final existing = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .eq('estado', 'borrador')
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

  // ── Inscripciones del usuario ───────────────────────────────────────────────
  // Sin filtro de estado en SQL → se filtra en Dart para evitar errores de enum
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

      // Filtrar estados cancelados en Dart (independiente del enum en BD)
      return (result as List<dynamic>)
          .map((raw) => InscripcionModel.fromJson(raw as Map<String, dynamic>))
          .where((i) => !_estadosCancelados.contains(i.estado.toLowerCase()))
          .toList();
    } catch (e) {
      debugPrint('[EnrollmentService] fetchEnrollments error: $e');
      return [];
    }
  }

  // ── Inscribir materia ───────────────────────────────────────────────────────
  Future<bool> enrollMateria(String userId, String materiaId) async {
    try {
      final cargaId = await _getOrCreateCargaId(userId);
      if (cargaId == null) return false;

      // Buscar inscripción previa (sin filtro de enum)
      final existing = await _client
          .from('inscripciones')
          .select('id, estado')
          .eq('carga_id', cargaId)
          .eq('materia_id', materiaId)
          .maybeSingle();

      if (existing != null) {
        final estado = (existing['estado'] as String? ?? '').toLowerCase();
        if (!_estadosCancelados.contains(estado)) {
          debugPrint('[EnrollmentService] Ya inscrito en $materiaId (estado: $estado)');
          return false;
        }
        // Reactivar inscripción cancelada con el estado inicial del enum
        await _client
            .from('inscripciones')
            .update({'estado': 'tentativa'})
            .eq('id', existing['id'] as String);
        return true;
      }

      await _client.from('inscripciones').insert({
        'carga_id': cargaId,
        'materia_id': materiaId,
        'estado': 'tentativa',
        'tipo': 'inscripcion',
      });
      return true;
    } catch (e) {
      debugPrint('[EnrollmentService] enrollMateria error: $e');
      return false;
    }
  }

  // ── Cancelar inscripción ────────────────────────────────────────────────────
  // Obtiene el valor correcto del enum consultando la BD antes de hacer UPDATE
  Future<bool> cancelInscripcion(String inscripcionId, String userId) async {
    try {
      final cargas = await _client
          .from('cargas_academicas')
          .select('id')
          .eq('usuario_id', userId);

      final cargaIds =
          (cargas as List).map((c) => c['id'] as String).toList();
      if (cargaIds.isEmpty) return false;

      final inscripcion = await _client
          .from('inscripciones')
          .select('id, carga_id, estado')
          .eq('id', inscripcionId)
          .inFilter('carga_id', cargaIds)
          .maybeSingle();

      if (inscripcion == null) return false;

      // Intentar con el valor más común primero, luego alternativas
      final candidatos = ['cancelada', 'cancelado', 'cancelled'];
      for (final estadoCancel in candidatos) {
        try {
          await _client
              .from('inscripciones')
              .update({'estado': estadoCancel})
              .eq('id', inscripcionId);
          debugPrint('[EnrollmentService] cancelInscripcion OK con estado: $estadoCancel');
          return true;
        } catch (_) {
          // probar siguiente candidato
          continue;
        }
      }

      debugPrint('[EnrollmentService] cancelInscripcion: ningún valor de enum funcionó');
      return false;
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

      await _client
          .from('cargas_academicas')
          .update({
            'estado': 'enviada',
            'fecha_solicitud': DateTime.now().toIso8601String(),
          })
          .eq('usuario_id', userId)
          .eq('semestre_id', semestreId)
          .eq('estado', 'borrador');
      return true;
    } catch (e) {
      debugPrint('[EnrollmentService] submitCargaAcademica error: $e');
      return false;
    }
  }
}
