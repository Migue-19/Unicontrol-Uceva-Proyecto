# Módulo de Validación de Firma — UniControl

## Requisitos
- Python 3.10+
- Imagen de la firma del coordinador en: `assets/firma_coordinador.png`

## Pasos para entrenar el modelo

1. Instalar dependencias:
   pip install -r ml_firma/requirements.txt

2. Colocar la imagen de la firma en assets/firma_coordinador.png

3. Generar la referencia determinista:
   python ml_firma/extract_reference.py

4. Copiar archivos generados a assets:
   bash ml_firma/copy_to_assets.sh

5. Probar el modelo con una imagen:
   python ml_firma/validate_signature.py ruta/a/firma_prueba.png

## Umbral de validación
- Similitud >= 64%: FIRMA VÁLIDA ✅
- Similitud < 64%: FIRMA NO VÁLIDA ❌