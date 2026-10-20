import 'package:flutter_google_places_2/src/places_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Place preserves partial masks and resource name separately', () {
    final place = Place.fromJson({
      'id': 'test-place',
      'name': 'places/test-place',
      'location': {'latitude': 32.5027, 'longitude': -117.0003},
      'unknownFutureField': true,
    });
    expect(place.id, 'test-place');
    expect(place.name, 'places/test-place');
    expect(place.displayName, isNull);
    expect(place.location!.latitude, 32.5027);
    expect(place.photos, isNull);
    expect(Place.fromJson({}).id, isNull);
  });

  test('Autocomplete decodes place and query without inventing IDs', () {
    final response = AutocompleteResponse.fromJson({
      'suggestions': [
        {
          'placePrediction': {
            'placeId': 'test-place',
            'place': 'places/test-place',
            'text': {
              'text': 'A😀B',
              'matches': [
                {'startOffset': 1, 'endOffset': 2},
              ],
            },
            'structuredFormat': {
              'mainText': {'text': 'A😀B'},
            },
          },
        },
        {
          'queryPrediction': {
            'text': {'text': 'cafés cerca'},
          },
        },
      ],
    });
    expect(response.placePredictions.single.placeId, 'test-place');
    expect(response.placePredictions.single.text.matches!.single.endOffset, 2);
    expect(response.suggestions.last, isA<QueryPrediction>());
    expect(AutocompleteResponse.fromJson({}).suggestions, isEmpty);
  });

  test('Place keeps native nested data and unknown enum values', () {
    final p = Place.fromJson({
      'displayName': {'text': 'Visible', 'languageCode': 'es'},
      'addressComponents': [
        {
          'longText': 'México',
          'shortText': 'MX',
          'types': ['country'],
        },
      ],
      'regularOpeningHours': {
        'openNow': false,
        'weekdayDescriptions': ['Lunes'],
        'periods': [
          {
            'open': {
              'day': 1,
              'hour': 9,
              'minute': 30,
              'date': {'year': 2026, 'month': 10, 'day': 20},
            },
          },
        ],
      },
      'photos': [
        {
          'name': 'places/test/photos/p',
          'widthPx': 800,
          'heightPx': 600,
          'authorAttributions': [
            {'displayName': 'Autor', 'uri': 'https://example.test/author'},
          ],
        },
      ],
      'reviews': [
        {
          'rating': 4,
          'text': {'text': 'Bien'},
          'authorAttribution': {'displayName': 'Autor'},
          'publishTime': '2026-10-20T00:00:00Z',
        },
      ],
      'attributions': [
        {'provider': 'Provider', 'providerUri': 'https://example.test'},
      ],
      'businessStatus': 'FUTURE_VALUE',
      'priceLevel': 'FUTURE_PRICE',
    });
    expect(p.displayName!.text, 'Visible');
    expect(p.addressComponents!.single.shortText, 'MX');
    expect(p.regularOpeningHours!.periods!.single.open!.date!.year, 2026);
    expect(p.photos!.single.authorAttributions!.single.displayName, 'Autor');
    expect(p.reviews!.single.rating, 4);
    expect(p.attributions!.single.provider, 'Provider');
    expect(p.priceLevel, 'FUTURE_PRICE');
    expect(p.toJson()['displayName'], {
      'text': 'Visible',
      'languageCode': 'es',
    });
    expect(p.toJson().containsKey('location'), isFalse);
  });
}
