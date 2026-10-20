# flutter_google_places_2 — 2.0

Widgets de autocompletado con la presentación original del fork y transporte REST de **Places API (New)**. Versión incompatible con la API Dart 1.x: no incluye fallback a Places Legacy.

Importa el cliente, los modelos y los widgets desde:

~~~dart
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
~~~

Construye un cliente compartido para Autocomplete y Details:

~~~dart
final client = PlacesClient(apiKey: apiKey);
try {
  final selection = await PlacesAutocomplete.show(
    context: context,
    client: client,
    mode: Mode.overlay,
    languageCode: 'es-MX',
    includedRegionCodes: const ['mx'],
  );
  if (!context.mounted || selection == null) return;
  final place = await client.fetchPlace(
    selection.prediction.placeId,
    fields: {'id', 'location'},
    sessionToken: selection.sessionToken,
  );
  if (!context.mounted) return;
  final latitude = place.location?.latitude;
  final longitude = place.location?.longitude;
  if (latitude == null || longitude == null) return;
  // Usar latitude y longitude; nunca sustituir ausentes por cero.
} on PlacesApiException catch (error) {
  // Registrar información segura y mostrar un mensaje adecuado para el cliente.
} finally {
  client.close();
}
~~~

El [ejemplo completo de selección](example/lib/places_picker.dart) incluye restricción geográfica, filtros y manejo de errores/coordenadas ausentes. Se compila y ejecuta con HTTP simulado en las pruebas de API pública.

Funciones disponibles: Autocomplete, Query Predictions, Details, Nearby Search, Text Search y Photo Media. Los widgets sólo seleccionan lugares y conservan overlay/fullscreen, foco, estilos, márgenes y carga. No consultan Details automáticamente.

Lee la [guía de migración v2](docs/migration-v2.md) antes de actualizar una aplicación. Los campos solicitados afectan la facturación; la clave/proyecto debe tener habilitada Places API (New). Referencias: [Autocomplete](https://developers.google.com/maps/documentation/places/web-service/place-autocomplete), [Details](https://developers.google.com/maps/documentation/places/web-service/place-details) y [sesiones](https://developers.google.com/maps/documentation/places/web-service/using-session-tokens).

La validación local usa respuestas sintéticas y comparaciones visuales. La [validación documentada](docs/validation-v2.md) distingue estos resultados de las comprobaciones pendientes contra Google y en dispositivos.
