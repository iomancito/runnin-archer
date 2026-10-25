# Arquitectura

Running Archer es un *runner* vertical para **móviles Android** (Godot 4.7, renderer Mobile, retrato 720×1280 escalado). El arquero corre solo hacia delante (+z), el jugador lo mueve a izquierda/derecha arrastrando el dedo y dispara automáticamente. Matar enemigos da oro para la tienda de mejoras permanentes. Hay 3 mapas, cada uno termina en un boss.

## Flujo de la aplicación

```
Splash de Godot ─► Pantalla de carga (misma imagen + barra) ─► fundido ─► Menú principal
                     · carga los 3 mapas en segundo plano
                     · precalienta shaders mostrando cada modelo una vez

Menú ─► PLAY ─► fundido a negro, se monta el mapa ─► partida
                                                     ├─ pausa (botón II, botón atrás, app en segundo plano)
                                                     ├─ muerte ─► Resultados (derrota): reintentar / tienda / menú
                                                     └─ boss muerto ─► Resultados (mapa superado) ─► siguiente mapa
                                                                       └─ mapa 3 ─► Victoria ─► menú
```

Toda esta orquestación está en [`main.gd`](../main.gd).

## Escena principal (`main.tscn`)

| Nodo | Función |
|---|---|
| `Main` (Node3D, `process_mode = ALWAYS`) | Script `main.gd`. Sigue procesando en pausa para gestionar menús |
| `MapContainer` (pausable) | Aquí se instancia el mapa actual |
| `ArrowContainer` (pausable) | Flechas disparadas por el player |
| `Camera3D` | Sigue al player en x/z desde `_physics_process` de `main.gd` |
| `HUD` (Control, `ALWAYS`, tema `ui_theme.tres`) | `GameHUD`, `MainMenu`, `Shop`, `PauseMenu`, `Results`, `Achievements`, `AchievementToast`, `Splash`, `fade` |

El player se instancia como hijo de `Main` con `process_mode = PAUSABLE` (si no, heredaría `ALWAYS` y seguiría corriendo en pausa).

## Autoloads

| Nombre | Script | Función |
|---|---|---|
| `Progreso` | [`scripts/progreso.gd`](../scripts/progreso.gd) | Oro, mejoras, dificultad, mapas superados, guardado. Ver [progreso-y-tienda.md](progreso-y-tienda.md) |
| `Logros` | [`scripts/logros.gd`](../scripts/logros.gd) | Logros, estadísticas totales y cronómetro del mapa. Ver [logros.md](logros.md) |
| `SignalLens` | addon | Depurador de señales del editor (pasivo) |

## Clases estáticas de configuración

| Clase | Archivo | Contenido |
|---|---|---|
| `Balance` | [`scripts/balance.gd`](../scripts/balance.gd) | Todos los números: enemigos, bosses, dificultad, tienda, puertas. Ver [balance.md](balance.md) |
| `Niveles` | [`scripts/niveles.gd`](../scripts/niveles.gd) | Diseño de cada mapa para el generador. Ver [mapas.md](mapas.md) |

`Balance` no depende de autoloads (guarda su propia `dificultad`, que sincroniza `Progreso`), para poder usarse en tests con `--script`.

## Estructura de carpetas

```
main.gd / main.tscn      orquestación del juego
fade.gd                  fundidos y pantalla negra
scripts/                 Balance, Niveles, Progreso
scenes/mapas/            mapas, generador, spawner, MeshBatcher
scenes/enemies/          Enemy, Boss, Caminante y Lanzador (bases) y cada enemigo por mapa (mapN/)
scenes/otros/            proyectiles: piedra del troll, Proyectil (bolas de los bosses) y su marca
scenes/player/           arquero
scenes/gui/              tema, HUD, menús, tienda, resultados, componentes
scenes/pickups/          moneda y puertas de mejora (panel)
scenes/Sides/            trozos de decorado lateral (30 m)
assets/                  modelos, texturas, fuentes, imágenes (icono, splash)
assets/naturaleza_simple/ árboles y arbustos del pack Nature con copas simplificadas (generados)
tools/                   fuera del juego: scripts de Blender (simplificar_copas.py, importar_modelos.py,
                         dragon_negro.py) y el simulador de balance (simular_balance.py)
docs/                    esta documentación
```

## Convenciones

- Comentarios e identificadores del juego en **español** (`vida`, `daño`, `recompensa`…); textos visibles en **inglés**.
- Los números de juego nunca van en las escenas ni en scripts sueltos: van en `Balance` o `Niveles`.
- Todo se valora en el móvil: ver [rendimiento.md](rendimiento.md) y [android.md](android.md).
