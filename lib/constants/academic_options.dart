class AcademicOptions {
  /// Facultad → lista de programas.
  /// Los nombres deben coincidir exactamente con los de la tabla public.programas.
  /// Al registrar, auth_service resuelve el nombre a UUID automáticamente.
  static const Map<String, List<String>> programsByFaculty = {
    'Ingeniería': [
      'Ingeniería de Sistemas',
      'Ingeniería Industrial',
      'Ingeniería Electrónica',
    ],
    'Ciencias Administrativas': [
      'Administración de Empresas',
      'Contaduría Pública',
      'Mercadeo',
    ],
    'Ciencias de la Salud': [
      'Enfermería',
      'Instrumentación Quirúrgica',
      'Fisioterapia',
    ],
    'Ciencias Jurídicas y Humanísticas': [
      'Derecho',
      'Licenciatura en Educación',
      'Trabajo Social',
    ],
  };

  static List<String> get faculties => programsByFaculty.keys.toList();

  static List<String> programsForFaculty(String? faculty) {
    if (faculty == null) return const [];
    return programsByFaculty[faculty] ?? const [];
  }
}
