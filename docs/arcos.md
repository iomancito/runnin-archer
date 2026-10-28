# Arcos especiales

Además del arco original hay 4 arcos con una habilidad propia. Cada uno se compra en la tienda (pestaña **BOWS**) después de superar los 3 mapas de su dificultad.

## Reglas

- **Un solo arco a la vez.** Comprar el arco equipado lo sube de nivel (máximo `ARCO_NIVEL_MAX = 5`).
- Comprar **otro** arco lo equipa en nivel 1 y **se pierden las mejoras del anterior**. La tienda pide un segundo toque ("TAP AGAIN: LOSE …").
- El arquero usa el modelo del último arco comprado; con el original se ve `arco1` (y el arco integrado del modelo).
- Modelos del "3D Fantasy Bows Pack" (CC0, `/mnt/D2T/GodotRecursos/models3d/bows`): `arco1` Ranger's Yew Longbow, `arco2` Paladin's Sun Bow, `arco3` Thorn Bramble Bow, `arco4` Dragon-Rib Greatbow, `arco5` Frost Ice Bow.
- Un arco superior es mejor a igual nivel, pero un arco inferior mejorado puede superarlo (por ejemplo Thorn nivel 5 atraviesa filas enteras, Sunfire nivel 1 apenas alcanza al carril vecino). La excepción es Dragonbone: ya al nivel 1 iguala o supera a Storm al nivel 5, y solo él permite los logros del mapa 3 de Hell.

## Los arcos

| Arco | Modelo | Se compra tras | Habilidad (nivel 1 → 5) | Daño | Precio (nivel 1 → 5) |
|---|---|---|---|---|---|
| **Thorn Bow** | `arco3` (zarzas con espinas) | Easy | **Perforación**: atraviesa 1 → 5 enemigos | ×1,10 → ×1,30 | 150 → 983 |
| **Sunfire Bow** | `arco2` (dorado con un sol) | Medium | **Explosión**: radio 1,5 → 2,5 m, 40 % → 100 % del daño a los de alrededor | ×1,20 → ×1,40 | 400 → 2621 |
| **Storm Bow** | `arco5` (hielo azul) | Hard | **Rayo en cadena** a 2 → 6 enemigos en 7 m con el 50 % → 90 % del daño; cadencia ×1,15 | ×1,30 → ×1,50 | 1000 → 6554 |
| **Dragonbone Bow** | `arco4` (costillas de dragón) | Hell | **Todo a la vez**: atraviesa 2 → 6 enemigos; explosión de fuego de 2 → 3 m (llega al carril de al lado) con el 60 % → 100 % del daño; quema 3 s al objetivo y a los de la explosión con el 50 % → 110 % del daño por segundo; +50 % → +150 % contra bosses; cadencia ×1,20 → ×1,40 | ×2,00 → ×3,00 | 2500 → 16384 |

Los números están en `Balance.ARCOS` ([`scripts/balance.gd`](../scripts/balance.gd)). Cada parámetro es `[valor a nivel 1, suma por nivel]`, y `Balance.arco_valor(id, clave, nivel)` lo calcula. Precio: `coste[0] × coste[1]^(nivel-1)`.

## Para qué sirve cada arco

Cada arco se compra al superar una dificultad y está pensado para la siguiente, que trae las formaciones donde brilla (ver [balance.md](balance.md)):

- **Thorn** (tras Easy) → Medium trae **columnas** (fila india en un carril): la flecha atraviesa a los de detrás.
- **Sunfire** (tras Medium) → Hard trae más **hordas**: la explosión daña a los vecinos de la rejilla (1,3 × 1,6 m).
- **Storm** (tras Hard) → Hell es lo más denso (hordas ×1,6, columnas ×1,2): el rayo salta entre grupos.
- **Dragonbone** (tras Hell) → el arco final y el mejor con diferencia: reúne perforación, explosión y fuego. Su explosión llega al carril de al lado, así que mata filas enteras aunque se corra a la máxima velocidad. Al nivel 5 y con la tienda al máximo permite **todos los logros de Hell** (Exterminator, Swift Hunter y Perfect Hunt de los 3 mapas, Hell's Ghost, Lone Wolf); el más difícil, Exterminator / Perfect Hunt del mapa 3, sale en ~1 de cada 3 intentos. Con Storm al nivel 5 es imposible (0 %).

Simulación (`python3 tools/simular_balance.py --fin`), Hell con la tienda al máximo, % de intentos por mapa:

| | Exterminator / Perfect Hunt (mapa 1 / 2 / 3) | Sin daño (mapa 1 / 2 / 3) | Lone Wolf mapa 3 |
|---|---|---|---|
| Storm nivel 5, jugador bueno | 100 / 98 / 0 | 5 / 1 / 0 | 2 |
| Dragonbone nivel 1, bueno | 100 / 47 / 0 | 30 / 14 / 1 | 34 |
| Dragonbone nivel 3, bueno | 100 / 100 / 0 | 59 / 29 / 7 | 73 |
| Dragonbone nivel 5, bueno | 100 / 100 / 36 | 62 / 51 / 30 | 95 |
| Dragonbone nivel 5, medio | 100 / 100 / 36 | 46 / 28 / 6 | 50 |

## Cómo funciona

| Pieza | Archivo | Función |
|---|---|---|
| Datos y textos | `Balance.ARCOS`, `arco_valor()`, `arco_coste()`, `arco_descripcion()` | Parámetros, precios y descripción para la tienda |
| Estado | `Progreso.arco`, `arco_nivel`, `completadas` | Arco equipado, nivel y dificultades superadas (cada una habilita su arco) |
| Compra | `Progreso.comprar_arco(id)` | Sube de nivel o cambia de arco, cobra y guarda |
| Stats de partida | `Progreso.stats_partida()` | Copia de las mejoras con `arco`, `arco_nivel` y la cadencia del arco |
| Modelo | `Player._ready()` → `set_bow(modelo)` | Muestra el modelo del arco y oculta el arco integrado |
| Habilidades | [`arrow_normal.gd`](../assets/weapons/arrow_normal.gd) | Daño del arco, perforación (Thorn y Dragonbone, clave `perfora`), explosión, cadena, quemadura (Dragonbone: al objetivo y a los de su explosión) y bonus contra bosses al impactar |
| Quemadura | `Enemy.quemar(dps, segundos)` | Temporizador de 0,5 s que se detiene en pausa |
| Efectos visuales | [`scenes/player/arco_efectos.gd`](../scenes/player/arco_efectos.gd) | Pool de efectos, búsqueda de enemigos cercanos (grupo `enemigos`) |
| Tienda | [`shop.gd`](../scenes/gui/shop.gd), [`bow_card.tscn`](../scenes/gui/bow_card.tscn) | Pestañas UPGRADES / BOWS y tarjetas de arco |
| Modelos e imágenes | `assets/weapons/arcoN.glb`, `assets/images/bows/*.png` | [`tools/preparar_armas.py`](../tools/preparar_armas.py) (Blender) orienta cada arco del pack como el que sustituye, renderiza la imagen con el modelo completo y exporta una versión de 4000 triángulos y texturas de 512/256. El contorno dorado de las imágenes se añade con ImageMagick (`-morphology Dilate Disk:6`, color `#e8c66a`) |

Al vencer al boss del mapa 3 por primera vez en una dificultad, la pantalla de victoria anuncia el arco nuevo.

## Efectos visuales

Efectos de **BinbunVFX Vol.2** (CC0, en `assets/BinbunVFX_Vol2/`, origen `/mnt/D2T/GodotRecursos/vfx`):

| Habilidad | Efecto |
|---|---|
| Explosión | `ExplosionFX/effects/ground/vfx_ground_explosion_01` (más pequeña, humo color fuego y más rápida) |
| Rayo | `ElectricFX/effects/zap/vfx_zap_lightning_01` sobre cada enemigo + línea azul del salto |
| Llamarada al impactar | `ElementalMagicFX/effects/cast/vfx_fire_cast_01` |
| Enemigo ardiendo | `ElementalMagicFX/effects/area/vfx_fire_area_01` (máximo 8 a la vez) |

Adaptaciones hechas al copiarlos:

- Sus `OmniLight3D` se apagan (cada luz dinámica cuesta en el móvil).
- Las `NoiseTexture2D` se convirtieron en PNG (`textures/noise_*.png`) para no generarlas al cargar.
- Se quitaron los `uid` de sus `ext_resource`: eran del proyecto original y Godot no exportaba los shaders.
- Se reutilizan en un pool (`TAM_POOL = 6` por efecto).

Las partículas tardan ~1-2 s en compilarse en el móvil la primera vez. Por eso solo se precalientan **los efectos del arco equipado** (al arrancar, en `Mapa.precalentar`) y los de un arco recién comprado (en la tienda, con `Main._precalentar_arco`, tapados por la propia tienda).

## Añadir un arco

1. Añadir la entrada en `Balance.ARCOS` y su id en `ORDEN_ARCOS`.
2. Añadir su texto en `Balance.arco_descripcion()` y su habilidad en `Normal_Arrow._habilidades()`.
3. Si tiene efecto nuevo: función en `ArcoEfectos` y caso en `ArcoEfectos.precalentar()`; si es una escena, añadirla a `export_files`.
4. Render del icono en `assets/images/bows/<id>.png` (ya entra por `include_filter`).

## Cambiar el modelo de un arco

1. Elegir el `.glb` del pack y ponerlo en `ARCOS` de [`tools/preparar_armas.py`](../tools/preparar_armas.py).
2. Copiar los `arcoN.glb` y `arrow.glb` actuales (de git) a `<renders>/viejos/`: son la referencia de orientación, tamaño y posición de la empuñadura.
3. `blender -b --python tools/preparar_armas.py -- <carpeta del pack> <renders> <Skeleton_Arrow.gltf>`.
4. Añadir el contorno a los renders y dejarlos en `assets/images/bows/` (256×256).
5. Comprobarlo en la mano del arquero: la colocación de `arcoN` en `player.tscn` no cambia.
