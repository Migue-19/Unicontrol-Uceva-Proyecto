import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:webcrypto/webcrypto.dart';

class UniControlMessaging {
  UniControlMessaging._();

  static AesGcmSecretKey? _sessionKey;
  static String?          _boundUserId;

  static bool get hasSession => _sessionKey != null;

  static Future<void> initSessionKey({required String userId}) async {
    _sessionKey  = await _deriveKeyForUser(userId);
    _boundUserId = userId;
    printDiagnosticTable();
  }

  static void clearSession() {
    _sessionKey  = null;
    _boundUserId = null;
  }

  static Future<AesGcmSecretKey> _deriveKeyForUser(String userId) async {
    const salt = 'unicontrol-aes-v1';
    final material = utf8.encode('$salt:$userId');
    final keyBytes = Uint8List.fromList(sha256.convert(material).bytes);
    return AesGcmSecretKey.importRawKey(keyBytes);
  }

  static Future<String> encryptForUser({
    required String plainText,
    required String receptorId,
  }) async {
    if (plainText.isEmpty) return plainText;
    final key = await _deriveKeyForUser(receptorId);
    return _encrypt(plainText, key);
  }

  static Future<String> encryptMessage(String plainText) async {
    if (_sessionKey == null || plainText.isEmpty) return plainText;
    return _encrypt(plainText, _sessionKey!);
  }

  static Future<String> decryptMessage(String encoded) async {
    if (_sessionKey == null || encoded.isEmpty) return encoded;
    if (!_looksEncrypted(encoded)) return encoded;
    try {
      final combined   = base64.decode(encoded);
      if (combined.length < 13) return encoded;
      final iv         = combined.sublist(0, 12);
      final ciphertext = combined.sublist(12);
      final output = await _sessionKey!.decryptBytes(ciphertext, iv);
      return utf8.decode(output);
    } catch (_) {
      return encoded;
    }
  }

  static Future<String> _encrypt(String plainText, AesGcmSecretKey key) async {
    final iv = Uint8List(12);
    fillRandomBytes(iv);
    final input  = Uint8List.fromList(utf8.encode(plainText));
    final cipher = await key.encryptBytes(input, iv);
    final combined = Uint8List(12 + cipher.length)
      ..setRange(0, 12, iv)
      ..setRange(12, 12 + cipher.length, cipher);
    return base64.encode(combined);
  }

  static bool _looksEncrypted(String s) {
    try {
      return base64.decode(s).length >= 13;
    } catch (_) {
      return false;
    }
  }

  static void printDiagnosticTable({
    String? campo,
    String? valorOriginal,
    String? valorCifrado,
    String? valorDescifrado,
  }) {
    final sep = '=' * 70;
    final div = '-' * 70;
    void p(String s) => print(s); // ignore: avoid_print

    p('\n$sep');
    p('  [AES] AES-256-GCM - UniControl Messaging');
    p(sep);
    p('  ${'Estado sesion'.padRight(22)} |  ${hasSession ? '[OK] Activa' : '[!!] Sin clave'}');
    p('  ${'Usuario ligado'.padRight(22)} |  ${_boundUserId ?? '-'}');
    p('  ${'Algoritmo'.padRight(22)} |  AES-256-GCM / nonce 96 bits / tag 128 bits');
    p(div);
    if (campo != null) {
      p('  ${'Campo'.padRight(22)} |  $campo');
      p('  ${'Valor original'.padRight(22)} |  ${valorOriginal ?? '-'}');
      p('  ${'Cifrado (B64)'.padRight(22)} |  ${_trunc(valorCifrado ?? '-', 50)}');
      p('  ${'Descifrado'.padRight(22)} |  ${valorDescifrado ?? '-'}');
      p('  ${'Integridad'.padRight(22)} |  ${valorOriginal == valorDescifrado ? '[OK]' : '[FALLA]'}');
    }
    p(sep);
  }

  static String _trunc(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}...' : s;
}