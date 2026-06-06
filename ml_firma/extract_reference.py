import cv2, numpy as np, json, os

def preprocess(img_path):
    img = cv2.imread(img_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    # firma_coordinador.png tiene fondo blanco -> invertir para tinta=255
    if binary.mean() > 127:
        binary = cv2.bitwise_not(binary)
    coords = cv2.findNonZero(binary)
    if coords is None:
        raise ValueError("Sin tinta")
    x, y, w, h = cv2.boundingRect(coords)
    px, py = int(w * 0.15), int(h * 0.15)
    x1, y1 = max(0, x - px), max(0, y - py)
    x2, y2 = min(binary.shape[1], x + w + px), min(binary.shape[0], y + h + py)
    cropped = binary[y1:y2, x1:x2]
    scale = 256 / max(cropped.shape)
    nw, nh = int(cropped.shape[1] * scale), int(cropped.shape[0] * scale)
    resized = cv2.resize(cropped, (nw, nh), interpolation=cv2.INTER_AREA)
    canvas = np.zeros((256, 256), dtype=np.uint8)
    ox, oy = (256 - nw) // 2, (256 - nh) // 2
    canvas[oy:oy + nh, ox:ox + nw] = resized
    _, canvas = cv2.threshold(canvas, 127, 255, cv2.THRESH_BINARY)
    return canvas

def extract_features(b):
    f = {}
    zm = []
    for r in range(8):
        for c in range(8):
            zone = b[r * 32:(r + 1) * 32, c * 32:(c + 1) * 32]
            zm.append(round(float(zone.sum()) / (32 * 32 * 255), 6))
    f['zone_map_8x8'] = zm
    hp = (b.sum(axis=1) / 255.0).tolist()
    vp = (b.sum(axis=0) / 255.0).tolist()
    hm = max(hp) if max(hp) > 0 else 1
    vm = max(vp) if max(vp) > 0 else 1
    f['h_profile'] = [round(v / hm, 6) for v in hp]
    f['v_profile'] = [round(v / vm, 6) for v in vp]
    cr = []
    for frac in [0.25, 0.5, 0.75]:
        line = (b[int(256 * frac), :] > 0).astype(int)
        cr.append(int((np.diff(line) != 0).sum() // 2))
    for frac in [0.25, 0.5, 0.75]:
        line = (b[:, int(256 * frac)] > 0).astype(int)
        cr.append(int((np.diff(line) != 0).sum() // 2))
    f['crossings_6'] = cr
    small = cv2.resize(b, (64, 64), interpolation=cv2.INTER_AREA)
    _, small = cv2.threshold(small, 127, 255, cv2.THRESH_BINARY)
    f['template_64x64'] = (small / 255.0).flatten().tolist()
    num_labels, _, stats, centroids = cv2.connectedComponentsWithStats(b, connectivity=8)
    sig = [
        (int(stats[i, cv2.CC_STAT_AREA]), float(centroids[i][0]), float(centroids[i][1]))
        for i in range(1, num_labels)
        if stats[i, cv2.CC_STAT_AREA] > 50
    ]
    f['stroke_count'] = len(sig)
    coords = cv2.findNonZero(b)
    x, y, w, h = cv2.boundingRect(coords)
    f['aspect_ratio'] = round(float(w) / float(h) if h > 0 else 1.0, 6)
    ink = int((b > 0).sum())
    f['ink_density'] = round(ink / (256 * 256), 6)
    m = cv2.moments(b)
    f['centroid'] = [round(m['m10'] / m['m00'] / 256, 6), round(m['m01'] / m['m00'] / 256, 6)] if m['m00'] > 0 else [0.5, 0.5]
    return f

if __name__ == '__main__':
    b = preprocess('assets/firma_coordinador.png')
    feats = extract_features(b)
    with open('assets/firma_reference_features.json', 'w') as f:
        json.dump(feats, f, indent=2)
    print('JSON generado')
    print(f"   stroke_count: {feats['stroke_count']}")
    print(f"   aspect_ratio: {feats['aspect_ratio']}")
    print(f"   ink_density: {feats['ink_density']}")
    print(f"   crossings_6: {feats['crossings_6']}")
    print(f"   Zonas con tinta: {sum(1 for v in feats['zone_map_8x8'] if v > 0.04)}/64")
