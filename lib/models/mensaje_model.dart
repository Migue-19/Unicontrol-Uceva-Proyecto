import 'package:unicontrol_app/services/aes_service.dart';

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

  // Getters de compatibilidad
  String get remitenteId      => emisorId;
  String get destinatarioId   => receptorId;
  String get contenido        => mensaje;
  String? get remitenteNombre => emisorNombre;
  String? get destinatarioNombre => receptorNombre;

  /// Construye desde JSON con texto plano (sin descifrar).
  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    final emisor  = json['emisor']  as Map<String, dynamic>?;
    final receptor = json['receptor'] as Map<String, dynamic>?;
    return MensajeModel(
      id:         json['id'] as String,
      emisorId:   (json['emisor_id']   ?? json['remitente_id']    ?? '') as String,
      receptorId: (json['receptor_id'] ?? json['destinatario_id'] ?? '') as String,
      asunto:     json['asunto'] as String? ?? '',
      mensaje:    (json['mensaje'] ?? json['contenido'] ?? '') as String,
      createdAt:  json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      leido:          json['leido'] as bool? ?? false,
      emisorNombre:   emisor?['nombre']  as String?,
      receptorNombre: receptor?['nombre'] as String?,
      cargaId:   json['carga_id']  as String?,
      parentId:  json['parent_id'] as String?,
    );
  }

  /// Construye desde JSON descifrando asunto y mensaje con AES-256-GCM.
  static Future<MensajeModel> fromJsonDecrypted(
      Map<String, dynamic> json) async {
    final emisor  = json['emisor']  as Map<String, dynamic>?;
    final receptor = json['receptor'] as Map<String, dynamic>?;

    final rawAsunto  = json['asunto'] as String? ?? '';
    final rawMensaje = (json['mensaje'] ?? json['contenido'] ?? '') as String;

    final asunto  = await UniControlMessaging.decryptMessage(rawAsunto);
    final mensaje = await UniControlMessaging.decryptMessage(rawMensaje);

    return MensajeModel(
      id:         json['id'] as String,
      emisorId:   (json['emisor_id']   ?? json['remitente_id']    ?? '') as String,
      receptorId: (json['receptor_id'] ?? json['destinatario_id'] ?? '') as String,
      asunto:     asunto,
      mensaje:    mensaje,
      createdAt:  json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      leido:          json['leido'] as bool? ?? false,
      emisorNombre:   emisor?['nombre']  as String?,
      receptorNombre: receptor?['nombre'] as String?,
      cargaId:   json['carga_id']  as String?,
      parentId:  json['parent_id'] as String?,
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
