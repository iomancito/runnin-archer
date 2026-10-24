# Balance

Todos los números de juego están en [`scripts/balance.gd`](../scripts/balance.gd) (clase estática `Balance`). Para ajustar dificultad, precios o daño **solo hay que tocar ese archivo**.

## La fórmula base

Un enemigo se puede alcanzar desde que entra en el alcance de las flechas hasta que llega al player, así que el daño que le hace el player antes de chocar es:

```
daño por enemigo = (alcance / velocidad de carrera) × cadencia × daño × flechas
```

- Velocidad de carrera base: `p_speed = 200` → 200/60 = **3,33 m/s** (la velocidad se multiplica por `delta` de física).
- Con los stats base: (10 m / 3,33) × 1,0 × 1 × 1 ≈ **3** de daño por enemigo.
- Con la tienda al máximo: (30 / 3,33) × 2,0 × 11 × 5 ≈ **990**.

El color del número de vida de cada enemigo usa esta misma fórmula (`Enemy.threat_color()`): **verde** = lo mata, **amarillo** = le hace al menos la mitad, **rojo** = mejor esquivar.

## Enemigos (`ENEMIGOS`)

Valores en el mapa 1, al inicio del recorrido, dificultad media:

| Tipo | Vida | Daño al chocar | Oro |
|---|---|---|---|
| `goblin` | 2 | 2 | 1 |
| `orc` | 5 | 3 | 2 |
| `troll` | 14 | 5 | 4 |
| `ogre` (mini jefe mapa 1/3) | 30 | 8 | 10 |
| `zombie` | 4 | 2 | 1 |
| `brute` (mini jefe mapa 2) | 25 | 6 | 8 |

- La vida crece con la distancia: `× (1 + z × VIDA_POR_METRO)` → ×1 al inicio, ×3,5 a los 1000 m.
- `ROCA_TROLL_DAÑO = 4`: daño de la piedra que lanza el troll.
- El daño al chocar es fijo por tipo (antes era la vida restante del enemigo). Chocar mata al enemigo pero **no da oro**.

## Multiplicadores por mapa (`MAPAS`)

`[vida, daño, oro]`: mapa 1 `[1, 1, 1]`, mapa 2 `[3, 1,5, 1,5]`, mapa 3 `[7, 2, 2]`.

## Bosses

| | Valor (mapa 1, medio) |
|---|---|
| `BOSS_VIDA` | 350 |
| `BOSS_DAÑO` | 3 por ataque |
| `BOSS_INTERVALO` | 2,5 s entre ataques |
| `BOSS_ORO` | 100 |

Se multiplican por mapa y por dificultad igual que los enemigos. Al tocar al boss el player se para y empieza el combate (ver [enemigos.md](enemigos.md)).

## Dificultad (`DIFICULTADES`)

| | Vida | Daño | Densidad | Oro | Intervalo boss | Hordas |
|---|---|---|---|---|---|---|
| `easy` | ×0,6 | ×0,5 | ×0,75 | ×0,6 | ×1,3 | no |
| `medium` | ×1 | ×1 | ×1 | ×1 | ×1 | no |
| `hard` | ×1,7 | ×1,5 | ×1,25 | ×1,6 | ×0,9 | ×1 |
| `hell` | ×3 | ×2,5 | ×1,5 | ×2,5 | ×0,75 | ×1,6 |

- **Densidad** divide la separación entre filas de enemigos del generador (más densidad = más enemigos).
- **Hordas** divide la separación entre hordas del mapa (0 = sin hordas). Ver abajo.
- Más dificultad da más oro, para que merezca la pena rejugar.
- La dificultad elegida se guarda en `Progreso.dificultad` y se copia a `Balance.dificultad`; `Balance.dif()` devuelve sus multiplicadores.
- Se empieza solo con Easy; superar los 3 mapas en una dificultad desbloquea la siguiente (ver [progreso-y-tienda.md](progreso-y-tienda.md)).

Resultado aproximado (generador, 20 partidas de media; oro si mata a todos, sin contar bosses):

| | Easy | Medium | Hard | Hell |
|---|---|---|---|---|
| Enemigos mapa 1 (de ellos en hordas) | 66 | 87 | 180 (89) | 251 (152) |
| Oro mapa 1 | 94 | 199 | 426 | 737 |
| Máximo de enemigos vivos a la vez, mapa 1 | 13 | 17 | 40 | 63 |
| Boss mapa 1: vida / golpe | 210 / 2 cada 3,2 s | 350 / 3 cada 2,5 s | 595 / 5 cada 2,2 s | 1050 / 8 cada 1,9 s |
| Enemigos mapa 2 (de ellos en hordas) | 87 | 120 | 226 (97) | 284 (152) |
| Boss mapa 2: vida / golpe | 630 / 3 cada 3,2 s | 1050 / 5 cada 2,5 s | 1785 / 7 cada 2,2 s | 3150 / 12 cada 1,9 s |

## Hordas (`HORDA`)

En Hard y Hell aparecen grupos compactos de enemigos débiles (goblins en los mapas 1 y 3, zombis en el 2) pegados a una pared, con al menos 2 carriles libres para esquivarlos. Cada miembro tiene los valores de su tipo multiplicados por `HORDA` (vida, daño y oro ×0,5): con los stats base hay que esquivarlas; con varias flechas o un arco especial (perforar, explosión, rayo) se barren y dan mucho oro. Dónde y cómo son: `hordas` en [`niveles.gd`](../scripts/niveles.gd) (ver [mapas.md](mapas.md)).

## Tienda (`tienda()`)

Cada entrada: `[nombre (clave de guardado), título, formato, stat, incremento, costes por nivel]`. Los costes se generan con `costes(base, crecimiento, niveles)` = `base × crecimiento^nivel`.

| Mejora | Stat | Por nivel | Niveles | Primer → último precio |
|---|---|---|---|---|
| Damage | `f_daño` | +1 | 10 | 12 → 248 |
| Fire Rate | `p_attack_speed` | +0,1/s | 10 | 12 → 248 |
| Arrows | `f_cantidad` | +1 | 4 | 50 / 150 / 400 / 900 |
| Max HP | `p_vida` | +5 | 10 | 8 → 165 |
| Range | `f_max_distancia` | +2 m | 10 | 8 → 165 |
| Dodge Speed | `p_side_speed` | +10 | 10 | 6 → 124 |
| Gold Bonus | `p_oro` | +10 % | 10 | 15 → 310 |

Total para maximizar todo: ~5750 de oro. Un mapa 1 completo en medio da ~300.

> Cambiar el `nombre` de una mejora rompe los niveles guardados (se guardan por nombre). Si se cambia la tienda de forma incompatible, añade una migración en `Progreso` (ver [progreso-y-tienda.md](progreso-y-tienda.md)).

## Arcos especiales (`ARCOS`)

4 arcos con habilidad propia, comprables tras superar cada dificultad. Valores, precios y reglas en [arcos.md](arcos.md).

## Puertas de mejora durante la partida (`PUERTAS`)

`[texto, stat, incremento]`: Damage +1, Fire rate +0,15/s, Arrows +1, Range +3 m, Dodge speed +15, Max HP +10 (también cura). `MAX_FLECHAS = 7` limita las flechas por disparo. Las aplica `Player.mejora(stat, valor)`.

## Stats base del player

En `Progreso.BASE_STATS`: velocidad 200, lateral 150, cadencia 1,0/s, vida 10, 1 flecha, velocidad de flecha 600, alcance 10 m, daño 1, bonus de oro 0 %.

## Ritmo esperado (simulación)

| Mejoras compradas | Boss mapa 1 | Boss mapa 2 | Boss mapa 3 |
|---|---|---|---|
| ~360 de oro (4-6 partidas) | gana justo | pierde | pierde |
| ~1500 | fácil | gana justo | pierde |
| ~4300 (casi todo al máximo) | — | fácil | gana justo |

## Cómo ajustar

- **Más difícil a lo largo del mapa**: subir `VIDA_POR_METRO`.
- **Mapas más duros**: `MAPAS`.
- **Bosses**: `BOSS_*`.
- **Progresión más lenta/rápida**: el crecimiento `1.4` de `costes()` o los `base`.
- **Cantidad de enemigos**: separación en [`niveles.gd`](../scripts/niveles.gd) o la densidad por dificultad.
- **Hordas**: `hordas` de cada dificultad (frecuencia), `HORDA` (lo fuerte que es cada miembro) y `hordas` de cada mapa en `niveles.gd` (tamaño y separación).
