# Roadmap: publicación gratuita en Google Play

Plan para pasar de la build de pruebas actual a una app publicada en Google Play, **gratis, sin anuncios y sin compras integradas**. Fechas y requisitos comprobados en octubre de 2026: **revisarlos antes de cada fase**, las tiendas los cambian cada año.

## Decisión de modelo: gratis y sin monetizar

El dragón negro (boss del mapa 2) tiene licencia **CC BY-NC 4.0**, que prohíbe el uso comercial. Por eso el juego se publica gratis y **sin ningún ingreso**: ni anuncios, ni compras integradas, ni versión de pago, ni donaciones dentro de la app. Así no hace falta AdMob ni Play Billing, ni permisos de red, ni formularios de consentimiento.

> **Si algún día se quiere monetizar**, antes hay que sustituir el dragón negro o comprarle una licencia comercial a su autor (3DHaupt, [3dhaupt.com](http://3dhaupt.com)), y revisar que el resto de licencias lo permiten (ver [licencias.md](licencias.md)). El plan anterior con AdMob y "Remove Ads" está en el historial de git de este archivo.

## Fase 0 — Bloqueos que hay que resolver antes de publicar nada

- [x] Dragón rojo sustituido por "Red Dragon 3D" (CC BY 4.0).
- [ ] **Licencias** (ver [licencias.md](licencias.md)): confirmar la textura de hierba y el splash/iconos. Sin esto, la app se puede retirar por denuncia de copyright.
- [x] Dragón negro: se puede usar porque el juego no da dinero. Crédito CC BY-NC ya en la pantalla de créditos.
- [x] **Nombre del paquete**: `com.ioman.runningarcher` (`package/unique_name`). **No se puede cambiar una vez publicado.**
- [x] Quitar el autoload de depuración `SignalLens` y `settings/stdout/verbose_stdout`; `addons/*` excluido de la exportación.
- [ ] Revisar textos en inglés, icono, splash y créditos (aviso MIT de Godot ya incluido).
- [ ] **Política de privacidad** publicada en una URL (Play la pide a todas las apps): el juego no recoge ni envía datos, el progreso se guarda solo en el dispositivo, contacto. Basta una página mínima (GitHub Pages sirve).

## Fase 1 — Cuenta (se puede empezar ya)

| Cuenta | Coste | Notas |
|---|---|---|
| Google Play Console | 25 $ una vez | Verificación de identidad. **Cuenta personal nueva: antes de producción hay que hacer una prueba cerrada con ≥ 12 testers durante 14 días seguidos** → empezar a reunir testers pronto (mejor 15-20 por si alguno se da de baja). Las cuentas de organización no tienen este requisito pero piden D-U-N-S |
| Estatus de comerciante (UE, DSA) | — | Sin ventas ni anuncios se puede declarar **no comerciante** (*non-trader*): Play no publica dirección ni teléfono |

## Fase 2 — Preparar la build de Android para Google Play

- [ ] **Gradle build** (`gradle_build/use_gradle_build=true`): necesario para exportar AAB. Instalar la plantilla de compilación de Android desde el editor.
- [ ] Formato **AAB** (`gradle_build/export_format=1`): Play no acepta APK para apps nuevas.
- [x] **SDK objetivo**: desde el **31-08-2026** hay que apuntar a **Android 16 (API 36)**. Godot 4.7 ya exporta con `targetSdk=36` (comprobado con `dumpsys package` en el móvil).
- [ ] **Firma**: crear la *upload key* (keystore propio, guardarlo con copia de seguridad fuera del repo) y activar **Play App Signing**.
- [ ] `version/code` creciente en cada subida y `version/name` (p. ej. `1.0.0`).
- [x] Permisos: ninguno (sin red). No activar `INTERNET` mientras no haga falta.
- [ ] Solo `arm64-v8a` está bien (Play exige 64 bits); valorar `armeabi-v7a` solo si se quiere llegar a móviles muy viejos.
- [ ] Medir el tamaño del AAB (APK actual ~105 MB). Play acepta 200 MB por descarga; por encima habría que usar *Play Asset Delivery*.

## Fase 3 — Ficha de Google Play y prueba cerrada

- [ ] Ficha: título, descripción corta (80) y larga (4000), icono 512×512, gráfico destacado 1024×500 (hecho: `docs/tienda/feature_graphic_1024x500.png`), 2-8 capturas de móvil (mejor 4+ en vertical), vídeo opcional. En inglés y, si se quiere, español.
- [ ] Cuestionarios de la consola: **clasificación de contenido (IARC)** (violencia de fantasía), **público objetivo** (13+; si se marca para niños entra en la política de Familias), **anuncios: no**, **seguridad de los datos** (no recoge ni comparte datos), política de privacidad, acceso a la app (sin login), ID de publicidad: no se usa.
- [ ] Prueba interna (hasta 100 testers, sin revisión) → **prueba cerrada ≥ 12 testers durante 14 días** (cuenta personal) → solicitar acceso a producción (pide responder cómo se ha probado y qué se ha cambiado).
- [ ] Revisar el *pre-launch report* de Play (pruebas automáticas en móviles reales) y Android vitals (ANR, cierres).
- [ ] Lanzamiento en producción, mejor por fases (*staged rollout* 20 % → 100 %).

## Fase 4 — Después de publicar

- [ ] Vigilar cierres (Android vitals) y valoraciones.
- [ ] Mantenimiento anual obligatorio: nuevo SDK objetivo de Android cada agosto (API 37 previsiblemente en 2027).
- [ ] No añadir anuncios, compras ni enlaces de donación mientras el dragón negro siga en el juego.

## Orden y estimación

| Semana | Trabajo |
|---|---|
| 1 | Fase 0 (licencias, política de privacidad) y fase 1 (cuenta). Empezar a reunir testers |
| 2 | Fase 2: build AAB firmada; pruebas en el móvil |
| 2-4 | Fase 3: ficha y prueba interna → **prueba cerrada (14 días)** |
| 4-5 | Producción |

Coste fijo: **25 $** (Google, una vez).

## Fuentes

- Requisito de SDK objetivo de Google Play: [developer.android.com/google/play/requirements/target-sdk](https://developer.android.com/google/play/requirements/target-sdk)
- Prueba cerrada de 12 testers / 14 días: [support.google.com/googleplay/android-developer/answer/14151465](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- Licencia CC BY-NC 4.0 (definición de "NonCommercial"): [creativecommons.org/licenses/by-nc/4.0](https://creativecommons.org/licenses/by-nc/4.0/)
