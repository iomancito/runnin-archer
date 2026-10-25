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

## Cámara, enemigos y sombras (octubre 2026)

Prueba de estrés en el mapa 1 (filas cada 3,5 m, ~35 enemigos vivos):

| | FPS | GPU |
|---|---|---|
| Densidad normal (12-19 enemigos), cámara antigua | ~39 | ~22 ms |
| Estrés, cámara antigua | ~35 | ~25 ms |
| Estrés, cámara nueva | ~40 | ~21,5 ms |
| Estrés, cámara nueva + sombras 1024 en móvil | ~40 | ~20,7 ms |
| Estrés, cámara nueva, sin sombras (primeros 10 s) | ~55 | ~14,6 ms |
| Estrés, cámara nueva, sombras estáticas (primeros 10 s; probado y descartado) | ~50 | ~16,1 ms |
| Hell con hordas (hasta 44 vivos) | 36-40 | 20-23 ms |

- **Enemigos**: pasar de ~15 a ~35 vivos solo cuesta ~3 ms de GPU. Los modelos ya usan LOD automático (`generate_lods`), así que hacerlos low poly a mano apenas ganaría.
- **Cámara**: lo caro es la parte lejana de la pantalla (árboles y hojas). La cámara nueva (altura 14 m, 69°, FOV horizontal 42° con `keep_aspect = KEEP_WIDTH`) ve todo el ancho del camino, queda fija en x y ve ~27 m por delante en vez de ~42. Con `KEEP_WIDTH` el ancho visible es el mismo en cualquier proporción de pantalla. Se sustituyó después por la cámara detrás del player (ver abajo).
- **Sombras**: `directional_shadow/size.mobile` vale 2048 por defecto y en Android **manda sobre** `size`: el mapa de sombras era de 2048 aunque `size` dijera 1024. Ahora se fija también `size.mobile=1024`. La distancia de sombra baja de 40 a 28 m: con la cámara nueva el suelo visible más lejano está a ~23 m de profundidad. El filtro ya es el más barato en móvil (`soft_shadow_filter_quality.mobile = 0`).
- **Sombras estáticas** (horneadas en el decorado + manchas bajo los personajes): ahorran ~3 ms de GPU, pero por el tope de 40 FPS no suben los FPS en este móvil. Se descartaron; están en la rama `sombras-estaticas` por si se retoman.
- **Tope de 40 FPS**: la pantalla va a 60 Hz. Mientras la GPU tarde más de 16,7 ms, los frames alternan entre 16,7 y 33 ms (~40 FPS). Además, tras ~10 s de carga el gestor de frecuencia del móvil (MediaTek/OPPO, sin estar caliente) baja la GPU hasta quedarse justo en 40 FPS, así que el tiempo de GPU medido sube hasta ~20 ms sea cual sea la escena. Las mejoras pequeñas no se notan hasta bajar claramente de 16,7 ms; para comparar, mirar los primeros 10-20 s.

## Cámara detrás del player (octubre 2026)

Primera versión: 3,5 m de altura, 3 m por detrás del player, inclinada 20°, FOV 42°. Mirando de frente al camino, sin límite dibujaba todo el mapa: **14 FPS, 69 ms, 1600 draw calls, 4,3 M triángulos**. Medidas en Hell (~15 enemigos vivos), media de 2-3 partidas, segundos 3-21:

| Mapa | Cámara cenital (14 m) | Cámara detrás |
|---|---|---|
| 1 | ~44 FPS, 19,6 ms, ~120 draw calls | ~44 FPS, 19,8 ms, ~115 draw calls |
| 2 | ~47 FPS, 18,4 ms, ~123 draw calls | ~44 FPS, 19,3 ms, ~117 draw calls |
| 3 | ~42 FPS, 20,3 ms, ~113 draw calls | ~48 FPS, 17,8 ms, ~106 draw calls |

Qué hizo falta:

- **Distancia de dibujo** `far = 40 m` en la cámara (ve ~37 m por delante del player frente a ~27 de la cenital) y **niebla de profundidad** de 22 a 40 m en los tres mapas para que no se vea el corte. La parte baja del cielo (`ground_*_color`) tiene el color de la niebla para que el fondo del camino no muestre una franja; `fog_sky_affect = 0` mantiene el cielo. La niebla no cuesta nada medible.
- **Sombras hasta 18 m** (antes 28): con la cámara mirando de frente casi toda la distancia de sombra cae en pantalla.
- **Hojas baratas**: lo que más cuesta son las copas de los árboles de los lados, que ahora ocupan mucha pantalla con varias capas de recorte alfa (sin decorado: ~15 ms; sin árboles: ~17 ms; sin rocas o sin plantas: sin cambio). Que las hojas no reciban sombras y no tengan especular (`MeshBatcher.HOJAS`) ahorra ~4 ms y casi no se nota. Hacerlas opacas ahorraría ~6 ms pero se ven las tarjetas cuadradas. Iluminación por vértice: sin ganancia.
- Sin efecto medible: cielo liso en vez de procedural, quitar la sombra de las rocas, cámara algo más alta, FOV más estrecho, `far` 35 m.
- Las medidas con esta cámara varían más entre partidas (±2-3 ms) que con la cenital: comparar varias partidas alternando versiones.

### Copas simplificadas

Las copas del pack son cientos de tarjetas con recorte alfa (CommonTree_1: 960 tarjetas, 1029 m² de hojas en un árbol de 4 m de ancho). [`tools/simplificar_copas.py`](../tools/simplificar_copas.py) (Blender) genera `assets/naturaleza_simple/`: por copa, varios volúmenes opacos del color medio de las hojas (tapan lo de detrás) y solo el 45 % exterior de las tarjetas; borra las ramas que quedan dentro. Usan las texturas originales de `assets/externos/Nature/`. Las escenas de `vegetation_pack` apuntan a estos modelos.

Mapa 1 en Hell, 3 partidas alternas: **43,2 → 46,1 FPS, 20,1 → 18,3 ms, ~190 k → ~90 k triángulos**.

### Cámara final

4,5 m de altura, 1,6 m por detrás, 32°, FOV 48°, `far` 40 m (`main.tscn`). Las medidas de abajo son con 5,5 m y 4 m; después se acercó para que el player se vea más grande y quede más abajo en la pantalla (pies a ~10 % del borde inferior en vez de ~30 %), sin cambiar lo que se ve por delante. Sigue el 60 % del desplazamiento lateral del player, suavizado, pero sin dejar que se separe más de 0,5 m de su centro (`CAMARA_SIGUE_X`, `CAMARA_SUAVIZADO`, `CAMARA_MARGEN_X` en `main.gd`): a la altura de la cabeza solo se ven ~1,3 m a cada lado y, sin ese límite, junto a las paredes (x = ±4,3) el player se salía de la pantalla. se ve más ancho cerca del player y los carriles se distinguen mejor que con la de 3,5 m. Rinde igual que la de 3,5 m (Hell, con copas simplificadas):

| Mapa | 3,5 m, 20° | Final |
|---|---|---|
| 1 | 46,1 FPS, 18,3 ms | 46,2 FPS, 18,7 ms |
| 2 | 45,7 FPS, 18,4 ms | 44,2 FPS, 19,4 ms (±2,5 ms) |
| 3 | 44,2 FPS, 19,3 ms | 45,8 FPS, 18,5 ms |

## Qué cuesta en esta GPU

- **Glow**: ~7 ms → desactivado en los tres mapas.
- **Sombras en tiempo real**: ~6-7 ms → se mantienen (una cascada, 18 m, mapa de 1024). Sin sombras ni glow se llega a ~55 FPS.
- **Resolución**: 3D al 100 % ≈ 32 ms, al 75 % ≈ 24 ms; por debajo de 75 % no mejora.
- **Triángulos**: reducirlos un 25 % solo ahorra ~1 ms. Simplificar modelos solo compensa si reduce píxeles pintados varias veces (copas con recorte alfa).
- Recorte alfa (`alpha scissor`) desactiva la eliminación de superficies ocultas de Mali: solo las hojas lo usan.

## Optimizaciones aplicadas

| Qué | Dónde |
|---|---|
| Decorado lateral (~6700 mallas) → MultiMesh por modelo y bloque de 30 m | [`mesh_batcher.gd`](../scenes/mapas/mesh_batcher.gd), llamado en `Mapa.instancia_laterales()` |
| Plantas pequeñas sin sombra; corteza y rocas opacas y de una cara; hojas sin recibir sombras ni especular | `MeshBatcher.SIN_SOMBRA`, `MeshBatcher.SOLIDOS`, `MeshBatcher.HOJAS` |
| Suelo: plano con UV normales en vez de caja con triplanar | `mapaN.tscn` |
| Glow desactivado, sombras de una cascada | `mapaN.tscn` |
| 3D al 75 %, LOD algo más agresivo (8 px), mapa de sombras 1024 (también `size.mobile`) | `project.godot` → `[rendering]` |
| Cámara detrás con `far` 40 m y niebla para ocultar el corte; sombras hasta 18 m | `main.tscn`, `main.gd` (`CAMARA_DETRAS`), `mapaN.tscn` |
| Enemigos creados por delante del player y eliminados detrás | [`mapa_base.gd`](../scenes/mapas/mapa_base.gd) (ver [mapas.md](mapas.md)) |
| Mapas cargados en segundo plano al arrancar | `main.gd` → `_carga_inicial()` |
| Shaders precompilados mostrando cada modelo una vez tras la pantalla de inicio | `Mapa.precalentar()` |
| El mapa se monta con la pantalla en negro | `main.gd` → `show_game()` |
| Texturas limitadas a 1024 px al importar | `.import` de cada textura |
| Efectos de los arcos en pool, sin luces dinámicas, ruido convertido a PNG; solo se precalientan los del arco equipado | [`arco_efectos.gd`](../scenes/player/arco_efectos.gd) (ver [arcos.md](arcos.md)) |

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
- Comprobar que el **ahorro de batería** está desactivado (`adb shell settings get global low_power`): limita la CPU a 925 MHz de 2000.
- El perfilador por pasadas de GPU no está disponible en builds exportadas (solo 2 marcas de tiempo).
