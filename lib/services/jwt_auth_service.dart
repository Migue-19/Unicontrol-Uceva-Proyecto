import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:unicontrol_app/models/jwt_user_model.dart';
import 'package:unicontrol_app/services/storage_service.dart';
import 'package:unicontrol_app/services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final JwtUserModel? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    JwtUserModel? user,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class JwtAuthService extends ChangeNotifier {
  JwtAuthService() {
    _restoreSession();
  }

  static String get _baseUrl => SupabaseService.supabaseUrl;
  static String get _anonKey => SupabaseService.supabaseAnonKey;
  static const Duration _timeout = Duration(seconds: 15);

  final StorageService _storage = StorageService.instance;

  AuthState _state = const AuthState(status: AuthStatus.initial);
  AuthState get state => _state;

  JwtUserModel? get user => _state.user;
  bool get isAuthenticated => _state.isAuthenticated;

  // ── Restaurar sesión ──────────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    _emit(_state.copyWith(status: AuthStatus.loading));
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        _emit(_state.copyWith(status: AuthStatus.unauthenticated, user: null));
        return;
      }

      final verifyRes = await http
          .get(
            Uri.parse('$_baseUrl/auth/v1/user'),
            headers: {
              'apikey': _anonKey,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      debugPrint('[RESTORE] verify status: ${verifyRes.statusCode}');

      if (verifyRes.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (!refreshed) {
          await _storage.clearAll();
          _emit(_state.copyWith(status: AuthStatus.unauthenticated, user: null));
          return;
        }
      } else if (verifyRes.statusCode != 200) {
        await _storage.clearAll();
        _emit(_state.copyWith(status: AuthStatus.unauthenticated, user: null));
        return;
      }

      final info = await _storage.getAllUserInfo();
      if (info['email'] == null) {
        _emit(_state.copyWith(status: AuthStatus.unauthenticated, user: null));
        return;
      }

      final restoredUser = JwtUserModel(
        nombre: info['nombre'] ?? 'Usuario',
        email: info['email']!,
        role: info['role'] ?? 'estudiante',
        tema: info['tema'] ?? 'light',
        idioma: info['idioma'] ?? 'es',
        programaNombre: info['programaNombre'],
        facultadNombre: info['facultadNombre'],
        codigoEstudiantil: info['codigoEstudiantil'],
        semestreActual: int.tryParse(info['semestreActual'] ?? ''),
      );
      _emit(_state.copyWith(
        status: AuthStatus.authenticated,
        user: restoredUser,
      ));
    } catch (e) {
      debugPrint('[JwtAuthService] _restoreSession error: $e');
      _emit(_state.copyWith(status: AuthStatus.unauthenticated, user: null));
    }
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      debugPrint('[RESTORE] intentando refresh_token...');

      final res = await http
          .post(
            Uri.parse('$_baseUrl/auth/v1/token?grant_type=refresh_token'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': _anonKey,
            },
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(_timeout);

      debugPrint('[RESTORE] refresh status: ${res.statusCode}');

      if (res.statusCode != 200) return false;

      final body = _parseBody(res);
      final newAccess = body['access_token'] as String?;
      final newRefresh = body['refresh_token'] as String?;

      if (newAccess == null) return false;

      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      debugPrint('[RESTORE] token renovado exitosamente');
      return true;
    } catch (e) {
      debugPrint('[RESTORE] _tryRefreshToken error: $e');
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<String?> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y contraseña.';
    }
    if (!email.toLowerCase().endsWith('@uceva.edu.co')) {
      return 'El correo debe ser institucional @uceva.edu.co';
    }

    _emit(_state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      // ── 1. Login HTTP ──────────────────────────────────────────────────
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': _anonKey,
            },
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(_timeout);

      debugPrint('[LOGIN] status: ${response.statusCode}');

      final body = _parseBody(response);

      if (response.statusCode != 200) {
        final serverMsg = body['error_description'] as String? ??
            body['msg'] as String? ??
            body['message'] as String?;
        return _emitError(serverMsg ?? 'Credenciales inválidas.');
      }

      final accessToken = body['access_token'] as String?;
      final refreshToken = body['refresh_token'] as String?;

      if (accessToken == null) {
        return _emitError('El servidor no devolvió un token válido.');
      }

      final userId =
          (body['user'] as Map<String, dynamic>?)?['id'] as String?;

      // ── 2. Consultar perfil desde tabla usuarios ───────────────────────
      String nombre = email.split('@').first;
      String role = 'estudiante';
      String? programaNombre;
      String? facultadNombre;
      String? codigoEstudiantil;
      int? semestreActual;

      if (userId != null) {
        try {
          final perfilRes = await http
              .get(
                Uri.parse(
                  '$_baseUrl/rest/v1/usuarios'
                  '?id=eq.$userId'
                  '&select=nombre,codigo_estudiantil,semestre_actual,programas(nombre,facultades(nombre))',
                ),
                headers: {
                  'apikey': _anonKey,
                  'Authorization': 'Bearer $accessToken',
                },
              )
              .timeout(_timeout);

          debugPrint('[PERFIL] status: ${perfilRes.statusCode}');
          debugPrint('[PERFIL] body: ${perfilRes.body}');

          if (perfilRes.statusCode == 200) {
            final lista = jsonDecode(perfilRes.body) as List<dynamic>;
            if (lista.isNotEmpty) {
              final p = lista.first as Map<String, dynamic>;
              nombre = p['nombre'] as String? ?? nombre;
              codigoEstudiantil = p['codigo_estudiantil'] as String?;
              semestreActual = p['semestre_actual'] != null
                  ? (p['semestre_actual'] as num).toInt()
                  : null;
              final programa = p['programas'] as Map<String, dynamic>?;
              programaNombre = programa?['nombre'] as String?;
              final facultad = programa?['facultades'] as Map<String, dynamic>?;
              facultadNombre = facultad?['nombre'] as String?;
            }
          }

          final rolRes = await http
              .get(
                Uri.parse(
                    '$_baseUrl/rest/v1/user_roles?user_id=eq.$userId&select=role'),
                headers: {
                  'apikey': _anonKey,
                  'Authorization': 'Bearer $accessToken',
                },
              )
              .timeout(_timeout);

          debugPrint('[ROL] status: ${rolRes.statusCode}');
          debugPrint('[ROL] body: ${rolRes.body}');

          if (rolRes.statusCode == 200) {
            final listaRol = jsonDecode(rolRes.body) as List<dynamic>;
            if (listaRol.isNotEmpty) {
              role = listaRol.first['role'] as String? ?? role;
            }
          }
        } catch (e) {
          debugPrint('[LOGIN] Error consultando perfil: $e');
        }
      }

      // ── 3. Guardar en storage ──────────────────────────────────────────
      final jwtUser = JwtUserModel(
        nombre: nombre,
        email: email.trim(),
        role: role,
        tema: 'light',
        idioma: 'es',
        programaNombre: programaNombre,
        facultadNombre: facultadNombre,
        codigoEstudiantil: codigoEstudiantil,
        semestreActual: semestreActual,
      );

      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _storage.saveUserInfo(
        nombre: jwtUser.nombre,
        email: jwtUser.email,
        tema: jwtUser.tema,
        idioma: jwtUser.idioma,
        role: jwtUser.role,
        programaNombre: jwtUser.programaNombre ?? '',
        facultadNombre: jwtUser.facultadNombre ?? '',
        codigoEstudiantil: jwtUser.codigoEstudiantil ?? '',
        semestreActual: jwtUser.semestreActual?.toString() ?? '',
      );

      _emit(_state.copyWith(
        status: AuthStatus.authenticated,
        user: jwtUser,
        errorMessage: null,
      ));
      return null;
    } catch (e) {
      debugPrint('[JwtAuthService] login error: $e');
      return _emitError('Error inesperado. Intenta nuevamente.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final token = await _storage.getAccessToken();

    await _storage.clearAll();
    _emit(const AuthState(status: AuthStatus.unauthenticated));

    if (token != null && token.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('$_baseUrl/auth/v1/logout'),
              headers: {
                'Content-Type': 'application/json',
                'apikey': _anonKey,
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _parseBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  String _emitError(String message) {
    _emit(_state.copyWith(
      status: AuthStatus.error,
      errorMessage: message,
      user: null,
    ));
    return message;
  }

  void _emit(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}