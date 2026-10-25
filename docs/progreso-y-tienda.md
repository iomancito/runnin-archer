# Progreso, guardado y tienda

## `Progreso` (autoload, [`scripts/progreso.gd`](../scripts/progreso.gd))

| Miembro | Función |
|---|---|
| `p_gold` | Oro. Al cambiar emite `gold_changed(gold)` (lo escuchan las píldoras de oro y la tienda) |
| `niveles` | `{nombre de mejora: nivel}` |
| `progreso_permanente` | Stats base + mejoras; lo recalcula la tienda a partir de `niveles` |
| `BASE_STATS` | Stats del player sin mejoras |
| `dificultad` | `easy` / `medium` / `hard` / `hell`; al cambiar actualiza `Balance.dificultad` |
| `desbloqueadas` | Dificultades disponibles. Se empieza solo con `easy` |
| `esta_desbloqueada(d)`, `siguiente_dificultad(d)` | Consultas sobre el orden `Balance.ORDEN_DIFICULTADES` |
| `completa_dificultad()` | Al superar el mapa 3: la marca en `completadas`, desbloquea la siguiente dificultad y la devuelve (`""` si ya lo estaba) |
| `completadas` | Dificultades con los 3 mapas superados (cada una habilita su arco) |
| `arco`, `arco_nivel` | Arco especial equipado (`""` = original) y su nivel. Ver [arcos.md](arcos.md) |
| `comprar_arco(id)`, `stats_partida()` | Compra de arcos y stats con los que empieza el player |
| `max_maps` / `max_map` | Mapa más alto alcanzado por dificultad; `max_map` es el de la dificultad actual |
| `current_map` | Mapa de la partida en curso (vuelve a 1 al morir o abandonar) |
| `player` | Referencia al player actual |
| `run_kills`, `run_gold` | Estadísticas de la partida (pantalla de resultados) |
| `oro_con_bonus(n)` | Aplica el bonus de oro acumulando la fracción en `oro_resto` |
| `reset_all()` | Borra todo (oro, mejoras, mapas, dificultades desbloqueadas) y emite `progress_reset` |
| `aviso` | Mensaje de un solo uso para el menú principal |

## Guardado

- Archivo: `user://save.json` (en Android, `files/save.json` del paquete). Se puede leer en el móvil con:
  `adb shell run-as com.example.runningarcher cat files/save.json`
- Se guarda al comprar, al morir, al matar un boss, al cambiar de dificultad, al resetear, al cerrar la app y al pasarla a segundo plano.
- Se guardan los **niveles** de las mejoras, no los stats finales: si cambian los incrementos en `Balance`, las partidas viejas usan los valores nuevos.

Contenido (versión 5):

```json
{"version": 5, "gold": 637, "niveles": {"damage": 3}, "max_maps": {"medium": 2}, "dificultad": "medium", "desbloqueadas": ["easy", "medium"], "completadas": ["easy"], "arco": "thorn", "arco_nivel": 2, "skin": 1}
```

### Versiones y migraciones (`load_game`)

| Versión | Cambio | Migración |
|---|---|---|
| 1 | Tienda antigua (precios 1-5) | `_migra_v1()`: reembolsa lo gastado, borra niveles y muestra un aviso |
| 2 | `max_map` único | Se asigna a `max_maps["medium"]` |
| 3 | Dificultades (todas abiertas) | — |
| 4 | Desbloqueo de dificultades | Se desbloquean las dificultades ya jugadas (`max_maps`) o la elegida, para no quitar acceso |
| 5 | Arcos especiales | `completadas` empieza vacía y sin arco |

Si haces un cambio incompatible: sube `SAVE_VERSION` y añade la conversión en `load_game()`.

## Tienda ([`scenes/gui/shop.gd`](../scenes/gui/shop.gd))

- Dos pestañas: **UPGRADES** (mejoras permanentes) y **BOWS** (arcos especiales, ver [arcos.md](arcos.md)).
- Construye una tarjeta (`shop_card.tscn`) por cada entrada de `Balance.tienda()`.
- `recalcula_stats()`: `progreso_permanente = BASE_STATS + incremento × nivel` (mantiene int/float del valor base).
- Comprar: comprueba el oro, sube el nivel, recalcula, cobra y guarda.
- **Reset de mejoras** (botón rojo): primer toque muestra el reembolso, el segundo lo confirma; devuelve todo lo gastado.
- Al recibir `progress_reset` pone todos los niveles a 0 sin reembolso.

## Desbloqueo de dificultades

- Al empezar solo está **Easy**. Superar los 3 mapas (vencer al boss del mapa 3) en una dificultad desbloquea la siguiente: Easy → Medium → Hard → Hell.
- Lo hace `Main.muere_boss()` con `Progreso.completa_dificultad()`; la pantalla de victoria muestra "*X* difficulty unlocked!".
- En el menú las dificultades bloqueadas salen deshabilitadas y se indica cómo desbloquear la siguiente.

## Reset total (menú principal)

Botón **RESET PROGRESS**: primer toque "TAP AGAIN TO ERASE ALL" durante 3 s, el segundo llama a `Progreso.reset_all()` → 0 de oro, sin mejoras, mapa 1 en todas las dificultades y solo Easy desbloqueada. Los logros no se borran (ver [logros.md](logros.md)).

## Mejoras durante la partida

Las puertas (`scenes/pickups/panel/panel.gd`) ofrecen dos mejoras al azar de `Balance.PUERTAS` y llaman a `Player.mejora(stat, valor)`. El pilar central es una cuña en la capa de los muros (capa 4) que desvía al arquero hacia un lado, así que solo se cruza una de las dos; si llega justo al centro sin tocar la pantalla, `Player` se aparta solo hacia un lado. Además `PanelSkills.cogido` impide aplicar las dos aunque ambas áreas avisen en el mismo frame. Solo duran esa partida (el player recibe una copia de `progreso_permanente` al aparecer).
