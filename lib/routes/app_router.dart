import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/services/jwt_auth_service.dart';
import 'package:unicontrol_app/views/admin/estudiantes_screen.dart';
import 'package:unicontrol_app/views/admin/mensajes_admin_screen.dart';
import 'package:unicontrol_app/views/admin/solicitudes_screen.dart';
import 'package:unicontrol_app/views/auth/complete_google_registration_screen.dart';
import 'package:unicontrol_app/views/auth/jwt_login_screen.dart';
import 'package:unicontrol_app/views/auth/register_screen.dart';
import 'package:unicontrol_app/views/cancel_subjects/cancel_subjects_screen.dart';
import 'package:unicontrol_app/views/catalog/catalog_screen.dart';
import 'package:unicontrol_app/views/dashboard/dashboard_screen.dart';
import 'package:unicontrol_app/views/messages/messages_screen.dart';
import 'package:unicontrol_app/views/my_subjects/my_subjects_screen.dart';
import 'package:unicontrol_app/views/profile/profile_screen.dart';
import 'package:unicontrol_app/views/session/session_info_screen.dart';

class AppRouter {
  AppRouter({
    required this.authService,
    required this.jwtAuthService,
  });

  final AuthService authService;
  final JwtAuthService jwtAuthService;

  late final GoRouter router = GoRouter(
    refreshListenable: Listenable.merge([authService, jwtAuthService]),
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // /session-info siempre accesible
      if (location == '/session-info') return null;

      // Mientras JwtAuthService restaura sesión, no redirigir
      if (jwtAuthService.state.status == AuthStatus.initial ||
          jwtAuthService.state.status == AuthStatus.loading) {
        return null;
      }

      final loggedIn =
          authService.isAuthenticated || jwtAuthService.isAuthenticated;
      final isAuthRoute = location == '/login' || location == '/register';
      final isCompletingGoogle =
          location == '/complete-google-registration';
      final needsGoogleCompletion = authService.pendingGoogleProfile != null;

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && needsGoogleCompletion && !isCompletingGoogle) {
        return '/complete-google-registration';
      }
      if (loggedIn && isAuthRoute) return '/dashboard';
      if (loggedIn &&
          location.startsWith('/admin') &&
          !authService.isAdmin) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      _build('/login', (_) => const JwtLoginScreen()),
      _build('/register', (_) => const RegisterScreen()),
      _build('/complete-google-registration',
          (_) => const CompleteGoogleRegistrationScreen()),
      _build('/session-info', (_) => const SessionInfoScreen()),
      _build('/dashboard', (_) => const DashboardScreen()),
      _build('/catalog', (_) => const CatalogScreen()),
      _build('/my-subjects', (_) => const MySubjectsScreen()),
      _build('/cancel-subjects', (_) => const CancelSubjectsScreen()),
      _build('/messages', (_) => const MessagesScreen()),
      _build('/profile', (_) => const ProfileScreen()),
      _build('/admin/solicitudes', (_) => const SolicitudesScreen()),
      _build('/admin/estudiantes', (_) => const EstudiantesScreen()),
      _build('/admin/mensajes', (_) => const MensajesAdminScreen()),
    ],
  );

  static GoRoute _build(
      String path, Widget Function(BuildContext) builder) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 300),
        child: builder(context),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}