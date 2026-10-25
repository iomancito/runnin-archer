# Interfaz

Todas las pantallas están en `scenes/gui/` y cuelgan del nodo `HUD` de `main.tscn`, que aplica el tema común.

## Tema ([`scenes/gui/theme/ui_theme.tres`](../scenes/gui/theme/ui_theme.tres))

- Fuente **Nunito** (ExtraBold por defecto, Black en botones y títulos), en `assets/fonts/` (licencia OFL).
- Texto blanco con contorno oscuro para leerse sobre el 3D.
- Variaciones (`theme_type_variation`):

| Variación | Uso |
|---|---|
| `Button` (por defecto) | Botón de madera |
| `PrimaryButton` | Verde (PLAY, comprar, reanudar) |
| `DangerButton` | Rojo (resets, dificultad Hell) |
| `TitleLabel`, `HeaderLabel`, `SmallLabel`, `GoldLabel` | Títulos, cabeceras, textos secundarios, cantidades de oro |
| `PanelContainer` / `CardPanel` / `PillPanel` | Panel de madera, tarjeta, píldora oscura |
| `ProgressBar` / `HPBar` / `BossBar` | Barra dorada (distancia, carga), roja (vida), morada (boss) |
| `PipOn` / `PipOff` | Niveles de las tarjetas de la tienda |

El tema está generado por un script; para retocarlo es más cómodo editar el `.tres` desde el editor de temas de Godot.

## Escalado

`window/stretch/mode = canvas_items` + `aspect = expand` sobre 720×1280: la UI se escala a cualquier móvil y se adapta a pantallas más alargadas. Los márgenes superiores (48 px) evitan la barra de estado. El 3D se renderiza al 75 % (ver [rendimiento.md](rendimiento.md)); la UI siempre a resolución nativa.

## Pantallas

| Escena / script | Contenido | Señales |
|---|---|---|
| `Splash` (en `main.tscn`) | Imagen de inicio + barra "Loading %" | — |
| `main_menu.tscn` | Título, oro, mapa más lejano, selector de dificultad (las bloqueadas deshabilitadas, con pista para desbloquear la siguiente), PLAY / SHOP + ACHIEVEMENTS / CREDITS + EXIT, RESET PROGRESS | `play_pressed`, `shop_pressed`, `achievements_pressed`, `credits_pressed`, `exit_pressed` |
| `achievements.tscn` + `achievement_toast.gd` | Logros (pestañas GENERAL / CHALLENGES) y aviso al desbloquear. Ver [logros.md](logros.md) | `back_pressed` |
| `credits.tscn` | Créditos de terceros y licencia MIT de Godot (`Engine.get_license_text()`), con scroll. Ver [licencias.md](licencias.md) | `back_pressed` |
| `shop.tscn` + `shop_card.tscn` + `bow_card.tscn` | Pestañas UPGRADES (tarjetas de mejora, reset) y BOWS (arcos con imagen, habilidad, nivel y estado) | `back_pressed`, `arco_equipado` |
| `game_hud.tscn` | Vida, oro, barra de distancia al boss, barra del boss, botón de pausa, destello rojo al recibir daño | `pause_pressed` |
| `pause_menu.tscn` | RESUME / QUIT RUN | `resume_pressed`, `menu_pressed` |
| `results.tscn` | Derrota / mapa superado / victoria con distancia, bajas y oro | `next_pressed`, `retry_pressed`, `shop_pressed`, `menu_pressed` |
| `fade.tscn` (`fade.gd`) | Fundidos a negro (`fade_in`, `fade_out`, `mostrar_negro`) | — |

`pause_menu` y `results` heredan de `OverlayPanel` (`overlay_panel.gd`): fondo oscurecido y entrada animada del panel `%Panel`.

Componentes reutilizables en `scenes/gui/components/`: `gold_pill.tscn` (oro con rebote al ganar) y `coin_icon.gd` (moneda dibujada).

## Controles en el móvil

- Arrastrar el dedo a izquierda/derecha mueve al arquero (`Player._input`).
- **Pausa**: botón II del HUD, botón atrás de Android, o automática al salir de la app.
- **Botón atrás**: en la tienda, los logros o los créditos vuelve al menú; en partida pausa; en el menú cierra el juego.
- En el editor, el ratón emula el táctil, Enter pausa y Escape hace de botón atrás.

## Feedback en el mundo 3D

- "+N" dorado flotante al matar (`Enemy.popup_texto`), "-N" rojo al recibir golpes del boss.
- Número de vida de cada enemigo coloreado según si lo puedes matar.
- Las puertas muestran el valor de la mejora ("Damage +1").

## Pantalla de inicio e icono

- `assets/images/splash.png`: splash de arranque de Godot (`application/boot_splash`, modo *cover*, fondo negro) y fondo de la pantalla de carga. Se muestra al menos `SPLASH_MIN = 3 s` (en `main.gd`); después se oscurece y entra el menú con un fundido.
- Iconos en `assets/images/icons/` (ver [android.md](android.md)).

## Añadir una pantalla

1. Crear la escena en `scenes/gui/` con raíz `Control` a pantalla completa, sin fijar fuentes ni colores (los pone el tema).
2. Exponer señales para los botones; la lógica de navegación va en `main.gd`.
3. Instanciarla bajo `HUD` en `main.tscn` (antes de `Splash` y `fade`, que deben quedar encima).
4. Si se carga desde código (`load`/`preload`), añadirla a `export_files` del preset Android.
