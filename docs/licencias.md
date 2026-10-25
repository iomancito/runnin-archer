# Licencias y créditos

Registro de **todos los recursos de terceros** del juego: de dónde salen, su licencia y si obligan a dar crédito. Al añadir un recurso nuevo, apuntarlo aquí (y en la pantalla de créditos si lo exige su licencia) **antes** de publicar.

Estado: ✅ confirmado (hay fichero de licencia o metadatos) · ❓ pendiente de confirmar el origen.

## Recursos

| Recurso | Dónde está | Autor / origen | Licencia | ¿Crédito obligatorio? | Estado |
|---|---|---|---|---|---|
| Motor Godot Engine | — | Juan Linietsky, Ariel Manzur y colaboradores ([godotengine.org](https://godotengine.org/license)) | MIT | **Sí**: incluir el aviso de copyright y la licencia MIT de Godot (y de sus bibliotecas de terceros) | ✅ |
| Stylized Nature MegaKit (árboles, arbustos, plantas, rocas y sus texturas) | `assets/externos/Nature/` (original en `/mnt/D2T/GodotRecursos/models3d/nature`) | Quaternius ([quaternius.com](https://quaternius.com)) | CC0 1.0 | No (se agradece mencionarlo) | ✅ `License_Standard.txt` |
| Árboles y arbustos con copas simplificadas (derivados del MegaKit) | `assets/naturaleza_simple/` | Quaternius, modificados con `tools/simplificar_copas.py` | CC0 1.0 | No | ✅ |
| BinbunVFX Vol.2: Explosion, Electric y Elemental Magic FX | `assets/BinbunVFX_Vol2/` | Binbun3D ([bun3d.com](https://bun3d.com)) | CC0 1.0 | No (se agradece mencionarlo) | ✅ `license.txt` |
| Fuente Nunito (ExtraBold, Black) | `assets/fonts/` | Vernon Adams, Cyreal, Jacques Le Bailly ([googlefonts/nunito](https://github.com/googlefonts/nunito)) | SIL Open Font License 1.1 | No en pantalla; la licencia debe acompañar a la fuente (ya está en `LICENSE.txt`) | ✅ |
| Modelo "Arrows" | `assets/weapons/arrows.gltf` | Akshat ([sketchfab](https://sketchfab.com/3d-models/arrows-2763023886cb4cb2a920b292d7024051)) | CC-BY 4.0 | **Sí**: "Arrows" by Akshat, CC-BY 4.0 | ✅ `assets/weapons/license.txt` |
| Signal Lens (autoload de depuración, se exporta con el juego) | `addons/signal_lens/` | Yann Lemos | MIT (Godot Asset Library) | Sí, si se distribuye: incluir su aviso MIT. Mejor **quitar el autoload** de las builds de publicación | ❓ falta el fichero de licencia en el addon |
| G-Kanban (solo editor, no se exporta) | `addons/gkanban/` | Leon Oscar Kidando, H4x0r_000 | MIT | No (no va en el APK) | ✅ `LICENSE` |
| Arquera (personaje "Erika Archer") | `assets/archer/archer.glb` | Probablemente Adobe Mixamo | Licencia de Mixamo (uso libre en juegos, sin crédito; no redistribuir el modelo suelto) | No | ❓ |
| Animaciones de personajes y zombis | `assets/archer/`, `scenes/enemies/map2/zombies/` | Probablemente Adobe Mixamo (`/mnt/D2T/GodotRecursos/AnimacionesMixamo`) | Licencia de Mixamo | No | ❓ |
| Enemigos del mapa 1: goblin, orco, troll, ogro, dragón rojo | `scenes/enemies/map1/` | ? | ? | ? | ❓ |
| Enemigos del mapa 2 y 3: zombis, dragón negro, zombi con espada | `scenes/enemies/map2/` | ? (¿`/mnt/D2T/GodotRecursos/models3d/zombies`?) | ? | ? | ❓ |
| Arcos especiales | `assets/weapons/arco1.glb` … `arco5.glb` | ? | ? | ? | ❓ |
| Flecha | `assets/weapons/arrow.glb`, `assets/images/arrow.jpg` | ? | ? | ? | ❓ |
| Texturas de terreno: `ganges_river_pebbles`, `rock_face`, `rocky_terrain` | `assets/textures/terrain/` | Por el nombre, Poly Haven ([polyhaven.com](https://polyhaven.com)) | CC0 1.0 (si son de Poly Haven) | No | ❓ |
| Textura de hierba | `assets/textures/terrain/grass.jpg` | ? | ? | ? | ❓ |
| Texturas de ruido para efectos (`T_*`) | `assets/textures/noise/` | ? | ? | ? | ❓ |
| Sonido `bullet_explode.wav` | `assets/weapons/bullet/` | ? | ? | ? | ❓ |
| Ilustración del splash, iconos e imágenes de los arcos | `assets/images/` | ¿Propios o generados con IA? Si son de IA, apuntar la herramienta y revisar sus términos de uso comercial | — | — | ❓ |

## Pendiente

- Confirmar el origen y la licencia de cada fila ❓. Si alguna no tiene licencia clara, sustituir el recurso antes de publicar.
- Guardar junto a cada recurso un `license.txt` con autor, URL y licencia (como en `assets/weapons/` y `assets/fonts/`).
- Si un recurso es CC-BY (o cualquier licencia con atribución), añadirlo a la pantalla de créditos.

## Pantalla de créditos

Los créditos se ven en el juego desde el menú principal (botón CREDITS). El texto está en [`scenes/gui/credits.gd`](../scenes/gui/credits.gd): al cambiar esta tabla, actualizarlo también. Incluye como mínimo:

- Lo obligatorio: Godot Engine (aviso MIT, se puede mostrar con `Engine.get_license_text()`) y "Arrows" by Akshat (CC-BY 4.0).
- Como agradecimiento: Quaternius, Binbun3D, fuente Nunito.
