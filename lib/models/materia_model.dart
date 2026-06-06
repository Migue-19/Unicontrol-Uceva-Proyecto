class MateriaModel {
  final String id;
  final String nombre;
  final String codigo;
  final int creditos;
  final String? horario;
  final int? cuposTotales;
  final int? cuposDisponibles;
  final int? semestre;
  final String? docente;
  final List<String>? diasSemana;
  final String? horaInicio;
  final String? horaFin;
  final String? salon;
  final bool esElectiva;
  final bool esCompartida;

  MateriaModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.creditos,
    this.horario,
    this.cuposTotales,
    this.cuposDisponibles,
    this.semestre,
    this.docente,
    this.diasSemana,
    this.horaInicio,
    this.horaFin,
    this.salon,
    this.esElectiva = false,
    this.esCompartida = false,
  });

  factory MateriaModel.fromJson(Map<String, dynamic> json) {
    return MateriaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String? ?? '',
      creditos: json['creditos'] is int
          ? json['creditos'] as int
          : int.tryParse('${json['creditos']}') ?? 0,
      horario: json['horario'] as String?,
      cuposTotales: json['cupos_totales'] is int
          ? json['cupos_totales'] as int
          : int.tryParse('${json['cupos_totales'] ?? ''}'),
      cuposDisponibles: json['cupos_disponibles'] is int
          ? json['cupos_disponibles'] as int
          : int.tryParse('${json['cupos_disponibles'] ?? ''}'),
      semestre: json['semestre'] is int
          ? json['semestre'] as int
          : int.tryParse('${json['semestre'] ?? ''}'),
      docente: json['docente'] as String?,
      diasSemana: json['dias_semana'] != null
          ? (json['dias_semana'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      horaInicio: json['hora_inicio'] as String?,
      horaFin: json['hora_fin'] as String?,
      salon: json['salon'] as String?,
      esElectiva: json['es_electiva'] as bool? ?? false,
      esCompartida: json['es_compartida'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'creditos': creditos,
      'horario': horario,
      'cupos_totales': cuposTotales,
      'cupos_disponibles': cuposDisponibles,
      'semestre': semestre,
      'docente': docente,
      'dias_semana': diasSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'salon': salon,
      'es_electiva': esElectiva,
      'es_compartida': esCompartida,
    };
  }
}
