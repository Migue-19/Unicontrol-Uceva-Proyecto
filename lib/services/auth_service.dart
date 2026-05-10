import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicontrol_app/models/usuario_model.dart';
import 'package:unicontrol_app/services/supabase_service.dart';

enum AuthFlowStatus {
  success,
  requiresProfileCompletion,
  cancelled,
  error,
}

class AuthFlowResult {
  final AuthFlowStatus status;
  final String? message;

  const AuthFlowResult._(this.status, [this.message]);
  const AuthFlowResult.success() : this._(AuthFlowStatus.success);
  const AuthFlowResult.requiresProfileCompletion()
      : this._(AuthFlowStatus.requiresProfileCompletion);
  const AuthFlowResult.cancelled() : this._(AuthFlowStatus.cancelled);
  const AuthFlowResult.error(String message)
      : this._(AuthFlowStatus.error, message);
}

class AuthService extends ChangeNotifier {
  AuthService() {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      user = data.session?.user;
      await _loadProfile(silent: true);
      notifyListeners();
    });
    _loadSession();
  }

  final SupabaseClient _client = SupabaseService.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: kIsWeb ? null : SupabaseService.googleWebClientId,
    clientId: kIsWeb ? SupabaseService.googleWebClientId : null,
  );

  User? user;
  String? role;
  UsuarioModel? profile;
  UsuarioModel? _pendingGoogleProfile;
  late final StreamSubscription<AuthState> _authSubscription;

  bool get isAuthenticated => user != null;
  bool get isAdmin => role == 'admin';
  bool get hasCompletedProfile =>
      profile?.codigoEstudiantil?.isNotEmpty == true &&
      profile?.programaId?.isNotEmpty == true &&
      profile?.semestreActual != null;
  UsuarioModel? get pendingGoogleProfile => _pendingGoogleProfile;

  Future<void> _loadSession() async {
    user = _client.auth.currentUser;
    await _loadProfile(silent: true);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    await _loadProfile(silent: true);
    notifyListeners();
  }

  Future<void> _loadProfile({bool silent = false}) async {
    if (user == null) {
      role = null;
      profile = null;
      _pendingGoogleProfile = null;
      return;
    }
    try {
      final userById = await _client
          .from('usuarios')
          .select('*, programas(nombre, facultades(nombre))')
          .eq('id', user!.id)
          .maybeSingle();

      if (userById != null) {
        profile = UsuarioModel.fromJson(userById);
      } else if (user!.email != null) {
        final userByEmail = await _client
            .from('usuarios')
            .select('*, programas(nombre, facultades(nombre))')
            .eq('email', user!.email!)
            .maybeSingle();
        profile = userByEmail != null
            ? UsuarioModel.fromJson(
                {...userByEmail, 'id': userByEmail['id'] ?? user!.id})
            : null;
      } else {
        profile = null;
      }

      final roleResponse = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user!.id)
          .maybeSingle();
      role = roleResponse?['role'] as String? ?? 'estudiante';
    } catch (e) {
      debugPrint('[AuthService] _loadProfile error: $e');
      if (!silent) rethrow;
      role ??= 'estudiante';
    }
  }

  Future<String?> _resolverProgramaId(String nombre) async {
    try {
      final result = await _client
          .from('programas')
          .select('id')
          .eq('nombre', nombre)
          .maybeSingle();
      return result?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  Future<String?> login(String email, String password) async {
    try {
      if (!email.toLowerCase().endsWith('@uceva.edu.co')) {
        return 'El correo debe ser institucional @uceva.edu.co';
      }
      final response = await _client.auth
          .signInWithPassword(email: email, password: password);
      user = response.user;
      await _loadProfile(silent: true);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error al iniciar sesion';
    }
  }

  Future<String?> register(
    String email,
    String password,
    String nombre, {
    String? codigoEstudiantil,
    String? carreraId,
    int? semestre,
  }) async {
    try {
      if (!email.toLowerCase().endsWith('@uceva.edu.co')) {
        return 'El correo debe ser institucional @uceva.edu.co';
      }
      if (nombre.isEmpty) return 'El nombre es requerido';

      String? programaId = carreraId;
      if (carreraId != null && !_looksLikeUuid(carreraId)) {
        programaId = await _resolverProgramaId(carreraId);
      }

      final response =
          await _client.auth.signUp(email: email, password: password);
      user = response.user;

      if (user != null) {
        await _client.from('usuarios').upsert({
          'id': user!.id,
          'nombre': nombre,
          'codigo_estudiantil': codigoEstudiantil,
          'programa_id': programaId,
          'semestre_actual': semestre ?? 1,
        });
        await _client.from('user_roles').upsert({
          'user_id': user!.id,
          'role': 'estudiante',
        });
      }

      await _loadProfile(silent: true);
      notifyListeners();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error al registrar usuario';
    }
  }

  Future<AuthFlowResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.toString(),
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
        return const AuthFlowResult.success();
      }

      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return const AuthFlowResult.cancelled();

      final email = googleUser.email.toLowerCase();
      if (!email.endsWith('@uceva.edu.co')) {
        await _googleSignIn.signOut();
        return const AuthFlowResult.error(
            'Solo se permite acceso con correo institucional @uceva.edu.co');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        await _googleSignIn.signOut();
        return const AuthFlowResult.error(
            'No fue posible obtener las credenciales de Google.');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      user = response.user;
      if (user == null) {
        await _googleSignIn.signOut();
        return const AuthFlowResult.error(
            'No fue posible completar el acceso con Google.');
      }

      final existingUser = await _client
          .from('usuarios')
          .select('*, programas(nombre, facultades(nombre))')
          .or('id.eq.${user!.id},email.eq.$email')
          .maybeSingle();

      if (existingUser != null) {
        profile = UsuarioModel.fromJson(existingUser);
        await _ensureBaseRole();
        await _loadProfile(silent: true);
        _pendingGoogleProfile = null;
        notifyListeners();
        return const AuthFlowResult.success();
      }

      _pendingGoogleProfile = UsuarioModel(
        id: user!.id,
        email: email,
        nombre: googleUser.displayName?.trim().isNotEmpty == true
            ? googleUser.displayName!.trim()
            : email.split('@').first,
      );
      await _ensureBaseRole();
      notifyListeners();
      return const AuthFlowResult.requiresProfileCompletion();
    } on AuthException catch (e) {
      await _googleSignIn.signOut();
      return AuthFlowResult.error(e.message);
    } catch (_) {
      await _googleSignIn.signOut();
      return const AuthFlowResult.error(
          'Error al continuar con Google. Intenta nuevamente.');
    }
  }

  Future<String?> completeGoogleRegistration({
    required String codigoEstudiantil,
    required String carreraId,
    required int semestre,
  }) async {
    try {
      final currentUser = user;
      final pendingProfile = _pendingGoogleProfile;
      if (currentUser == null || pendingProfile == null) {
        return 'No hay un registro pendiente para completar.';
      }

      String? programaId = carreraId;
      if (!_looksLikeUuid(carreraId)) {
        programaId = await _resolverProgramaId(carreraId);
      }

      await _client.from('usuarios').upsert({
        'id': currentUser.id,
        'nombre': pendingProfile.nombre,
        'codigo_estudiantil': codigoEstudiantil,
        'programa_id': programaId,
        'semestre_actual': semestre,
      });

      await _ensureBaseRole();
      _pendingGoogleProfile = null;
      await _loadProfile(silent: true);
      notifyListeners();
      return null;
    } catch (_) {
      return 'No fue posible completar el registro institucional.';
    }
  }

  Future<void> _ensureBaseRole() async {
    if (user == null) return;
    final existing = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', user!.id)
        .maybeSingle();
    if (existing == null) {
      await _client
          .from('user_roles')
          .insert({'user_id': user!.id, 'role': 'estudiante'});
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _client.auth.signOut();
    } catch (_) {}
    user = null;
    role = null;
    profile = null;
    _pendingGoogleProfile = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}