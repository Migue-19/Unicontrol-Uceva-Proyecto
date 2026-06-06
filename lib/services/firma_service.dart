import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class FirmaService {
  static final FirmaService _instance = FirmaService._internal();
  factory FirmaService() => _instance;
  FirmaService._internal();

  Map<String, dynamic>? _refFeatures;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/firma_reference_features.json',
      );
      final decoded = jsonDecode(jsonStr);
      _refFeatures = decoded is Map<String, dynamic>
          ? decoded
          : (decoded as Map).cast<String, dynamic>();
      _isInitialized = true;
      debugPrint('FirmaService: referencia cargada desde JSON');
    } catch (e) {
      debugPrint('FirmaService: usando valores hardcodeados ($e)');
      _refFeatures = _getHardcodedReference();
      _isInitialized = true;
    }
  }

  Future<double> calcularSimilitud(Uint8List imagenBytes) async {
    if (!_isInitialized) await initialize();

    try {
      // PASO A: decodificar la imagen recibida
      final decoded = img.decodeImage(imagenBytes);
      if (decoded == null) {
        debugPrint('FirmaService: no se pudo decodificar la imagen');
        return 0.0;
      }
      debugPrint(
        'FirmaService: imagen decodificada ${decoded.width}x${decoded.height}',
      );

      // PASO B: preprocesar a binaria 256x256
      final binary256 = _preprocess(decoded);
      if (binary256 == null) {
        debugPrint('FirmaService: preprocesamiento falló (sin tinta detectada)');
        return 0.0;
      }

      // PASO C: contar píxeles de tinta como validación básica
      var inkPixels = 0;
      for (var y = 0; y < 256; y++) {
        for (var x = 0; x < 256; x++) {
          if (binary256[y][x] > 0) inkPixels++;
        }
      }
      debugPrint('FirmaService: píxeles de tinta en 256x256 = $inkPixels');

      // Si hay muy poca o demasiada tinta, es señal de captura incorrecta.
      if (inkPixels < 100) {
        debugPrint('FirmaService: muy poca tinta, firma vacía');
        return 0.0;
      }
      if (inkPixels > 40000) {
        final ratio = (inkPixels / 65536.0 * 100).toStringAsFixed(1);
        debugPrint(
          'FirmaService: demasiada tinta ($ratio%), posible error de captura',
        );
        return 5.0;
      }

      // PASO D: extraer features y calcular similitud
      final newFeatures = _extractFeatures(binary256);
      final similarity = _calculateSimilarity(_refFeatures!, newFeatures);
      debugPrint(
        'FirmaService: similitud = ${similarity.toStringAsFixed(1)}%',
      );
      return similarity.clamp(0.0, 100.0);
    } catch (e, stack) {
      debugPrint('FirmaService error: $e\n$stack');
      return 0.0;
    }
  }

  bool esValida(double similitud) => similitud >= 64.0;

  // PREPROCESAMIENTO - IDÉNTICO AL DE extract_reference.py
  List<List<int>>? _preprocess(img.Image original) {
    // 1. Convertir a escala de grises
    final gray = img.grayscale(original);

    // 2. Construir histograma
    final hist = List<int>.filled(256, 0);
    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        final lum = _getLum(gray, x, y);
        hist[lum]++;
      }
    }

    // 3. Umbral de Otsu
    final threshold = _otsuThreshold(hist, gray.width * gray.height);
    debugPrint('FirmaService preprocess: Otsu threshold=$threshold');

    // 4. Detectar si el fondo es claro (canvas con fondo blanco)
    final borderSamples = <int>[];
    final xStep = max(1, gray.width ~/ 10);
    final yStep = max(1, gray.height ~/ 10);

    for (var i = 0; i < gray.width; i += xStep) {
      borderSamples.add(_getLum(gray, i, 0));
      borderSamples.add(_getLum(gray, i, gray.height - 1));
    }
    for (var i = 0; i < gray.height; i += yStep) {
      borderSamples.add(_getLum(gray, 0, i));
      borderSamples.add(_getLum(gray, gray.width - 1, i));
    }

    final avgBorder =
        borderSamples.reduce((a, b) => a + b) / borderSamples.length;
    final bgIsLight = avgBorder > 127;
    debugPrint(
      'FirmaService preprocess: avgBorder=${avgBorder.toStringAsFixed(1)} bgIsLight=$bgIsLight',
    );

    // 5. Binarizar: tinta = 255, fondo = 0
    bool isInkPixel(int lum) => bgIsLight ? lum < threshold : lum > threshold;

    // 6. Encontrar bounding box del trazo
    var minX = gray.width;
    var minY = gray.height;
    var maxX = 0;
    var maxY = 0;
    var hasInk = false;

    for (var y = 0; y < gray.height; y++) {
      for (var x = 0; x < gray.width; x++) {
        if (isInkPixel(_getLum(gray, x, y))) {
          hasInk = true;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (!hasInk) return null;

    // 7. Padding 15%
    final strokeW = maxX - minX;
    final strokeH = maxY - minY;
    final padX = (strokeW * 0.15).toInt().clamp(2, 50);
    final padY = (strokeH * 0.15).toInt().clamp(2, 50);
    final x1 = (minX - padX).clamp(0, gray.width - 1);
    final y1 = (minY - padY).clamp(0, gray.height - 1);
    final x2 = (maxX + padX).clamp(0, gray.width - 1);
    final y2 = (maxY + padY).clamp(0, gray.height - 1);
    final cropW = x2 - x1;
    final cropH = y2 - y1;
    if (cropW <= 0 || cropH <= 0) return null;

    // 8. Escalar a 256x256 manteniendo aspect ratio con padding centrado
    final scale = 256.0 / max(cropW, cropH);
    final newW = (cropW * scale).toInt().clamp(1, 256);
    final newH = (cropH * scale).toInt().clamp(1, 256);
    final offsetX = (256 - newW) ~/ 2;
    final offsetY = (256 - newH) ~/ 2;

    final result = List.generate(256, (_) => List<int>.filled(256, 0));

    for (var py = 0; py < newH; py++) {
      for (var px = 0; px < newW; px++) {
        final srcX = (x1 + px / scale).toInt().clamp(0, gray.width - 1);
        final srcY = (y1 + py / scale).toInt().clamp(0, gray.height - 1);
        final lum = _getLum(gray, srcX, srcY);
        if (isInkPixel(lum)) {
          final dstX = (px + offsetX).clamp(0, 255);
          final dstY = (py + offsetY).clamp(0, 255);
          result[dstY][dstX] = 255;
        }
      }
    }

    return result;
  }

  int _getLum(img.Image grayImg, int x, int y) {
    final pixel = grayImg.getPixel(x, y);
    return pixel.r.toInt().clamp(0, 255);
  }

  int _otsuThreshold(List<int> hist, int total) {
    var sum = 0.0;
    for (var i = 0; i < 256; i++) sum += i * hist[i];

    var sumB = 0.0;
    var wB = 0.0;
    var maxVar = 0.0;
    var threshold = 128;

    for (var t = 0; t < 256; t++) {
      wB += hist[t];
      if (wB == 0) continue;
      final wF = total - wB;
      if (wF == 0) break;

      sumB += t * hist[t];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;
      final varBetween = wB * wF * (mB - mF) * (mB - mF);
      if (varBetween > maxVar) {
        maxVar = varBetween;
        threshold = t;
      }
    }

    return threshold.clamp(50, 220);
  }

  // EXTRACCIÓN DE FEATURES
  Map<String, dynamic> _extractFeatures(List<List<int>> b) {
    final f = <String, dynamic>{};

    // Zone map 8x8
    final zm = <double>[];
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        var s = 0.0;
        for (var py = r * 32; py < (r + 1) * 32; py++) {
          for (var px = c * 32; px < (c + 1) * 32; px++) {
            s += b[py][px];
          }
        }
        zm.add(s / (32 * 32 * 255));
      }
    }
    f['zone_map_8x8'] = zm;

    // Perfiles de proyección normalizados
    final hp = List<double>.filled(256, 0);
    final vp = List<double>.filled(256, 0);
    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 256; x++) {
        if (b[y][x] > 0) {
          hp[y]++;
          vp[x]++;
        }
      }
    }
    final hm = hp.reduce(max);
    final vm = vp.reduce(max);
    f['h_profile'] = hm > 0 ? hp.map((v) => v / hm).toList() : hp;
    f['v_profile'] = vm > 0 ? vp.map((v) => v / vm).toList() : vp;

    // Cruces topológicos 6 líneas
    final cr = <int>[];
    for (final frac in [0.25, 0.5, 0.75]) {
      final ri = (256 * frac).toInt();
      var c = 0;
      var prev = false;
      for (var x = 0; x < 256; x++) {
        final cur = b[ri][x] > 0;
        if (cur != prev) c++;
        prev = cur;
      }
      cr.add(c ~/ 2);
    }
    for (final frac in [0.25, 0.5, 0.75]) {
      final ci = (256 * frac).toInt();
      var c = 0;
      var prev = false;
      for (var y = 0; y < 256; y++) {
        final cur = b[y][ci] > 0;
        if (cur != prev) c++;
        prev = cur;
      }
      cr.add(c ~/ 2);
    }
    f['crossings_6'] = cr;

    // Template 64x64
    final tmpl = <double>[];
    for (var r = 0; r < 64; r++) {
      for (var c = 0; c < 64; c++) {
        var s = 0.0;
        for (var py = r * 4; py < (r + 1) * 4; py++) {
          for (var px = c * 4; px < (c + 1) * 4; px++) {
            s += b[py][px];
          }
        }
        tmpl.add(s / (4 * 4 * 255));
      }
    }
    f['template_64x64'] = tmpl;

    // Stroke count
    f['stroke_count'] = _countStrokes(b);

    // Aspect ratio, ink density, centroid
    var ink = 0;
    var sx = 0;
    var sy = 0;
    var mnx = 256;
    var mny = 256;
    var mxx = 0;
    var mxy = 0;

    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 256; x++) {
        if (b[y][x] > 0) {
          ink++;
          sx += x;
          sy += y;
          if (x < mnx) mnx = x;
          if (y < mny) mny = y;
          if (x > mxx) mxx = x;
          if (y > mxy) mxy = y;
        }
      }
    }

    f['aspect_ratio'] = (mxy - mny) > 0 ? (mxx - mnx) / (mxy - mny) : 1.0;
    f['ink_density'] = ink / (256.0 * 256.0);
    f['centroid'] = ink > 0 ? [sx / (ink * 256.0), sy / (ink * 256.0)] : [0.5, 0.5];

    return f;
  }

  int _countStrokes(List<List<int>> b) {
    final vis = List.generate(256, (_) => List<bool>.filled(256, false));
    var count = 0;

    for (var y = 0; y < 256; y++) {
      for (var x = 0; x < 256; x++) {
        if (b[y][x] > 0 && !vis[y][x]) {
          final q = <List<int>>[
            [y, x],
          ];
          vis[y][x] = true;
          var area = 0;

          while (q.isNotEmpty) {
            final p = q.removeAt(0);
            area++;
            for (final d in const [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1],
              [-1, -1],
              [-1, 1],
              [1, -1],
              [1, 1],
            ]) {
              final ny = p[0] + d[0];
              final nx = p[1] + d[1];
              if (ny >= 0 &&
                  ny < 256 &&
                  nx >= 0 &&
                  nx < 256 &&
                  !vis[ny][nx] &&
                  b[ny][nx] > 0) {
                vis[ny][nx] = true;
                q.add([ny, nx]);
              }
            }
          }

          if (area > 50) count++;
        }
      }
    }

    return count;
  }

  // CÁLCULO DE SIMILITUD MULTI-FEATURE
  double _calculateSimilarity(Map<String, dynamic> ref, Map<String, dynamic> nueva) {
    final sTemplate = _scoreTemplate(
      List<double>.from(ref['template_64x64'] as List),
      List<double>.from(nueva['template_64x64'] as List),
    );
    final sZone = _scoreZoneMap(
      List<double>.from(ref['zone_map_8x8'] as List),
      List<double>.from(nueva['zone_map_8x8'] as List),
    );
    final sProfile = _scoreProfiles(
      List<double>.from(ref['h_profile'] as List),
      List<double>.from(nueva['h_profile'] as List),
      List<double>.from(ref['v_profile'] as List),
      List<double>.from(nueva['v_profile'] as List),
    );
    final sCrossings = _scoreCrossings(
      List<int>.from(ref['crossings_6'] as List),
      List<int>.from(nueva['crossings_6'] as List),
    );
    final sStruct = _scoreStructural(ref, nueva);

    debugPrint(
      'FirmaService scores: '
      'tmpl=${(sTemplate * 100).toStringAsFixed(1)} '
      'zone=${(sZone * 100).toStringAsFixed(1)} '
      'prof=${(sProfile * 100).toStringAsFixed(1)} '
      'cross=${(sCrossings * 100).toStringAsFixed(1)} '
      'struct=${(sStruct * 100).toStringAsFixed(1)}',
    );

    return (sTemplate * 0.35 +
            sZone * 0.25 +
            sProfile * 0.20 +
            sCrossings * 0.10 +
            sStruct * 0.10) *
        100.0;
  }

  double _scoreTemplate(List<double> a, List<double> b) => max(0.0, _pearson(a, b));

  double _scoreZoneMap(List<double> ref, List<double> nv) {
    var score = 0.0;
    var w = 0.0;
    for (var i = 0; i < ref.length; i++) {
      final r = ref[i];
      final n = nv[i];
      if (r > 0.04) {
        score += max(0.0, 1 - (r - n).abs() / (r + 1e-6));
        w += 1.0;
      } else if (n > 0.04) {
        score -= 0.5;
        w += 0.5;
      }
    }
    return w > 0 ? (score / w).clamp(0.0, 1.0) : 0.0;
  }

  double _scoreProfiles(
    List<double> rh,
    List<double> nh,
    List<double> rv,
    List<double> nv,
  ) {
    return ((_pearson(rh, nh) + 1) / 2 + (_pearson(rv, nv) + 1) / 2) / 2;
  }

  double _scoreCrossings(List<int> ref, List<int> nv) {
    var t = 0.0;
    for (var i = 0; i < ref.length; i++) {
      final d = (ref[i] - nv[i]).abs();
      if (d == 0) {
        t += 1.0;
      } else if (d == 1) {
        t += 0.5;
      }
    }
    return t / ref.length;
  }

  double _scoreStructural(Map<String, dynamic> ref, Map<String, dynamic> nv) {
    final sc = max(
      0.0,
      1.0 - ((ref['stroke_count'] as int) - (nv['stroke_count'] as int)).abs() * 0.25,
    );
    final ar = max(
      0.0,
      1.0 - ((ref['aspect_ratio'] as double) - (nv['aspect_ratio'] as double)).abs() * 2,
    );
    final id = max(
      0.0,
      1.0 -
          ((ref['ink_density'] as double) - (nv['ink_density'] as double)).abs() /
              ((ref['ink_density'] as double) + 1e-6),
    );
    final rc = List<double>.from(ref['centroid'] as List);
    final nc = List<double>.from(nv['centroid'] as List);
    final cent = max(
      0.0,
      1.0 - ((rc[0] - nc[0]).abs() + (rc[1] - nc[1]).abs()) * 3,
    );
    return (sc + ar + id + cent) / 4;
  }

  double _pearson(List<double> a, List<double> b) {
    final n = a.length;
    var sa = 0.0;
    var sb = 0.0;
    var sab = 0.0;
    var sa2 = 0.0;
    var sb2 = 0.0;

    for (var i = 0; i < n; i++) {
      sa += a[i];
      sb += b[i];
      sab += a[i] * b[i];
      sa2 += a[i] * a[i];
      sb2 += b[i] * b[i];
    }

    final num = n * sab - sa * sb;
    final den = sqrt((n * sa2 - sa * sa) * (n * sb2 - sb * sb));
    return den < 1e-10 ? 0.0 : num / den;
  }

  // REFERENCIA HARDCODEADA - VALORES REALES DE firma_coordinador.png
  Map<String, dynamic> _getHardcodedReference() {
    return {
      'stroke_count': 6,
      'aspect_ratio': 1.2375,
      'ink_density': 0.039749,
      'centroid': [0.515615, 0.532495],
      'crossings_6': [1, 3, 2, 1, 0, 1],
      'zone_map_8x8': [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.059600,
        0.0,
        0.010700,
        0.092800,
        0.0,
        0.081100,
        0.0,
        0.0,
        0.125000,
        0.0,
        0.043900,
        0.233400,
        0.162100,
        0.189500,
        0.0,
        0.0,
        0.093800,
        0.0,
        0.0,
        0.127900,
        0.0,
        0.163100,
        0.105500,
        0.069300,
        0.218800,
        0.025400,
        0.0,
        0.032200,
        0.0,
        0.061500,
        0.227500,
        0.121100,
        0.112300,
        0.030300,
        0.0,
        0.0,
        0.0,
        0.0,
        0.157200,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
      ],
      'h_profile': List<double>.filled(256, 0.0),
      'v_profile': List<double>.filled(256, 0.0),
      'template_64x64': List<double>.filled(4096, 0.0),
    };
  }
}
