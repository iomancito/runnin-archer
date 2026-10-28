# Roadmap: anuncios, versión sin anuncios y publicación en Google Play y App Store

Plan para pasar de la build de pruebas actual a una app publicada en las dos tiendas, gratis con anuncios (AdMob) y con una opción de pago sin anuncios. Fechas y requisitos comprobados en octubre de 2026: **revisarlos antes de cada fase**, las tiendas los cambian cada año.

## Decisión de modelo: una sola app con compra "Remove Ads" (recomendado)

| | A. Una app gratis + compra integrada "Remove Ads" | B. Dos apps: gratis con anuncios y de pago |
|---|---|---|
| Fichas en la tienda | 1 (reseñas y descargas juntas) | 2 |
| Progreso al pasar a pago | Se conserva (es la misma app) | Se pierde salvo que se sincronice con un servidor |
| Builds que mantener | 1 | 2 (dos paquetes, dos firmas, dos fichas, dos revisiones) |
| Apple | Lo que prefiere su guía | Las versiones "lite" duplicadas pueden rechazarse (guía 4.3, *spam*) |
| Trabajo extra | Plugin de compras (Play Billing / StoreKit) y botón "Restore purchases" | Ninguno de pagos, pero todo lo demás duplicado |

**Recomendación: A.** Un producto **no consumible** `remove_ads` (p. ej. 2,99 €) que quita los anuncios intersticiales para siempre. Los anuncios **con recompensa** (ver un vídeo a cambio de oro) se pueden dejar también en la versión de pago porque los elige el jugador. El resto del documento sigue la opción A; si se eligiera la B, las fases 4 y 7 cambian de "compra integrada" a "segundo paquete" (otro `package/unique_name` y otra ficha).

## Dónde poner los anuncios (sin estropear el juego)

En partida no: la partida es táctil a pantalla completa y en el móvil de pruebas ya va justa de rendimiento (ver [rendimiento.md](rendimiento.md)).

| Formato | Dónde | Frecuencia |
|---|---|---|
| **Intersticial** | Al pasar de la pantalla de resultados al menú o al siguiente mapa | Como mucho 1 cada 3 partidas o cada 4 min; nunca en la primera sesión |
| **Con recompensa** (opcional, también en la versión de pago) | Botón en resultados: "Watch an ad: x2 gold"; o "Revive" una vez por partida | Lo decide el jugador |
| Banner | Solo en menú y tienda, o ninguno | — |

Toda la lógica de anuncios en un autoload nuevo (`Anuncios`), que no hace nada si la compra está hecha, si no hay conexión o si el SDK no está (escritorio, tests sin pantalla). Los números (frecuencia, multiplicador de oro del vídeo) en `Balance`.

---

## Fase 0 — Bloqueos que hay que resolver antes de publicar nada

- [ ] **Licencias** (ver [licencias.md](licencias.md)): sustituir o confirmar el dragón esqueleto (sin licencia, posiblemente de un juego comercial), los esqueletos mago/pícaro (sin licencia), el dragón negro (confirmar CC-BY), la cría de dragón (términos de Meshy) y el resto de filas ❓. Sin esto, la app se puede retirar por denuncia de copyright.
- [ ] **Nombre del paquete**: `package/unique_name` es `com.example.$genname` → elegir el definitivo (p. ej. `com.<tu_dominio>.runningarcher`). **No se puede cambiar una vez publicado.** Para iOS el *Bundle ID* debería ser el mismo.
- [ ] Quitar el autoload de depuración `SignalLens` y `settings/stdout/verbose_stdout` de las builds de publicación.
- [ ] Revisar textos en inglés, icono, splash y créditos (aviso MIT de Godot ya incluido).
- [ ] **Política de privacidad** publicada en una URL (obligatoria en las dos tiendas y para AdMob): qué datos recoge AdMob, que el progreso se guarda solo en el dispositivo, contacto. Hace falta una web mínima (GitHub Pages sirve), que también aloja `app-ads.txt`.

## Fase 1 — Cuentas (se puede empezar ya, en paralelo)

| Cuenta | Coste | Notas |
|---|---|---|
| Google Play Console | 25 $ una vez | Verificación de identidad. **Cuenta personal nueva: antes de producción hay que hacer una prueba cerrada con ≥ 12 testers durante 14 días seguidos** → empezar a reunir testers pronto (mejor 15-20 por si alguno se da de baja). Las cuentas de organización no tienen este requisito pero piden D-U-N-S |
| Apple Developer Program | 99 $/año | Necesita un **Mac con Xcode 26** (desde el 28-04-2026 App Store Connect solo acepta builds con el SDK 26) y un iPhone para probar |
| AdMob | Gratis | Crear la app (Android e iOS por separado), unidades de anuncio, datos de pago y fiscales (formulario W-8BEN para EE. UU.) |
| Perfil de pagos (Play) y *Paid Apps Agreement* (Apple) | — | Imprescindibles para vender `remove_ads`. Datos bancarios y fiscales |
| Estatus de comerciante (UE, DSA) | — | Si se vende algo, las dos tiendas piden declararse *trader* y **muestran públicamente nombre, dirección y contacto**. Valorar darse de alta como autónomo/empresa o usar una dirección profesional |

## Fase 2 — Preparar la build de Android para Google Play

- [ ] **Gradle build** (`gradle_build/use_gradle_build=true`): obligatorio para los plugins de AdMob y Billing. Instalar la plantilla de compilación de Android desde el editor.
- [ ] Formato **AAB** (`gradle_build/export_format=1`): Play no acepta APK para apps nuevas.
- [ ] **SDK objetivo**: a partir del **31-08-2026** las apps nuevas y las actualizaciones deben apuntar a **Android 16 (API 36)** (prórroga posible hasta el 01-11-2026). Comprobar qué pone Godot 4.7 por defecto y fijar `gradle_build/target_sdk=36` si hace falta; probar en el móvil.
- [ ] **Firma**: crear la *upload key* (keystore propio, guardarlo con copia de seguridad fuera del repo) y activar **Play App Signing**.
- [ ] `version/code` creciente en cada subida y `version/name` (p. ej. `1.0.0`).
- [ ] Permisos: `INTERNET` y `ACCESS_NETWORK_STATE` (ahora están desactivados; los necesitan los anuncios y las compras). `AD_ID` lo añade el SDK de anuncios.
- [ ] Solo `arm64-v8a` está bien (Play exige 64 bits); valorar `armeabi-v7a` solo si se quiere llegar a móviles muy viejos.
- [ ] Medir el tamaño del AAB (APK actual ~107 MB). Play acepta 200 MB por descarga; por encima habría que usar *Play Asset Delivery*.

## Fase 3 — AdMob en Android

- [ ] Plugin: **Poing Studios AdMob plugin** (MIT, Godot 4.2+, Android e iOS, v5.0) o el de **godot-sdk-integrations/godot-admob** (v6 para Godot 4.5+). Elegir uno que cubra **las dos plataformas** para no escribir dos veces el autoload; comprobar en GitHub que la versión funciona con Godot 4.7.
- [ ] Usar los **IDs de prueba de Google** mientras se desarrolla (usar los reales en pruebas puede suspender la cuenta de AdMob por clics inválidos). Registrar el móvil de pruebas como dispositivo de prueba.
- [ ] **Consentimiento (UMP)**: en el EEE, Reino Unido y Suiza es obligatorio pedir consentimiento antes de mostrar anuncios personalizados. El SDK trae el formulario de Google (UMP); configurar el mensaje en AdMob → *Privacy & messaging*. Opción "Privacy settings" en el menú para cambiarlo después.
- [ ] Público objetivo **13+** (no "niños"): si la app se dirige a menores entra en la política de Familias y solo admite redes de anuncios certificadas. Marcar el contenido como *no dirigido a niños* en AdMob y en Play.
- [ ] Autoload `Anuncios`: precargar el intersticial al empezar la partida, mostrarlo en las transiciones de la tabla de arriba, pausar el audio mientras se ve, y no mostrar nada si `Progreso.sin_anuncios`.
- [ ] Probar en el móvil: tiempo de arranque, memoria, que el juego **siga a 40-60 FPS** con el SDK cargado, botón atrás durante un anuncio, app en segundo plano, sin conexión.
- [ ] Publicar `app-ads.txt` en la web del desarrollador (la misma URL que en la ficha de Play).

## Fase 4 — Compra "Remove Ads" en Android

- [ ] Plugin oficial **GodotGooglePlayBilling** (godot-sdk-integrations, Godot 4.2+). Ojo: su API cambió (docs de 4.4 usan el singleton y señales; las nuevas, `BillingClient` y `start_connection`).
- [ ] Crear el producto no consumible `remove_ads` en Play Console (requiere el perfil de pagos).
- [ ] Flujo: comprar → **reconocer (acknowledge) la compra** (si no, Google la reembolsa a los 3 días) → guardar `sin_anuncios` en `Progreso` (nueva migración del guardado) → ocultar anuncios.
- [ ] Al arrancar, consultar las compras del usuario para restaurarla (cambio de móvil, reinstalación).
- [ ] Botón en el menú o la tienda: "Remove Ads" con el precio que devuelve la tienda (no escrito a mano: varía por país).
- [ ] Probar con **cuentas de prueba de licencias** de Play Console (compras sin cobro).

## Fase 5 — Ficha de Google Play y prueba cerrada

- [ ] Ficha: título, descripción corta (80) y larga (4000), icono 512×512, gráfico destacado 1024×500 (hecho: `docs/tienda/feature_graphic_1024x500.png`), 2-8 capturas de móvil (mejor 4+ en vertical), vídeo opcional. En inglés y, si se quiere, español.
- [ ] Cuestionarios de la consola: **clasificación de contenido (IARC)** (violencia de fantasía), **público objetivo** (13+), **anuncios: sí**, **seguridad de los datos** (AdMob recoge el ID de publicidad, datos de uso y de diagnóstico; compras; nada se vende), política de privacidad, acceso a la app (sin login), declaración del ID de publicidad.
- [ ] Prueba interna (hasta 100 testers, sin revisión) → **prueba cerrada ≥ 12 testers durante 14 días** (cuenta personal) → solicitar acceso a producción (pide responder cómo se ha probado y qué se ha cambiado).
- [ ] Revisar el *pre-launch report* de Play (pruebas automáticas en móviles reales) y Android vitals (ANR, cierres).
- [ ] Lanzamiento en producción, mejor por fases (*staged rollout* 20 % → 100 %).

## Fase 6 — Build de iOS

- [ ] Mac con **Xcode 26**; exportar desde Godot con el preset de iOS (genera un proyecto de Xcode) y compilar/firmar en Xcode.
- [ ] Crear el *App ID* / *Bundle ID* y los perfiles de firma; equipo de desarrollo en el preset.
- [ ] Renderer: Godot usa Metal en iOS; volver a medir rendimiento en un iPhone (sombras y efectos como en [rendimiento.md](rendimiento.md)). Probar varios tamaños de pantalla y la *safe area* (muesca / Dynamic Island) en la interfaz.
- [ ] Ajustes del juego: no hay botón atrás (el menú de pausa ya cubre salir); comprobar el ciclo de vida en segundo plano y el guardado.
- [ ] Iconos de iOS (1024×1024 sin transparencia) y pantalla de carga.

## Fase 7 — AdMob y compras en iOS

- [ ] Mismo plugin de AdMob que en Android (parte iOS) o el iOS AdMob plugin de godot-sdk-integrations.
- [ ] **App Tracking Transparency (ATT)**: pedir permiso antes de los anuncios personalizados; texto `NSUserTrackingUsageDescription` en el Info.plist. Si dice que no, anuncios no personalizados.
- [ ] `GADApplicationIdentifier` y la lista `SKAdNetworkItems` que indica Google en el Info.plist.
- [ ] **Privacy manifest** (`PrivacyInfo.xcprivacy`): el SDK de Google trae el suyo; añadir el de la app si usa APIs de la lista de Apple (p. ej. fechas de archivos o `UserDefaults`).
- [ ] Compras: plugin con **StoreKit 2** (p. ej. *Godot StoreKit* o *godot-iap/OpenIAP*; el *Godot iOS plugin for In-App purchase* de hrk4649 tiene versión para 4.7 pero usa StoreKit en Swift: comprobar). Producto no consumible `remove_ads` en App Store Connect.
- [ ] **Botón "Restore Purchases" obligatorio** en iOS para compras no consumibles (Apple rechaza la app sin él).
- [ ] Probar con cuentas *sandbox* y con un archivo de configuración StoreKit en Xcode.

## Fase 8 — App Store Connect y revisión de Apple

- [ ] Ficha: nombre (30), subtítulo, descripción, palabras clave, URL de soporte, URL de la política de privacidad, capturas (como mínimo las de iPhone de 6,9"; iPad solo si se publica para iPad).
- [ ] **App Privacy** ("etiquetas de nutrición"): mismos datos que en la seguridad de datos de Play (identificadores, datos de uso, diagnósticos, compras; *usados para seguimiento* si hay anuncios personalizados).
- [ ] Clasificación por edades (cuestionario nuevo), cumplimiento de exportación (`ITSAppUsesNonExemptEncryption = false`: no hay cifrado propio), *Paid Apps Agreement* firmado.
- [ ] **TestFlight**: pruebas internas (sin revisión) y externas (revisión ligera).
- [ ] Enviar a revisión. Motivos de rechazo habituales a prevenir: falta "Restore Purchases", ATT pedido sin explicación o pedido después de mostrar anuncios, anuncios que tapan controles, enlaces de privacidad rotos, cierres en el iPhone del revisor.

## Fase 9 — Después de publicar

- [ ] Vigilar cierres (Android vitals, Xcode Organizer) y valoraciones.
- [ ] Ajustar la frecuencia de intersticiales con datos (retención vs. ingresos) — en `Balance`.
- [ ] Mantenimiento anual obligatorio: nuevo SDK objetivo de Android cada agosto (API 37 previsiblemente en 2027) y nuevo Xcode/SDK de Apple cada primavera; renovar la cuota de Apple.
- [ ] Mantener al día los plugins (AdMob, Billing, StoreKit) y el formulario de consentimiento.

## Orden y estimación

| Semana | Trabajo |
|---|---|
| 1 | Fase 0 (licencias, paquete, privacidad, web) y fase 1 (cuentas). Empezar a reunir testers |
| 2-3 | Fases 2-4: build AAB firmada, AdMob con consentimiento, compra `remove_ads`; pruebas en el móvil |
| 3 | Fase 5: ficha y prueba interna → **prueba cerrada (14 días)** |
| 4-5 | Mientras corre la prueba cerrada: fases 6-7 en el Mac (iOS) |
| 5-6 | Producción en Google Play; fase 8 (TestFlight y revisión de Apple, 1-3 días por envío) |

Coste fijo mínimo: **25 $** (Google, una vez) + **99 $/año** (Apple) + un Mac con Xcode 26 si no se tiene.

## Fuentes

- Requisito de SDK objetivo de Google Play: [developer.android.com/google/play/requirements/target-sdk](https://developer.android.com/google/play/requirements/target-sdk)
- Prueba cerrada de 12 testers / 14 días: [support.google.com/googleplay/android-developer/answer/14151465](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- Requisito de Xcode 26 / SDK 26 (Apple): [developer.apple.com/news/upcoming-requirements](https://www.developer.apple.com/news/upcoming-requirements/)
- Plugin oficial de Google Play Billing: [docs.godotengine.org — Android in-app purchases](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_in_app_purchases.html), [github.com/godot-sdk-integrations/godot-google-play-billing](https://github.com/godot-sdk-integrations/godot-google-play-billing)
- Plugins de AdMob: [Poing Studios (asset library)](https://www.godotengine.org/asset-library/asset/2063), [iOS AdMob plugin de godot-sdk-integrations](https://godotengine.org/asset-library/asset/edit/20615)
- Compras en iOS: [Godot iOS plugin for In-App purchase](https://godotengine.org/asset-library/asset/4709), [foro: StoreKit 1 vs 2](https://forum.godotengine.org/t/ios-in-app-purchase-godot-4-4/106649)
