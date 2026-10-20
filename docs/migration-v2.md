# Migración de 1.x a 2.0

Esta versión sustituye el transporte y los modelos Legacy por REST Places API (New). Cambia la API Dart y requiere adaptar al consumidor. La interfaz de los widgets mantiene su presentación; Google puede devolver resultados, textos y orden diferentes.

## Cliente compartido y selección

Usa el barrel principal flutter_google_places_2.dart. google_maps_webservice_places.dart se conserva como import de transición, pero sólo exporta tipos New.

Construye PlacesClient(apiKey: apiKey), pásalo a show/Widget/Field/FormField y reutilízalo en fetchPlace. show devuelve PlaceSelection?; null significa cancelar. PlaceSelection contiene prediction y sessionToken. El widget genera un UUID v4 por apertura salvo que proporciones uno. Todas las ediciones de esa apertura usan el mismo token; pásalo a Details y no reutilices una sesión concluida.

El propietario cierra PlacesClient. Los widgets no lo cierran. close() cierra únicamente el http.Client creado internamente; si inyectas uno, te corresponde cerrarlo. No se permite solicitar con un PlacesClient cerrado.

El [ejemplo compilable](../example/lib/places_picker.dart) devuelve PlaceLocation? y maneja ausencia de coordenadas, errores y context.mounted. El llamador conserva la propiedad del cliente:

~~~dart
final client = PlacesClient(apiKey: apiKey);
try {
  final point = await pickDeliveryLocation(
    context,
    client,
    center: const PlaceLocation(latitude: 32.5027, longitude: -117.0003),
    onError: (error) {
      // Mensaje visible decidido por la aplicación, sin imprimir claves.
    },
  );
  final latitude = point?.latitude;
  final longitude = point?.longitude;
  if (!context.mounted || latitude == null || longitude == null) return;
  // Actualizar marcador/cámara usando latitude y longitude.
} finally {
  client.close();
}
~~~

## Correspondencias incompatibles

| Antes | Ahora |
| --- | --- |
| GoogleMapsPlaces | PlacesClient |
| Prediction / description | PlacePrediction / text.text |
| Future<Prediction?> al abrir | Future<PlaceSelection?>; prediction y sessionToken |
| getDetailsByPlaceId(id) / PlacesDetailsResponse.result | fetchPlace(id, fields: {...}) / Place |
| geometry.location.lat/lng | location?.latitude/longitude |
| name visible del lugar | displayName?.text; name es el recurso places/{id} |
| language / region | languageCode / regionCode |
| location, radius, strictbounds | locationBias o locationRestriction con CircleArea/RectangleArea |
| components: country mx | includedRegionCodes: ['mx'] |
| types | includedPrimaryTypes, con tipos admitidos por New |
| apiKey/httpClient/headers/proxyBaseUrl en widgets | configuración en PlacesClient |
| build...Url | solicitudes tipadas y métodos REST; las búsquedas usan POST |
| photo_reference / buildPhotoUrl | PlacePhoto.name / fetchPhotoMedia |
| status/errorMessage Legacy | PlacesApiException y estados HTTP |

Los componentes latitude/longitude de PlaceLocation también son nullable en respuestas parciales; no se interpretan campos ausentes como cero. Al construir solicitudes, validate() exige ambos componentes completos, finitos y en rango.

Los campos opcionales de Place son nullable: una máscara parcial o datos no disponibles no producen coordenadas, nombres ni IDs inventados. Las respuestas de búsqueda sin places y Autocomplete sin suggestions sí tienen listas vacías. Se preservan nombres de recurso e IDs por separado, textos localizados, coincidencias Unicode, horarios semanales, reseñas y atribuciones nativas. priceLevel/businessStatus se reciben como strings para conservar valores nuevos desconocidos.

## Autocomplete y áreas

~~~dart
final response = await client.autocomplete(const AutocompleteRequest(
  input: 'Tijuana',
  languageCode: 'es-MX',
  regionCode: 'mx',
  includedRegionCodes: ['mx'],
  includeQueryPredictions: true,
));
~~~

Las suggestions distinguen PlacePrediction y QueryPrediction. Una consulta no tiene placeId; no se puede pasar a fetchPlace. Google no devuelve query predictions cuando se especifican includedRegionCodes; omite ese filtro para solicitar consultas. Los widgets usan sólo placePredictions.

locationBias y locationRestriction son excluyentes. CircleArea admite coordenadas finitas y radio 0..50000 metros; Autocomplete con restricción circular exige radio positivo. No se recorta un radio inválido. RectangleArea conserva cruces válidos de antimeridiano. inputOffset de la solicitud es un índice Unicode; el widget convierte el cursor UTF-16 de Flutter cuando no se proporciona explícitamente.

Se admiten hasta cinco tipos primarios o una colección (cities)/(regions), sin mezclarlas, y hasta quince códigos de región. El literal address de Legacy se rechaza. No se traduce silenciosamente a otro filtro.

Para la integración posterior en sites_maps.dart:
- Sustituir Location por PlaceLocation y construir/reutilizar el mismo PlacesClient para show y Details.
- Usar includedRegionCodes: ['mx'], languageCode: 'es-MX' y regionCode: 'mx'.
- Cambiar el radio alternativo 71450 por un radio explícito 50000; otra cobertura necesita una decisión geográfica distinta.
- Evaluar ['street_address'] como candidato para includedPrimaryTypes. No es equivalencia demostrada de ['address']: probar Tijuana, edificios/interiores, colonias y direcciones sin número antes de decidir filtros.
- Pasar selection.sessionToken a fetchPlace con fields: {'id', 'location'}, leer location y manejar null/errores/mounted. Mantener marcador, cámara, dirección y geocodificación de la app.

Esta migración del paquete no modifica esa app ni su dependencia Git.

## Details y máscaras

fetchPlace recibe un ID independiente, no una URL ni un nombre places/{id}. fields es obligatorio y no vacío. Para coordenadas usa {'id', 'location'}; añade únicamente los campos necesarios. No se solicita '*' por defecto. Para Search las rutas llevan prefijo places., por ejemplo {'places.id', 'places.location'}; Text Search necesita también nextPageToken en la máscara si se quiere paginar.

El coste y el tratamiento de sesión dependen de los campos y de cómo se concluye la sesión. Incluir location no es una consulta IDs Only; no se promete una reducción de precio. Revisa [campos Details](https://developers.google.com/maps/documentation/places/web-service/place-details) y [facturación por sesión](https://developers.google.com/maps/documentation/places/web-service/session-pricing).

## Nearby y Text Search

~~~dart
final nearby = await client.searchNearby(
  const NearbySearchRequest(
    locationRestriction: CircleArea(
      center: PlaceLocation(latitude: 32.5, longitude: -117),
      radiusMeters: 5000,
    ),
    includedTypes: ['restaurant'],
    rankPreference: NearbyRankPreference.distance,
    maxResultCount: 20,
  ),
  fields: {'places.id', 'places.location'},
);
~~~

Nearby admite filtros incluidos/excluidos de tipos y tipos primarios, idioma/región, ranking popularity/distance y un círculo obligatorio. Límite de resultados explícito 1..20 y hasta 50 tipos por filtro. No tiene keyword, name textual, precio, openNow ni paginación Legacy. Para texto llama explícitamente a searchText; no hay sustitución automática de endpoint.

~~~dart
final page = await client.searchText(
  const TextSearchRequest(
    textQuery: 'restaurantes en Tijuana',
    languageCode: 'es-MX',
    includedType: 'restaurant',
    strictTypeFiltering: true,
    openNow: true,
    priceLevels: ['PRICE_LEVEL_MODERATE'],
    rankPreference: TextRankPreference.relevance,
    pageSize: 20,
  ),
  fields: {'places.id', 'places.location', 'nextPageToken'},
);
~~~

Text Search admite ranking relevance/distance, filtros nativos, locationBias o restricción rectangular (anchura máxima 180 grados). pageSize omitido/0 usa el predeterminado de Google; 1..20 es explícito, negativos o >20 se rechazan localmente sin recorte. Para la siguiente página reconstruye la solicitud conservando todos los parámetros salvo pageToken y pageSize; pasa page.nextPageToken. No se usa maxResultCount obsoleto en Text Search.

Fuentes: [Nearby](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places/searchNearby), [Text Search](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places/searchText).

## Photos

Solicita photos en Details, o places.photos en Search. Usa el nombre fresco devuelto, por ejemplo places/{id}/photos/{photo}:

~~~dart
final media = await client.fetchPhotoMedia(photo.name!, maxWidthPx: 400);
// Mostrar media.photoUri sin copiar encabezados de autenticación a ese host.
// Mostrar también photo.authorAttributions cuando estén presentes.
~~~

Al menos una dimensión entera 1..4800. El cliente pide skipHttpRedirect=true, valida PhotoMedia y devuelve una URI HTTP(S) absoluta; no descarga la imagen, no sigue redirecciones y no reenvía secretos al host de la imagen. El nombre puede caducar: conserva las atribuciones y no persistas nombres temporales ni agregues caché. Un recurso vencido devuelve error, sin reintento ni fallback oculto. [Photos New](https://developers.google.com/maps/documentation/places/web-service/place-photos).

## Errores, proxy e identidad

Las solicitudes inválidas fallan con ArgumentError antes de enviar HTTP. Los errores HTTP/Google, transporte, identidad y formato se entregan como PlacesApiException(kind, httpStatus, code, message, details). El widget transforma errores locales en kind validation para onError y termina la carga. No abre diálogos técnicos. El consumidor decide cómo registrar el error seguro y el texto que ve su cliente. Los errores de una consulta obsoleta o de un widget desmontado no se notifican.

baseUri por defecto: https://places.googleapis.com/v1. Para un proxy configura su raíz New completa, por ejemplo https://proxy.example/proxy/v1; se conserva el prefijo. Sin apiKey se exige baseUri explícita y el proxy debe autenticar al consumidor, por ejemplo mediante headers. El paquete no implementa el servidor proxy.

GoogleApiHeaders proporciona identidad móvil en todas las operaciones, incluido Details directo y Photos. X-Android-Cert se normaliza a 40 caracteres hexadecimales mayúsculos sin separadores; identidad mal formada falla localmente. headers personalizados no sustituyen clave, máscara, Content-Type ni identidad protegidos. identityHeaders es el punto de inyección para pruebas/plataformas especiales; quien lo sustituya debe suministrar identidad correcta.

La clave se envía en X-Goog-Api-Key y se redacta en los errores del cliente. No se incluyen claves en URL ni se siguen redirecciones. Esto no demuestra que Google aplique las restricciones: antes de activar, verifica identidad correcta exitosa y paquete/certificado incorrectos rechazados en Autocomplete y Details. También verifica las operaciones Search/Photos usadas. [Seguridad de API](https://developers.google.com/maps/api-security-best-practices).

Habilita Places API (New), revisa proyecto/facturación/cuotas y autoriza New en las restricciones de la clave. Comprueba el certificado del APK efectivo; debug, release local y Play pueden diferir. Web exige pruebas de CORS/origen; Android no certifica iOS, Web ni proxy. Si las restricciones no se cumplen, no actives conexión directa: revisa un proxy autenticado o integración nativa.

## Verificación

~~~sh
flutter pub get --no-example
dart run build_runner build
flutter test --no-pub
~~~

Los .g.dart se generan, no se editan manualmente. Las doce referencias visuales fueron capturadas con Legacy antes de migrar y deben compararse sin --update-goldens. Consulta [validation-v2.md](validation-v2.md) para la evidencia local y los pendientes reales.
