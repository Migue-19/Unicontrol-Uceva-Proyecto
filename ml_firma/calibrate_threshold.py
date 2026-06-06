"""
calibrate_threshold.py
Genera firmas sintéticas buenas y malas para verificar que el umbral separa bien.
Uso: python ml_firma/calibrate_threshold.py
"""
from __future__ import annotations

import json
from pathlib import Path

import cv2
import numpy as np

from extract_reference import extract_features, preprocess
from validate_signature import calculate_similarity


ROOT = Path(__file__).resolve().parents[1]
REF_PATH = ROOT / "assets" / "firma_reference_features.json"


def normalize_reference(ref_features):
    zone_map = [float(v) for v in ref_features['zone_map_8x8']]

    rows = [0.0] * 8
    cols = [0.0] * 8
    for r in range(8):
        for c in range(8):
            value = zone_map[r * 8 + c]
            rows[r] += value
            cols[c] += value

    row_max = max(rows) if max(rows) > 0 else 1.0
    col_max = max(cols) if max(cols) > 0 else 1.0
    h_profile = [rows[i // 32] / row_max for i in range(256)]
    v_profile = [cols[i // 32] / col_max for i in range(256)]

    template = [0.0] * 4096
    for r in range(8):
        for c in range(8):
            value = zone_map[r * 8 + c]
            for y in range(8):
                for x in range(8):
                    template[(r * 8 + y) * 64 + (c * 8 + x)] = value

    normalized = dict(ref_features)
    if not normalized.get('h_profile'):
        normalized['h_profile'] = h_profile
    if not normalized.get('v_profile'):
        normalized['v_profile'] = v_profile
    if not normalized.get('template_64x64'):
        normalized['template_64x64'] = template
    normalized['h_profile'] = [float(v) for v in normalized['h_profile']]
    normalized['v_profile'] = [float(v) for v in normalized['v_profile']]
    normalized['template_64x64'] = [float(v) for v in normalized['template_64x64']]
    normalized['zone_map_8x8'] = zone_map
    normalized['crossings_6'] = [int(v) for v in normalized['crossings_6']]
    normalized['hu_moments'] = [float(v) for v in normalized['hu_moments']]
    normalized['centroid'] = [float(v) for v in normalized['centroid']]
    normalized['strokes'] = [
        [int(stroke[0]), float(stroke[1]), float(stroke[2])] for stroke in normalized.get('strokes', [])
    ]
    return normalized


def make_variation(binary_256, strength='light'):
    result = binary_256.copy()
    if strength == 'light':
        angle = np.random.uniform(-8, 8)
        scale = np.random.uniform(0.92, 1.08)
    else:
        angle = np.random.uniform(-15, 15)
        scale = np.random.uniform(0.85, 1.15)

    h, w = result.shape
    M = cv2.getRotationMatrix2D((w // 2, h // 2), angle, scale)
    result = cv2.warpAffine(result, M, (w, h), flags=cv2.INTER_NEAREST, borderValue=0)

    noise = np.random.normal(0, 10, result.shape).astype(np.int16)
    result = np.clip(result.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    _, result = cv2.threshold(result, 128, 255, cv2.THRESH_BINARY)
    return result


def make_random_scribble():
    canvas = np.zeros((256, 256), dtype=np.uint8)
    n_strokes = np.random.randint(2, 8)
    for _ in range(n_strokes):
        pts = np.random.randint(20, 236, (np.random.randint(3, 8), 2))
        for i in range(len(pts) - 1):
            cv2.line(canvas, tuple(pts[i]), tuple(pts[i + 1]), 255, np.random.randint(2, 6))
    return canvas


def main() -> None:
    with REF_PATH.open(encoding='utf-8') as f:
        ref_features = normalize_reference(json.load(f))

    ref_binary = preprocess(ROOT / 'assets' / 'firma_coordinador.png')
    ref_feat = extract_features(ref_binary)

    print('CALIBRACIÓN DEL UMBRAL')
    print('=' * 50)

    sim_self = calculate_similarity(ref_features, ref_feat)
    print(f'Firma vs sí misma:        {sim_self:.1f}% (esperado: >90%)')

    sims_light = []
    for _ in range(10):
        var = make_variation(ref_binary, 'light')
        feat = extract_features(var)
        sims_light.append(calculate_similarity(ref_features, feat))
    print(f'Variaciones leves (x10):  {np.mean(sims_light):.1f}% ± {np.std(sims_light):.1f}% (esperado: >64%)')

    sims_scribble = []
    for _ in range(10):
        scribble = make_random_scribble()
        feat = extract_features(scribble)
        sims_scribble.append(calculate_similarity(ref_features, feat))
    print(f'Garabatos aleatorios:     {np.mean(sims_scribble):.1f}% ± {np.std(sims_scribble):.1f}% (esperado: <64%)')


if __name__ == '__main__':
    main()