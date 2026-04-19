import 'package:flutter/foundation.dart';

class IsolateService {
  static Future<Map<String, dynamic>> runHeavyTask(int iterations) async {
    debugPrint('[IsolateService] Iniciando compute...');
    final stopwatch = Stopwatch()..start();

    final result = await compute(_heavyComputation, iterations);

    stopwatch.stop();
    debugPrint(
      '[IsolateService] compute completado en ${stopwatch.elapsedMilliseconds} ms',
    );
    return result;
  }

  static Map<String, dynamic> _heavyComputation(int iterations) {
    final sw = Stopwatch()..start();

    int sum = 0;
    for (int i = 0; i < iterations; i++) {
      sum += i;
    }

    sw.stop();

    return {
      'sum': sum,
      'iterations': iterations,
      'durationMs': sw.elapsedMilliseconds,
    };
  }
}