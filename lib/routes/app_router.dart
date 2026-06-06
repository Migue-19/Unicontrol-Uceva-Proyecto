import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unicontrol_app/services/auth_service.dart';
import 'package:unicontrol_app/views/admin/estudiantes_screen.dart';
import 'package:unicontrol_app/views/admin/mensajes_admin_screen.dart';
import 'package:unicontrol_app/views/admin/solicitudes_screen.dart';
import 'package:unicontrol_app/views/auth/complete_google_registration_screen.dart';
import 'package:unicontrol_app/views/auth/login_screen.dart';
import 'package:unicontrol_app/views/auth/register_screen.dart';
import 'package:unicontrol_app/views/cancel_subjects/cancel_subjects_screen.dart';
import 'package:unicontrol_app/views/catalog/catalog_screen.dart';
import 'package:unicontrol_app/views/dashboard/dashboard_screen.dart';
import 'package:unicontrol_app/views/messages/messages_screen.dart';
import 'package:unicontrol_app/views/my_subjects/my_subjects_screen.dart';
import 'package:unicontrol_app/views/profile/profile_screen.dart';
import 'package:unicontrol_app/views/admin/admin_dashboard_screen.dart';
import 'package:unicontrol_app/views/admin/admin_perfil_screen.dart';
import 'package:unicontrol_app/views/admin/estudiante_detalle_screen.dart';

class AppRouter {
  AppRouter({required this.authService});

  final AuthService authService;

  late final GoRouter router = GoRouter(
    refreshListenable: authService,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final loggedIn = authService.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isCompletingGoogle = location == '/complete-google-registration';
      final needsGoogleCompletion = authService.pendingGoogleProfile != null;

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && needsGoogleCompletion && !isCompletingGoogle) {
        return '/complete-google-registration';
      }
      if (loggedIn && isAuthRoute) {
        return authService.isAdmin ? '/admin/dashboard' : '/dashboard';
      }
      if (loggedIn && location.startsWith('/admin') && !authService.isAdmin) {
        return '/dashboard';
      }
      if (loggedIn && authService.isAdmin && ['/dashboard', '/catalog', '/my-subjects', '/cancel-subjects', '/messages', '/profile'].contains(location)) {
        return '/admin/dashboard';
      }
      return null;
    },
    routes: [
      _build('/login', (_) => const LoginScreen()),
      _build('/register', (_) => const RegisterScreen()),
      _build('/complete-google-registration',
          (_) => const CompleteGoogleRegistrationScreen()),
      _build('/dashboard', (_) => const DashboardScreen()),
      _build('/catalog', (_) => const CatalogScreen()),
      _build('/my-subjects', (_) => const MySubjectsScreen()),
      _build('/cancel-subjects', (_) => const CancelSubjectsScreen()),
      _build('/messages', (_) => const MessagesScreen()),
      _build('/profile', (_) => const ProfileScreen()),
      _build('/admin/dashboard', (_) => const AdminDashboardScreen()),
      _build('/admin/solicitudes', (_) => const SolicitudesScreen()),
      _build('/admin/estudiantes', (_) => const EstudiantesScreen()),
      GoRoute(
        path: '/admin/estudiantes/:id',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          child: EstudianteDetalleScreen(estudianteId: state.pathParameters['id']!),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      _build('/admin/mensajes', (_) => const MensajesAdminScreen()),
      _build('/admin/perfil', (_) => const AdminPerfilScreen()),
    ],
  );

  static GoRoute _build(String path, Widget Function(BuildContext) builder) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        transitionDuration: const Duration(milliseconds: 300),
        child: builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}