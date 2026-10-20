# Validación de Places New v2

Fecha: 2026-10-20. **Entrega local completada en el checkout del fork** C:/Users/Usuario/Documents/GitHub/flutter_google_places_2, versión 2.0.0. La app consumidora no se modificó ni se activó. Cambios sin stage, commit ni push; HEAD permanece en fd99ecd7d3fe992823b18fc1ab69243dcc09ad63.

## Resultado local

Entorno: Windows, Flutter 3.47.7 estable / Dart 3.13.5.

| Comprobación | Resultado |
| --- | --- |
| Suite completa en el fork real | 77/77, real-final-tests.log |
| Dart MCP applyFixes:false, lib/test/example/lib | No errors, real-mcp-final.log |
| Generación con json_serializable 6.15.2 | Correcta, real-codegen.log |
| Formato Dart | 24 archivos, 0 cambios pendientes |
| pub get y pub outdated | Correctos; sólo dos transitivas fijadas por Flutter |
| diff --check | Sin errores |
| Doce referencias visuales Legacy | Comparación aprobada sin regenerar; hashes originales conservados |

Las dependencias directas están en las últimas versiones compatibles consultadas al cerrar. material_color_utilities 0.13.0 frente a 0.13.1 y test_api 0.7.12 frente a 0.7.15 están fijadas por el SDK; comentarios en pubspec explican el límite. meta pasó a transitiva al retirar el transporte Legacy. No se agregaron dependencias.

## Cobertura y revisión

HTTP sintético: Autocomplete/Query Predictions, Details con máscaras parciales, Nearby, Text Search/paginación y Photos/atribuciones/recurso vencido; identidad Android/iOS compartida, prefijo de proxy, propiedad del cliente y redirecciones deshabilitadas. Errores 400/403/404/429/500, transporte, identidad, JSON inválido y claves redactadas. Validaciones locales no emiten HTTP.

Widgets: overlay/fullscreen, claro/oscuro, vacío/carga/resultados, logo e iconos reales, foco/teclado sintético, selección/cancelar, token único por apertura y compartido con Details, cursor Unicode, respuestas fuera de orden, cierre con HTTP pendiente, controladores internos/externos, reset/validator y selección tras desmontar. Los goldens usan 400x800 y Ahem determinista; no certifican fuentes ni dispositivos reales.

Revisor independiente con contexto fresco: /root/places_v2_final_review, gpt-6-astra/high. Detectó tres hallazgos importantes, corregidos en una pasada con diez regresiones RED antes del cambio y GREEN posterior:

- Fin de sesión inmediato al pop, incluyendo animación de salida, botón, sistema y barrera.
- Filas invalidadas al editar; debounce únicamente para HTTP y selección protegida por generación/consulta.
- Componentes de coordenadas nullable en respuestas con máscaras anidadas; solicitudes exigen coordenadas completas, finitas y en rango. Nunca se fabrica cero. Ejemplo probado con ubicación completa, ausente y parcial.

Resultado posterior: 13/13 focales y 77/77 completos. No quedaron hallazgos locales pendientes. Se retiraron seis archivos Legacy; ningún método público conserva llamadas a esos endpoints.

La copia al fork verificó HEAD y hashes previos antes de escribir, y comprobó los archivos aplicados. Se conservaron los documentos aprobados, pruebas, ejemplo y doce goldens. Logs, hashes y ledger están en appfloridomobile/build/places-new-v2-evidence.

## Reproducción

~~~sh
flutter pub get --no-example
flutter pub outdated --json
dart run build_runner build
flutter test --no-pub
dart format --output=none --set-exit-if-changed lib test example
git diff --check
~~~

Ejecutar además Dart MCP analyze_files(applyFixes:false) con URIs file: completas de lib, test y example/lib. Los .g.dart se generan; no se editan manualmente. No usar --update-goldens para aceptar diferencias de la migración.

## Pendientes externos antes de activar una app

No se hicieron solicitudes reales a Google ni cambios de claves/Cloud. DTD no tiene una app debug conectada para recargar el fork. No se certificaron APK, Android real, iOS, Web/CORS ni proxy desplegado.

1. Verificar Places API (New) habilitada, proyecto, facturación/cuotas y API autorizada en las restricciones de clave.
2. Inspeccionar el certificado efectivo del APK. En Autocomplete y Details comprobar éxito con identidad correcta y rechazo con paquete incorrecto y certificado incorrecto, sin registrar claves. Los mocks no prueban restricciones remotas; si no se cumplen, revisar proxy autenticado o integración nativa antes de activar conexión directa.
3. Verificar Search/Photos reales si se usan, atribuciones y recursos caducados.
4. Comparar direcciones de Tijuana/alrededores, edificios/interiores, colonias y sin número. street_address es candidato, no equivalencia demostrada de address. El ejemplo usa radio explícito 50000; 71450 se rechaza.
5. Confirmar apariencia, teclado, cancelar/seleccionar y actualización de marcador/cámara en Android. iOS, Web/origen/CORS y proxy requieren comprobaciones propias.

La siguiente intervención es adaptar sites_maps.dart y actualizar la referencia Git de la app después del commit/push manual del usuario. Esta entrega se detiene antes de modificar esa app.
