# Places New 2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking. Native execution approved by the user; independent final review required.

**Goal:** Migrar todo el funcionamiento Places que hoy ofrece el fork a Places API (New), manteniendo iguales sus widgets y su presentación.

**Architecture:** Reutilizar el renderizado y los streams existentes. Un PlacesClient compartido centraliza REST New, identidad y errores; solicitudes y modelos tipados sustituyen al protocolo Legacy. El widget devuelve la selección con su token y el consumidor decide cuándo consultar Details.

**Tech Stack:** Flutter 3.47.7 / Dart 3.13.5, http ^1.6.0, google_api_headers ^5.4.3, rxdart ^0.28.0, rxdart_ext ^0.4.0, listenable_stream ^2.0.1, json_serializable ^6.15.2 / build_runner ^2.17.1.

**Spec:** [Diseño aprobado](../specs/2026-10-20-places-new-v2-design.md). El usuario aprobó el diseño el 2026-10-20. Plan y ejecución nativa aprobados por el usuario. Ver docs/validation-v2.md y el ledger para el estado actual.

## Global Constraints

- Trabajar en C:/Users/Usuario/Documents/GitHub/flutter_google_places_2, base fd99ecd7d3fe992823b18fc1ab69243dcc09ad63. Verificar HEAD y cambios antes de ejecutar; conservar los documentos existentes.
- Publicar el resultado local como versión 2.0.0. El usuario hará commit/push y actualizará la referencia de la app; no stage, commit, reset, stash, clean ni worktree sin autorización explícita.
- No modificar ahora C:/Users/Usuario/Documents/Repositorios/0 - Mejora coordenadas/appfloridomobile ni activar New en esa app. La guía sí describirá los cambios necesarios en sites_maps.dart.
- Conservar Mode.overlay/fullscreen, navegación, foco, estilos, colores, márgenes, bordes, logo, scroll e indicador de carga. No añadir pantallas ni diálogos técnicos.
- Base New https://places.googleapis.com/v1. Ningún método público final debe seguir llamando a Legacy; no implementar fallback automático ni selector de versiones.
- Mantener sdk ^3.13.5 y las dependencias compatibles existentes; no añadir otro cliente Places ni paquetes de estado, UUID, mocking o goldens.
- Máscaras explícitas y no vacías para Details/Nearby/Text Search. Sin '*' por defecto; no pedir campos de coste mayor que el consumidor no usa.
- Radio de círculo válido entre 0 y 50000 inclusive; Autocomplete con locationRestriction requiere radio mayor que 0. No recortar 71450 silenciosamente.
- Modelos New: JSON camelCase, ausencia de campos Place representada por null; no fabricar datos Legacy. Las colecciones de respuestas vacías sí se representan como listas vacías.
- Usar Dart MCP analyze_files(applyFixes:false) antes/después de los cambios. Si no hay raíces, agregar la URI exacta y repetir; no sustituir ese gate por CLI.
- No modificar claves/configuración Cloud ni ejecutar peticiones reales en los tests. Registrar las validaciones de identidad/dispositivo aparte de los checks locales.
- Mantener los archivos generados sincronizados mediante build_runner; no editar .g.dart manualmente.

## Review Focus

1. Details con máscara id/location y campos omitidos: no crear nombres/coordenadas falsos ni fallar por modelos Legacy obligatorios (tarea 2).
2. Edición con emoji y cursor dentro del texto: inputOffset usa caracteres Unicode, no unidades UTF-16 (tarea 3).
3. Consulta anterior que termina después de borrar/cambiar texto o cerrar la pantalla: no mostrar resultados/callbacks obsoletos (tarea 3).
4. Field/FormField alternando controladores internos/externos y selección tardía: no perder texto, usar un controlador liberado ni cerrar uno ajeno (tarea 3).
5. Details directo, proxy y Photos: conservar identidad y prefijo de ruta sin reenviar claves a otra URL ni cerrarle el cliente HTTP al consumidor (tareas 2 y 4).

## Estructura y convenciones comunes

Los paths de las tareas son relativos al fork. Evidencia temporal en build/places-new-v2/; tests y goldens bajo test/ se conservan en el repositorio. No aceptar cambios de goldens generados después de migrar como prueba de igualdad.

Publicar los nuevos tipos desde lib/flutter_google_places_2.dart. lib/google_maps_webservice_places.dart se puede mantener como barrel de los tipos New para facilitar el cambio de imports; no exportará el transporte/modelos Legacy. Antes de retirar el directorio antiguo, buscar imports internos y corregirlos en las tareas 3/4.

Conservar serialización generada con @JsonSerializable(explicitToJson: true, includeIfNull: false), sin FieldRename.snake. Los discriminadores de suggestions requieren una factory que elija placePrediction o queryPrediction; una respuesta mal formada produce el error de protocolo definido en la tarea 2.

## Tarea 1: Fijar la referencia visual e interacciones del código actual

**Files:**
- Create: test/places_autocomplete_test.dart, test/places_autocomplete_fields_test.dart.
- Create: test/helpers/places_test_harness.dart, test/fixtures/legacy_autocomplete.json, test/goldens/places/*.png.
- Read only: lib/src/flutter_google_places.dart, places_autocomplete_field.dart, places_autocomplete_form_field.dart.

**Interfaces:**
- Consumes: API Legacy vigente de PlacesAutocomplete.show, PlacesAutocompleteWidget, Field y FormField.
- Produces: capturas deterministas y tests cuyos datos visibles serán los mismos tras migrar. Un harness solo en tests aísla la creación Legacy/New para no duplicar escenarios.

- [x] **1. Verificar baseline:** registrar HEAD, git status y hashes de lib/pubspec en build/places-new-v2/baseline.json; invocar Dart MCP sobre lib/test. No exponer valores de claves en evidencia.
- [x] **2. Crear fixtures y pruebas de referencia:** HTTP simulado con predicción placeId='test-place', description='Tijuana, Baja California'; otro resultado con distinto ID para probar selección. Cubrir overlay/fullscreen, claro/oscuro y estados vacío/cargando/resultados, con tamaño fijo 400x800 y text scale 1.
- [x] **3. Verificar RED de capturas:** correr flutter test --no-pub test/places_autocomplete_test.dart. El fallo esperado es la ausencia de los archivos golden, no errores de red, assets o compilación. Las pruebas iniciales de interacción deben funcionar con el código vigente.
- [x] **4. Capturar la referencia desde fd99ecd:** generar goldens con --update-goldens y revisar visualmente las imágenes; incluir el logo real, decoración/estilos personalizados, separación del overlay y bordes. Fijar frames de carga con pump acotado; no usar pumpAndSettle con un spinner activo.
- [x] **5. Fijar interacciones:** selección devuelve el ID esperado, cancelar devuelve null; teclado/foco y Field/FormField conservan texto/reset/validación. Dejar los escenarios de bugs de controladores para el RED causal de la tarea 3.
- [x] **6. Verificar GREEN:** repetir ambos archivos sin --update-goldens y ejecutar Dart MCP. Guardar hashes de las capturas de referencia; no modificar todavía código productivo.

## Tarea 2: Modelos, solicitudes y cliente New para Autocomplete/Details

**Files:**
- Create: lib/src/places_models.dart, lib/src/places_models.g.dart, lib/src/places_requests.dart, lib/src/places_client.dart.
- Create: test/places_models_test.dart, test/places_client_test.dart, test/places_requests_test.dart.
- Create: test/fixtures/autocomplete_new.json, place_new.json, error_new.json.
- Modify: lib/flutter_google_places_2.dart (exports nuevos sin romper aún el harness Legacy).

**Interfaces:**

```dart
typedef PlacesIdentityHeaders = Future<Map<String, String>> Function();

PlacesClient({String? apiKey, Uri? baseUri, http.Client? httpClient,
  Map<String, String> headers = const {}, PlacesIdentityHeaders? identityHeaders});
Future<AutocompleteResponse> autocomplete(AutocompleteRequest request);
Future<Place> fetchPlace(String placeId, {required Set<String> fields,
  String? sessionToken, String? languageCode, String? regionCode});
void close();
```

baseUri por defecto es https://places.googleapis.com/v1; sin apiKey se requiere un proxy configurado explícitamente. identityHeaders por defecto usa GoogleApiHeaders.getHeaders. Un http.Client inyectado pertenece a quien lo suministra; close() solo cierra el cliente creado internamente y evita solicitudes posteriores.

**Tipos producidos:**
- PlaceLocation(latitude, longitude): componentes nullable al leer respuestas parciales; ambos obligatorios y válidos al serializar solicitudes (ruling de revisión final); PlacesArea sellado con CircleArea(center, radiusMeters) y RectangleArea(low, high). Coordenadas finitas y en rango; no normalizar un valor inválido a otro válido. Los cruces de antimeridiano válidos se conservan.
- AutocompleteRequest: input requerido; languageCode, regionCode, sessionToken, inputOffset, origin, locationBias/locationRestriction opcionales; includedPrimaryTypes/includedRegionCodes listas vacías por defecto; includeQueryPredictions=false. inputOffset ya está expresado en caracteres Unicode.
- AutocompleteSuggestion sellado con PlacePrediction y QueryPrediction. PlacePrediction tiene placeId y FormattableText text requeridos; place, structuredFormat, distanceMeters y types opcionales. QueryPrediction tiene text requerido y structuredFormat opcional, sin placeId.
- AutocompleteResponse.suggestions es una lista, vacía si Google omite suggestions; placePredictions es un getter filtrado para los widgets. FormattableText conserva text y coincidencias startOffset/endOffset; StructuredFormat conserva mainText/secondaryText. No crear terms Legacy a partir de texto.
- PlaceSelection(prediction: PlacePrediction, sessionToken: String) es un resultado local, sin serialización de protocolo.
- Place tiene propiedades nullable: id, name, displayName, location, viewport, formattedAddress, shortFormattedAddress, adrFormatAddress, addressComponents, nationalPhoneNumber, internationalPhoneNumber, regularOpeningHours, photos, priceLevel, rating, types, googleMapsUri, websiteUri, utcOffsetMinutes, reviews, businessStatus, iconMaskBaseUri, iconBackgroundColor y attributions.
- Modelar LocalizedText(text/languageCode), AddressComponent(longText/shortText/types/languageCode), OpeningHours/OpeningHoursPeriod/OpeningTime con day/hour/minute/date/truncated (date es PlaceDate con year/month/day), PlacePhoto, PlaceReview y Attribution con campos nativos correspondientes. No convertir horas semanales en fechas UTC inventadas. Los valores enum recibidos como businessStatus/priceLevel se conservan como strings para no falsear valores nuevos desconocidos.
- PlacePhoto conserva name, heightPx, widthPx y authorAttributions; PlaceReview conserva name, rating, text/originalText, authorAttribution, publishTime y relativePublishTimeDescription; Attribution/AuthorAttribution conservan los campos distintos que envía cada objeto (provider/providerUri frente a displayName/uri/photoUri).
- PlacesApiException: kind (api, transport, invalidResponse, identity), httpStatus/code opcionales, message requerido y detalles de Google disponibles sin claves. Una validación de argumentos locales usa ArgumentError antes de emitir HTTP.

- [x] **1. Crear RED de modelos y contratos:** fixture suggestions con lugar/consulta, Place con solo id/location, Place vacío y Place con anidados opcionales. Assert place.name=='places/test-place', displayName.text=='Nombre visible', location.latitude==32.5027, y ausencia de campos como displayName==null cuando no llegaron. Datos desconocidos adicionales no rompen fromJson.
- [x] **2. Crear RED de red:** MockClient comprueba POST /v1/places:autocomplete y JSON New; Details comprueba GET /v1/places/test-place, fields='id,location' en X-Goog-FieldMask, query sessionToken='test-session', languageCode='es-MX', regionCode='mx'. Clave solo en encabezado; respuesta devuelve Place directamente.
- [x] **3. Implementar modelos/solicitudes y generar:** serialización camelCase y omisión de null. Validar listas/límites estructurales, inputOffset entre 0 e input.runes.length, exclusión de bias/restriction y radios según su uso. Rechazar address como tipo primario Legacy, combinaciones de (cities)/(regions) con otros tipos, más de 5 tipos o 15 regiones. No declarar inválidos tipos New válidos mediante una lista parcial.
- [x] **4. Implementar cliente y límites:** combinar prefijo de baseUri sin perder /v1 o /proxy/v1, codificar segmentos y query por separado. fetchPlace admite un ID, no URLs arbitrarias. Custom headers no sobrescriben clave, máscara ni identidad obtenida por el cliente. Normalizar X-Android-Cert a 40 hexadecimales mayúsculos; cadena mal formada genera error identity. La precedencia de encabezados protegidos también se aplica sin distinguir mayúsculas/minúsculas. En Web/escritorio el proveedor puede devolver un mapa vacío.
- [x] **5. Añadir pruebas de fallos y propiedad:** 400/403/404/429/500, cuerpo no JSON, JSON inesperado, Socket/ClientException, proveedor de identidad fallido y mensajes con la clave de prueba deben producir error tipado seguro. Máscara vacía/radio 71450 no emiten HTTP; radio 50000 sí. Details también lleva X-Android-Package/Cert o X-Ios-Bundle-Identifier. Un proxy https://example.test/proxy/v1 genera /proxy/v1/places:autocomplete y acepta no enviar API key si el proxy autentica. close() no cierra el cliente inyectado.
- [x] **6. Verificar GREEN:** generar con dart run build_runner build --delete-conflicting-outputs (solo outputs generados del fork), correr los tres tests nuevos y Dart MCP. Revisar el diff generado y todos los campos anidados; mantener pasando la referencia visual Legacy hasta conectar widgets.

## Tarea 3: Conectar widgets New conservando apariencia y arreglar su ciclo de vida

**Files:**
- Modify: lib/src/flutter_google_places.dart, places_autocomplete_field.dart, places_autocomplete_form_field.dart.
- Modify: test/helpers/places_test_harness.dart, test/places_autocomplete_test.dart, test/places_autocomplete_fields_test.dart.
- No update: test/goldens/places/*.png.

**Interfaces:**
- Consumes: PlacesClient, AutocompleteRequest, AutocompleteResponse, PlaceSelection y PlacesApiException de la tarea 2.
- Produces: PlacesAutocomplete.show({required BuildContext context, required PlacesClient client, ...}) -> Future<PlaceSelection?>; PlacesAutocompleteWidget/Field/FormField reciben el mismo client. onError usa ValueChanged<PlacesApiException>; Field.onSelected usa ValueChanged<PlaceSelection>; onChanged sigue recibiendo el texto visible.
- En show y en los tres widgets usar String? languageCode/regionCode, List<String> includedPrimaryTypes/includedRegionCodes (vacías por defecto), PlacesArea? locationBias/locationRestriction, PlaceLocation? origin, int? inputOffset y String? sessionToken. Sustituir location/radius/strictbounds/types/components y quitar apiKey/proxyBaseUrl/httpClient/headers del widget: esa configuración pertenece al client.
- show y Widget mantienen todas las opciones visuales existentes y debounce; Field/FormField conservan sus opciones de estilo, controller y decoración. No añadir opciones visuales que no existían.

- [x] **1. Crear RED del contrato New:** adaptar el harness únicamente para usar cliente/fixtures New y esperar PlaceSelection. Las pruebas visuales deben fallar por tipos/contrato antes de conectar el widget; conservar las mismas cadenas, frames y capturas de la tarea 1.
- [x] **2. Crear RED de estado y Unicode:** dos consultas con Completer terminan en orden inverso y solo aparece la segunda; borrar mientras carga deja vacío/carga terminada; cancelar/desmontar antes de terminar impide callbacks. TextEditingValue(text: 'A😀B', selection: offset 3 UTF-16) debe enviar inputOffset=2, y los rangos de coincidencias se conservan en unidades New sin cortar emoji.
- [x] **3. Conectar el estado existente:** reutilizar debounceTime/switchMap y el árbol visual. El texto visible de una predicción es prediction.text.text. Si no se proporciona inputOffset, convertir la selección UTF-16 válida del controlador; si se proporciona, tratarlo como Unicode. Cambios relevantes de texto/cursor actualizan la consulta. Borrar no queda filtrado por where(isNotEmpty): emite estado vacío y cancela la consulta anterior.
- [x] **4. Conectar sesión/selección/errores:** un UUID v4 de dart:math por apertura salvo token explícito; devolverlo con la predicción. Mantener el token durante las ediciones; no consultar Details automáticamente. Solo lugares son seleccionables en estos widgets. Error de HTTP/identidad/transporte cierra carga y llama una vez a onError; nunca crea un diálogo técnico. Mantener el orden existente usando los mismos datos de distanceMeters, sin inventar distancias ausentes.
- [x] **5. Crear RED y corregir Field/FormField:** transición null->controller externo, externo->otro externo, externo->interno y dispose. El texto del controlador nuevo debe respetarse; conservar el texto anterior al crear uno interno; liberar los internos y retirar listeners; nunca dispose del externo. Selección tras desmontar no llama setState/callbacks. Callback onSelected que desmonta el campo no causa accesos posteriores; reset/validator/initialValue continúan funcionando.
- [x] **6. Verificar GREEN:** correr tests de widgets/fields/client/modelos y comparar TODOS los goldens sin --update-goldens. Assert cancelar devuelve null; una nueva apertura genera otro UUID; token explícito llega a todas las peticiones y a PlaceSelection. Verificar que destruir la pantalla no cierra client ni http.Client externos. Dart MCP lib/test sin errores.

## Tarea 4: Completar Search/Photos y retirar transporte Legacy

**Files:**
- Modify: lib/src/places_requests.dart, places_client.dart, places_models.dart y serialización generada.
- Modify: lib/google_maps_webservice_places.dart y lib/flutter_google_places_2.dart.
- Remove after tracing imports: lib/src/google_maps_webservice/places.dart y src/core.dart, core.g.dart, places.dart, places.g.dart, utils.dart de ese directorio.
- Create: test/places_search_test.dart, test/places_photos_test.dart, fixtures search_new.json y photo_media_new.json.

**Interfaces:**

```dart
Future<NearbySearchResponse> searchNearby(NearbySearchRequest request,
  {required Set<String> fields});
Future<TextSearchResponse> searchText(TextSearchRequest request,
  {required Set<String> fields});
Future<PhotoMedia> fetchPhotoMedia(String photoName,
  {int? maxWidthPx, int? maxHeightPx});
```

- NearbySearchRequest: required CircleArea locationRestriction; includedTypes/excludedTypes/includedPrimaryTypes/excludedPrimaryTypes listas; languageCode/regionCode opcionales; maxResultCount opcional (1..20); rankPreference popularity/distance. Sin keyword, name, min/maxprice, opennow ni pageToken.
- TextSearchRequest: textQuery requerido; languageCode/regionCode, includedType, strictTypeFiltering, openNow, rankPreference relevance/distance, priceLevels, pageSize/pageToken y áreas opcionales. locationRestriction solo RectangleArea; locationBias admite las áreas documentadas y es excluyente. Usar pageSize actual, no maxResultCount obsoleto: permitir omitido/0 como tamaño predeterminado de Google y 1..20 como tamaño explícito; rechazar negativos o mayores de 20 localmente, sin recorte silencioso. Al paginar, conservar todos los parámetros salvo pageToken/pageSize.
- NearbySearchResponse.places y TextSearchResponse.places usan List<Place> vacía por defecto; TextSearchResponse incluye nextPageToken nullable. PhotoMedia incluye name y photoUri; sin caché persistente.

- [x] **1. Crear RED de búsquedas:** MockClient inspecciona POST /v1/places:searchNearby y searchText, JSON, identidad y máscara nativa places.id,places.location. Parsear {} como lista vacía; validar resultados con campos parciales. La segunda página Text Search conserva filtros/query y envía el token anterior; su máscara incluye nextPageToken.
- [x] **2. Implementar requests/métodos:** filtros, ranking, precio y paginación con semántica New. La validación local no cambia de endpoint ni limita silenciosamente coordenadas/radios. Query Autocomplete se cubre mediante autocomplete(includeQueryPredictions:true) y retorna QueryPrediction sin ID; con includedRegionCodes se documenta que Google no devuelve consultas.
- [x] **3. Crear RED e implementar Photos:** GET /v1/places/test-place/photos/test-photo/media?maxWidthPx=400&skipHttpRedirect=true, misma identidad/clave por headers y respuesta PhotoMedia. Al menos una dimensión, enteros 1..4800; nombre de recurso con estructura places/{id}/photos/{photo}; no aceptar URLs arbitrarias. photoUri debe ser una URI HTTP(S) absoluta; otro esquema o recurso mal formado es invalidResponse. Un photoUri de otro host es dato devuelto: el cliente no lo solicita ni le reenvía secretos.
- [x] **4. Cubrir fallos de Photos/Search:** 403/429, foto vencida 400 y atribuciones presentes no se ocultan; preservar authorAttributions en el modelo. Tamaño inválido/máscara vacía/ubicación incompatible no emiten HTTP. No agregar reintentos automáticos, búsquedas de sustitución ni caché.
- [x] **5. Retirar Legacy:** rg de todos los imports/métodos/modelos viejos antes de eliminar archivos, actualizar barrels y quitar exports antiguos. El barrel antiguo solo reexporta cliente/modelos/requests New. Ningún método restante construye /maps/api/place, /autocomplete/json, /details/json o /queryautocomplete/json. Los ejemplos históricos en la guía se identifican como código anterior.
- [x] **6. Verificar GREEN:** regenerar únicamente serialización vigente, correr toda la suite y Dart MCP. Confirmar que los goldens de la tarea 1 siguen sin cambios y que el código público cubre las seis familias previstas.

## Tarea 5: Entrega local v2, guía del consumidor y validación separada

**Files:**
- Modify: pubspec.yaml (version: 2.0.0), pubspec.lock, README.md, CHANGELOG.md.
- Create: docs/migration-v2.md, test/public_api_test.dart, build/places-new-v2/validation.md (evidencia local).
- Read only: appfloridomobile/lib/Views/ConfigSites/sites_maps.dart y lib/Utils/GoogleMapsToken.dart.

**Interfaces:**
- Consumes: cliente, modelos, requests, widgets y evidencia de tareas 1-4.
- Produces: checkout listo para commit manual con guía compilable y reporte que distingue local PASS, comprobaciones remotas pendientes y plataformas probadas.

- [x] **1. Escribir prueba de API pública y documentación:** importar únicamente package:flutter_google_places_2/flutter_google_places_2.dart y comprobar también el barrel de transición, sin imports src/Legacy. La muestra principal construye PlacesClient, abre show, usa selection.prediction.placeId y selection.sessionToken, pide {'id','location'} y lee place.location; cerrar cliente en finally. Un fallo del consumidor no debe convertir location ausente en (0,0).
- [x] **2. Escribir guía de ruptura:** tabla de modelos/métodos/args retirados, error callback tipado, base del proxy New, campos de coste, sesiones y propiedad de recursos. Para sites_maps.dart proponer CircleArea de 50000, includedRegionCodes ['mx'], es-MX y filtro candidato ['street_address']; no declarar equivalencia geográfica sin comprobarla. Añadir guards mounted y manejo de location/error en la muestra sin editar la app.
- [x] **3. Actualizar versión y resolver:** flutter pub get --no-example, flutter pub outdated --json y revisar que los cambios de lock sean causales. Mantener las versiones SDK y dependencias compatibles aprobadas; no añadir paquetes para esquivar pruebas o validaciones.
- [x] **4. Ejecutar checks locales:** dart run build_runner build --delete-conflicting-outputs; flutter test --no-pub; Dart MCP analyze_files(lib,test, applyFixes:false); git diff --check; búsqueda de endpoints/imports Legacy activos y claves de prueba filtradas. Registrar versiones SDK, conteo real de pruebas y hashes de goldens. Intentar hot reload solo si existe app debug conectada; indicar si no se puede.
- [x] **5. Revisar el cambio completo:** revisor independiente del código final, centrado en contratos, errores, estado/cancelación, máscaras, identidad y goldens; corregir hallazgos causales y repetir gates afectados. No tratar el reporte del implementador como evidencia de cierre.
- [x] **6. Preparar comprobación externa separada:** documentar habilitación Places API New, clave restringida, proyecto/facturación y certificado efectivo. En una prueba explícita con credenciales de prueba, comprobar Autocomplete/Details: identidad correcta exitosa, paquete incorrecto rechazado y certificado incorrecto rechazado. Nunca registrar la clave ni tomar un header simulado como prueba de rechazo remoto. Search/Photos requieren sus comprobaciones si se anuncian validados.
- [ ] **7. Comparar búsquedas reales y límites:** direcciones precisas de Tijuana, edificios/interiores, colonias y sin número, México/es-MX y radios; revisar cobertura de street_address antes de ampliar filtros. Confirmar visualmente en Android; iOS, Web y proxy solo se marcan validados si se prueban. Si no hay acceso/configuración/dispositivo, terminar el paquete local y dejar estos puntos expresamente pendientes, sin activar New en la app ni declarar cierre integral.
- [x] **8. Entregar:** resumir cambios, pruebas y límites; dejar todo sin stage/commit/push. La actualización de la referencia Git y la adaptación de la app siguen a cargo del usuario o de una instrucción posterior.

## Comandos y entorno de ejecución

Desde el fork usar flutter pub get --no-example, flutter test --no-pub y dart run build_runner build --delete-conflicting-outputs. Si Flutter.bat introduce problemas de bloqueo en este host, se puede invocar C:/flutter/bin/cache/dart-sdk/bin/dart.exe con C:/flutter/bin/cache/flutter_tools.snapshot para los mismos subcomandos Flutter. SDK/telemetría fuera del workspace pueden requerir escalación del sandbox; no modificar configuración global para evitarlo.

Dart MCP root exacto: file:///C:/Users/Usuario/Documents/GitHub/flutter_google_places_2. No ejecutar SDKs concurrentemente ni crear una app de ejemplo con credenciales reales incrustadas.

Referencias adicionales verificadas para este plan: [Circle](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/Circle), [Text Search, pageSize y restricciones](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places/searchText). Las demás fuentes primarias están junto al contrato correspondiente en el diseño.

## Revisión del plan

- Cobertura: visuales (1/3), protocolo/modelos/sesiones/errores/identidad (2/3), todas las búsquedas y fotos (4), exportación/versionado/documentación y validación real (5). Sin requisitos del diseño abandonados.
- Tipos y propiedad: PlaceSelection.prediction/placeId/sessionToken, Place.location y PlacesClient se usan de forma consistente. Nada requiere un http.Client o TextEditingController ajeno liberado por un widget.
- Las cinco clases de riesgo de Review Focus tienen tests causales asignados; no se agregan nuevas abstracciones de arquitectura ni funcionalidades ajenas.
- El criterio local y el externo se informan por separado. El plan no presume disponibilidad de claves, rechazo remoto, dispositivo, CORS ni aprobación de ejecución.

## Estado de ejecución

Ejecución nativa aprobada y tareas 1–4 implementadas y verificadas localmente. Tarea 5 completada localmente: revisión independiente atendida, aplicación al checkout real y gates finales aprobados (77/77 y MCP No errors). Las comprobaciones reales de Google/dispositivos siguen pendientes sin activar la app.
