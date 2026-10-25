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

Valores base (multiplicador de etapa 1, al inicio del recorrido); en el juego se multiplican por la etapa (ver abajo):

| Tipo | Vida | Daño al chocar | Oro |
|---|---|---|---|
| `goblin` | 2 | 2 | 1 |
| `orc` | 5 | 3 | 2 |
| `troll` | 14 | 5 | 4 |
| `ogre` (mini jefe mapa 1) | 30 | 8 | 10 |
| `whelp` (cría de dragón, dispara) | 7 | 3 | 3 |
| `zombie` | 4 | 2 | 1 |
| `spitter` (zombi escupidor, dispara ácido) | 6 | 3 | 3 |
| `brute` (zombi gordo, mini jefe mapa 2) | 25 | 6 | 8 |
| `skeleton` | 3 | 2 | 1 |
| `skeleton_mage` (dispara) | 6 | 3 | 3 |
| `reaper` | 12 | 5 | 4 |
| `death_knight` (mini jefe mapa 3) | 32 | 8 | 10 |

- La vida crece con la distancia: `× (1 + z × VIDA_POR_METRO)` → ×1 al inicio, ×3,5 a los 1000 m.
- El daño al chocar crece la mitad de rápido: `× (1 + z × DAÑO_POR_METRO)` → ×1 al inicio, ×2,25 a los 1000 m. Así embestir enemigos al final del mapa sigue siendo peligroso aunque no se les pueda matar.
- `velocidad` (opcional): m/s a los que avanza hacia el player (`skeleton` 1,6, `brute` 1, `reaper` 0,8). Los zombis normales llevan la suya en su script.
- `ROCA_TROLL_DAÑO = 4`: daño de la piedra que lanza el troll.
- `PROYECTIL_DAÑO`: daño del disparo de la cría (3), del escupidor (3) y del mago (4), con el multiplicador de daño de la etapa.
- `LANZADOR`: los que disparan lo hacen al tener al player a menos de 20 m, cada 2,4 s, 2 veces como mucho; la marca está 1,2 s en el suelo (radio 0,9 m) y cae donde estará el player si sigue recto.
- El daño al chocar depende del tipo y de la distancia, no de la vida que le quede (antes era la vida restante del enemigo). Chocar mata al enemigo pero **no da oro**.

## Etapas: dificultad y mapa en una sola escala

Vida, daño y oro de enemigos, proyectiles y bosses se multiplican por `ETAPA_BASE × ETAPA_CRECIMIENTO^etapa`, con `etapa = índice de dificultad × ETAPAS_POR_DIFICULTAD + (mapa − 1)` (`Balance.etapa()`, `Balance._mult()`).

Con `ETAPAS_POR_DIFICULTAD = 2` **el mapa 1 de cada dificultad es la misma etapa que el mapa 3 de la anterior**: cada dificultad empieza donde acabó la otra y no hay bajones (antes Medium 1 era 4 veces más fácil que Easy 3). Crecimiento por etapa: vida ×1,6, daño ×1,2, oro ×1,15. El oro crece menos que la vida: cada etapa pide más mejoras de las que paga.

| | Etapa | Vida | Daño | Oro | Boss: vida / daño por impacto / oro |
|---|---|---|---|---|---|
| Easy 1 / 2 / 3 | 0 / 1 / 2 | ×0,6 / 0,96 / 1,54 | ×0,5 / 0,6 / 0,72 | ×0,6 / 0,69 / 0,79 | 210 / 336 / 537 — 2 / 2 / 3 — 60 / 69 / 79 |
| Medium 1 / 2 / 3 | 2 / 3 / 4 | ×1,54 / 2,46 / 3,93 | ×0,72 / 0,86 / 1,04 | ×0,79 / 0,91 / 1,05 | 537 / 860 / 1376 — 3 / 3 / 4 — 79 / 91 / 105 |
| Hard 1 / 2 / 3 | 4 / 5 / 6 | ×3,93 / 6,29 / 10,1 | ×1,04 / 1,24 / 1,49 | ×1,05 / 1,21 / 1,39 | 1376 / 2202 / 3523 — 4 / 4 / 5 — 105 / 121 / 139 |
| Hell 1 / 2 / 3 | 6 / 7 / 8 | ×10,1 / 16,1 / 25,8 | ×1,49 / 1,79 / 2,15 | ×1,39 / 1,6 / 1,84 | 3523 / 5637 / 9019 — 5 / 6 / 7 — 139 / 160 / 184 |

## Bosses

| | Valor (mapa 1, medio) |
|---|---|
| `BOSS_VIDA` | 350 |
| `BOSS_DAÑO` | 3 por impacto |
| `BOSS_INTERVALO` | 2,5 s de pausa entre ataques |
| `BOSS_ORO` | 100 |

Se multiplican por etapa igual que los enemigos. Al tocar al boss el player se para y empieza el combate (ver [enemigos.md](enemigos.md)).

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

Vida, daño y oro van por etapas (arriba); la dificultad decide cuántos enemigos salen, el ritmo del boss y las formaciones:

| | Densidad | Intervalo boss | Hordas | Columnas |
|---|---|---|---|---|
| `easy` | ×0,75 | ×1,3 | no | no |
| `medium` | ×1 | ×1 | ×0,6 | ×1 |
| `hard` | ×1,25 | ×0,9 | ×1 | ×1 |
| `hell` | ×1,5 | ×0,75 | ×1,6 | ×1,2 |

- **Densidad** divide la separación entre filas de enemigos del generador (más densidad = más enemigos, y más oro).
- **Hordas** y **columnas** dividen la separación entre esas formaciones del mapa (0 = no salen). Ver abajo.
- La dificultad elegida se guarda en `Progreso.dificultad` y se copia a `Balance.dificultad`; `Balance.dif()` devuelve sus multiplicadores.
- Se empieza solo con Easy; superar los 3 mapas en una dificultad desbloquea la siguiente (ver [progreso-y-tienda.md](progreso-y-tienda.md)).

Enemigos por mapa (generador, 20 partidas de media; entre paréntesis, los que van en hordas):

| | Easy | Medium | Hard | Hell |
|---|---|---|---|---|
| Mapa 1 | 66 | 145 (55) | 192 (90) | 261 (156) |
| Mapa 2 | 88 | 176 (62) | 234 (107) | 284 (151) |
| Mapa 3 | 78 | 164 (60) | 207 (89) | 275 (156) |

## Formaciones: hordas y columnas

Dan sentido a los arcos especiales, que se compran al superar cada dificultad y se usan en la siguiente:

- **Columnas** (desde Medium): 3-5 enemigos normales del mismo tipo en fila india en un carril, a 1,8 m. Con el arco original hay que gastar mucho tiempo en ellas o esquivarlas; **Thorn Bow** (tras Easy) las atraviesa enteras y **Sunfire** alcanza al de detrás cuando su radio llega a 1,8 m.
- **Hordas** (desde Medium): grupos compactos de enemigos débiles (abajo). **Sunfire** (tras Medium) y **Storm** (tras Hard) las barren con daño en área y en cadena.

Simulación: sin arcos el jugador medio no supera Hell; con arcos pero sin formaciones necesita ~23 partidas en Hell, y con formaciones ~14.

### Hordas (`HORDA`)

Desde Medium aparecen grupos compactos de enemigos débiles (goblins en el mapa 1, zombis en el 2, esqueletos en el 3) pegados a una pared, con al menos 2 carriles libres para esquivarlos. Cada miembro tiene los valores de su tipo multiplicados por `HORDA` (vida, daño y oro ×0,5): con los stats base hay que esquivarlas; con varias flechas o un arco especial (perforar, explosión, rayo) se barren y dan mucho oro. Dónde y cómo son: `hordas` en [`niveles.gd`](../scripts/niveles.gd) (ver [mapas.md](mapas.md)).

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

Simulación en Python (fuera del repo) de campañas completas desde 0 de oro: reproduce `MapGenerator` (filas, hordas y columnas) y estos números; el bot mata lo que le da tiempo, esquiva el resto, coge puertas (vida si va por debajo del 50 %, si no DPS), compra cada arco nuevo al desbloquearlo y entre partidas compra siempre el nivel más barato (de 6 mejoras y del arco). Jugador *bueno*: choca con el 5 % de lo que esquiva y le aciertan el 10 % de los disparos; *medio*: 12 %, 25 % y el doble de impactos del boss. No simula Gold Bonus, Run Speed ni Arrow Speed.

Partidas hasta superar cada dificultad (mediana, entre paréntesis p10-p90):

| Jugador | Easy | Medium | Hard | Hell |
|---|---|---|---|---|
| bueno | 2 (1-2) | 1 (1-2) | 2 (1-3) | 4 (3-7) |
| medio | 3 (3-4) | 2 (1-3) | 4 (2-8) | 14 (10-27) |

La muerte llega casi siempre en el mapa 3 de cada dificultad (su etapa es la más alta) y en el camino, no en el boss. Medium sale algo más corto que Easy porque su mapa 1 es la etapa ya superada y Thorn Bow barre sus columnas.

## Cómo ajustar

- **Más difícil de una etapa a otra**: `ETAPA_CRECIMIENTO` (vida, daño, oro); el solapamiento entre dificultades, `ETAPAS_POR_DIFICULTAD`.
- **Más difícil a lo largo del mapa**: subir `VIDA_POR_METRO` (aguante) o `DAÑO_POR_METRO` (lo que duele chocar).
- **Bosses**: `BOSS_*`; lo difícil que es esquivar sus ataques, `BOSS_ATAQUES` (sobre todo `aviso`).
- **Progresión más lenta/rápida**: `CRECIMIENTO_COSTES` o los `base` de cada mejora.
- **Cantidad de enemigos**: separación en [`niveles.gd`](../scripts/niveles.gd) o la densidad por dificultad.
- **Hordas y columnas**: `hordas` / `columnas` de cada dificultad (frecuencia), `HORDA` (lo fuerte que es cada miembro de una horda) y `hordas` / `columnas` de cada mapa en `niveles.gd` (tamaño y separación).
