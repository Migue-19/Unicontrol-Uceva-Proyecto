import 'dart:convert';
import 'dart:typed_data';
import 'package:webcrypto/webcrypto.dart';

class UniControlRsa {
  UniControlRsa._();

  static RsaOaepPublicKey?  _publicKey;
  static RsaOaepPrivateKey? _privateKey;

  static bool get isReady => _publicKey != null && _privateKey != null;

  static Future<void> initSessionKeys() async {
    final pair = await RsaOaepPrivateKey.generateKey(
      2048,
      BigInt.from(65537),
      Hash.sha256,
    );
    _publicKey  = pair.publicKey;
    _privateKey = pair.privateKey;
    printDiagnosticTable();
  }

  static Future<String> encryptField(String value) async {
    if (_publicKey == null || value.isEmpty) return value;
    final input  = Uint8List.fromList(utf8.encode(value));
    final output = await _publicKey!.encryptBytes(input);
    return base64.encode(output);
  }

  static Future<String> decryptField(String value) async {
    if (_privateKey == null || value.isEmpty) return value;
    try {
      final input  = base64.decode(value);
      final output = await _privateKey!.decryptBytes(input);
      return utf8.decode(output);
    } catch (_) {
      return value;
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
    p('  [RSA] RSA-OAEP-SHA256 - UniControl');
    p(sep);
    p('  ${'Estado claves'.padRight(22)} |  ${isReady ? '[OK] Listas' : '[!!] No inicializadas'}');
    p('  ${'Algoritmo'.padRight(22)} |  RSA-OAEP-SHA256 / 2048 bits');
    p('  ${'Plataforma'.padRight(22)} |  Web Crypto API / BoringSSL');
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