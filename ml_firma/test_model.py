from __future__ import annotations
"""
test_model.py
Compatibilidad con el flujo anterior para probar una firma.
Uso: python ml_firma/test_model.py ruta/a/firma_prueba.png
"""
from validate_signature import main


if __name__ == '__main__':
    main()
ASSETS_DIR = ROOT / "assets"
MODEL_PATH = ASSETS_DIR / "firma_model.tflite"
REFERENCE_PATH = ASSETS_DIR / "firma_referencia.npy"


def preprocess_image(path: Path) -> np.ndarray:
    image = Image.open(path).convert("RGB")
    image = ImageOps.grayscale(image)
    image = ImageOps.fit(image, (128, 128), method=Image.Resampling.BILINEAR)
    array = np.asarray(image, dtype=np.float32)
    array = 255.0 - array
    array /= 255.0
    return array[..., np.newaxis]


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    a = a.reshape(-1)
    b = b.reshape(-1)
    denom = np.linalg.norm(a) * np.linalg.norm(b)
    if denom == 0:
        return 0.0
    return float(np.dot(a, b) / denom)


def main() -> None:
    parser = argparse.ArgumentParser(description="Prueba el modelo de validación de firma.")
    parser.add_argument("image", type=Path, help="Ruta de la firma a probar")
    args = parser.parse_args()

    if not MODEL_PATH.exists():
        raise FileNotFoundError(f"No se encontró el modelo: {MODEL_PATH}")
    if not REFERENCE_PATH.exists():
        raise FileNotFoundError(f"No se encontró el embedding de referencia: {REFERENCE_PATH}")

    interpreter = tf.lite.Interpreter(model_path=str(MODEL_PATH))
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()[0]
    output_details = interpreter.get_output_details()[0]

    image = preprocess_image(args.image)
    interpreter.set_tensor(input_details["index"], image[np.newaxis, ...].astype(np.float32))
    interpreter.invoke()
    embedding = interpreter.get_tensor(output_details["index"])[0]

    reference = np.load(REFERENCE_PATH)
    similarity = cosine_similarity(embedding, reference) * 100.0
    print(f"Similitud: {similarity:.2f}%")
    print("Firma válida" if similarity >= 64.0 else "Firma no válida")


if __name__ == "__main__":
    main()