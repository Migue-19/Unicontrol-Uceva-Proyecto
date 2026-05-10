import 'package:flutter/material.dart';
import 'package:unicontrol_app/models/usuario_model.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class EstudiantesScreen extends StatefulWidget {
  const EstudiantesScreen({super.key});

  @override
  State<EstudiantesScreen> createState() => _EstudiantesScreenState();
}

class _EstudiantesScreenState extends State<EstudiantesScreen> {
  final AdminService _adminService = AdminService();
  late Future<List<UsuarioModel>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = _adminService.fetchEstudiantes();
  }

  Future<void> _refresh() async {
    setState(() => _studentsFuture = _adminService.fetchEstudiantes());
    await _studentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Estudiantes',
      isAdminSection: true,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<UsuarioModel>>(
          future: _studentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const ShimmerListPlaceholder();
            }
            final students = snapshot.data ?? [];
            if (students.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'Sin estudiantes',
                    message:
                        'Los registros institucionales aparecerán aquí agrupados por programa.',
                  ),
                ],
              );
            }

            // Agrupar por nombre de programa
            final grouped = <String, List<UsuarioModel>>{};
            for (final s in students) {
              final key = s.programaNombre?.trim().isNotEmpty == true
                  ? s.programaNombre!
                  : s.programaId?.trim().isNotEmpty == true
                      ? s.programaId!
                      : 'Sin programa asignado';
              grouped.putIfAbsent(key, () => []).add(s);
            }
            final entries = grouped.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final group = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: StaggeredEntrance(
                    index: index,
                    child: AppCard(
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 8),
                        title: Text(group.key,
                            style: Theme.of(context).textTheme.titleMedium),
                        subtitle: Text(
                          '${group.value.length} '
                          '${group.value.length == 1 ? 'estudiante' : 'estudiantes'}',
                        ),
                        children: group.value
                            .map((s) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    child: Text(initialsFromName(s.nombre)),
                                  ),
                                  title: Text(s.nombre),
                                  subtitle: Text(
                                    s.facultadNombre ?? s.email ?? '',
                                  ),
                                  trailing: Text(
                                    s.codigoEstudiantil ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
