# Validación de Places New v2

## Checkpoint vigente: corrección de atribución

Fecha: 2026-10-20. Checkout: C:/Users/Usuario/Documents/GitHub/flutter_google_places_2. Base verificada: HEAD 079cdc1429f89579a35287f75c02300fdc8ebb1c (Update to Places (New)), main, limpio antes de esta intervención. Versión 2.0.0 conservada. La corrección descrita aquí queda local, sin stage, commit, push ni publicación. La app consumidora no se modificó.

Se corrigió el logo que desaparecía cuando llegaban predicciones en overlay y fullscreen. Ahora queda fuera de la lista desplazable. El overlay descuenta el teclado y fullscreen protege el pie con SafeArea. Se conserva el widget/asset existente y el parámetro logo; no cambian cliente HTTP, modelos, filtros, sesiones, selección ni mensajes de error. No se agregaron dependencias ni se cambiaron pubspec.yaml, pubspec.lock o archivos generados.

La [política oficial de atribución](https://developers.google.com/maps/documentation/places/web-service/policies) exige que ésta permanezca visible junto al contenido. Permite temporalmente mantener la marca Google en implementaciones existentes; por eso se reutilizan los assets Legacy para preservar su apariencia. Google recomienda Google Maps para nuevas implementaciones. El consumidor que sustituya logo debe proporcionar una atribución válida y legible.

## Resultado local actual

Entorno: Windows, Flutter 3.47.7 estable / Dart 3.13.5.

| Comprobación | Resultado |
| --- | --- |
| Regresión antes del cambio | 8/8 fallan por atribución ausente, red.log |
| Teclado y área del sistema | Regresiones adicionales detectaron ocultamiento; corregido |
| Suite completa final | 93/93, exit 0, full-final-tests.log y test-result.json |
| Nuevas regresiones | 16 combinaciones: ambos modos, temas, logos predeterminado/personalizado, teclado abierto/cerrado y barra del sistema; desplazamiento y selección final |
| Dart MCP applyFixes:false, lib/test/example/lib | No errors, invocado antes y después de editar |
| Formato Dart | 25 archivos, 0 cambios pendientes |
| git diff --check | Sin errores |
| Referencias visuales | 8 de vacío/carga intactas por SHA256; sólo 4 de resultados actualizadas tras inspección visual |
| Dependencias y configuración | SHA256 idénticos a la base, incluidas las fuentes generadas |
| Git | HEAD e índice conservados; cambios locales revisables |

Evidencia de esta corrección: build/attribution-validation/ en este fork (directorio ignorado por Git). Incluye baseline.json, goldens-before/, golden-differences/, intentos RED/GREEN, log final completo, resultado con fecha, logs de formato/MCP/diff y manifiesto de integridad. El primer intento de --update-goldens falló por acceso denegado al escribir desde el proceso de pruebas; no se cambiaron ACL. Se guardaron explícitamente las cuatro imágenes reales ya generadas e inspeccionadas, conservando originales/diferencias, y se repitió la suite completa sin --update-goldens con éxito. No se ocultaron fallos ni se regeneraron las otras ocho referencias.

Los bloques negros del texto en los goldens corresponden a la fuente Ahem determinista del entorno de pruebas. No certifican tipografía ni dispositivo real. Los logos e iconos son assets reales.

## Cobertura conservada

Las 77 pruebas de la base siguen pasando: Autocomplete/Query Predictions, Details con máscaras parciales, Nearby, Text Search/paginación y Photos; identidad Android/iOS compartida, proxy, propiedad del cliente y redirecciones deshabilitadas. Incluyen errores HTTP/transporte/identidad/JSON y redacción de claves; validaciones locales sin HTTP.

Widgets: selección/cancelar, foco, token por apertura compartido con Details, cursor Unicode, respuestas fuera de orden, invalidación inmediata de filas, cierre con HTTP pendiente o durante la transición, controladores internos/externos, reset/validator, selección tras desmontar y coordenadas parciales sin fabricar cero. La revisión anterior del paquete corrigió esos casos; el fallo de atribución descubierto al revisar el commit actual queda cubierto por las 16 regresiones de esta intervención.

La generación con json_serializable y la resolución de dependencias fueron verificadas en la entrega anterior, no se repitieron aquí porque esta corrección no modifica modelos ni dependencias. No se afirma que las versiones sigan siendo las últimas disponibles. La evidencia histórica anterior está en appfloridomobile/build/places-new-v2-evidence y build/places-new-recheck-20261020; la tabla anterior y build/attribution-validation son el cierre local vigente.

## Comandos y reproducción

~~~sh
flutter test --no-pub test/places_attribution_test.dart --reporter expanded
flutter test --no-pub --reporter expanded
dart format --output=none --set-exit-if-changed lib test example
git diff --check
~~~

Ejecutar también Dart MCP analyze_files(applyFixes:false) sobre lib, test y example/lib con el URI file:///C:/Users/Usuario/Documents/GitHub/flutter_google_places_2. No usar --update-goldens al verificar; las cuatro referencias actuales ya incluyen la atribución. No editar .g.dart manualmente.

## SHA256 de los archivos funcionales afectados

| Archivo | SHA256 |
| --- | --- |
| lib/src/flutter_google_places.dart | 09C58BDD936D7D10299EE398CA42E9407F6A28E9054449A15C76007A77FE9647 |
| test/helpers/places_test_harness.dart | 5A6AD4B35CDFCEE57882B6B7247264D55545F82C175AD83A47AF632C7AFE1BF8 |
| test/places_attribution_test.dart | 81E660C2638ECF2B810628D8B383F7A68204FE01A337D3DC8226C474F1724BAD |
| test/goldens/places/overlay-light-results.png | 2282B699CBC8A785F8175EE75033C506D4311BEBCA5048C1C6D2D1DE0AC3CEF6 |
| test/goldens/places/overlay-dark-results.png | A13DC668B2A84F17711A8E9777234FD91F69E24E1EBFD6A72F976468D015FEBA |
| test/goldens/places/fullscreen-light-results.png | 79EB2833BDC330936C3DF39F3A0239029C6EC5FCAA7F6B3C08118421D77D48E0 |
| test/goldens/places/fullscreen-dark-results.png | 3AC44DB84D6B1071C76E6E853092071E129F7ED0B969B21B4D8E7420B7C08DA3 |

## Pendientes externos antes de activar la app

No se hicieron solicitudes reales a Google ni cambios de claves/Cloud. Los tres DTD encontrados se conectaron sin apps activas; el intento de hot reload devolvió No active app connection. No se presenta una recarga ni una ejecución móvil como realizada. No se certificaron APK/AAB, Android real, iOS, Web/CORS ni proxy desplegado desde este paquete.

1. Verificar Places API (New) habilitada, proyecto, facturación/cuotas y restricciones de clave.
2. Inspeccionar el certificado efectivo del APK. En Autocomplete y Details comprobar éxito con identidad correcta y rechazo con paquete incorrecto y certificado incorrecto, sin registrar claves. Los mocks no prueban restricciones remotas. Si no se cumplen, revisar proxy autenticado o integración nativa antes de activar conexión directa.
3. Verificar Search/Photos reales y atribuciones de autor si se usan; la app consumidora debe mostrar los créditos exigidos.
4. Comparar direcciones de Tijuana/alrededores, edificios/interiores, colonias y sin número. street_address no demuestra equivalencia con address. El radio 71450 no es válido en Places New; el máximo aceptado es 50000.
5. Confirmar apariencia, teclado, desplazamiento, cancelar/seleccionar y marcador/cámara en Android. iOS, Web/origen/CORS y proxy requieren comprobaciones propias.

Siguiente paso: integrar la API Dart v2 en la app, ajustar sites_maps.dart y actualizar su referencia Git cuando el usuario disponga de estos cambios en el remoto. Esta intervención se detiene antes de modificar esa app. Los resultados locales no equivalen a aceptación de Google Play.
