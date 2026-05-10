# Módulo de Autenticación JWT — UniControl UCEVA

## Descripción

Este módulo añade autenticación JWT propia al proyecto Flutter existente,
con separación estricta entre datos sensibles y no sensibles, manejo de
estados y una vista de evidencia del almacenamiento local.

---

## Archivos entregados

```
lib/
├── models/
│   └── jwt_user_model.dart          ← Modelo de usuario JWT
├── services/
│   ├── jwt_auth_service.dart        ← Servicio JWT (estados + HTTP + persistencia)
│   └── storage_service.dart         ← SharedPreferences + FlutterSecureStorage
├── views/
│   ├── auth/
│   │   └── jwt_login_screen.dart    ← Pantalla de login JWT
│   └── session/
│       └── session_info_screen.dart ← Vista de evidencia (almacenamiento local)
├── routes/
│   └── app_router.dart              ← Router actualizado con /login y /session-info
└── main.dart                        ← main.dart con MultiProvider
pubspec.yaml                         ← Dependencias actualizadas
ANDROID_MANIFEST_PATCH.txt           ← Cambios necesarios en AndroidManifest
```

---

## Dependencias agregadas

```yaml
# pubspec.yaml
http: ^1.2.2                  # HTTP para login JWT
shared_preferences: ^2.3.2    # Datos NO sensibles
flutter_secure_storage: ^9.2.2 # Datos SENSIBLES (cifrados)
```

Instalar con:
```bash
flutter pub get
```

---

## Arquitectura del almacenamiento

### SharedPreferences — datos NO sensibles
| Clave         | Tipo   | Contenido                        |
|---------------|--------|----------------------------------|
| `user_nombre` | String | Nombre del usuario               |
| `user_email`  | String | Correo institucional             |
| `user_tema`   | String | Preferencia de tema (light/dark) |
| `user_idioma` | String | Preferencia de idioma (es/en)    |
| `user_role`   | String | Rol asignado por el backend      |

### FlutterSecureStorage — datos SENSIBLES (cifrados)
| Clave           | Tipo   | Contenido                     |
|-----------------|--------|-------------------------------|
| `access_token`  | String | JWT de acceso (AES-256/Keychain) |
| `refresh_token` | String | JWT de refresco (opcional)    |

En **Android** usa `EncryptedSharedPreferences` (AES-256).  
En **iOS** usa el **Keychain** del sistema.

---

## Estados de autenticación (`AuthStatus`)

```
initial         → Cargando sesión al inicio
loading         → Petición HTTP en curso
authenticated   → Login exitoso, token y perfil disponibles
unauthenticated → Sin sesión (logout o primera vez)
error           → Credenciales inválidas u otro error
```

El widget escucha el estado con:
```dart
final state = context.watch<JwtAuthService>().state;
if (state.isLoading) { ... }
if (state.hasError)  { ... }
```

---

## Configuración del endpoint

En `jwt_auth_service.dart`, línea 33:
```dart
static const String _baseUrl = 'https://unicontrol-api.uceva.edu.co';
```

El servicio espera que el backend responda al POST `/auth/login` con:
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",      // opcional
  "user": {
    "nombre": "Juan García",
    "email": "jgarcia@uceva.edu.co",
    "role": "estudiante"
  }
}
```

Si la respuesta no incluye el objeto `"user"`, los campos se buscan
directamente en la raíz del JSON.

---

## Integración paso a paso

### 1. Agregar dependencias
```bash
flutter pub add http shared_preferences flutter_secure_storage
flutter pub get
```

### 2. Reemplazar archivos
Copia los archivos de este módulo a tu proyecto conservando la estructura.

### 3. Actualizar `AndroidManifest.xml`
Agrega el permiso de Internet (ver `ANDROID_MANIFEST_PATCH.txt`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 4. iOS — Info.plist (si usas flutter_secure_storage)
No se requieren cambios adicionales. El Keychain funciona sin configuración.

### 5. Registrar providers en `main.dart`
El `main.dart` entregado ya incluye `MultiProvider` con ambos servicios:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
    ChangeNotifierProvider<JwtAuthService>(create: (_) => JwtAuthService()),
  ],
  ...
)
```

---

## Vista de evidencia (`/session-info`)

Accesible desde el botón "Ver almacenamiento local" en el login,
o directamente con `context.go('/session-info')`.

Muestra:
- **Datos de SharedPreferences**: nombre, email, tema, idioma, rol.
- **Estado de tokens**: "presente" (con máscara `••••`) o "ausente".
- **Indicador de sesión**: "Sesión activa" / "Sin sesión activa".
- **Botón "Cerrar sesión"**: elimina todos los datos y tokens, redirige a `/login`.

---

## Uso del StorageService directamente

```dart
final storage = StorageService.instance;

// Guardar info no sensible
await storage.saveUserInfo(
  nombre: 'Ana López',
  email: 'alopez@uceva.edu.co',
  tema: 'dark',
  idioma: 'es',
  role: 'estudiante',
);

// Guardar tokens (sensibles)
await storage.saveTokens(
  accessToken: 'eyJ...',
  refreshToken: 'eyJ...', // opcional
);

// Leer
final nombre = await storage.getNombre();
final token  = await storage.getAccessToken();
final tiene  = await storage.hasToken(); // bool

// Cerrar sesión
await storage.clearAll(); // elimina prefs + tokens
```

---

## Notas de seguridad

- **Nunca** mostrar el valor real del token en la UI (la vista de evidencia
  usa `••••••••••••` por diseño).
- Los tokens se almacenan cifrados; en caso de jailbreak/root avanzado,
  considerar `androidOptions: AndroidOptions(encryptedSharedPreferences: true)`
  (ya configurado en `StorageService`).
- El logout intenta notificar al backend (fire-and-forget) y siempre limpia
  el almacenamiento local, independientemente de la respuesta del servidor.
