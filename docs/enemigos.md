# Enemigos y bosses

## Jerarquía

```
CharacterBody3D
└─ Enemy            scenes/enemies/Enemy.gd     vida, daño al chocar, oro, número de vida coloreado
   ├─ Goblin, Orc   (sin lógica propia)
   ├─ Troll         lanza piedras (Piedra.tscn) con predicción de trayectoria
   ├─ Ogro          mira al player, suelta una puerta de mejora al morir
   ├─ zombies       avanzan hacia el player (v = −1 / −2)
   ├─ Caminante     scenes/enemies/caminante.gd  animación en bucle y avanza a Balance velocidad
   │                (esqueleto, segador, zombi gordo, caballero de la muerte)
   ├─ Lanzador      scenes/enemies/lanzador.gd   quieto, dispara un Proyectil (cría de dragón, esqueleto mago)
   │  └─ ZombiEscupidor  scenes/enemies/map2/zombi_escupidor.gd  chorro de ácido por la boca
   └─ Boss          scenes/enemies/boss.gd       para al player y le ataca con proyectiles esquivables
      ├─ DragonRojo      (mapa 1)  fuego
      ├─ DragonNegro     (mapa 2)  fuego violeta
      └─ DragonEsqueleto (mapa 3)  almas (fuego cian)
```

| Mapa | Enemigos | Mini jefe | Boss |
|---|---|---|---|
| 1 | goblin, orco, troll, cría de dragón (desde el 60 %) | ogro | dragón rojo |
| 2 | zombis (3 modelos), zombi escupidor | zombi gordo (`brute`) | dragón negro |
| 3 | esqueleto, esqueleto mago, segador | caballero de la muerte | dragón esqueleto |

## `Enemy` ([`Enemy.gd`](../scenes/enemies/Enemy.gd))

| Miembro | Función |
|---|---|
| `setup(tipo, z, mapa)` | Pone vida, daño al chocar y oro desde `Balance` (lo llama el spawner) |
| `vida`, `vida_max` | Vida actual y máxima (la barra del boss usa `vida_max`) |
| `daño_contacto` | Daño al player si choca |
| `gold` | Oro al morir por flechas (0 si murió chocando) |
| `recibe_daño(d)` | Lo llama la flecha; al llegar a 0 llama a `die()` |
| `die()` | `recompensa()`, suelta moneda y se libera |
| `recompensa(cantidad)` | Suma oro (con el bonus de la tienda), cuenta la baja y muestra "+N" flotante |
| `update_hp()` / `threat_color()` | Número de vida en `Label3D` coloreado verde/amarillo/rojo (ver [balance.md](balance.md)) |

Las escenas de enemigo necesitan: `Label3D` (número de vida), un `Area3D` conectado a `_on_area_3d_body_entered`, el export `moneda` y un `VisibleOnScreenEnabler3D` (para de procesar fuera de cámara).

## `Boss` ([`boss.gd`](../scenes/enemies/boss.gd))

- `setup_boss(mapa)`: vida, daño, intervalo y oro desde `Balance`.
- Al entrar el player en su `Area3D`: `p_speed = 0` y empieza el combate; el primer ataque llega a medio intervalo.
- Ataca en el orden de `Niveles.MAPAS[n].boss_ataques` (`bola`, `barrera`, `lluvia`; ver [balance.md](balance.md)) y deja `intervalo` segundos entre ataques.
- Cada ataque: reproduce su animación y, en el segundo en que el dragón lanza la cabeza, crea los `Proyectil` desde la boca (`boca()`: hueso `hueso_boca` + `boca_adelante` m hacia el player).
- Cada subclase rellena en `_init`: `anim_ataques` (`{tipo: [animación, segundo del disparo]}`), `hueso_boca`, `boca_adelante` y `estilo` (color del fuego). `anim_reposo` (`idle`, se pone en bucle) y `anim_muerte` (`death`) son comunes.
- Al morir: `recompensa(boss_gold)`, cancela los proyectiles en el aire, reproduce `death` (`tiempo_muerte` = 1,8 s) y emite `muere_boss`, que conecta `Mapa.set_boss()` con `Main.muere_boss()` (pantalla de resultados / siguiente mapa).

| Boss | Bola | Barrera | Lluvia |
|---|---|---|---|
| Dragón rojo | `bite` 0,55 s | `breath` 1,05 s | `roar` 0,8 s |
| Dragón negro | `spit` 0,55 s | `breath` 0,85 s | `spit` 0,55 s |
| Dragón esqueleto | `breath` 1,05 s | `rear_breath` 1,6 s | `roar` 0,85 s |

## `Proyectil` ([`proyectil.gd`](../scenes/otros/proyectil.gd))

`Proyectil.lanzar(padre, desde, hasta, tiempo, daño, estilo, forma, radio, arco, escala)`:

- Pone una **marca en el suelo** en `hasta` (círculo o rectángulo de un carril, shader [`aviso.gdshader`](../scenes/otros/aviso.gdshader) con parámetros por instancia: un solo material) que se rellena hasta el impacto.
- Mueve el efecto `vfx_fire_projectile_01` de BinbunVFX en parábola (`arco` m sobre la recta) durante `tiempo` s. El color depende del `estilo` (`FUEGO`, `FUEGO_OSCURO`, `ALMAS`, `MAGIA`); sin luz dinámica. El estilo `ACIDO` usa en su lugar una bola con estela de gotas y salpica al caer (ver abajo).
- Al llegar: si el player está dentro (`dentro()`, con `Balance.RADIO_PLAYER`) recibe el daño y sale "-N"; explosión naranja con el fuego normal y destello de la marca en todos.
- `Proyectil.precalentar()` lo muestra durante la carga (lo llama `Mapa.precalentar()` para el boss y los lanzadores del mapa).

## `Caminante` y `Lanzador`

- `Caminante` ([`caminante.gd`](../scenes/enemies/caminante.gd)): exports `anim`, `anim_escala` y, opcional, `anim_cerca` (una vez cuando el player está a `distancia_cerca` m: el caballero ruge, el zombi gordo grita). Avanza a `Balance.velocidad_enemigo(tipo)`.
- `Lanzador` ([`lanzador.gd`](../scenes/enemies/lanzador.gd)): exports `anim_reposo`, `anim_ataque`, `retardo` (segundo del disparo), `hueso`/`adelante` (de dónde sale) y `estilo`. Dispara según `Balance.LANZADOR` a donde estará el player si sigue recto.

## Zombi escupidor y `Acido`

- Escena [`zombi_escupidor.tscn`](../scenes/enemies/map2/zombi_escupidor.tscn): **heredada** de `zombi_espada.tscn` (mismo modelo Yakuzombie, sin duplicar la malla en el APK) con el script `ZombiEscupidor` (un `Lanzador` en reposo `agonize`, disparo desde `mixamorig_Head`, estilo `ACIDO`). Lleva un tinte verde (`material_overlay`) para distinguirlo.
- Al disparar le sale de la boca un chorro de gotas hacia el player durante 0,45 s y el proyectil cae en la marca.
- [`scenes/otros/acido.gd`](../scenes/otros/acido.gd) (`Acido`): chorro, gota en vuelo, salpicadura y tinte, con partículas creadas por código y recursos compartidos. El chorro es el del zombi vomitador de YoelGame (código propio, sin texturas).
- `mapa2.gd` lo carga con `preload`: está en `export_files` del preset Android.

## Modelos

Los modelos nuevos son glb recortados (solo las animaciones que se usan, texturas ≤ 1024 px) por scripts de Blender en `tools/`:

- [`tools/importar_modelos.py`](../tools/importar_modelos.py): copia los modelos animados de YoelGame (dragón rojo y esqueleto, cría, zombi gordo, esqueletos, segador, caballero). El origen no se modifica.
- [`tools/dragon_negro.py`](../tools/dragon_negro.py): monta el dragón negro de 3DHaupt; le pone las texturas (se habían perdido) y crea sus animaciones de ataque y muerte girando huesos sobre el reposo (`--render DIR` para verlas).

En las escenas, el modelo es el nodo `Modelo` (instancia del glb, girado 180° para mirar al player y escalado). Las texturas extraídas van con compresión VRAM.

## Añadir un tipo de enemigo

1. Crear la escena con un script que herede de `Enemy` (o de `Boss`); si solo anda o dispara, usar `caminante.gd` o `lanzador.gd` con sus exports. Si el modelo viene de YoelGame, añadirlo a `MODELOS` de `tools/importar_modelos.py`.
2. Añadir sus valores en `Balance.ENEMIGOS` (`vida`, `daño`, `oro` y, si avanza, `velocidad`; si dispara, `PROYECTIL_DAÑO`).
3. Añadirlo al diseño del mapa en `Niveles.MAPAS[n].tipos` (o como `jefes.tipo`).
4. Exportar la escena en el `.tscn` del mapa (`enemies` o `boss`) y devolverla en `escena_de(tipo)` del script del mapa.
5. El precalentado de shaders (`Mapa.precalentar()`) lo incluye automáticamente porque recorre los tipos del diseño.

## Notas

- El ogro (`Ogro.tscn`) intenta reproducir una animación `idle` que no tiene y nunca reproduce `golpear` (heredado de la versión anterior).
- Los enemigos mueren sin animación (se liberan al momento); solo los bosses tienen animación de muerte.
- `Enemy` y `Boss` usan el autoload `Progreso`: en tests con `--script` no referencies la clase `Boss` desde el script de test (se compilaría antes de existir el autoload).
