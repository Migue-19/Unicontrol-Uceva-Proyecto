class JwtUserModel {
  const JwtUserModel({
    required this.nombre,
    required this.email,
    this.role = 'estudiante',
    this.tema = 'light',
    this.idioma = 'es',
    this.programaNombre,
    this.facultadNombre,
    this.codigoEstudiantil,
    this.semestreActual,
  });

  final String nombre;
  final String email;
  final String role;
  final String tema;
  final String idioma;
  final String? programaNombre;
  final String? facultadNombre;
  final String? codigoEstudiantil;
  final int? semestreActual;

  String get initials {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  JwtUserModel copyWith({
    String? nombre,
    String? email,
    String? role,
    String? tema,
    String? idioma,
    String? programaNombre,
    String? facultadNombre,
    String? codigoEstudiantil,
    int? semestreActual,
  }) =>
      JwtUserModel(
        nombre: nombre ?? this.nombre,
        email: email ?? this.email,
        role: role ?? this.role,
        tema: tema ?? this.tema,
        idioma: idioma ?? this.idioma,
        programaNombre: programaNombre ?? this.programaNombre,
        facultadNombre: facultadNombre ?? this.facultadNombre,
        codigoEstudiantil: codigoEstudiantil ?? this.codigoEstudiantil,
        semestreActual: semestreActual ?? this.semestreActual,
      );
}