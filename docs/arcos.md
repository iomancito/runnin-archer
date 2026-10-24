# Arcos especiales

Además del arco original hay 4 arcos con una habilidad propia. Cada uno se compra en la tienda (pestaña **BOWS**) después de superar los 3 mapas de su dificultad.

## Reglas

- **Un solo arco a la vez.** Comprar el arco equipado lo sube de nivel (máximo `ARCO_NIVEL_MAX = 5`).
- Comprar **otro** arco lo equipa en nivel 1 y **se pierden las mejoras del anterior**. La tienda pide un segundo toque ("TAP AGAIN: LOSE …").
- El arquero usa el modelo del último arco comprado; con el original se ve `arco1` (y el arco integrado del modelo).
- Un arco superior es mejor a igual nivel, pero un arco inferior mejorado puede superarlo (por ejemplo Thorn nivel 5 atraviesa filas enteras, Sunfire nivel 1 apenas alcanza al carril vecino).

## Los arcos

| Arco | Modelo | Se compra tras | Habilidad (nivel 1 → 5) | Daño | Precio (nivel 1 → 5) |
|---|---|---|---|---|---|
| **Thorn Bow** | `arco3` (púas) | Easy | **Perforación**: atraviesa 1 → 5 enemigos | ×1,10 → ×1,30 | 150 → 983 |
| **Sunfire Bow** | `arco2` (llamas) | Medium | **Explosión**: radio 1,5 → 2,5 m, 40 % → 100 % del daño a los de alrededor | ×1,20 → ×1,40 | 400 → 2621 |
| **Storm Bow** | `arco5` (gemas azules) | Hard | **Rayo en cadena** a 2 → 6 enemigos en 7 m con el 50 % → 90 % del daño; cadencia ×1,15 | ×1,30 → ×1,50 | 1000 → 6554 |
| **Dragonbone Bow** | `arco4` (hueso) | Hell | **Fuego**: quema 3 s con el 40 % → 100 % del daño por segundo; +30 % → +90 % contra bosses | ×1,50 → ×1,70 | 2500 → 16384 |

Los números están en `Balance.ARCOS` ([`scripts/balance.gd`](../scripts/balance.gd)). Cada parámetro es `[valor a nivel 1, suma por nivel]`, y `Balance.arco_valor(id, clave, nivel)` lo calcula. Precio: `coste[0] × coste[1]^(nivel-1)`.

## Cómo funciona

| Pieza | Archivo | Función |
|---|---|---|
| Datos y textos | `Balance.ARCOS`, `arco_valor()`, `arco_coste()`, `arco_descripcion()` | Parámetros, precios y descripción para la tienda |
| Estado | `Progreso.arco`, `arco_nivel`, `completadas` | Arco equipado, nivel y dificultades superadas (cada una habilita su arco) |
| Compra | `Progreso.comprar_arco(id)` | Sube de nivel o cambia de arco, cobra y guarda |
| Stats de partida | `Progreso.stats_partida()` | Copia de las mejoras con `arco`, `arco_nivel` y la cadencia del arco |
| Modelo | `Player._ready()` → `set_bow(modelo)` | Muestra el modelo del arco y oculta el arco integrado |
| Habilidades | [`arrow_normal.gd`](../assets/weapons/arrow_normal.gd) | Daño del arco, perforación, explosión, cadena, quemadura y bonus contra bosses al impactar |
| Quemadura | `Enemy.quemar(dps, segundos)` | Temporizador de 0,5 s que se detiene en pausa |
| Efectos visuales | [`scenes/player/arco_efectos.gd`](../scenes/player/arco_efectos.gd) | Pool de efectos, búsqueda de enemigos cercanos (grupo `enemigos`) |
| Tienda | [`shop.gd`](../scenes/gui/shop.gd), [`bow_card.tscn`](../scenes/gui/bow_card.tscn) | Pestañas UPGRADES / BOWS y tarjetas de arco |
| Imágenes | `assets/images/bows/*.png` | Renders de los modelos con Blender (contorno dorado) |

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
