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
- Lista `export_files`: `main.tscn`, los 3 mapas, `panel.tscn`, `zombi_escupidor.tscn`, la piedra `Pebble_Square_3.gltf` (proyectil del troll), `shop_card.tscn`, `bow_card.tscn`, los 4 efectos de BinbunVFX, `icon.svg`.
- `include_filter`: `*.gd,assets/images/bows/*.png`.

> **Importante:** Godot no sigue los `load()`/`preload()` de los scripts al calcular dependencias. Lo que **solo se cargue desde código** hay que añadirlo a mano, o en el móvil faltará (pasó con `shop_card.tscn`: pantalla negra):
> - **escenas** → `export_files` (esta lista **solo admite escenas**: los PNG puestos ahí se ignoran);
> - **otros recursos** (imágenes…) → `include_filter`.
>
> Tras instalar, buscar `does not exist` o `No loader found` en logcat.
>
> Escenas copiadas de otro proyecto (como los efectos de BinbunVFX) traen `uid` de ese proyecto en sus `ext_resource`: en el editor funcionan por la ruta, pero el exportador no incluye sus dependencias. Hay que quitar esos `uid`.

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

Las coordenadas de los botones del menú cambian si se añaden elementos: comprobar con una captura antes de automatizar toques (ahora PLAY está en y≈1437 y SHOP en y≈1640).

Para probar con una partida concreta sin perder la del móvil: copiar `files/save.json`, escribir la de prueba con ruta absoluta y restaurarla al terminar:

```bash
F=/data/data/com.example.runningarcher/files/save.json
$A shell run-as com.example.runningarcher cat $F > copia.json
echo '{...}' | $A shell "run-as com.example.runningarcher sh -c 'cat > $F'"
cat copia.json | $A shell "run-as com.example.runningarcher sh -c 'cat > $F'"
```

El **ahorro de batería** (`adb shell settings get global low_power` = 1) limita la CPU a menos de la mitad: el arranque pasa de ~7 s a ~15-19 s. Tenerlo en cuenta al medir.

## Carpeta de solo lectura

`assets/externos/Nature/` está en solo lectura (NTFS). Git necesita escribir en la carpeta para reemplazar archivos (cambiar de rama, merge…):

```bash
chmod u+w assets/externos/Nature   # antes
chmod u-w assets/externos/Nature   # después
```
