import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/constants/academic_options.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class CompleteGoogleRegistrationScreen extends StatefulWidget {
  const CompleteGoogleRegistrationScreen({super.key});

  @override
  State<CompleteGoogleRegistrationScreen> createState() =>
      _CompleteGoogleRegistrationScreenState();
}

class _CompleteGoogleRegistrationScreenState
    extends State<CompleteGoogleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _semestreController = TextEditingController();
  String? _selectedFaculty;
  String? _selectedCareer;
  bool _isSaving = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _semestreController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final error = await context
        .read<AuthService>()
        .completeGoogleRegistration(
          codigoEstudiantil: _codigoController.text.trim(),
          carreraId: _selectedCareer!,
          semestre: int.parse(_semestreController.text.trim()),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
      return;
    }
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<AuthService>().pendingGoogleProfile;
    final careers = AcademicOptions.programsForFaculty(_selectedFaculty);

    if (pending == null) {
      return BaseView(
        title: 'Completar registro',
        showBottomNav: false,
        useGradientBackground: true,
        child: EmptyState(
          title: 'Registro no disponible',
          message:
              'No encontramos un acceso con Google pendiente. Inicia sesion nuevamente.',
          action: SizedBox(
            width: 220,
            child: GradientButton(
                label: 'Volver al login',
                onTap: () => context.go('/login')),
          ),
        ),
      );
    }

    return BaseView(
      title: 'Completar registro',
      showBottomNav: false,
      useGradientBackground: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StaggeredEntrance(
                      index: 0, child: Center(child: UcevaLogoHero())),
                  const SizedBox(height: 20),
                  StaggeredEntrance(
                    index: 1,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Termina tu acceso institucional',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(
                            'Estos datos faltan para completar tu perfil académico.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF7FBF8),
                                borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFE4F4EA),
                                  child: Text(
                                    initialsFromName(pending.nombre),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: const Color(0xFF1B7A3E),
                                            fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(pending.nombre,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      const SizedBox(height: 4),
                                      Text(pending.email ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _codigoController,
                            decoration: const InputDecoration(
                                labelText: 'Código estudiantil',
                                prefixIcon: Icon(Icons.badge_outlined)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa tu código'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedFaculty,
                            decoration: const InputDecoration(
                                labelText: 'Facultad',
                                prefixIcon:
                                    Icon(Icons.account_balance_outlined)),
                            items: AcademicOptions.faculties
                                .map((f) => DropdownMenuItem(
                                    value: f, child: Text(f)))
                                .toList(),
                            onChanged: (v) => setState(() {
                              _selectedFaculty = v;
                              _selectedCareer = null;
                            }),
                            validator: (v) =>
                                v == null ? 'Selecciona una facultad' : null,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedCareer,
                            decoration: const InputDecoration(
                                labelText: 'Programa académico',
                                prefixIcon: Icon(Icons.school_outlined)),
                            items: careers
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: careers.isEmpty
                                ? null
                                : (v) =>
                                    setState(() => _selectedCareer = v),
                            validator: (v) =>
                                v == null ? 'Selecciona un programa' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _semestreController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Semestre',
                                prefixIcon: Icon(Icons.timeline_outlined)),
                            validator: (v) {
                              final s = int.tryParse(v ?? '');
                              if (s == null || s < 1 || s > 12)
                                return 'Semestre entre 1 y 12';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            label: 'Completar registro',
                            icon: Icons.arrow_forward_rounded,
                            onTap: _submit,
                            isLoading: _isSaving,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
