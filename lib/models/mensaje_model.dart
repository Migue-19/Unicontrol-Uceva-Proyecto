class MensajeModel {
  final String id;
  final String emisorId;
  final String receptorId;
  final String asunto;
  final String mensaje;
  final DateTime? createdAt;
  final bool leido;
  final String? emisorNombre;
  final String? receptorNombre;
  final String? cargaId;
  final String? parentId;

  MensajeModel({
    required this.id,
    required this.emisorId,
    required this.receptorId,
    required this.asunto,
    required this.mensaje,
    this.createdAt,
    this.leido = false,
    this.emisorNombre,
    this.receptorNombre,
    this.cargaId,
    this.parentId,
  });

  // Getters de compatibilidad con código que use nombres viejos
  String get remitenteId => emisorId;
  String get destinatarioId => receptorId;
  String get contenido => mensaje;
  String? get remitenteNombre => emisorNombre;
  String? get destinatarioNombre => receptorNombre;

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    final emisor = json['emisor'] as Map<String, dynamic>?;
    final receptor = json['receptor'] as Map<String, dynamic>?;
    return MensajeModel(
      id: json['id'] as String,
      emisorId: (json['emisor_id'] ?? json['remitente_id'] ?? '') as String,
      receptorId: (json['receptor_id'] ?? json['destinatario_id'] ?? '') as String,
      asunto: json['asunto'] as String? ?? '',
      mensaje: (json['mensaje'] ?? json['contenido'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      leido: json['leido'] as bool? ?? false,
      emisorNombre: emisor?['nombre'] as String?,
      receptorNombre: receptor?['nombre'] as String?,
      cargaId: json['carga_id'] as String?,
      parentId: json['parent_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'emisor_id': emisorId,
        'receptor_id': receptorId,
        'asunto': asunto,
        'mensaje': mensaje,
        'created_at': createdAt?.toIso8601String(),
        'leido': leido,
      };
}
