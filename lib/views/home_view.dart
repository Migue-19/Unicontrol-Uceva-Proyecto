import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taller: Segundo Plano'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selecciona una demostración',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _MenuButton(
              icon: Icons.cloud_download_outlined,
              label: '1. Future / async / await',
              subtitle: 'Consulta simulada con estados de carga',
              route: AppRoutes.async,
            ),
            const SizedBox(height: 16),
            _MenuButton(
              icon: Icons.timer_outlined,
              label: '2. Timer — Cronómetro',
              subtitle: 'Iniciar · Pausar · Reanudar · Reiniciar',
              route: AppRoutes.timer,
            ),
            const SizedBox(height: 16),
            _MenuButton(
              icon: Icons.memory_outlined,
              label: '3. Isolate — Tarea Pesada',
              subtitle: 'Suma masiva sin bloquear la UI',
              route: AppRoutes.isolate,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }
}