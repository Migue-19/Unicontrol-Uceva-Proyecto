Segundo-Plano-Flutter

- Estudiantes:
Miguel Angel Ruiz Urdemendiz
Jolmer Alexander Viedma Agudelo

- ¿Cuándo usar cada herramienta?

| Herramienta | Cuándo usarla |
|---|---|
| `Future` | Operación que entregará un valor en el futuro (HTTP, DB, I/O) |
| `async/await` | Escribir código asíncrono de forma legible y secuencial |
| `Timer` | Ejecutar código después de un retraso o repetidamente cada N ms |
| `Isolate` | Tareas CPU-bound que bloquearían el hilo principal (UI thread) |

---

1. Home
Menú de navegación a las tres demostraciones.

2. Future / async / await
- El usuario presiona **Consultar datos**.
- La UI muestra **Cargando...** mientras espera.
- Tras 3 segundos se muestra **Éxito** (con los datos) o **Error** (20% aleatorio).
- Consola imprime: antes del fetch → durante → después.

3. Cronómetro — Timer
- **Iniciar**: arranca `Timer.periodic` cada 100 ms.
- **Pausar**: llama `_timer?.cancel()`.
- **Reanudar**: re-crea el timer desde el tiempo actual.
- **Reiniciar**: cancela y vuelve a 00:00.00.
- Al salir de la vista (`dispose`) se cancela el timer automáticamente.

4. Isolate — Tarea Pesada
- El usuario presiona el botón.
- Se lanza `Isolate.spawn` con 500 millones de iteraciones.
- La UI permanece responsiva (puede navegar, el spinner gira).
- El resultado (suma + tiempo) llega por `ReceivePort` y se muestra en pantalla.