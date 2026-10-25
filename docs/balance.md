# Balance

Todos los números de juego están en [`scripts/balance.gd`](../scripts/balance.gd) (clase estática `Balance`). Para ajustar dificultad, precios o daño **solo hay que tocar ese archivo**.

## La fórmula base

Un enemigo se puede alcanzar desde que entra en el alcance de las flechas hasta que llega al player, así que el daño que le hace el player antes de chocar es:

```
daño por enemigo = (alcance / velocidad de carrera) × cadencia × daño × flechas
```

- Velocidad de carrera base: `p_speed = 200` → 200/60 = **3,33 m/s** (la velocidad se multiplica por `delta` de física).
- Con los stats base: (10 m / 3,33) × 1,0 × 1 × 1 ≈ **3** de daño por enemigo.
- Con la tienda al máximo: (30 / 3,33) × 2,0 × 11 × 5 ≈ **990** (con Run Speed al máximo, 5 m/s: ≈ 660).
- **Run Speed** acorta el mapa (necesario para los logros de tiempo) pero reduce el daño por enemigo; **Arrow Speed** no entra en la fórmula: las flechas llegan antes, útil contra enemigos que se mueven.

El color del número de vida de cada enemigo usa esta misma fórmula (`Enemy.threat_color()`): **verde** = lo mata, **amarillo** = le hace al menos la mitad, **rojo** = mejor esquivar.

## Enemigos (`ENEMIGOS`)

Valores en el mapa 1, al inicio del recorrido, dificultad media:

| Tipo | Vida | Daño al chocar | Oro |
|---|---|---|---|
| `goblin` | 2 | 2 | 1 |
| `orc` | 5 | 3 | 2 |
| `troll` | 14 | 5 | 4 |
| `ogre` (mini jefe mapa 1) | 30 | 8 | 10 |
| `whelp` (cría de dragón, dispara) | 7 | 3 | 3 |
| `zombie` | 4 | 2 | 1 |
| `brute` (zombi gordo, mini jefe mapa 2) | 25 | 6 | 8 |
| `skeleton` | 3 | 2 | 1 |
| `skeleton_mage` (dispara) | 6 | 3 | 3 |
| `reaper` | 12 | 5 | 4 |
| `death_knight` (mini jefe mapa 3) | 32 | 8 | 10 |

- La vida crece con la distancia: `× (1 + z × VIDA_POR_METRO)` → ×1 al inicio, ×3,5 a los 1000 m.
- El daño al chocar crece la mitad de rápido: `× (1 + z × DAÑO_POR_METRO)` → ×1 al inicio, ×2,25 a los 1000 m. Así embestir enemigos al final del mapa sigue siendo peligroso aunque no se les pueda matar.
- `velocidad` (opcional): m/s a los que avanza hacia el player (`skeleton` 1,6, `brute` 1, `reaper` 0,8). Los zombis normales llevan la suya en su script.
- `ROCA_TROLL_DAÑO = 4`: daño de la piedra que lanza el troll.
- `PROYECTIL_DAÑO`: daño del disparo de la cría (3) y del mago (4), con los multiplicadores de mapa y dificultad.
- `LANZADOR`: los que disparan lo hacen al tener al player a menos de 20 m, cada 2,4 s, 2 veces como mucho; la marca está 1,2 s en el suelo (radio 0,9 m) y cae donde estará el player si sigue recto.
- El daño al chocar depende del tipo y de la distancia, no de la vida que le quede (antes era la vida restante del enemigo). Chocar mata al enemigo pero **no da oro**.

## Multiplicadores por mapa (`MAPAS`)

`[vida, daño, oro]`: mapa 1 `[1, 1, 1]`, mapa 2 `[3, 1,5, 1,5]`, mapa 3 `[7, 2, 2]`.

## Bosses

| | Valor (mapa 1, medio) |
|---|---|
| `BOSS_VIDA` | 350 |
| `BOSS_DAÑO` | 3 por impacto |
| `BOSS_INTERVALO` | 2,5 s de pausa entre ataques |
| `BOSS_ORO` | 100 |

Se multiplican por mapa y por dificultad igual que los enemigos. Al tocar al boss el player se para y empieza el combate (ver [enemigos.md](enemigos.md)).

### Ataques de los bosses (`BOSS_ATAQUES`)

Cada ataque lanza proyectiles que marcan el suelo donde caerán; si el player sigue dentro al caer, recibe `BOSS_DAÑO`. Se pueden esquivar todos moviéndose a tiempo. La secuencia de cada boss está en `boss_ataques` de [`niveles.gd`](../scripts/niveles.gd):

- **bola**: ráfaga de bolas (radio `BOSS_BOLA_RADIO` = 1,1 m) cada `BOSS_RAFAGA_CADENCIA` = 0,45 s, a donde está el player o a donde estará si sigue moviéndose (`prediccion`).
- **barrera**: fuego en todos los carriles menos los `libres`; uno de ellos es contiguo al del player.
- **lluvia**: `oleadas` de fuego que sube y cae del cielo por carriles; el libre se mueve un carril en cada oleada (`BOSS_OLEADAS_PAUSA` = 0,5 s entre ellas).

| | aviso (s) | bolas por ráfaga | predicción | carriles libres | oleadas |
|---|---|---|---|---|---|
| `easy` | 1,5 | 1 | 0 | 2 | 1 |
| `medium` | 1,25 | 2 | 0,3 | 2 | 1 |
| `hard` | 1,05 | 3 | 0,6 | 1 | 2 |
| `hell` | 0,9 | 4 | 0,9 | 1 | 3 |

- **aviso**: lo que tarda en caer desde que aparece la marca. En barrera y lluvia se multiplica por `BOSS_AVISO_CARRILES` = 1,2 (hay que cambiar de carril: 2 m).
- Con Dodge Speed base (150 → 2,5 m/s) salir de una bola lleva ~0,6 s y cambiar de carril ~0,8 s: todo es esquivable en Hell sin mejoras, pero sin margen.
- `RADIO_PLAYER` = 0,3 m: medio ancho del player para los impactos.
- Prueba con un bot que esquiva con 0,3 s de reacción y Dodge Speed base, 15 s de combate: Easy 0-1 impactos, Medium 1-2, Hard 2-3, Hell 3-6 (sin moverse: 8-12 en Hell).

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
| Boss mapa 1: vida / daño por impacto | 210 / 2 | 350 / 3 | 595 / 5 | 1050 / 8 |
| Enemigos mapa 2 (de ellos en hordas) | 87 | 120 | 226 (97) | 284 (152) |
| Boss mapa 2: vida / daño por impacto | 630 / 3 | 1050 / 5 | 1785 / 7 | 3150 / 12 |

## Hordas (`HORDA`)

En Hard y Hell aparecen grupos compactos de enemigos débiles (goblins en el mapa 1, zombis en el 2, esqueletos en el 3) pegados a una pared, con al menos 2 carriles libres para esquivarlos. Cada miembro tiene los valores de su tipo multiplicados por `HORDA` (vida, daño y oro ×0,5): con los stats base hay que esquivarlas; con varias flechas o un arco especial (perforar, explosión, rayo) se barren y dan mucho oro. Dónde y cómo son: `hordas` en [`niveles.gd`](../scripts/niveles.gd) (ver [mapas.md](mapas.md)).

## Tienda (`tienda()`)

Cada entrada: `[nombre (clave de guardado), título, formato, stat, incremento, costes por nivel]`. Los costes se generan con `costes(base, CRECIMIENTO_COSTES, niveles)` = `base × 1,6^nivel` (con 1,4 la tienda se agotaba al terminar Hard).

| Mejora | Stat | Por nivel | Niveles | Primer → último precio |
|---|---|---|---|---|
| Damage | `f_daño` | +1 | 10 | 12 → 825 |
| Fire Rate | `p_attack_speed` | +0,1/s | 10 | 12 → 825 |
| Arrows | `f_cantidad` | +1 | 4 | 50 / 170 / 520 / 1340 |
| Max HP | `p_vida` | +5 | 10 | 8 → 550 |
| Range | `f_max_distancia` | +2 m | 10 | 8 → 550 |
| Dodge Speed | `p_side_speed` | +10 | 10 | 6 → 412 |
| Run Speed | `p_speed` | +10 (200 → 300, 3,33 → 5 m/s) | 10 | 10 → 687 |
| Arrow Speed | `f_velocidad` | +40 (600 → 1000) | 10 | 6 → 412 |
| Gold Bonus | `p_oro` | +10 % | 10 | 15 → 1031 |

Total para maximizar todo: ~16 000 de oro. Un mapa 1 completo en medio da ~300.

> Cambiar el `nombre` de una mejora rompe los niveles guardados (se guardan por nombre). Si se cambia la tienda de forma incompatible, añade una migración en `Progreso` (ver [progreso-y-tienda.md](progreso-y-tienda.md)).

## Arcos especiales (`ARCOS`)

4 arcos con habilidad propia, comprables tras superar cada dificultad. Valores, precios y reglas en [arcos.md](arcos.md).

## Puertas de mejora durante la partida (`PUERTAS`)

`[texto, stat, incremento]`: Damage +1, Fire rate +0,15/s, Arrows +1, Range +3 m, Dodge speed +15, Max HP +10 (también cura). `MAX_FLECHAS = 7` limita las flechas por disparo. Las aplica `Player.mejora(stat, valor)`.

## Stats base del player

En `Progreso.BASE_STATS`: velocidad 200, lateral 150, cadencia 1,0/s, vida 10, 1 flecha, velocidad de flecha 600, alcance 10 m, daño 1, bonus de oro 0 %.

## Ritmo esperado (simulación)

Simulación en Python (fuera del repo) de campañas completas desde 0 de oro: reproduce `MapGenerator` y estos números; el bot mata lo que le da tiempo, esquiva el resto, coge puertas (vida si va por debajo del 50 %, si no DPS) y entre partidas compra siempre el nivel más barato. Jugador *bueno*: choca con el 5 % de lo que esquiva y le aciertan el 10 % de los disparos; *medio*: 12 %, 25 % y el doble de impactos del boss. No simula arcos especiales (Hell no se puede evaluar) ni Gold Bonus, Run Speed o Arrow Speed.

Partidas hasta superar cada dificultad (mediana, entre paréntesis p10-p90), con `DAÑO_POR_METRO` y `CRECIMIENTO_COSTES = 1.6`:

| Jugador | Easy | Medium | Hard |
|---|---|---|---|
| bueno | 2 (2-3) | 2 (1-3) | 4 (2-6) |
| medio | 4 (3-5) | 4 (3-6) | 16 (5-39) |

Antes del cambio (daño de choque fijo, crecimiento 1,4) eran 2 / 1-2 / 2 y 3 / 2-3 / 6, y la tienda quedaba al máximo durante Hard. La muerte llega casi siempre en el camino del mapa 3 (choques y rayos de los magos), no en el boss: con las puertas los combates son cortos y el boss solo quita 1-4 de vida de media.

## Cómo ajustar

- **Más difícil a lo largo del mapa**: subir `VIDA_POR_METRO` (aguante) o `DAÑO_POR_METRO` (lo que duele chocar).
- **Mapas más duros**: `MAPAS`.
- **Bosses**: `BOSS_*`; lo difícil que es esquivar sus ataques, `BOSS_ATAQUES` (sobre todo `aviso`).
- **Progresión más lenta/rápida**: `CRECIMIENTO_COSTES` o los `base` de cada mejora.
- **Cantidad de enemigos**: separación en [`niveles.gd`](../scripts/niveles.gd) o la densidad por dificultad.
- **Hordas**: `hordas` de cada dificultad (frecuencia), `HORDA` (lo fuerte que es cada miembro) y `hordas` de cada mapa en `niveles.gd` (tamaño y separación).
