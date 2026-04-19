import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/data_model.dart';

class DataService {
  /// Simula una consulta asíncrona con Future.delayed
  Future<Map<String, dynamic>> fetchData() async {
    debugPrint('[DataService] Antes del fetch - ${DateTime.now()}');
    final stopwatch = Stopwatch()..start();

    await Future.delayed(
      Duration(seconds: AppConstants.fetchDelaySeconds),
    );

    // Simular error aleatorio ~20% del tiempo
    if (Random().nextDouble() < 0.2) {
      debugPrint('[DataService] Error simulado - ${DateTime.now()}');
      throw Exception('Error al obtener datos del servidor');
    }

    stopwatch.stop();
    debugPrint('[DataService] Despues del fetch - ${DateTime.now()}');

    final model = DataModel(
      id: '#${Random().nextInt(9000) + 1000}',
      title: 'Registro de usuario',
      description: 'Perfil obtenido correctamente desde el servidor remoto.',
      author: 'Jolmer Alexander',
      email: 'jolmer.viedma01@uceva.edu.co',
      status: 'Activo',
      timestamp: DateTime.now(),
    );

    return {
      'data': model,
      'durationMs': stopwatch.elapsedMilliseconds,
    };
  }
}