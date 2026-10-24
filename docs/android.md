# Android: compilar, instalar y probar

El juego solo se publica para **móviles Android** (no se mantienen builds de Windows/Linux). Todo cambio se valida en el móvil.

## Herramientas

| Herramienta | Ruta |
|---|---|
| Godot 4.7.1 | `/mnt/ARC100/Godot/Godot_v4.7.1-stable_linux.x86_64` |
| Plantillas de exportación | `~/.local/share/godot/export_templates/4.7.1.stable/` (`android_debug.apk`, `android_release.apk`, `android_source.zip`) |
| Android SDK / adb | `~/Android/Sdk` · `~/Android/Sdk/platform-tools/adb` |
| JDK | `/usr/lib/jvm/java-25-openjdk` (configurado en *Editor Settings*) |
| Keystore de depuración | `~/.local/share/godot/keystores/debug.keystore` (alias `androiddebugkey`, clave `android`) |

## Compilar e instalar

```bash
G=/mnt/ARC100/Godot/Godot_v4.7.1-stable_linux.x86_64
A=~/Android/Sdk/platform-tools/adb
$G --headless --path . --export-debug "Android" /tmp/RunningArcher.apk
$A install -r /tmp/RunningArcher.apk
$A shell monkey -p com.example.runningarcher -c android.intent.category.LAUNCHER 1   # abrir
$A logcat -s godot:*                                                                   # ver errores
```

- Desde el editor también funciona el botón de *one-click deploy* de Android.
- Tras añadir scripts con `class_name` nuevos, ejecutar antes `$G --headless --path . --import` para actualizar la caché de clases.
- Paquete: `com.example.runningarcher` (cambiar `package/unique_name` antes de publicar en Google Play, que no acepta `com.example`).

## Preset de exportación (`export_presets.cfg`)

- Solo `arm64-v8a`.
- **Exporta solo las escenas necesarias** (`export_filter="scenes"`) más todos los `*.gd` (`include_filter`). El APK pasó de 440 MB a ~86 MB.
- Lista `export_files`: `main.tscn`, los 3 mapas, `panel.tscn`, `Piedra.tscn`, `shop_card.tscn`, `icon.svg`.

> **Importante:** Godot no sigue los `load()`/`preload()` de los scripts al calcular dependencias. Cualquier escena o recurso que **solo se cargue desde código** debe añadirse a `export_files`, o en el móvil faltará (pasó con `shop_card.tscn`: pantalla negra). Tras instalar, buscar `does not exist` en logcat.

## Icono y pantalla de inicio

- Imagen original: `/home/ioman/Imágenes/imagenes-video/running-archer/logo.png` (941×1672).
- `project.godot`: `config/icon` → `assets/images/icons/icon.png`; `boot_splash/image` → `assets/images/splash.png` (el splash de Godot **solo admite PNG**), `stretch_mode = 4` (cover), fondo negro.
- Preset: `launcher_icons/main_192x192`, `adaptive_foreground_432x432`, `adaptive_background_432x432`. En los iconos adaptativos el sistema solo muestra el 66 % central, por eso esas capas usan un recorte 1,5× más amplio.

## Pruebas automáticas sin pantalla

Scripts de test `extends SceneTree` ejecutados con:

```bash
$G --headless --path . --script /ruta/test.gd
```

- Cargar `res://main.tscn` con `change_scene_to_file` y esperar ~1 s; acceder a autoloads con `root.get_node("Progreso")`.
- En modo `--script` los autoloads no existen al compilar el test: no referenciar desde el test clases que usen `Progreso` (p. ej. `Boss`); usar `has_method()`.
- Sin pantalla, `VisibleOnScreenEnabler3D` desactiva a los enemigos: para probar combate, forzar `process_mode = ALWAYS`.
- La partida de prueba se guarda en `~/.local/share/godot/app_userdata/RunningArcher/save.json`; bórrala al terminar.

## Probar en el móvil con adb

```bash
$A exec-out screencap -p > captura.png          # captura
$A shell input tap X Y                          # tocar (coordenadas de 1080×2400)
$A shell input keyevent 4                       # botón atrás
$A shell run-as com.example.runningarcher cat files/save.json   # leer el guardado
```

Las coordenadas de los botones del menú cambian si se añaden elementos: comprobar con una captura antes de automatizar toques.

## Carpeta de solo lectura

`assets/externos/Nature/` está en solo lectura (NTFS). Git necesita escribir en la carpeta para reemplazar archivos (cambiar de rama, merge…):

```bash
chmod u+w assets/externos/Nature   # antes
chmod u-w assets/externos/Nature   # después
```
