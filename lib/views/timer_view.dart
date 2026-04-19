import 'dart:async';
import 'package:flutter/material.dart';

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  Timer? _timer;
  int _elapsedMs = 0;
  bool _isRunning = false;

  String get _display {
    final ms = _elapsedMs % 1000;
    final secs = (_elapsedMs ~/ 1000) % 60;
    final mins = (_elapsedMs ~/ 60000) % 60;
    return '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}.'
        '${(ms ~/ 10).toString().padLeft(2, '0')}';
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        setState(() => _elapsedMs += 100);
    });
    setState(() => _isRunning = true);
}

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedMs = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Limpieza de recursos
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cronómetro — Timer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _display,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 16,
              children: [
                if (!_isRunning)
                  ElevatedButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_elapsedMs == 0 ? 'Iniciar' : 'Reanudar'),
                  ),
                if (_isRunning)
                  ElevatedButton.icon(
                    onPressed: _pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pausar'),
                  ),
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}