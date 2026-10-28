# Logros

Autoload `Logros` ([`scripts/logros.gd`](../scripts/logros.gd)). 71 logros en dos pestañas de la pantalla **ACHIEVEMENTS** del menú principal. Los umbrales están en [`Balance`](../scripts/balance.gd) (`LOGRO_*`).

## Lista

**General** (35):

| Logros | Condición |
|---|---|
| First Blood, Hunter, Slayer, Living Legend | 1 / 500 / 5.000 / 25.000 bajas en total (`LOGRO_BAJAS`) |
| Pocket Money, Treasure Hunter, Dragon's Hoard | 1.000 / 25.000 / 100.000 de oro ganado en total (`LOGRO_ORO`) |
| Map 1-3 Cleared | Vencer al boss de ese mapa en cualquier dificultad |
| Apprentice, Ranger, Veteran, Hellwalker | Superar los 3 mapas en Easy / Medium / Hard / Hell |
| Getting Stronger | Comprar una mejora |
| Master of *X* (×9) | Una mejora de la tienda al máximo |
| Fully Upgraded | Todas las mejoras al máximo |
| Special Delivery, Bow Master, Collector | Comprar un arco especial / subirlo al nivel 5 / haber tenido los 4 |
| Dragon Hunter, Giant Slayer, Horde Breaker | 25 bosses / 25 mini jefes / 1.000 enemigos de horda |
| Full Quiver | Llegar a `MAX_FLECHAS` flechas por disparo |
| Close Call | Matar al boss con menos del 10 % de vida (`LOGRO_VIDA_AGONICA`) |
| Untouchable, Hell's Ghost | Superar un mapa sin recibir daño (cualquiera / en Hell) |

**Challenges** (36): por cada dificultad y mapa,

| Logro | Condición |
|---|---|
| Exterminator *N* | Superar el mapa matando a todos los enemigos (plan del generador + boss) |
| Swift Hunter *N* | Superarlo por debajo del tiempo límite |
| Perfect Hunt *N* | Las dos cosas en la misma partida |

**Tiempo límite** por dificultad en `Balance.LOGRO_TIEMPO`, igual en los 3 mapas: Easy y Medium 4:00, Hard 4:10, Hell 4:20. Recorrer un mapa lleva 300 s a velocidad base y 200 s con Run Speed al máximo, y el player solo se para ante el boss: hace falta subir Run Speed (~6-7 niveles) y matar al boss rápido. El cronómetro corre en `_physics_process` del autoload, así que se para con el árbol en pausa (menú de pausa, resultados, app en segundo plano).

## Cómo se detectan

| Evento | Llamada |
|---|---|
| Enemigo muerto por el player (no al chocar) | `Enemy.recompensa()` → `Logros.baja(enemigo, oro)` |
| Daño recibido | `Player.recibe_daño()` → `Logros.golpe()` |
| Puerta cruzada | `PanelSkills` → `Logros.puerta(player)` |
| Empieza un mapa | `Main.load_map()` → `Logros.empieza_mapa(plan.size() + 1)` |
| Boss muerto | `Main.muere_boss()` → `Logros.mapa_superado(mapa, dificultad, run_kills, player)` |
| Muerte / abandonar | `Logros.termina_partida()` (guarda) |
| Compra en la tienda, mapa superado | `Logros.comprueba()`: logros de estado según `Progreso` |

Al arrancar se llama a `comprueba()` sin avisos, así una partida antigua recibe los logros que ya cumplía (mapas, dificultades, mejoras, arco equipado). Los contadores totales empiezan en 0.

## Guardado

`user://logros.json` (aparte de `save.json`): `{"version", "conseguidos": {id: fecha unix}, "stats": {bajas, oro, bosses, minijefes, horda, arcos}}`. **RESET PROGRESS no lo borra**. En el móvil:
`adb shell run-as com.ioman.runningarcher cat files/logros.json`

## Interfaz

- `scenes/gui/achievements.tscn` (`AchievementsScreen`): pestañas GENERAL / CHALLENGES (esta con una cabecera por dificultad) y contador `N / 71`. Los conseguidos se ven normales con medalla dorada; los pendientes, oscurecidos (`COLOR_PENDIENTE`), con su progreso si es un contador.
- `scenes/gui/achievement_toast.gd`: aviso arriba al desbloquear; en cola si llegan varios (cada uno más corto).
- `scenes/gui/components/medal_icon.gd`: medalla dibujada (sin texturas).

## Añadir un logro

1. Umbral en `Balance` si tiene número.
2. `_add(id, nombre, texto, grupo, progreso)` en `_define()`; `progreso` es un `Callable` que devuelve `[actual, meta]` y hace que `comprueba()` lo desbloquee solo.
3. Si depende de un evento, llamar a `desbloquea(id)` desde donde ocurra. Los ids guardados que ya no existan se ignoran al cargar.
