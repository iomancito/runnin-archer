# Mapas y generador

Cada partida genera una distribución nueva de enemigos a partir de un diseño de datos. Los enemigos no se crean todos al cargar: aparecen ~80 m por delante del player y se eliminan al dejarlos atrás.

## Piezas

| Archivo | Función |
|---|---|
| [`scripts/niveles.gd`](../scripts/niveles.gd) | Diseño de cada mapa (datos) |
| [`scenes/mapas/map_generator.gd`](../scenes/mapas/map_generator.gd) | Convierte el diseño en un plan de spawns `[{tipo, z, x}]` ordenado por z |
| [`scenes/mapas/mapa_base.gd`](../scenes/mapas/mapa_base.gd) | Clase `Mapa`: decorado, puertas, boss final y spawner |
| `scenes/mapas/mapa1.gd` … `mapa3.gd` | Solo número de mapa, nombre del boss y qué escena usa cada tipo |
| `scenes/mapas/mapaN.tscn` | Suelo, luz, entorno y las escenas exportadas (`left`, `right`, `enemies`, `boss`, `final`, `panel`) |
| [`scenes/mapas/mesh_batcher.gd`](../scenes/mapas/mesh_batcher.gd) | Junta el decorado en MultiMesh (ver [rendimiento.md](rendimiento.md)) |

## Diseño de un mapa (`Niveles.MAPAS`)

Distancias en metros sobre z. Los pares `[inicio, fin]` se interpolan a lo largo del recorrido (0 = salida, 1 = boss).

| Clave | Significado |
|---|---|
| `largo` | z del boss final (1000) |
| `inicio` | zona segura al empezar |
| `fin_libre` | metros sin enemigos antes del boss |
| `separacion` | metros entre filas `[inicio, fin]`; se divide por la densidad de la dificultad |
| `por_fila` | máximo de enemigos por fila `[inicio, fin]` (tope 3) |
| `tipos` | `{tipo: [peso_inicio, peso_fin, desde]}`; `desde` = punto del recorrido en que empieza a salir |
| `jefes` | `{tipo, z: [...]}` mini jefes en el carril central |
| `puertas` | z de las puertas de mejora |

Diseño actual:

- **Mapa 1**: goblins al principio, orcos a partir del 10 %, trolls desde el 45 %. Separación 20 → 10 m. Ogros en 250/500/750 m. 8 puertas repartidas.
- **Mapa 2**: zombis (3 modelos al azar) que avanzan hacia el player. Separación 14 → 7 m. *Brutes* (zombi ×1,6 de tamaño) en 300/600/850 m. 9 puertas.
- **Mapa 3**: provisional con los enemigos del mapa 1 (más trolls y 4 ogros) hasta que tenga los suyos.

## Reglas del generador

- **Carriles** x = −4, −2, 0, 2, 4 (con ±0,5 de variación). Como mucho **3 enemigos por fila**: siempre quedan 2 carriles libres para esquivar.
- **Separación mínima entre filas: 6 m** (a velocidad base, cambiar de carril lleva ~2,7 m de avance).
- **Zona libre de 7 m** alrededor de cada puerta y de cada mini jefe.
- El tipo de cada enemigo se elige al azar por peso según el punto del recorrido.
- Vida, daño y oro los pone `Enemy.setup(tipo, z, mapa)` desde [Balance](balance.md).

## Spawner (`Mapa`)

- `ADELANTE = 80 m`: los enemigos se crean cuando el player está a esa distancia (la cámara ve ~60 m).
- `DETRAS = 15 m`: los enemigos superados se eliminan (sin dar oro), revisando cada 0,5 s.
- `SPAWNS_POR_FRAME = 2`: reparte el coste de instanciar.
- Al montar el mapa se crean ya los de los primeros 80 m (durante el fundido a negro).
- Resultado: 8-15 enemigos vivos a la vez en lugar de 70-180.

## Añadir un mapa nuevo

1. Crear `scenes/mapas/mapa4.tscn` (copiar uno existente) y asignar sus escenas exportadas.
2. Crear `mapa4.gd` con `extends Mapa`, `numero = 4`, `boss_name` y `escena_de(tipo)` (y `prepara()` si hace falta).
3. Añadir el diseño en `Niveles.MAPAS[4]` y los multiplicadores en `Balance.MAPAS[4]`.
4. Añadir la ruta a `RUTAS_MAPAS` en `main.gd` (precarga) y revisar el final de partida (`muere_boss`, que termina en el mapa 3).
5. **Añadir la escena a `export_files` del preset Android** en `export_presets.cfg`: se carga por ruta desde código y Godot no la exportaría (pantalla negra en el móvil). Ver [android.md](android.md).

## Añadir un tipo de enemigo

Ver [enemigos.md](enemigos.md).
