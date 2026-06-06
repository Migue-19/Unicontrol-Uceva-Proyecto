from __future__ import annotations
"""
train_model.py
Compatibilidad con el flujo anterior.
Ejecuta la extracción de referencia y genera assets/firma_reference_features.json.
"""
from extract_reference import main


if __name__ == '__main__':
    main()
ROOT = Path(__file__).resolve().parents[1]
ASSETS_DIR = ROOT / "assets"
REFERENCE_IMAGE = ASSETS_DIR / "firma_coordinador.png"
MODEL_OUT = Path(__file__).resolve().parent / "firma_model.tflite"
REFERENCE_EMBEDDING_OUT = Path(__file__).resolve().parent / "firma_referencia.npy"


def preprocess_image(image: Image.Image) -> np.ndarray:
    image = ImageOps.grayscale(image)
    image = ImageOps.fit(image, (128, 128), method=Image.Resampling.BILINEAR)
    array = np.asarray(image, dtype=np.float32)
    array = 255.0 - array
    array /= 255.0
    return array[..., np.newaxis]


def load_reference_image() -> Image.Image:
    if not REFERENCE_IMAGE.exists():
      raise FileNotFoundError(f"No se encontró la firma de referencia: {REFERENCE_IMAGE}")
    return Image.open(REFERENCE_IMAGE).convert("RGB")


def augmentations(base_image: Image.Image, total: int = 256) -> list[np.ndarray]:
    samples: list[np.ndarray] = []
    rng = np.random.default_rng(42)
    for index in range(total):
        image = base_image.copy()

        angle = float(rng.uniform(-8.0, 8.0))
        image = image.rotate(angle, resample=Image.Resampling.BICUBIC, fillcolor=255)

        if rng.random() < 0.5:
            contrast = float(rng.uniform(0.85, 1.25))
            image = ImageEnhance.Contrast(image).enhance(contrast)

        if rng.random() < 0.35:
            sharpness = float(rng.uniform(0.9, 1.4))
            image = ImageEnhance.Sharpness(image).enhance(sharpness)

        if rng.random() < 0.25:
            radius = float(rng.uniform(0.0, 0.8))
            image = image.filter(ImageFilter.GaussianBlur(radius=radius))

        shift_x = int(rng.integers(-6, 7))
        shift_y = int(rng.integers(-6, 7))
        canvas = Image.new("RGB", image.size, (255, 255, 255))
        canvas.paste(image, (shift_x, shift_y))

        sample = preprocess_image(canvas)
        samples.append(sample)

        if index % 16 == 0:
            inverted = ImageOps.autocontrast(canvas)
            samples.append(preprocess_image(inverted))

    return samples


def build_feature_model(input_shape: tuple[int, int, int], embedding_size: int, mean_vector: np.ndarray, components: np.ndarray) -> tf.keras.Model:
    inputs = tf.keras.Input(shape=input_shape, name="firma_input")
    x = tf.keras.layers.Flatten(name="flatten")(inputs)
    dense = tf.keras.layers.Dense(
        embedding_size,
        use_bias=True,
        activation=None,
        name="embedding",
    )
    outputs = dense(x)
    model = tf.keras.Model(inputs=inputs, outputs=outputs, name="firma_encoder")

    weights = components.T.astype(np.float32)
    bias = (-mean_vector @ components.T).astype(np.float32)
    dense.set_weights([weights, bias])
    return model


def fit_components(samples: list[np.ndarray], embedding_size: int = 128) -> tuple[np.ndarray, np.ndarray]:
    flattened = np.stack([sample.reshape(-1) for sample in samples], axis=0)
    mean_vector = flattened.mean(axis=0)
    centered = flattened - mean_vector

    # Componentes principales vía SVD para obtener un embedding compacto y estable.
    _, _, vt = np.linalg.svd(centered, full_matrices=False)
    available = min(embedding_size, vt.shape[0])
    components = vt[:available]

    if available < embedding_size:
        padding = np.eye(flattened.shape[1], dtype=np.float32)[: embedding_size - available]
        components = np.concatenate([components, padding], axis=0)

    return mean_vector.astype(np.float32), components.astype(np.float32)


def save_model_and_reference() -> None:
    base_image = load_reference_image()
    samples = augmentations(base_image)
    reference_tensor = preprocess_image(base_image)
    samples.append(reference_tensor)

    mean_vector, components = fit_components(samples)
    model = build_feature_model((128, 128, 1), 128, mean_vector, components)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = []
    tflite_model = converter.convert()

    MODEL_OUT.write_bytes(tflite_model)

    reference_embedding = model.predict(reference_tensor[np.newaxis, ...], verbose=0)[0]
    np.save(REFERENCE_EMBEDDING_OUT, reference_embedding.astype(np.float32))

    print(f"Modelo guardado en: {MODEL_OUT}")
    print(f"Embedding de referencia guardado en: {REFERENCE_EMBEDDING_OUT}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Entrena el módulo de validación de firma.")
    parser.parse_args()
    save_model_and_reference()


if __name__ == "__main__":
    main()