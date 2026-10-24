# Running Archer

Runner vertical en Godot 4.7 para **móviles Android** (retrato, renderer Mobile). El arquero corre solo, el jugador lo mueve a los lados y dispara automáticamente; el oro de los enemigos compra mejoras permanentes. 3 mapas con boss final y 4 dificultades (superar los 3 mapas desbloquea la siguiente).

## Reglas del proyecto

- **Solo móvil**: ignorar Windows/Linux. Todo cambio se valora y se prueba en el móvil (táctil, rendimiento, tamaño del APK, botón atrás, app en segundo plano).
- **Números de juego solo en [`scripts/balance.gd`](scripts/balance.gd)** y diseño de mapas en [`scripts/niveles.gd`](scripts/niveles.gd); nunca en escenas o scripts sueltos.
- Comentarios e identificadores en **español**; textos visibles para el jugador en **inglés**.
- Escenas cargadas solo desde código (`load`/`preload`) → añadirlas a `export_files` del preset Android; **otros recursos** (imágenes, etc.) → a `include_filter`. Si no, faltarán en el APK.
- Optimizar según lo medido en el móvil: en su GPU (Mali-G57) cuestan los efectos a pantalla completa (glow, sombras), no los triángulos.

## Documentación

| Documento | Contenido |
|---|---|
| [docs/arquitectura.md](docs/arquitectura.md) | Flujo de la app, escena principal, autoloads, estructura de carpetas, convenciones |
| [docs/balance.md](docs/balance.md) | Fórmula de daño, enemigos, bosses, dificultades, precios de la tienda, puertas, cómo ajustar |
| [docs/mapas.md](docs/mapas.md) | Diseño de mapas, generador de enemigos, spawner, cómo añadir un mapa |
| [docs/enemigos.md](docs/enemigos.md) | Clases `Enemy` y `Boss`, cómo añadir un tipo de enemigo |
| [docs/arcos.md](docs/arcos.md) | Arcos especiales: habilidades, precios, compra, efectos visuales, cómo añadir un arco |
| [docs/progreso-y-tienda.md](docs/progreso-y-tienda.md) | Autoload `Progreso`, guardado y migraciones, tienda, resets |
| [docs/interfaz.md](docs/interfaz.md) | Tema, escalado, pantallas y señales, controles, splash, cómo añadir una pantalla |
| [docs/rendimiento.md](docs/rendimiento.md) | Medidas en el móvil, optimizaciones aplicadas, cómo medir |
| [docs/android.md](docs/android.md) | Herramientas, compilar e instalar, preset de exportación, icono, tests sin pantalla, adb |

## Comandos rápidos

```bash
G=/mnt/ARC100/Godot/Godot_v4.7.1-stable_linux.x86_64
A=~/Android/Sdk/platform-tools/adb
$G --headless --path . --import                                   # validar scripts / actualizar caché de clases
$G --headless --path . --export-debug "Android" /tmp/RunningArcher.apk
$A install -r /tmp/RunningArcher.apk
$A logcat -s godot:*
```

## Trampas conocidas

- `assets/externos/Nature/` es de solo lectura: `chmod u+w` antes de operaciones de git que la toquen y `chmod u-w` después.
- En tests con `--script` los autoloads no existen al compilar: no referenciar clases que usen `Progreso` (como `Boss`) desde el test.
- Cambiar el `Environment` en tiempo de ejecución recompila shaders: medir rendimiento con builds estáticas.
- El splash de arranque de Godot solo admite PNG.
- `export_files` solo admite escenas: los PNG listados ahí se ignoran.
- Escenas copiadas de otro proyecto: quitar los `uid` de sus `ext_resource` o el exportador no incluirá sus dependencias.
- Con el **ahorro de batería** del móvil activo la CPU va a menos de la mitad: las medidas de tiempo no son comparables.
