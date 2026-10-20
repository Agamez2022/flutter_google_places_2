# Diseño de migración a Places API (New), versión 2.0

Fecha: 2026-10-20. Estado: diseño y ejecución nativa aprobados por el usuario. Este documento conserva el inventario y las decisiones iniciales; el estado de implementación está en docs/validation-v2.md.

## Objetivo y decisiones confirmadas

Migrar el funcionamiento de flutter_google_places_2 a Places API (New), conservando la apariencia y las interacciones de sus widgets. El usuario confirmó una versión 2.0 con modelos y llamadas Dart nuevos; la app se adaptará después. El usuario realizará el commit y actualizará la referencia Git manualmente.

Repositorio revisado: C:/Users/Usuario/Documents/GitHub/flutter_google_places_2. Base limpia al iniciar la revisión: fd99ecd7d3fe992823b18fc1ab69243dcc09ad63. La app actualmente apunta a fd99ecd.

Esta propuesta cubre las capacidades que el paquete ya ofrece: Autocomplete, Query Autocomplete, Place Details, Nearby Search, Text Search y Photos. No agrega Address Validation, rutas, resúmenes de IA ni pantallas nuevas.

## Resultado de la inspección

- El transporte actual usa maps.googleapis.com/maps/api/place y solicitudes GET de Legacy.
- lib/src/flutter_google_places.dart contiene el overlay, pantalla completa, lista, selección y estado reactivo. Se deben conservar sus árboles visuales.
- lib/src/places_autocomplete_field.dart y places_autocomplete_form_field.dart abren la búsqueda y actualizan controladores, callbacks y validación.
- lib/src/google_maps_webservice/src/places.dart concentra métodos, constructores de URL y modelos Legacy; places.g.dart y core.g.dart contienen serialización generada.
- Los exports públicos están en lib/flutter_google_places_2.dart, lib/google_maps_webservice_places.dart y lib/src/google_maps_webservice/places.dart.
- El único consumidor productivo encontrado en la app es lib/Views/ConfigSites/sites_maps.dart, método placeAuto(): abre overlay y consulta coordenadas después de seleccionar.
- La app pide México, es-MX, strictbounds=true, types=['address'] y radio 50000 o 71450. Genera un UUID v4 seguro, pero no lo pasa a Details.
- Los encabezados de identidad se agregan en el widget de autocompletado. La consulta independiente de Details de la app no recibe esos encabezados.
- El repositorio actual solo contiene test/flutter_google_places_test.dart con void main() {}. Las pruebas añadidas en la intervención anterior no están en este checkout; no se consideran cobertura vigente.
- El análisis actual con Dart MCP, applyFixes:false, de lib y test devolvió No errors. Esto no prueba funcionamiento contra Google.

## Alternativas y recomendación

1. Recomendada: conservar los widgets e implementar REST New en el fork con http, google_api_headers y los streams ya instalados. Evita otra dependencia, permite revisar todas las solicitudes y preserva la UI.
2. Usar un cliente externo de Places New por debajo de los widgets: reduce código de protocolo propio, pero obliga a auditar su cobertura, traducciones y encabezados y vuelve a depender de su mantenimiento.
3. Usar SDK nativos Android/iOS conservando Flutter como UI: es viable, pero amplía la migración a integración nativa y diferencias entre plataformas. No es necesario para el alcance actual.

El diseño propone la alternativa 1 y una versión mayor. No mantiene un selector Legacy/New ni una segunda ruta de red oculta.

## Contrato visual

Preservar Mode.overlay y Mode.fullscreen; navegación por showDialog/Navigator.push; botón de retorno y cancelar; autofocus; hint, estilos y colores configurados; bordes; márgenes horizontales 16 y verticales 30; separación superior de resultados 48; insetPadding; logo; iconos; scroll; indicador de carga y representación de una línea por sugerencia.

Conservar los valores de dialogTheme.backgroundColor y su respaldo colorScheme.surface. La migración no añade títulos, botones, pantallas, diálogos de errores ni consulta automática de Details al pintar sugerencias.

Comparar imágenes deterministas antes/después con los mismos datos simulados, fuentes, escala, tema y tamaño. Cubrir claro/oscuro, overlay/fullscreen, vacío/cargando/resultados y opciones visuales personalizadas. Comparar Field/FormField y foco/teclado aparte.

Se conserva la presentación; Google puede devolver textos, orden y resultados distintos entre Legacy y New. La equivalencia de resultados geográficos se debe verificar con búsquedas reales representativas.

## Correspondencia del protocolo

| Función actual | Operación New | Cambio de contrato |
| --- | --- | --- |
| autocomplete | POST /v1/places:autocomplete | JSON y suggestions; distingue placePrediction y queryPrediction. |
| queryAutocomplete | POST /v1/places:autocomplete | includeQueryPredictions=true; las consultas no tienen placeId. |
| getDetailsByPlaceId | GET /v1/places/{placeId} | Devuelve un Place; requiere máscara explícita de campos. |
| searchNearbyWithRadius / searchNearbyWithRankBy | POST /v1/places:searchNearby | Restricción circular, ranking y filtros New. |
| searchByText | POST /v1/places:searchText | JSON, máscara y paginación New. |
| buildPhotoUrl | GET /v1/{photoName}/media | Nombre completo del recurso y dimensiones en píxeles. |

Los constructores públicos build...Url de búsquedas POST se sustituyen por métodos/solicitudes tipados; una URL por sí sola ya no describe la operación. Base normal: https://places.googleapis.com/v1. Mantener cliente HTTP inyectable y base de proxy, documentando que el proxy debe hablar el protocolo New y que /v1 no debe duplicarse o perderse al combinar rutas.

Fuentes: [migración general](https://developers.google.com/maps/documentation/places/web-service/legacy/migrate-overview), [Autocomplete](https://developers.google.com/maps/documentation/places/web-service/legacy/migrate-autocomplete), [Details](https://developers.google.com/maps/documentation/places/web-service/legacy/migrate-details), [Text Search](https://developers.google.com/maps/documentation/places/web-service/legacy/migrate-text).

## Parámetros de Autocomplete y diferencias que deben resolverse

| Legacy | New / política propuesta |
| --- | --- |
| language | languageCode. |
| region | regionCode; afecta presentación/ranking, no sustituye la restricción por país. |
| Component(country, 'mx') | includedRegionCodes: ['mx']. Otros Component Legacy no se traducen a países. |
| location + radius, strictbounds=false | locationBias.circle. |
| location + radius, strictbounds=true | locationRestriction.circle. |
| offset | inputOffset entero, medido en caracteres Unicode. |
| sessiontoken | sessionToken. |
| types | includedPrimaryTypes con tipos admitidos por New. |

locationBias y locationRestriction son excluyentes. Validar coordenadas, radios finitos, tipos y combinaciones antes de solicitar. No recortar silenciosamente valores inválidos ni convertir círculos en rectángulos.

Para la app, proponer radio explícito 50000 también cuando no haya ubicación previa: New limita los círculos a 50000 metros; Legacy ya documentaba recortar el radio de Autocomplete a ese máximo. El valor 71450 no se enviará a New. Si el negocio exige realmente 71,45 km, requerirá otra definición geográfica y pruebas específicas.

El literal Legacy 'address' no es un tipo primario New admitido. Para direcciones precisas, el candidato inicial es includedPrimaryTypes: ['street_address']; no se afirma equivalencia completa. Se probarán direcciones de Tijuana y alrededores, edificios, números interiores, colonias y ubicaciones sin número. Incluir premise, subpremise o route requiere justificarlo por esas pruebas y documentar el cambio de cobertura.

Los widgets de selección actual seguirán mostrando solo predicciones de lugares. El cliente de bajo nivel permitirá consultas mediante includeQueryPredictions; no inventará IDs para ellas. Google no devuelve query predictions cuando se envía includedRegionCodes.

Los offsets del cursor y de coincidencias New usan caracteres Unicode. Dart y TextSelection usan unidades UTF-16: convertir cuando corresponda y probar acentos y emoji; no truncar por índices incompatibles.

Fuentes: [Autocomplete New](https://developers.google.com/maps/documentation/places/web-service/place-autocomplete), [referencia REST](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places/autocomplete), [tipos admitidos](https://developers.google.com/maps/documentation/places/web-service/place-types), [radio Legacy](https://developers.google.com/maps/documentation/places/web-service/legacy/autocomplete).

## Cliente, modelos y sesiones propuestos

Crear PlacesClient como cliente compartido para Autocomplete y Details, además de Search/Photos. El widget recibe ese cliente; no crea un cliente diferente con otra identidad por cada pantalla. El propietario cierra PlacesClient; un widget no cierra un cliente que recibió del consumidor. Un http.Client inyectado conserva la responsabilidad de cierre de quien lo proporcionó.

Crear modelos New para Place, PlacePrediction, QueryPrediction, AutocompleteResponse, respuestas de búsqueda, Photo/PhotoMedia, textos localizados, ubicaciones y atribuciones. Las solicitudes de búsqueda tendrán sus parámetros propios; no una bolsa Map sin tipos. Los campos ausentes por máscara o por falta de datos serán nullable; no inventar nombres, IDs, referencias ni coordenadas para satisfacer constructores Legacy.

Usar camelCase de New. Place.name identifica el recurso places/{id}; el texto visible es displayName.text. Las coordenadas son location.latitude/longitude; ya no result.geometry.location. Mantener por separado ID y nombre de recurso. Los campos Legacy eliminados dejan de exponerse con valores ficticios.

Propuesta de métodos: autocomplete(AutocompleteRequest), fetchPlace(placeId, fields, sessionToken, languageCode, regionCode), searchNearby(NearbySearchRequest, fields), searchText(TextSearchRequest, fields) y fetchPhotoMedia(photoName, maxWidthPx/maxHeightPx). La implementación detallará las firmas definitivas en el plan posterior.

PlacesAutocomplete.show devuelve Future<PlaceSelection?>. PlaceSelection contiene la predicción seleccionada y su sessionToken. PlacePrediction se adapta a la línea visual actual usando text.text. Una búsqueda usa un token durante todas sus ediciones; la siguiente apertura recibe un token nuevo. Si el consumidor no suministra uno, el widget genera un UUID v4 con dart:math; no se agrega una dependencia para esto.

Después de seleccionar, el consumidor consulta fetchPlace con el mismo token y la misma configuración de proyecto/clave. Cancelar descarta la sesión local. No reutilizar tokens concluidos. La generación UUID v4 de GoogleMapsToken de la app ya es reutilizable si se prefiere proporcionarlo.

Details y las búsquedas exigen fields no vacío. Para Details de esta app basta empezar con {'id','location'} y agregar addressComponents/formattedAddress únicamente si un consumidor los necesita. En búsquedas, usar las rutas de máscara New correspondientes, por ejemplo places.id y places.location; incluir nextPageToken cuando se necesite paginar Text Search. No solicitar '*' por defecto ni displayName/reseñas/fotos solo para obtener coordenadas.

Google factura según los campos solicitados y cómo concluye la sesión; esta propuesta no promete un precio menor. Una llamada Details IDs Only tiene un tratamiento distinto al incluir location. Las máscaras quedarán explícitas y se revisarán con la configuración de facturación del proyecto.

Fuentes: [respuesta Place](https://developers.google.com/maps/documentation/places/web-service/legacy/migrate-response), [Details y máscaras](https://developers.google.com/maps/documentation/places/web-service/place-details), [sesiones New](https://developers.google.com/maps/documentation/places/web-service/using-session-tokens), [tratamiento de sesiones](https://developers.google.com/maps/documentation/places/web-service/session-pricing).

## Search y Photos: límites de compatibilidad

Nearby New no admite keyword, name como búsqueda textual, precio, opennow o pagetoken Legacy. Una consulta textual debe llamar explícitamente a Text Search; no cambiar de endpoint silenciosamente. Nearby tiene radio/restricción, filtros y rankPreference propios; no ofrece paginación. Text Search conserva su siguiente página mediante su token New y parámetros compatibles. La búsqueda inversa de coordenadas no se simula con Text Search.

Photos recibe nombres places/{id}/photos/{photo}, no photo_reference Legacy. Se propone fetchPhotoMedia con skipHttpRedirect=true para obtener photoUri sin reenviar claves/encabezados sensibles a otro host. Mostrar atribuciones cuando correspondan; no persistir el nombre temporal de foto ni tratarlo como ID estable.

Fuentes: [Nearby](https://developers.google.com/maps/documentation/places/web-service/legacy/migrate-nearby), [referencia Nearby](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places/searchNearby), [referencia Text Search](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places/searchText), [migración Photos](https://developers.google.com/maps/documentation/places/web-service/legacy/migrate-photo), [Photos New](https://developers.google.com/maps/documentation/places/web-service/place-photos).

## Errores, estado y ciclo de vida

New usa estados HTTP y un objeto error; eliminar la suposición de recibir siempre status/error_message Legacy. Definir PlacesApiException con estado HTTP, código, mensaje y detalles del error. Distinguir validación local, respuesta de Google, transporte y JSON inválido.

Los callbacks de error de los widgets de v2 recibirán el error tipado y cerrarán el estado de carga también si falla la obtención de encabezados. No mostrar mensajes técnicos directamente al usuario ni añadir diálogos. Los consumidores deciden el texto visible; las claves no deben entrar en logs, excepciones o URLs registradas.

Conservar debounce de 300 ms por defecto y descarte de respuestas obsoletas. Vaciar el texto debe vaciar resultados y dejar de cargar; desmontar/cancelar debe impedir callbacks tardíos. Antes de actualizar controladores/estado tras cerrar la búsqueda, comprobar mounted. Corregir la transición entre controlador interno y externo y liberar únicamente los controladores propios; el código actual del Field puede leer oldWidget.controller! cuando antes era null, y ambos campos requieren revisar sus controladores internos.

Estos ajustes pertenecen al flujo que se migra; no implican refactorizar otras vistas de la app.

## Claves e identidad

Habilitar Places API (New), revisar facturación/cuotas y autorizar esa API en las restricciones de la clave. No cambiar Google Cloud como parte de esta revisión.

Centralizar X-Goog-Api-Key, Content-Type y FieldMask con la identidad móvil para TODAS las operaciones, incluido Details independiente del widget. Reutilizar google_api_headers y normalizar X-Android-Cert a 40 hexadecimales sin separadores; conservar X-Android-Package y, en iOS, X-Ios-Bundle-Identifier. No asumir que generar encabezados demuestra que el servidor los valida.

Antes de activar en la app: verificar con su identidad efectiva que Autocomplete y Details funcionan; comprobar que paquete incorrecto y certificado incorrecto son rechazados en ambos endpoints. Inspeccionar el certificado del APK concreto; debug, release local y Play pueden diferir. Si las restricciones no se hacen cumplir en los endpoints probados, la conexión directa no queda aceptada: se debe usar un proxy autenticado o revisar la alternativa nativa.

Para Photos/Search se verificará el alcance de las restricciones antes de anunciar soporte validado. Web requiere pruebas propias de CORS, origen y restricciones de clave; un resultado Android no certifica Web o iOS. El proxy existente debe adaptarse al protocolo y probarse si se utiliza.

Conservar logo/atribuciones actuales y actualizar solo lo que exija la atribución New. No incorporar cachés de contenido; los IDs y los recursos temporales no comparten la misma política.

Fuentes: [configuración de New](https://developers.google.com/maps/documentation/places/web-service/get-api-key), [identidad móvil y pruebas negativas](https://developers.google.com/maps/api-security-best-practices), [atribuciones](https://developers.google.com/maps/documentation/places/web-service/policies).

## Archivos previstos

| Archivo | Responsabilidad |
| --- | --- |
| lib/src/places_client.dart, lib/src/places_requests.dart | Transporte New y parámetros tipados con validación. |
| lib/src/places_models.dart y serialización generada correspondiente | Modelos New, selección, respuestas y error tipado. Separar por responsabilidad si el tamaño lo requiere. |
| lib/src/flutter_google_places.dart | Conservar renderizado; conectar cliente/modelos/sesión/errores New. |
| lib/src/places_autocomplete_field.dart, places_autocomplete_form_field.dart | Propagar cliente, selección y opciones New; ciclo de vida de controladores. |
| lib/flutter_google_places_2.dart y barrels existentes | Exports públicos de v2; retirar dependencias de modelos/protocolo Legacy cuando no tengan consumidores. |
| pubspec.yaml / pubspec.lock | Versión 2.0.0 y dependencias compatibles; no agregar otro paquete de Places. |
| README.md / CHANGELOG.md / guía de migración | Documentar cambios incompatibles, campos, sesiones, identidad, proxy y ejemplo completo. |
| test/places_client_test.dart, test/places_models_test.dart | Contratos HTTP, parámetros y modelos con respuestas sintéticas. |
| test/places_autocomplete_test.dart, test/places_autocomplete_fields_test.dart y goldens | Interacciones, ciclo de vida y comparación visual antes/después. |

En la app, la integración posterior afectará inicialmente sites_maps.dart: construir/reutilizar PlacesClient, pasar la restricción New y México/es-MX, usar PlaceSelection, compartir sessionToken, solicitar id/location, leer location, controlar ausencia de coordenadas/errores/mounted y liberar cliente. El marcador, cámara y actualización de dirección mantienen su comportamiento. No modificar ahora el pubspec ni la app productiva.

## Secuencia y aceptación

1. Revisar y aprobar este diseño. Después escribir el plan de implementación; no iniciar aún el reemplazo del código.
2. Capturar goldens y pruebas del estado visual actual antes de modificar el transporte.
3. Implementar modelos/cliente New mediante contratos HTTP sintéticos: método, URL, JSON, encabezados, máscaras, tokens, paginación y errores.
4. Conectar widgets sin rediseñar su renderizado; probar selección, cancelar, callbacks, filtros, estados y controladores.
5. Cubrir Search y Photos; retirar el transporte Legacy y actualizar exports/documentación/versionado sin dejar métodos que todavía llamen a Legacy.
6. Ejecutar generación de código controlada, análisis Dart MCP y pruebas. Verificar pub get/outdated y ausencia de dependencias o endpoints Legacy activos.
7. Validar una app de ejemplo o copia aislada del consumidor con búsquedas mexicanas reales y pruebas de identidad; luego integrar en la app cuando se cumplan los criterios.

Casos obligatorios: lista vacía; 400/403/404/429/5xx; error de red y JSON inválido; campos omitidos por máscara; IDs y recursos distintos; respuestas fuera de orden; cancelar/desmontar con solicitud pendiente; Unicode/emoji; círculo 50000 y rechazo de 71450; filtros incompatibles; token único entre aperturas y compartido con Details; encabezados de identidad en Details; cliente/controlador externo no cerrado indebidamente; fotos con atribución/recurso vencido; y ambas presentaciones con imágenes equivalentes.

## Qué está demostrado y qué falta

Demostrado: inventario del código vigente, consumidor de la app, dependencias y restricciones documentadas por Google; análisis Dart MCP sin errores en la base actual. Esta revisión agrega únicamente este documento.

Pendiente: revisión del plan de implementación, código v2, tests/goldens de migración, habilitación/configuración real del proyecto Google Cloud, respuestas reales, rechazo de identidades inválidas y pruebas en dispositivos/plataformas. Ninguna evidencia histórica de otra carpeta se considera una certificación actual.

## Revisión del propio documento

Alcance confirmado: versión mayor y apariencia conservada. No se promete compatibilidad total de filtros/resultados Legacy ni se deja una ruta Legacy automática. El contrato cubre todas las familias que hoy exporta el paquete; las incompatibilidades están explícitas. No se hicieron commits, push, cambios de claves, solicitudes facturables ni cambios de código productivo.
