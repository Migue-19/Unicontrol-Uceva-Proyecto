import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/data_model.dart';

enum FetchState { idle, loading, success, error }

class AsyncView extends StatefulWidget {
  const AsyncView({super.key});

  @override
  State<AsyncView> createState() => _AsyncViewState();
}

class _AsyncViewState extends State<AsyncView> {
  FetchState _state = FetchState.idle;
  DataModel? _data;
  String _errorMsg = '';
  int _durationMs = 0;
  final _service = DataService();

  Future<void> _fetchData() async {
    setState(() {
      _state = FetchState.loading;
      _data = null;
      _errorMsg = '';
      _durationMs = 0;
    });

    debugPrint('[AsyncView] Durante la espera - UI mostrando Cargando...');

    try {
      final response = await _service.fetchData();
      if (!mounted) return;
      setState(() {
        _state = FetchState.success;
        _data = response['data'] as DataModel;
        _durationMs = response['durationMs'] as int;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = FetchState.error;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Future / async / await')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStateWidget(),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _state == FetchState.loading ? null : _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Consultar datos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateWidget() {
    switch (_state) {
      case FetchState.idle:
        return const _StatusCard(
          icon: Icons.info_outline,
          color: Colors.grey,
          title: 'Listo',
          message: 'Presiona el boton para iniciar la consulta.',
        );
      case FetchState.loading:
        return const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando...', style: TextStyle(fontSize: 20)),
          ],
        );
      case FetchState.success:
        return _DataCard(data: _data!, durationMs: _durationMs);
      case FetchState.error:
        return _StatusCard(
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Error',
          message: _errorMsg,
        );
    }
  }
}

// --- Tarjeta de datos del servidor ---
class _DataCard extends StatelessWidget {
  final DataModel data;
  final int durationMs;

  const _DataCard({required this.data, required this.durationMs});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 32, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Datos recibidos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _DataRow(icon: Icons.tag, label: 'ID', value: data.id),
            _DataRow(icon: Icons.title, label: 'Titulo', value: data.title),
            _DataRow(
                icon: Icons.description,
                label: 'Descripcion',
                value: data.description),
            _DataRow(icon: Icons.person, label: 'Autor', value: data.author),
            _DataRow(icon: Icons.email, label: 'Email', value: data.email),
            _DataRow(
              icon: Icons.circle,
              label: 'Estado',
              value: data.status,
              valueColor: Colors.green,
            ),
            _DataRow(
              icon: Icons.access_time,
              label: 'Timestamp',
              value: data.timestamp.toString().substring(0, 19),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.speed, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Tiempo de respuesta: $durationMs ms',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tarjeta genérica de estado ---
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}