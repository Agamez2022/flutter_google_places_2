import 'dart:convert';

import 'package:flutter_google_places_2/src/places_client.dart';
import 'package:flutter_google_places_2/src/places_models.dart';
import 'package:flutter_google_places_2/src/places_requests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TrackingClient extends MockClient {
  TrackingClient() : super((_) async => http.Response('{}', 200));
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  Future<Map<String, String>> identity() async => {
    'X-Android-Package': 'example.app',
    'X-Android-Cert': List.filled(20, 'ab').join(':'),
  };
  test('Autocomplete and Details share native auth and identity', () async {
    final requests = <http.Request>[];
    final transport = MockClient((r) async {
      requests.add(r);
      if (r.method == 'POST') {
        return http.Response(
          jsonEncode({
            'suggestions': [
              {
                'placePrediction': {
                  'placeId': 'test-place',
                  'text': {'text': 'Tijuana'},
                },
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        '{"id":"test-place","location":{"latitude":32.5027,"longitude":-117.0003}}',
        200,
      );
    });
    final client = PlacesClient(
      apiKey: 'synthetic-key',
      httpClient: transport,
      identityHeaders: identity,
      headers: const {
        'x-goog-api-key': 'wrong',
        'x-android-cert': 'wrong',
        'custom': 'ok',
      },
    );
    final predictions = await client.autocomplete(
      const AutocompleteRequest(input: 'Tijuana', sessionToken: 'session'),
    );
    final place = await client.fetchPlace(
      predictions.placePredictions.single.placeId,
      fields: {'id', 'location'},
      sessionToken: 'session',
      languageCode: 'es-MX',
      regionCode: 'mx',
    );
    expect(place.location!.longitude, -117.0003);
    expect(requests.first.method, 'POST');
    expect(
      requests.first.url.toString(),
      'https://places.googleapis.com/v1/places:autocomplete',
    );
    expect(jsonDecode(requests.first.body), {
      'input': 'Tijuana',
      'sessionToken': 'session',
      'includeQueryPredictions': false,
    });
    expect(requests.last.url.path, '/v1/places/test-place');
    expect(requests.last.url.queryParameters, {
      'sessionToken': 'session',
      'languageCode': 'es-MX',
      'regionCode': 'mx',
    });
    expect(requests.last.headers['x-goog-fieldmask'], 'id,location');
    for (final r in requests) {
      expect(r.headers['x-goog-api-key'], 'synthetic-key');
      expect(r.headers['x-android-package'], 'example.app');
      expect(r.headers['x-android-cert'], List.filled(20, 'AB').join());
      expect(r.url.toString(), isNot(contains('synthetic-key')));
      expect(r.headers['custom'], 'ok');
    }
    client.close();
    transport.close();
  });
  for (final status in [400, 403, 404, 429, 500]) {
    test('HTTP $status is a typed, redacted API error', () async {
      final transport = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {
              'code': status,
              'status': 'ERROR',
              'message': 'bad synthetic-key',
              'details': [
                {'key': 'synthetic-key'},
              ],
            },
          }),
          status,
        ),
      );
      final client = PlacesClient(
        apiKey: 'synthetic-key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await expectLater(
        client.fetchPlace('test', fields: {'id'}),
        throwsA(
          isA<PlacesApiException>()
              .having((e) => e.httpStatus, 'status', status)
              .having(
                (e) => e.toString() + e.details.toString(),
                'secrets',
                isNot(contains('synthetic-key')),
              ),
        ),
      );
      transport.close();
    });
  }
  test('invalid JSON and transport failures are typed', () async {
    for (final invalid in [false, true]) {
      final transport = MockClient((_) async {
        if (!invalid) throw http.ClientException('offline');
        return http.Response('bad JSON', 200);
      });
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await expectLater(
        client.fetchPlace('test', fields: {'id'}),
        throwsA(isA<PlacesApiException>()),
      );
      transport.close();
    }
  });
  test('bad fields or identity fail without HTTP', () async {
    var calls = 0;
    final transport = MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {'X-Android-Cert': 'bad'},
    );
    await expectLater(
      client.fetchPlace('test', fields: {}),
      throwsArgumentError,
    );
    await expectLater(
      client.fetchPlace('test', fields: {'id'}),
      throwsA(isA<PlacesApiException>()),
    );
    expect(calls, 0);
    transport.close();
  });
  test('proxy preserves prefix and injected client ownership', () async {
    final transport = TrackingClient();
    final requests = <Uri>[];
    final mock = MockClient((r) async {
      requests.add(r.url);
      return http.Response('{}', 200);
    });
    final proxy = PlacesClient(
      baseUri: Uri.parse('https://example.test/proxy/v1'),
      httpClient: mock,
      identityHeaders: () async => {'X-Ios-Bundle-Identifier': 'example.app'},
    );
    await proxy.autocomplete(const AutocompleteRequest(input: 'a'));
    expect(requests.single.path, '/proxy/v1/places:autocomplete');
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {},
    );
    client.close();
    client.close();
    expect(transport.closed, isFalse);
    await expectLater(
      client.fetchPlace('test', fields: {'id'}),
      throwsStateError,
    );
    transport.close();
    mock.close();
  });
}
