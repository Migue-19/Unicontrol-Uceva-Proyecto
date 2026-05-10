import 'package:unicontrol_app/models/materia_model.dart';

class InscripcionModel {
  final String id;
  final String cargaId;
  final String materiaId;
  final String estado;
  final String tipo;
  final DateTime? createdAt;
  final MateriaModel? materia;

  InscripcionModel({
    required this.id,
    required this.cargaId,
    required this.materiaId,
    required this.estado,
    this.tipo = 'inscripcion',
    this.createdAt,
    this.materia,
  });

  factory InscripcionModel.fromJson(Map<String, dynamic> json) {
    final materiaJson = json['materias'] as Map<String, dynamic>?;
    return InscripcionModel(
      id: json['id'] as String,
      cargaId: json['carga_id'] as String? ?? '',
      materiaId: json['materia_id'] as String,
      estado: json['estado'] as String? ?? 'tentativa',
      tipo: json['tipo'] as String? ?? 'inscripcion',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      materia: materiaJson != null ? MateriaModel.fromJson(materiaJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'carga_id': cargaId,
        'materia_id': materiaId,
        'estado': estado,
        'tipo': tipo,
        'created_at': createdAt?.toIso8601String(),
      };
}
