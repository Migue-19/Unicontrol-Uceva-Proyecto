import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/models/usuario_model.dart';
import 'package:unicontrol_app/services/admin_service.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
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
  
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
  }

  Future<List<UsuarioModel>> _loadStudents() async {
    final userId = context.read<AuthService>().user?.id;
    if (userId == null) return [];
    return _adminService.fetchEstudiantesDeFacultad(userId);
  }

  Future<void> _refresh() async {
    final f = _loadStudents();
    void _upd() { _studentsFuture = f; } setState(_upd);
    await f;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                        'No hay estudiantes registrados en tu facultad en este momento.',
                  ),
                ],
              );
            }

            final query = _searchQuery.toLowerCase();
            final filteredStudents = students.where((s) {
              final matchNombre = s.nombre.toLowerCase().contains(query);
              final matchCodigo = (s.codigoEstudiantil ?? '').toLowerCase().contains(query);
              final matchSemestre = s.semestreActual.toString().contains(query);
              return matchNombre || matchCodigo || matchSemestre;
            }).toList();

            final grouped = <String, List<UsuarioModel>>{};
            for (final s in filteredStudents) {
              final key = s.programaNombre?.trim().isNotEmpty == true
                  ? s.programaNombre!
                  : s.programaId?.trim().isNotEmpty == true
                      ? s.programaId!
                      : 'Sin programa asignado';
              grouped.putIfAbsent(key, () => []).add(s);
            }
            final entries = grouped.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: StaggeredEntrance(
                      index: 0,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, código o semestre...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (filteredStudents.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: EmptyState(
                        title: 'Sin resultados',
                        message: 'No se encontraron estudiantes con esos criterios.',
                      ),
                    ),
                  )
                else
                  ...entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final group = entry.value;
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: StaggeredEntrance(
                              index: index + 1,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                                child: Text(
                                  group.key,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final s = group.value[i];
                                return StaggeredEntrance(
                                  index: index + i + 2,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: AppCard(
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () => context.push('/admin/estudiantes/${s.id}'),
                                        leading: CircleAvatar(
                                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                                          child: Text(
                                            initialsFromName(s.nombre),
                                            style: const TextStyle(color: AppTheme.primary),
                                          ),
                                        ),
                                        title: Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.codigoEstudiantil ?? 'Sin código'),
                                            Text('Semestre: ${s.semestreActual}'),
                                          ],
                                        ),
                                        trailing: const Icon(Icons.chevron_right_rounded),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: group.value.length,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            );
          },
        ),
      ),
    );
  }
}