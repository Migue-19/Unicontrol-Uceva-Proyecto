import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/constants/academic_options.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _semestreController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedFaculty;
  String? _selectedCareer;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codigoController.dispose();
    _semestreController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final error = await context.read<AuthService>().register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          codigoEstudiantil: _codigoController.text.trim(),
          carreraId: _selectedCareer,
          semestre: int.tryParse(_semestreController.text.trim()),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
      return;
    }
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final careers = AcademicOptions.programsForFaculty(_selectedFaculty);
    return BaseView(
      title: 'Registro',
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
                  const SizedBox(height: 8),
                  const StaggeredEntrance(
                      index: 0, child: Center(child: UcevaLogoHero())),
                  const SizedBox(height: 20),
                  StaggeredEntrance(
                    index: 1,
                    child: Column(children: [
                      Text('Crea tu cuenta UCEVA',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(
                        'Registrate con tus datos academicos y deja lista tu experiencia en UniControl.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  StaggeredEntrance(
                    index: 2,
                    child: AppCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa tu nombre'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Correo institucional',
                                prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Ingresa tu correo';
                              if (!v.toLowerCase().trim().endsWith('@uceva.edu.co'))
                                return 'El correo debe terminar en @uceva.edu.co';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _codigoController,
                            decoration: const InputDecoration(
                                labelText: 'Código estudiantil',
                                prefixIcon: Icon(Icons.badge_outlined)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa tu código estudiantil'
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
                                return 'Ingresa un semestre entre 1 y 12';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa una contraseña';
                              if (v.length < 6)
                                return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon:
                                  const Icon(Icons.verified_user_outlined),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(_obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Confirma tu contraseña';
                              if (v != _passwordController.text)
                                return 'Las contraseñas no coinciden';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            label: 'Crear cuenta',
                            onTap: _register,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Ya tengo cuenta'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
