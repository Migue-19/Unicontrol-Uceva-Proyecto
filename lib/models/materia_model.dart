class MateriaModel {
  final String id;
  final String nombre;
  final String codigo;
  final int creditos;
  final String? horario;
  final int? cuposTotales;
  final int? cuposDisponibles;
  final int? semestre;

  MateriaModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.creditos,
    this.horario,
    this.cuposTotales,
    this.cuposDisponibles,
    this.semestre,
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
    };
  }
}
