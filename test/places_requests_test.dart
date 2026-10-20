import 'package:flutter_google_places_2/src/places_models.dart';
import 'package:flutter_google_places_2/src/places_requests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const point = PlaceLocation(latitude: 32.5027, longitude: -117.0003);
  test('Autocomplete emits native circle, filters and integer offset', () {
    const request = AutocompleteRequest(
      input: 'A😀B',
      inputOffset: 2,
      locationRestriction: CircleArea(center: point, radiusMeters: 50000),
      includedPrimaryTypes: ['street_address'],
      includedRegionCodes: ['mx'],
      sessionToken: 'session',
      languageCode: 'es-MX',
      regionCode: 'mx',
    );
    expect(request.toJson(), {
      'input': 'A😀B',
      'inputOffset': 2,
      'locationRestriction': {
        'circle': {'center': point.toJson(), 'radius': 50000},
      },
      'includedPrimaryTypes': ['street_address'],
      'includedRegionCodes': ['mx'],
      'sessionToken': 'session',
      'languageCode': 'es-MX',
      'regionCode': 'mx',
      'includeQueryPredictions': false,
    });
  });
  for (final radius in [71450.0, -1.0, double.nan, double.infinity]) {
    test('rejects invalid radius $radius', () {
      expect(
        () => AutocompleteRequest(
          input: 'a',
          locationBias: CircleArea(center: point, radiusMeters: radius),
        ).toJson(),
        throwsArgumentError,
      );
    });
  }
  test('bias allows zero but restriction does not', () {
    expect(
      const AutocompleteRequest(
        input: 'a',
        locationBias: CircleArea(center: point, radiusMeters: 0),
      ).toJson(),
      isNotEmpty,
    );
    expect(
      () => const AutocompleteRequest(
        input: 'a',
        locationRestriction: CircleArea(center: point, radiusMeters: 0),
      ).toJson(),
      throwsArgumentError,
    );
  });
  test('rejects conflicting areas and legacy address collection', () {
    const circle = CircleArea(center: point, radiusMeters: 500);
    expect(
      () => const AutocompleteRequest(
        input: 'a',
        locationBias: circle,
        locationRestriction: circle,
      ).toJson(),
      throwsArgumentError,
    );
    expect(
      () => const AutocompleteRequest(
        input: 'a',
        includedPrimaryTypes: ['address'],
      ).toJson(),
      throwsArgumentError,
    );
    expect(
      () => const AutocompleteRequest(
        input: 'a',
        includedPrimaryTypes: ['(cities)', 'restaurant'],
      ).toJson(),
      throwsArgumentError,
    );
    expect(
      () => AutocompleteRequest(
        input: 'a',
        includedPrimaryTypes: List.filled(6, 'restaurant'),
      ).toJson(),
      throwsArgumentError,
    );
    expect(
      () => AutocompleteRequest(
        input: 'a',
        includedRegionCodes: List.filled(16, 'mx'),
      ).toJson(),
      throwsArgumentError,
    );
    expect(
      () => const AutocompleteRequest(input: '😀', inputOffset: 2).toJson(),
      throwsArgumentError,
    );
  });
  test('accepts New Table B primary types without a partial allowlist', () {
    for (final type in ['geocode', 'establishment']) {
      expect(
        AutocompleteRequest(input: 'a', includedPrimaryTypes: [type]).toJson(),
        isNotEmpty,
      );
    }
  });
  test('valid antimeridian rectangle remains a rectangle', () {
    const rectangle = RectangleArea(
      low: PlaceLocation(latitude: 0, longitude: 170),
      high: PlaceLocation(latitude: 10, longitude: -170),
    );
    expect(
      const AutocompleteRequest(
        input: 'a',
        locationRestriction: rectangle,
      ).toJson()['locationRestriction'],
      {
        'rectangle': {
          'low': {'latitude': 0.0, 'longitude': 170.0},
          'high': {'latitude': 10.0, 'longitude': -170.0},
        },
      },
    );
  });
}
