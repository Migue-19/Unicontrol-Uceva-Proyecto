// lib/views/auth/jwt_login_screen.dart
//
// Pantalla de login JWT para UniControl.
// Muestra estados: cargando / éxito (navegación) / error (snackbar + banner).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/jwt_auth_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';
import 'package:unicontrol_app/widgets/app_ui.dart';

class JwtLoginScreen extends StatefulWidget {
  const JwtLoginScreen({super.key});

  @override
  State<JwtLoginScreen> createState() => _JwtLoginScreenState();
}

class _JwtLoginScreenState extends State<JwtLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final svc = context.read<JwtAuthService>();
    final error = await svc.login(_emailCtrl.text, _passCtrl.text);

    if (!mounted) return;

    if (error != null) {
      _showError(error);
      return;
    }

    // Éxito → navegar al dashboard
    context.go('/dashboard');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: AppTheme.destructive,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<JwtAuthService>().state;
    final isLoading = state.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.authBackgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
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
                          const SizedBox(height: 24),
                          // ── Logo / Título ──────────────────────────────
                          Icon(Icons.school_rounded,
                              size: 72, color: AppTheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'UniControl UCEVA',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Accede con tu correo institucional',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // ── Tarjeta de login ───────────────────────────
                          _LoginCard(
                            emailCtrl: _emailCtrl,
                            passCtrl: _passCtrl,
                            obscure: _obscure,
                            isLoading: isLoading,
                            onToggleObscure: () =>
                                setState(() => _obscure = !_obscure),
                            onSubmit: _submit,
                          ),

                          const SizedBox(height: 16),

                          // ── Banner de error (estado) ───────────────────
                          if (state.hasError && state.errorMessage != null)
                            _ErrorBanner(message: state.errorMessage!),

                          const SizedBox(height: 24),

                          // ── Link evidencia ─────────────────────────────
                          Center(
                            child: TextButton.icon(
                              onPressed: () => context.go('/session-info'),
                              icon: const Icon(Icons.storage_outlined,
                                  size: 16),
                              label: const Text('Ver almacenamiento local'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.mutedForeground),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Iniciar sesión',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                hintText: 'ejemplo@uceva.edu.co',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa tu correo institucional';
                }
                if (!v.trim().toLowerCase().endsWith('@uceva.edu.co')) {
                  return 'El correo debe terminar en @uceva.edu.co';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Contraseña
            TextFormField(
              controller: passCtrl,
              obscureText: obscure,
              textInputAction: TextInputAction.done,
              enabled: !isLoading,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: onToggleObscure,
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
            ),
            const SizedBox(height: 20),

            // Botón
            _SubmitButton(isLoading: isLoading, onTap: onSubmit),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onTap});
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              height: 56,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey('button'),
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onTap,
                    child: const Center(
                      child: Text(
                        'Ingresar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withValues(alpha: 0.08),
        border: Border.all(color: AppTheme.destructive.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppTheme.destructive, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
