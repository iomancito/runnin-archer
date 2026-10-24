# Rendimiento en el móvil

Móvil de pruebas: **OPPO CPH2065** (MediaTek Dimensity 800U, GPU **Mali-G57 MC4**, 1080×2400, 60 Hz).

## Medidas (mapa 1 en partida)

| | Antes | Ahora |
|---|---|---|
| FPS | ~25 | ~41 |
| Tiempo de GPU por frame | ~32 ms | ~22 ms |
| Draw calls | ~580 | ~160 |
| Triángulos por frame | ~1,3 M | ~0,25 M |
| Parón al pulsar PLAY | ~3,2 s visible | ~190 ms bajo fundido negro |

## Qué cuesta en esta GPU

- **Glow**: ~7 ms → desactivado en los tres mapas.
- **Sombras en tiempo real**: ~7 ms → se mantienen (una cascada, 40 m, mapa de 1024). Sin sombras ni glow se llega a ~55 FPS.
- **Resolución**: 3D al 100 % ≈ 32 ms, al 75 % ≈ 24 ms; por debajo de 75 % no mejora.
- **Triángulos**: reducirlos un 25 % solo ahorra ~1 ms. Simplificar modelos no compensa en esta GPU.
- Recorte alfa (`alpha scissor`) desactiva la eliminación de superficies ocultas de Mali: solo las hojas lo usan.

## Optimizaciones aplicadas

| Qué | Dónde |
|---|---|
| Decorado lateral (~6700 mallas) → MultiMesh por modelo y bloque de 30 m | [`mesh_batcher.gd`](../scenes/mapas/mesh_batcher.gd), llamado en `Mapa.instancia_laterales()` |
| Plantas pequeñas sin sombra; corteza y rocas opacas y de una cara | `MeshBatcher.SIN_SOMBRA`, `MeshBatcher.SOLIDOS` |
| Suelo: plano con UV normales en vez de caja con triplanar | `mapaN.tscn` |
| Glow desactivado, sombras de una cascada | `mapaN.tscn` |
| 3D al 75 %, LOD algo más agresivo (8 px), mapa de sombras 1024 | `project.godot` → `[rendering]` |
| Enemigos creados por delante del player y eliminados detrás | [`mapa_base.gd`](../scenes/mapas/mapa_base.gd) (ver [mapas.md](mapas.md)) |
| Mapas cargados en segundo plano al arrancar | `main.gd` → `_carga_inicial()` |
| Shaders precompilados mostrando cada modelo una vez tras la pantalla de inicio | `Mapa.precalentar()` |
| El mapa se monta con la pantalla en negro | `main.gd` → `show_game()` |
| Texturas limitadas a 1024 px al importar | `.import` de cada textura |

## Cómo medir en el móvil

1. Crear un autoload temporal (no commitear) que escriba en logcat cada 2-4 s:
   - `RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)` en `_ready`
   - `RenderingServer.viewport_get_measured_render_time_gpu(vp)` → ms de GPU
   - `Performance.get_monitor(...)`: `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, `TIME_PROCESS`
   - Para tirones: imprimir los frames con `delta > 0.04`.
2. Exportar, instalar, abrir, pulsar PLAY con `adb shell input tap …` y leer `adb logcat -s godot:*` (ver [android.md](android.md)).

Cuidados:

- `TIME_PROCESS` incluye la espera a la GPU: un "process" alto suele ser GPU.
- Cambiar ajustes del `Environment` en tiempo de ejecución recompila shaders y da números falsos: comparar **builds estáticas** durante 20-30 s.
- Las medidas varían ±2 ms entre ejecuciones.
- El perfilador por pasadas de GPU no está disponible en builds exportadas (solo 2 marcas de tiempo).
