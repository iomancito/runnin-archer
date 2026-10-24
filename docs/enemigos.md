# Enemigos y bosses

## Jerarquía

```
CharacterBody3D
└─ Enemy            scenes/enemies/Enemy.gd     vida, daño al chocar, oro, número de vida coloreado
   ├─ Goblin, Orc   (sin lógica propia)
   ├─ Troll         lanza piedras (Piedra.tscn) con predicción de trayectoria
   ├─ Ogro          mira al player, suelta una puerta de mejora al morir
   ├─ zombies       avanzan hacia el player (v = −1 / −2)
   └─ Boss          scenes/enemies/boss.gd      para al player y le ataca cada cierto tiempo
      ├─ DragonRojo (mapa 1 y 3)
      └─ DragonNegro (mapa 2, modelo provisional)
```

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
- Al entrar el player en su `Area3D`: `p_speed = 0` y empieza el combate.
- Cada `intervalo` segundos hace `daño_ataque` al player con un "-N" rojo flotante.
- Al morir: `recompensa(boss_gold)` y emite `muere_boss`, que conecta `Mapa.set_boss()` con `Main.muere_boss()` (pantalla de resultados / siguiente mapa).
- La animación `fireball` del dragón rojo llama a `lanzar_bola()`, que no hace nada: el ataque lo controla el temporizador de `Boss`.

## Añadir un tipo de enemigo

1. Crear la escena con un script que herede de `Enemy` (o de `Boss`).
2. Añadir sus valores en `Balance.ENEMIGOS` (`vida`, `daño`, `oro`).
3. Añadirlo al diseño del mapa en `Niveles.MAPAS[n].tipos` (o como `jefes.tipo`).
4. Exportar la escena en el `.tscn` del mapa (`enemies` o `boss`) y devolverla en `escena_de(tipo)` del script del mapa.
5. El precalentado de shaders (`Mapa.precalentar()`) lo incluye automáticamente porque recorre los tipos del diseño.

## Notas

- El ogro (`Ogro.tscn`) intenta reproducir una animación `idle` que no tiene y nunca reproduce `golpear` (heredado de la versión anterior).
- El dragón negro es un modelo provisional sin animaciones.
- `Enemy` y `Boss` usan el autoload `Progreso`: en tests con `--script` no referencies la clase `Boss` desde el script de test (se compilaría antes de existir el autoload).
