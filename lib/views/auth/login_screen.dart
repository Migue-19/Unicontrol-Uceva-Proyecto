import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';
import 'package:unicontrol_app/widgets/base_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final error = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);
    if (error != null) {
      showAppSnackBar(context, error, isError: true);
      return;
    }
    context.go(authService.isAdmin ? '/admin/solicitudes' : '/dashboard');
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final authService = context.read<AuthService>();
    final result = await authService.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _isGoogleLoading = false);

    switch (result.status) {
      case AuthFlowStatus.success:
        if (authService.pendingGoogleProfile != null) {
          context.go('/complete-google-registration');
        } else {
          context.go(authService.isAdmin ? '/admin/solicitudes' : '/dashboard');
        }
        break;
      case AuthFlowStatus.requiresProfileCompletion:
        context.go('/complete-google-registration');
        break;
      case AuthFlowStatus.cancelled:
        break;
      case AuthFlowStatus.error:
        showAppSnackBar(
          context,
          result.message ?? 'No fue posible continuar con Google.',
          isError: true,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Iniciar sesion',
      showBottomNav: false,
      useGradientBackground: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StaggeredEntrance(
                          index: 0,
                          child: Center(child: UcevaLogoHero()),
                        ),
                        const SizedBox(height: 20),
                        StaggeredEntrance(
                          index: 1,
                          child: Column(
                            children: [
                              Text(
                                'Bienvenido a UniControl',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Accede con tu correo institucional UCEVA y administra tu vida academica desde un solo lugar.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        StaggeredEntrance(
                          index: 2,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Iniciar sesion',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo institucional',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu correo institucional';
                                    }
                                    if (!value
                                        .toLowerCase()
                                        .trim()
                                        .endsWith('@uceva.edu.co')) {
                                      return 'El correo debe terminar en @uceva.edu.co';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Contrasena',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingresa tu contrasena';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                GradientButton(
                                  label: 'Ingresar',
                                  onTap: _login,
                                  isLoading: _isLoading,
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: AppTheme.mutedForeground
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'o',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: AppTheme.mutedForeground
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _GoogleButton(
                                  isLoading: _isGoogleLoading,
                                  onTap: _continueWithGoogle,
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: TextButton(
                                    onPressed: () => context.go('/register'),
                                    child: const Text(
                                      'No tienes cuenta? Registrate',
                                    ),
                                  ),
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
        },
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.onTap,
    required this.isLoading,
  });

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primary.withValues(alpha: 0.08),
          onTap: isLoading ? null : onTap,
          child: SizedBox(
            height: 56,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continuar con Google',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF374151),
                                    fontWeight: FontWeight.w700,
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
