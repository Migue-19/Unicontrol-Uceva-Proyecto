class UsuarioModel {
  final String id;
  final String? email;
  final String nombre;
  final String? codigoEstudiantil;
  final String? programaId;
  final String? programaNombre;
  final String? facultadNombre;
  final int semestreActual;
  final bool tutorialVisto;

  UsuarioModel({
    required this.id,
    this.email,
    required this.nombre,
    this.codigoEstudiantil,
    this.programaId,
    this.programaNombre,
    this.facultadNombre,
    this.semestreActual = 1,
    this.tutorialVisto = false,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final programaJson = json['programas'] as Map<String, dynamic>?;
    final facultadJson = programaJson?['facultades'] as Map<String, dynamic>?;
    return UsuarioModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      nombre: json['nombre'] as String? ?? '',
      codigoEstudiantil: json['codigo_estudiantil'] as String?,
      programaId: json['programa_id'] as String?,
      programaNombre: programaJson?['nombre'] as String?,
      facultadNombre: facultadJson?['nombre'] as String?,
      semestreActual: json['semestre_actual'] != null
          ? (json['semestre_actual'] as num).toInt()
          : 1,
      tutorialVisto: json['tutorial_visto'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'codigo_estudiantil': codigoEstudiantil,
        'programa_id': programaId,
        'semestre_actual': semestreActual,
        'tutorial_visto': tutorialVisto,
      };
}
