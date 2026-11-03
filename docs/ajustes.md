# Ajustes

Autoload `Ajustes` ([`scripts/ajustes.gd`](../scripts/ajustes.gd)) y pantalla [`settings.tscn`](../scenes/gui/settings.tscn) (engranaje en la esquina inferior derecha del menú principal). Se guardan en `user://ajustes.cfg`, aparte del progreso: RESET PROGRESS no los borra. La pantalla guarda al salir (BACK o botón atrás).

## Audio

| Ajuste | Bus | Inicial |
|---|---|---|
| Música | `Music` (vía `Musica.volumen`) | 50 % |
| Efectos | `Effects` (lo crea `Ajustes`) | 50 % |

La barra va de 0 a 100 en pasos de 5 con escala `linear_to_db` (50 % ≈ −6 dB); a 0 el bus se silencia. Al mover la barra de efectos suena un clic para oír el volumen. Los efectos están en [sonidos.md](sonidos.md).

## Vídeo

Qué se puede cambiar en tiempo de ejecución y cuánto importa en el móvil de pruebas (Mali-G57, ver [rendimiento.md](rendimiento.md)):

| Opción | Coste medido | ¿En ajustes? |
|---|---|---|
| Sombras del sol | ~6-7 ms de GPU (sin ellas ~55 FPS frente a ~40-46) | Sí, en el nivel de calidad |
| Resolución 3D (`scaling_3d_scale`) | 100 % ≈ 32 ms, 75 % ≈ 24 ms | Sí, en el nivel de calidad |
| Tope de FPS (`Engine.max_fps`) | — (batería y temperatura) | Sí: 30 / 60 |
| Glow | ~7 ms | No: ya desactivado en los mapas |
| Niebla, LOD, triángulos | inapreciable | No |

Niveles (`Ajustes.NIVELES`):

| Nivel | Sombras | Resolución 3D |
|---|---|---|
| LOW | no | 60 % |
| MEDIUM | no | 75 % |
| HIGH | sí | 75 % (lo que había antes de los ajustes) |
| ULTRA | sí | 100 % |

- Las sombras se aplican al montar cada mapa (`Ajustes.aplica_a_mapa`, también en el precalentado de la carga para compilar los shaders correctos); la resolución y los FPS al momento.
- **AUTO** (por defecto): empieza en HIGH, o MEDIUM si el móvil tiene menos de 3 GB de RAM. En partida (sin pausa, tras 3 s) mide los FPS medios cada 6 s; si bajan de 28 (o del 80 % del tope de 30) baja un nivel, lo guarda (`nivel_auto`) y quita las sombras del mapa en marcha si toca. Nunca sube sola. La pantalla muestra el nivel elegido ("Now: High").
- No se puede saber la potencia de la GPU por su nombre de forma fiable; medir en partida sí funciona en cualquier móvil.
