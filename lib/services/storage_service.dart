import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String _kNombre = 'user_nombre';
  static const String _kEmail = 'user_email';
  static const String _kTema = 'user_tema';
  static const String _kIdioma = 'user_idioma';
  static const String _kRole = 'user_role';
  static const String _kProgramaNombre = 'user_programa_nombre';
  static const String _kFacultadNombre = 'user_facultad_nombre';
  static const String _kCodigoEstudiantil = 'user_codigo_estudiantil';
  static const String _kSemestreActual = 'user_semestre_actual';
  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';

  FlutterSecureStorage? get _secure => kIsWeb
      ? null
      : const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── SharedPreferences — datos no sensibles ────────────────────────────

  Future<void> saveUserInfo({
    required String nombre,
    required String email,
    String tema = 'light',
    String idioma = 'es',
    String role = 'estudiante',
    String programaNombre = '',
    String facultadNombre = '',
    String codigoEstudiantil = '',
    String semestreActual = '',
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_kNombre, nombre);
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kTema, tema);
    await prefs.setString(_kIdioma, idioma);
    await prefs.setString(_kRole, role);
    await prefs.setString(_kProgramaNombre, programaNombre);
    await prefs.setString(_kFacultadNombre, facultadNombre);
    await prefs.setString(_kCodigoEstudiantil, codigoEstudiantil);
    await prefs.setString(_kSemestreActual, semestreActual);
  }

  Future<String?> getNombre() async => (await _prefs).getString(_kNombre);
  Future<String?> getEmail() async => (await _prefs).getString(_kEmail);
  Future<String?> getTema() async => (await _prefs).getString(_kTema);
  Future<String?> getIdioma() async => (await _prefs).getString(_kIdioma);
  Future<String?> getRole() async => (await _prefs).getString(_kRole);
  Future<String?> getProgramaNombre() async =>
      (await _prefs).getString(_kProgramaNombre);
  Future<String?> getFacultadNombre() async =>
      (await _prefs).getString(_kFacultadNombre);
  Future<String?> getCodigoEstudiantil() async =>
      (await _prefs).getString(_kCodigoEstudiantil);
  Future<String?> getSemestreActual() async =>
      (await _prefs).getString(_kSemestreActual);

  Future<Map<String, String?>> getAllUserInfo() async {
    final prefs = await _prefs;
    return {
      'nombre': prefs.getString(_kNombre),
      'email': prefs.getString(_kEmail),
      'tema': prefs.getString(_kTema),
      'idioma': prefs.getString(_kIdioma),
      'role': prefs.getString(_kRole),
      'programaNombre': prefs.getString(_kProgramaNombre),
      'facultadNombre': prefs.getString(_kFacultadNombre),
      'codigoEstudiantil': prefs.getString(_kCodigoEstudiantil),
      'semestreActual': prefs.getString(_kSemestreActual),
    };
  }

  Future<void> clearUserInfo() async {
    final prefs = await _prefs;
    await prefs.remove(_kNombre);
    await prefs.remove(_kEmail);
    await prefs.remove(_kTema);
    await prefs.remove(_kIdioma);
    await prefs.remove(_kRole);
    await prefs.remove(_kProgramaNombre);
    await prefs.remove(_kFacultadNombre);
    await prefs.remove(_kCodigoEstudiantil);
    await prefs.remove(_kSemestreActual);
  }

  // ── Tokens ────────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.setString(_kAccessToken, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_kRefreshToken, refreshToken);
      }
    } else {
      await _secure!.write(key: _kAccessToken, value: accessToken);
      if (refreshToken != null) {
        await _secure!.write(key: _kRefreshToken, value: refreshToken);
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return (await _prefs).getString(_kAccessToken);
    return _secure!.read(key: _kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return (await _prefs).getString(_kRefreshToken);
    return _secure!.read(key: _kRefreshToken);
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.remove(_kAccessToken);
      await prefs.remove(_kRefreshToken);
    } else {
      await _secure!.delete(key: _kAccessToken);
      await _secure!.delete(key: _kRefreshToken);
    }
  }

  Future<void> clearAll() async {
    await clearUserInfo();
    await clearTokens();
  }
}