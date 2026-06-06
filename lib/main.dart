import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/routes/app_router.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/notification_service.dart';
import 'package:unicontrol_app/services/firma_service.dart';
import 'package:unicontrol_app/services/rsa_service.dart';
import 'package:unicontrol_app/services/supabase_service.dart';
import 'package:unicontrol_app/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseAnonKey,
  );

  await FirmaService().initialize();

  await UniControlRsa.initSessionKeys();
  _printEncryptionBanner();
  runApp(const UniControlApp());
}

void _printEncryptionBanner() {
  final sep = '=' * 70;
  final div = '-' * 70;
  // ignore: avoid_print
  void p(String s) => print(s);
  p('\n$sep');
  p('  UniControl -- Sistema de Cifrado Inicializado');
  p(sep);
  p('  ${'Modulo'.padRight(22)} |  ${'Estado'.padRight(20)} |  Algoritmo');
  p('  ${div.substring(0, 22)} |  ${div.substring(0, 20)} |  ${div.substring(0, 20)}');
  p('  ${'RSA (datos usuario)'.padRight(22)} |  ${'[OK] Listo'.padRight(20)} |  RSA-OAEP-SHA256 / 2048b');
  p('  ${'AES (mensajeria)'.padRight(22)} |  ${'[...] Espera login'.padRight(20)} |  AES-256-GCM');
  p(sep);
  p('  Cifrado activo en: nombre, codigo estudiantil, asunto, mensaje');
  p('$sep\n');
}

class UniControlApp extends StatefulWidget {
  const UniControlApp({super.key});

  @override
  State<UniControlApp> createState() => _UniControlAppState();
}

class _UniControlAppState extends State<UniControlApp> {
  late final AuthService _authService;
  late final NotificationService _notifService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _notifService = NotificationService();
    _router = AppRouter(authService: _authService).router;

    // ── CORRECCIÓN: escuchar cambios de auth UNA SOLA VEZ aquí,
    //   NO dentro del Consumer/builder (que se llama en cada rebuild).
    _authService.addListener(_onAuthChanged);
    // Aplicar el estado inicial
    _onAuthChanged();
  }

  void _onAuthChanged() {
    final userId = _authService.user?.id;
    if (userId != null) {
      if (_authService.isAdmin) {
        _notifService.listenForNewSolicitudes();
      } else {
        _notifService.listenForNewMessages(userId);
      }
    } else {
      _notifService.stopListening();
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    _notifService.dispose();
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<NotificationService>.value(value: _notifService),
      ],
      child: Consumer<NotificationService>(
        builder: (context, notifService, _) {
          return MaterialApp.router(
            title: 'UniControl UCEVA',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            builder: (context, child) => _NotificationOverlay(
              authService: _authService,
              notifService: notifService,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}

/// Escucha el NotificationService y muestra un SnackBar cuando llegan
/// nuevos mensajes (estudiante) o solicitudes (admin).
class _NotificationOverlay extends StatefulWidget {
  const _NotificationOverlay({
    required this.authService,
    required this.notifService,
    required this.child,
  });

  final AuthService authService;
  final NotificationService notifService;
  final Widget child;

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay> {
  Map<String, dynamic>? _lastShownMessage;
  int _lastShownSolicitudesCount = 0;

  @override
  void didUpdateWidget(covariant _NotificationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndShowNotification();
  }

  void _checkAndShowNotification() {
    final notifService = widget.notifService;
    final isAdmin = widget.authService.isAdmin;

    if (!isAdmin) {
      final msg = notifService.lastUnreadMessage;
      if (msg != null && msg != _lastShownMessage) {
        _lastShownMessage = msg;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 5),
              content: const Row(
                children: [
                  Icon(Icons.mail_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tienes una respuesta de tu coordinador sobre tu solicitud.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      }
    } else {
      final count = notifService.newSolicitudesCount;
      if (count > _lastShownSolicitudesCount && _lastShownSolicitudesCount > 0) {
        _lastShownSolicitudesCount = count;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              backgroundColor: const Color(0xFF2563EB),
              duration: const Duration(seconds: 5),
              content: Row(
                children: [
                  const Icon(Icons.assignment_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Nueva solicitud pendiente. Total: $count.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        });
      } else {
        _lastShownSolicitudesCount = count;
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}