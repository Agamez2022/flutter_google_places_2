import 'dart:convert';

import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const circle = CircleArea(
  center: PlaceLocation(latitude: 32.5, longitude: -117),
  radiusMeters: 50000,
);
const rectangle = RectangleArea(
  low: PlaceLocation(latitude: 32, longitude: -118),
  high: PlaceLocation(latitude: 33, longitude: -116),
);
void main() {
  test('Nearby sends native filters, circle, ranking, identity and explicit mask', () async {
    final transport = MockClient((r) async {
      expect(r.method, 'POST');
      expect(r.url.path, '/v1/places:searchNearby');
      expect(r.headers['x-goog-fieldmask'], 'places.id,places.location');
      expect(r.headers['x-ios-bundle-identifier'], 'test.bundle');
      expect(jsonDecode(r.body), {
        'locationRestriction': circle.toJson(),
        'includedTypes': ['restaurant'],
        'excludedTypes': ['cafe'],
        'includedPrimaryTypes': ['restaurant'],
        'excludedPrimaryTypes': ['bar'],
        'maxResultCount': 20,
        'rankPreference': 'DISTANCE',
        'languageCode': 'es-MX',
        'regionCode': 'mx',
      });
      return http.Response(
        '{"places":[{"id":"p","location":{"latitude":32.5,"longitude":-117}}]}',
        200,
      );
    });
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {'X-Ios-Bundle-Identifier': 'test.bundle'},
    );
    final response = await client.searchNearby(
      const NearbySearchRequest(
        locationRestriction: circle,
        includedTypes: ['restaurant'],
        excludedTypes: ['cafe'],
        includedPrimaryTypes: ['restaurant'],
        excludedPrimaryTypes: ['bar'],
        maxResultCount: 20,
        rankPreference: NearbyRankPreference.distance,
        languageCode: 'es-MX',
        regionCode: 'mx',
      ),
      fields: {'places.id', 'places.location'},
    );
    expect(response.places.single.id, 'p');
    expect(response.places.single.displayName, isNull);
    transport.close();
  });
  test(
    'Text pagination preserves filters and parses native nextPageToken',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final transport = MockClient((r) async {
        expect(r.url.path, '/v1/places:searchText');
        expect(
          r.headers['x-goog-fieldmask'],
          'places.id,places.location,nextPageToken',
        );
        bodies.add(jsonDecode(r.body) as Map<String, dynamic>);
        return http.Response(
          bodies.length == 1 ? '{"nextPageToken":"page2"}' : '{}',
          200,
        );
      });
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      TextSearchRequest page(String? token) => TextSearchRequest(
        textQuery: 'restaurantes Tijuana',
        languageCode: 'es-MX',
        regionCode: 'mx',
        includedType: 'restaurant',
        strictTypeFiltering: true,
        openNow: true,
        priceLevels: ['PRICE_LEVEL_MODERATE'],
        pageSize: 20,
        pageToken: token,
        rankPreference: TextRankPreference.relevance,
        locationRestriction: rectangle,
      );
      final first = await client.searchText(
        page(null),
        fields: {'places.id', 'places.location', 'nextPageToken'},
      );
      expect(first.places, isEmpty);
      final second = await client.searchText(
        page(first.nextPageToken),
        fields: {'places.id', 'places.location', 'nextPageToken'},
      );
      expect(second.places, isEmpty);
      expect(second.nextPageToken, isNull);
      expect(bodies[1].remove('pageToken'), 'page2');
      expect(bodies[1], bodies[0]);
      expect(bodies[0]['pageSize'], 20);
      expect(bodies[0].containsKey('maxResultCount'), isFalse);
      expect(bodies[0]['priceLevels'], ['PRICE_LEVEL_MODERATE']);
      transport.close();
    },
  );
  test('invalid search options and masks emit no HTTP', () async {
    var calls = 0;
    final transport = MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {},
    );
    for (final count in [0, -1, 21]) {
      await expectLater(
        client.searchNearby(
          NearbySearchRequest(
            locationRestriction: circle,
            maxResultCount: count,
          ),
          fields: {'places.id'},
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      client.searchNearby(
        const NearbySearchRequest(
          locationRestriction: circle,
          includedTypes: ['cafe'],
          excludedTypes: ['cafe'],
        ),
        fields: {'places.id'},
      ),
      throwsArgumentError,
    );
    await expectLater(
      client.searchNearby(
        const NearbySearchRequest(locationRestriction: circle),
        fields: {},
      ),
      throwsArgumentError,
    );
    for (final size in [-1, 21]) {
      await expectLater(
        client.searchText(
          TextSearchRequest(textQuery: 'a', pageSize: size),
          fields: {'places.id'},
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      client.searchText(
        const TextSearchRequest(textQuery: ' '),
        fields: {'places.id'},
      ),
      throwsArgumentError,
    );
    await expectLater(
      client.searchText(
        const TextSearchRequest(
          textQuery: 'a',
          locationBias: circle,
          locationRestriction: rectangle,
        ),
        fields: {'places.id'},
      ),
      throwsArgumentError,
    );
    await expectLater(
      client.searchText(
        const TextSearchRequest(
          textQuery: 'a',
          locationRestriction: RectangleArea(
            low: PlaceLocation(latitude: 0, longitude: -170),
            high: PlaceLocation(latitude: 10, longitude: 170),
          ),
        ),
        fields: {'places.id'},
      ),
      throwsArgumentError,
    );
    expect(calls, 0);
    transport.close();
  });
  test('pageSize zero and native query suggestions are supported', () async {
    final requests = <http.Request>[];
    final transport = MockClient((r) async {
      requests.add(r);
      return http.Response(
        r.url.path.endsWith('autocomplete')
            ? '{"suggestions":[{"queryPrediction":{"text":{"text":"cafes near me"}}}]}'
            : '{}',
        200,
      );
    });
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {},
    );
    expect(
      (await client.searchText(
        const TextSearchRequest(textQuery: 'a', pageSize: 0),
        fields: {'places.id'},
      )).places,
      isEmpty,
    );
    final queries = await client.autocomplete(
      const AutocompleteRequest(input: 'caf', includeQueryPredictions: true),
    );
    expect(queries.suggestions.single, isA<QueryPrediction>());
    expect(queries.placePredictions, isEmpty);
    expect(jsonDecode(requests.last.body)['includeQueryPredictions'], isTrue);
    transport.close();
  });
  for (final status in [403, 429]) {
    test('Search propagates $status without fallback or retry', () async {
      var calls = 0;
      final transport = MockClient((_) async {
        calls++;
        return http.Response('{"error":{"message":"denied"}}', status);
      });
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await expectLater(
        client.searchText(
          const TextSearchRequest(textQuery: 'a'),
          fields: {'places.id'},
        ),
        throwsA(
          isA<PlacesApiException>().having(
            (e) => e.httpStatus,
            'status',
            status,
          ),
        ),
      );
      expect(calls, 1);
      transport.close();
    });
  }
}
