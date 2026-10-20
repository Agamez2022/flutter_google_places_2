import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';

/// The caller owns [client] and can reuse it until its screen is disposed.
Future<PlaceLocation?> pickDeliveryLocation(
  BuildContext context,
  PlacesClient client, {
  required PlaceLocation center,
  ValueChanged<PlacesApiException>? onError,
}) async {
  if (!context.mounted) return null;
  final selection = await PlacesAutocomplete.show(
    context: context,
    client: client,
    mode: Mode.overlay,
    hint: 'Buscar',
    languageCode: 'es-MX',
    regionCode: 'mx',
    includedRegionCodes: const ['mx'],
    // Candidate filter: compare actual address coverage before enabling in an app.
    includedPrimaryTypes: const ['street_address'],
    locationRestriction: CircleArea(center: center, radiusMeters: 50000),
    onError: onError,
  );
  if (!context.mounted || selection == null) return null;
  try {
    final place = await client.fetchPlace(
      selection.prediction.placeId,
      fields: {'id', 'location'},
      sessionToken: selection.sessionToken,
      languageCode: 'es-MX',
      regionCode: 'mx',
    );
    if (!context.mounted) return null;
    if (place.location?.latitude == null || place.location?.longitude == null) {
      throw const PlacesApiException(
        kind: PlacesErrorKind.invalidResponse,
        message: 'The selected place has no complete coordinates.',
      );
    }
    return place.location;
  } on PlacesApiException catch (error) {
    if (context.mounted) onError?.call(error);
    return null;
  }
}
