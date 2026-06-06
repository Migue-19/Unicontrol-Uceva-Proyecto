"""
validate_signature.py
Uso: python ml_firma/validate_signature.py ruta/firma_prueba.png
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import cv2
import numpy as np

from extract_reference import extract_features, preprocess


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


def score_zone_map(ref_zones, new_zones, threshold=0.05):
    score = 0.0
    total_weight = 0.0
    for r, n in zip(ref_zones, new_zones):
        if r > threshold:
            diff = abs(r - n) / (r + 1e-6)
            score += max(0, 1 - diff)
            total_weight += 1.0
        elif n > threshold:
            score -= 0.5
            total_weight += 0.5
    return score / total_weight if total_weight > 0 else 0.0


def score_hu_moments(ref_hu, new_hu):
    diffs = [abs(r - n) / (abs(r) + 1e-6) for r, n in zip(ref_hu[:4], new_hu[:4])]
    avg_diff = sum(diffs) / len(diffs)
    return max(0, 1 - avg_diff * 0.3)


def score_profiles(ref_h, new_h, ref_v, new_v):
    def pearson(a, b):
        a, b = np.array(a), np.array(b)
        if a.std() == 0 or b.std() == 0:
            return 0.0
        return float(np.corrcoef(a, b)[0, 1])

    corr_h = pearson(ref_h, new_h)
    corr_v = pearson(ref_v, new_v)
    score_h = (corr_h + 1) / 2
    score_v = (corr_v + 1) / 2
    return (score_h + score_v) / 2


def score_crossings(ref_cross, new_cross):
    total = 0.0
    for r, n in zip(ref_cross, new_cross):
        diff = abs(r - n)
        if diff == 0:
            total += 1.0
        elif diff == 1:
            total += 0.5
    return total / len(ref_cross)


def score_template(ref_tmpl, new_tmpl):
    a, b = np.array(ref_tmpl), np.array(new_tmpl)
    if a.std() == 0 or b.std() == 0:
        return 0.0
    corr = float(np.corrcoef(a, b)[0, 1])
    return max(0.0, corr)


def score_structural(ref_feat, new_feat):
    scores = []
    sc_diff = abs(ref_feat['stroke_count'] - new_feat['stroke_count'])
    scores.append(max(0, 1 - sc_diff * 0.25))

    ar_diff = abs(ref_feat['aspect_ratio'] - new_feat['aspect_ratio'])
    scores.append(max(0, 1 - ar_diff * 2))

    id_diff = abs(ref_feat['ink_density'] - new_feat['ink_density'])
    id_norm = id_diff / (ref_feat['ink_density'] + 1e-6)
    scores.append(max(0, 1 - id_norm))

    cx_diff = abs(ref_feat['centroid'][0] - new_feat['centroid'][0])
    cy_diff = abs(ref_feat['centroid'][1] - new_feat['centroid'][1])
    scores.append(max(0, 1 - (cx_diff + cy_diff) * 3))

    return sum(scores) / len(scores)


def calculate_similarity(ref_features, new_features):
    s_template = score_template(ref_features['template_64x64'], new_features['template_64x64'])
    s_zone = score_zone_map(ref_features['zone_map_8x8'], new_features['zone_map_8x8'])
    s_profile = score_profiles(
        ref_features['h_profile'], new_features['h_profile'],
        ref_features['v_profile'], new_features['v_profile'],
    )
    s_cross = score_crossings(ref_features['crossings_6'], new_features['crossings_6'])
    s_struct = score_structural(ref_features, new_features)
    s_hu = score_hu_moments(ref_features['hu_moments'], new_features['hu_moments'])

    weighted = (
        s_template * 0.35 +
        s_zone * 0.25 +
        s_profile * 0.20 +
        s_cross * 0.10 +
        s_struct * 0.07 +
        s_hu * 0.03
    )
    return weighted * 100.0


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python ml_firma/validate_signature.py ruta/firma_prueba.png")
        sys.exit(1)

    if not REF_PATH.exists():
        print("Falta assets/firma_reference_features.json. Ejecuta extract_reference.py primero.")
        sys.exit(1)

    with REF_PATH.open(encoding='utf-8') as f:
        ref_features = normalize_reference(json.load(f))

    new_path = sys.argv[1]
    binary_new = preprocess(new_path)
    new_features = extract_features(binary_new)

    sim = calculate_similarity(ref_features, new_features)
    print(f"\n{'='*50}")
    print(f"  Similitud: {sim:.1f}%")
    print(f"  Umbral:    64.0%")
    print(f"  Resultado: {'✅ VÁLIDA' if sim >= 64 else '❌ RECHAZADA'}")
    print(f"{'='*50}")


if __name__ == '__main__':
    main()