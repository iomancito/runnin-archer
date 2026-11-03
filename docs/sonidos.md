# Efectos de sonido

Autoload `Sonidos` ([`scripts/sonidos.gd`](../scripts/sonidos.gd)): `Sonidos.toca("nombre")`. Suenan en el bus `Effects`, cuyo volumen pone `Ajustes` (ver [ajustes.md](ajustes.md)).

- Un `AudioStreamPlayer` por efecto, sin posición 3D (la cámara va pegada al player), con `max_polyphony` = voces y un `AudioStreamRandomizer` que elige variante y varía el tono.
- `intervalo`: segundos mínimos entre dos del mismo efecto. Evita la avalancha de disparos, impactos, bajas y monedas en las hordas.
- Los de partida solo suenan con `Sonidos.en_partida` (lo pone `main.gd` al empezar y acabar la partida): así no suenan los precalentados de la carga ni de la tienda. Los de interfaz (`"interfaz": true`) suenan siempre, también en pausa.
- Todos los botones hacen clic sin conectar nada: `Sonidos` escucha `node_added` y, al acabar su primer frame, conecta también los que ya existen (al arrancar, Godot mete la escena principal en el árbol **antes** del `_ready` de los autoloads, así que sus botones no pasan por `node_added`). Los que se llaman `BackButton` suenan a "atrás", y tocar un botón desactivado (sin oro para comprar, dificultad bloqueada) suena a error.

## Lista

| Efecto | Cuándo | Dónde |
|---|---|---|
| `disparo` (3 variantes) | Cada disparo (uno por andanada, no por flecha) | `Player.attack()` |
| `impacto` (3) | Flecha que golpea a un enemigo | `arrow_normal.gd` |
| `muerte` (2) | Muere un enemigo | `Enemy.die()` |
| `moneda` | Oro de una baja | `Enemy.recompensa()` |
| `explosion` (2) | Sunfire y Dragonbone al impactar; bolas de fuego de los dragones rojo y negro al caer | `arrow_normal.gd`, `Proyectil._impacto()` |
| `rayo` | Storm Bow al encadenar | `arrow_normal.gd` |
| `puerta` | Coger una puerta de mejora | `PanelSkills` |
| `herido` / `muerte_jugador` | El player recibe daño / muere | `Player.recibe_daño()` |
| `bola_fuego`, `magia`, `acido`, `piedra` | Lanzamiento de proyectiles enemigos (por estilo, `Sonidos.PROYECTILES`) | `Proyectil._ready()` |
| `salpicadura`, `impacto_magia`, `golpe_piedra` | Impacto de esos proyectiles | `Proyectil._impacto()` |
| `rugido` | Empieza el combate con el boss | `Boss` |
| `muerte_boss` | Muere el boss | `Boss.die()` |
| `click`, `atras` | Cualquier botón / BACK | automático |
| `compra` / `error` | Compra en la tienda / no se puede | `shop.gd`, botones desactivados |
| `logro` | Aviso de logro desbloqueado | `achievement_toast.gd` |

## Generar los sonidos

[`tools/generar_sonidos.py`](../tools/generar_sonidos.py) los sintetiza (numpy y scipy) y escribe `assets/sonidos/*.wav` (mono, 44,1 kHz; ~1,5 MB, Godot los comprime en QOA al importar).

**Volumen pensado para el altavoz del móvil**, que casi no reproduce nada por debajo de ~900 Hz: el script normaliza cada sonido a la misma sonoridad medida por encima de 900 Hz (−14 dB, RMS de los 100 ms más fuertes; pico limitado a −1 dBFS) y los sonidos llevan contenido en 1-5 kHz aunque sean graves (clics a 1,8 kHz, chasquido en los impactos, crepitar en explosiones y rocas). La música, medida igual, da ~−25 dB. Con los volúmenes de `EFECTOS`, los clics quedan a ~−17 (por encima de la música), los sonidos constantes (disparo, moneda) a ~−22/−24 y los grandes momentos a ~−14. Cada sonido es una función: cuerda pulsada (Karplus-Strong) para el arco, ruido filtrado para golpes, soplidos y explosiones, campanas inarmónicas para monedas y logros, diente de sierra por formantes para los rugidos. Son propios: no hay licencia que cumplir.

## Ajustar o añadir

- **Volumen relativo, variación de tono, voces e intervalo**: en `Sonidos.EFECTOS`, sin regenerar.
- **El sonido en sí**: cambiar su función en el script y ejecutar `python3 tools/generar_sonidos.py`.
- **Uno nuevo**: función en el script + llamada en `main()`, entrada en `EFECTOS` y `Sonidos.toca("nombre")` donde ocurra. Los WAV ya entran en el APK (`assets/sonidos/*.wav` en `include_filter`).
