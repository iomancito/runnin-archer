# Música

Autoload `Musica` ([`scripts/musica.gd`](../scripts/musica.gd)). Toca una pista cada vez en el bus `Music` (lo crea si no existe), con fundido cruzado entre dos `AudioStreamPlayer`. Procesa siempre, así que suena también en pausa y en los resultados. El volumen del bus lo pone `Ajustes` (`Musica.volumen`, 0 = silencio; ver [ajustes.md](ajustes.md)) y con el menú de pausa abierto baja `PAUSA_DB` más.

## Pistas

Archivos en `assets/musica/<archivo>.ogg` (incluidos en el APK con `include_filter`). Si falta uno se usa su alternativa; si no hay ninguna, se apaga la música.

| Pista | Archivo (origen) | Cuándo | Bucle |
|---|---|---|---|
| `menu` | `menu.ogg` (`menu_principal.mp3`) | Al salir de la pantalla de carga y al volver al menú | sí |
| `tienda` | `tienda.ogg` (`menu_mejoras.mp3`) | Tienda, logros | sí |
| `creditos` | `final.ogg` | Créditos | sí |
| `mapa1`…`mapa3` | `mapaN.ogg` (`mapN.mp3`) | Al empezar cada mapa | sí |
| `boss1`…`boss3` | `bossN.ogg` (`red_dragon`, `black_dragon`, `skeleton_dragon`) | Cuando el player deja de disparar antes del dragón (cambio de cámara) | sí |
| `victoria` | `victoria.ogg` | Mapa 1 o 2 superado | no |
| `derrota` | `derrota.ogg` (`Game Over.mp3`) | Muerte | no |
| `final` | `final.ogg` (`victoria_final.mp3`) | Mapa 3 superado | no |

Hay además una pista `boss` (común) sin archivo, alternativa de `boss1`…`boss3`.

La pantalla de resultados no deja pulsar sus botones hasta un toque nuevo (ver [interfaz.md](interfaz.md)), así que los jingles de victoria y derrota no se cortan al instante.

## Duraciones

Recorrer un mapa (1000 m) lleva **~300 s a Run Speed base (200)** y **~200 s al máximo (300)**, igual en los tres mapas y todas las dificultades. Las pistas de mapa (78-186 s) se repiten. Un combate con boss dura de unos segundos a 1-2 min.

## Convertir las canciones

[`tools/convertir_musica.sh`](../tools/convertir_musica.sh) `[carpeta]` (por defecto `~/Música/running_archer/`) genera todos los OGG:

- Pistas en bucle: los últimos 2,5 s se mezclan con los primeros y el archivo empieza en 2,5 s, así el final enlaza sin corte con el principio. El bucle se activa desde código (`Musica._carga`), no hace falta marcarlo al importar.
- Jingles: tal cual, con un fundido de 1 s al final.
- OGG Vorbis calidad 1 (~80 kbps): ~12 MB las 11 pistas.

Para cambiar una canción: sustituir el MP3, revisar la tabla del script y volver a ejecutarlo. Licencia: ver [licencias.md](licencias.md).
