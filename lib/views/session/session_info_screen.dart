import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicontrol_app/services/jwt_auth_service.dart';
import 'package:unicontrol_app/services/storage_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';

class SessionInfoScreen extends StatefulWidget {
  const SessionInfoScreen({super.key});

  @override
  State<SessionInfoScreen> createState() => _SessionInfoScreenState();
}

class _SessionInfoScreenState extends State<SessionInfoScreen> {
  bool _loadingData = true;
  Map<String, String?> _prefs = {};
  bool _hasToken = false;
  bool _hasRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStorageData();
    });
  }

  Future<void> _loadStorageData() async {
    if (!mounted) return;
    setState(() => _loadingData = true);
    final storage = StorageService.instance;
    final info = await storage.getAllUserInfo();
    final token = await storage.getAccessToken();
    final refresh = await storage.getRefreshToken();
    if (!mounted) return;
    setState(() {
      _prefs = info;
      _hasToken = token != null && token.isNotEmpty;
      _hasRefresh = refresh != null && refresh.isNotEmpty;
      _loadingData = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content:
            const Text('¿Deseas eliminar todos los datos locales y salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.destructive),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<JwtAuthService>().logout();
    // El router redirige automáticamente al detectar unauthenticated
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ELIMINADO: el bloque que redirigía a /login cuando status == unauthenticated.
    // /session-info es accesible siempre (el router lo permite explícitamente),
    // así que no debe haber ninguna redirección aquí dentro.

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/login'),
        ),
        title: const Text('Almacenamiento Local'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadStorageData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStorageData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SectionHeader(
                    icon: Icons.info_outline_rounded,
                    title: 'Vista de Evidencia',
                    subtitle:
                        'Datos leídos en tiempo real del almacenamiento local del dispositivo.',
                  ),
                  const SizedBox(height: 20),

                  // ── SharedPreferences ────────────────────────────────
                  _CardSection(
                    title: 'SharedPreferences',
                    subtitle: 'Datos NO sensibles',
                    iconColor: const Color(0xFF2563EB),
                    icon: Icons.storage_outlined,
                    child: Column(
                      children: [
                        _StorageRow(
                          label: 'Nombre',
                          value: _prefs['nombre'],
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _StorageRow(
                          label: 'Email',
                          value: _prefs['email'],
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 12),
                        _StorageRow(
                          label: 'Programa',
                          value: _prefs['programaNombre'],
                          icon: Icons.school_outlined,
                        ),
                        const SizedBox(height: 12),
                        _StorageRow(
                          label: 'Semestre',
                          value: _prefs['semestreActual'],
                          icon: Icons.timeline_outlined,
                        ),
                        const SizedBox(height: 12),
                        _StorageRow(
                          label: 'Tema',
                          value: _prefs['tema'],
                          icon: Icons.palette_outlined,
                        ),
                        const SizedBox(height: 12),
                        _StorageRow(
                          label: 'Idioma',
                          value: _prefs['idioma'],
                          icon: Icons.language_outlined,
                        ),
                        const SizedBox(height: 12),
                        _StorageRow(
                          label: 'Rol',
                          value: _prefs['role'],
                          icon: Icons.verified_user_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── FlutterSecureStorage / SharedPreferences web ─────
                  _CardSection(
                    title: kIsWeb
                        ? 'SharedPreferences (web)'
                        : 'FlutterSecureStorage',
                    subtitle: kIsWeb
                        ? 'Tokens en localStorage (entorno web)'
                        : 'Datos SENSIBLES (cifrados en Keychain/Keystore)',
                    iconColor: AppTheme.primary,
                    icon: Icons.lock_outline_rounded,
                    child: Column(
                      children: [
                        _TokenRow(
                          label: 'access_token',
                          present: _hasToken,
                        ),
                        const SizedBox(height: 12),
                        _TokenRow(
                          label: 'refresh_token',
                          present: _hasRefresh,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Estado de sesión ─────────────────────────────────
                  _SessionStatusCard(hasToken: _hasToken, prefs: _prefs),
                  const SizedBox(height: 28),

                  // ── Botón cerrar sesión (solo si hay sesión activa) ──
                  if (_hasToken)
                    _LogoutButton(onTap: () => _logout(context)),

                  // ── Botón volver al login (si no hay sesión) ─────────
                  if (!_hasToken)
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Volver al inicio de sesión'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedForeground)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppTheme.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.mutedForeground)),
              const SizedBox(height: 2),
              Text(
                hasValue ? value! : '— sin datos —',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasValue
                          ? AppTheme.foreground
                          : AppTheme.mutedForeground,
                      fontStyle:
                          hasValue ? FontStyle.normal : FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: hasValue
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            hasValue ? 'OK' : 'vacío',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: hasValue
                      ? AppTheme.success
                      : AppTheme.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.label, required this.present});
  final String label;
  final bool present;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          present ? Icons.lock_rounded : Icons.lock_open_rounded,
          size: 18,
          color: present ? AppTheme.primary : AppTheme.mutedForeground,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.mutedForeground)),
              const SizedBox(height: 2),
              Text(
                present
                    ? '••••••••••••  (cifrado en dispositivo)'
                    : '— sin token —',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: present
                          ? AppTheme.foreground
                          : AppTheme.mutedForeground,
                      fontStyle:
                          present ? FontStyle.normal : FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: present
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.destructive.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            present ? 'presente' : 'ausente',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: present ? AppTheme.success : AppTheme.destructive,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _SessionStatusCard extends StatelessWidget {
  const _SessionStatusCard(
      {required this.hasToken, required this.prefs});
  final bool hasToken;
  final Map<String, String?> prefs;

  @override
  Widget build(BuildContext context) {
    final hasUserData =
        prefs['email'] != null && prefs['email']!.isNotEmpty;
    final isSessionActive = hasToken && hasUserData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSessionActive
            ? AppTheme.success.withValues(alpha: 0.06)
            : AppTheme.destructive.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSessionActive
              ? AppTheme.success.withValues(alpha: 0.25)
              : AppTheme.destructive.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSessionActive
                ? Icons.verified_rounded
                : Icons.cancel_rounded,
            color: isSessionActive
                ? AppTheme.success
                : AppTheme.destructive,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSessionActive ? 'Sesión activa' : 'Sin sesión activa',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSessionActive
                            ? AppTheme.success
                            : AppTheme.destructive,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSessionActive
                      ? 'Token presente · Datos de usuario cargados'
                      : 'No hay token almacenado en este dispositivo',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.destructive,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}