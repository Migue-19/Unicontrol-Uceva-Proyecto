import 'package:flutter/material.dart';
import '../services/isolate_service.dart';
import '../constants/app_constants.dart';

enum IsolateState { idle, running, done, error }

class IsolateView extends StatefulWidget {
  const IsolateView({super.key});

  @override
  State<IsolateView> createState() => _IsolateViewState();
}

class _IsolateViewState extends State<IsolateView> {
  IsolateState _state = IsolateState.idle;
  Map<String, dynamic>? _result;
  String _errorMsg = '';

  Future<void> _runTask() async {
    setState(() {
      _state = IsolateState.running;
      _result = null;
    });

    debugPrint('[IsolateView] UI libre - compute trabajando en segundo plano...');

    try {
      final res = await IsolateService.runHeavyTask(
        AppConstants.heavyTaskIterations,
      );
      if (!mounted) return;
      setState(() {
        _state = IsolateState.done;
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = IsolateState.error;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isolate — Tarea Pesada')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildContent(),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _state == IsolateState.running ? null : _runTask,
              icon: const Icon(Icons.memory),
              label: Text(
                'Ejecutar suma (${AppConstants.heavyTaskIterations ~/ 1000000}M iteraciones)',
              ),
            ),
            if (_state == IsolateState.running) ...[
              const SizedBox(height: 16),
              const Text(
                'La UI sigue respondiendo mientras el compute trabaja',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case IsolateState.idle:
        return const _InfoCard(
          icon: Icons.memory_outlined,
          color: Colors.blueGrey,
          title: 'Listo',
          body: 'Presiona el boton para lanzar el compute.\n'
              'La UI permanecera responsiva.',
        );
      case IsolateState.running:
        return const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Compute ejecutandose...', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Puedes seguir interactuando con la app'),
          ],
        );
      case IsolateState.done:
        return _InfoCard(
          icon: Icons.check_circle_outline,
          color: Colors.green,
          title: 'Completado!',
          body: 'Iteraciones: ${_result!['iterations']}\n'
              'Resultado de suma: ${_result!['sum']}\n'
              'Tiempo del compute: ${_result!['durationMs']} ms',
        );
      case IsolateState.error:
        return _InfoCard(
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Error',
          body: _errorMsg,
        );
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 56, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}