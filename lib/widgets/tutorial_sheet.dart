import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';

class TutorialStepData {
  const TutorialStepData({
    required this.title,
    required this.description,
    required this.icon,
    this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? route;
}

const List<TutorialStepData> _tutorialSteps = [
  TutorialStepData(
    title: 'Inicio',
    description:
        'Consulta tu resumen academico, el estado del perfil y tus accesos rapidos.',
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
  ),
  TutorialStepData(
    title: 'Catalogo',
    description:
        'Explora las materias disponibles, cupos, creditos y horario por semestre.',
    icon: Icons.grid_view_rounded,
    route: '/catalog',
  ),
  TutorialStepData(
    title: 'Mis materias',
    description:
        'Revisa tus inscripciones activas y confirma tu carga academica cuando este lista.',
    icon: Icons.menu_book_rounded,
    route: '/my-subjects',
  ),
  TutorialStepData(
    title: 'Cancelar materias',
    description:
        'Solicita la cancelacion de asignaturas inscritas con confirmacion previa.',
    icon: Icons.remove_circle_outline_rounded,
    route: '/cancel-subjects',
  ),
  TutorialStepData(
    title: 'Perfil',
    description:
        'Verifica que tus datos personales y academicos coincidan.',
    icon: Icons.person_outline_rounded,
    route: '/profile',
  ),
];

Future<void> showTutorialSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.65,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const UcevaLogoHero(size: 54, heroTag: 'uceva-tutorial'),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tutorial UniControl',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Puedes abrir esta guia cada vez que la necesites.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _tutorialSteps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final step = _tutorialSteps[index];
                      return AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(step.icon, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    step.description,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (step.route != null) ...[
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        context.go(step.route!);
                                      },
                                      child: const Text('Ir a esta seccion'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: 'Entendido',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
