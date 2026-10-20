import 'dart:convert';

import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Photo media uses native resource and identity, never fetches returned host', () async {
    final requests = <http.Request>[];
    final transport = MockClient((r) async {
      requests.add(r);
      expect(r.url.path, '/proxy/v1/places/p/photos/photo/media');
      expect(r.url.queryParameters, {
        'maxWidthPx': '400',
        'skipHttpRedirect': 'true',
      });
      expect(r.headers['x-goog-api-key'], 'key');
      expect(r.headers['x-ios-bundle-identifier'], 'test.bundle');
      expect(r.url.toString(), isNot(contains('key')));
      return http.Response(
        jsonEncode({
          'name': 'places/p/photos/photo/media',
          'photoUri': 'https://images.example.test/image.jpg',
        }),
        200,
      );
    });
    final client = PlacesClient(
      apiKey: 'key',
      baseUri: Uri.parse('https://proxy.test/proxy/v1'),
      httpClient: transport,
      identityHeaders: () async => {'X-Ios-Bundle-Identifier': 'test.bundle'},
    );
    final media = await client.fetchPhotoMedia(
      'places/p/photos/photo',
      maxWidthPx: 400,
    );
    expect(media.photoUri.host, 'images.example.test');
    expect(requests, hasLength(1));
    final photo = PlacePhoto.fromJson({
      'name': 'places/p/photos/photo',
      'authorAttributions': [
        {'displayName': 'Author', 'uri': 'https://author.test'},
      ],
    });
    expect(photo.authorAttributions!.single.displayName, 'Author');
    transport.close();
  });
  test('invalid photo resources and dimensions emit no request', () async {
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
    for (final resource in [
      'https://evil.test/p',
      'places/p/photos/..',
      'places/../photos/a',
      'places/p/photos/a/media',
      'places/p/photos/',
      'places/p/photos/a?key=x',
    ]) {
      await expectLater(
        client.fetchPhotoMedia(resource, maxWidthPx: 1),
        throwsArgumentError,
      );
    }
    await expectLater(
      client.fetchPhotoMedia('places/p/photos/a'),
      throwsArgumentError,
    );
    for (final size in [0, -1, 4801]) {
      await expectLater(
        client.fetchPhotoMedia('places/p/photos/a', maxHeightPx: size),
        throwsArgumentError,
      );
    }
    expect(calls, 0);
    transport.close();
  });
  for (final uri in [
    'javascript:alert(1)',
    '/relative',
    'https:///',
    'data:image/png;base64,a',
  ]) {
    test('malformed photoUri $uri is a typed invalidResponse', () async {
      final transport = MockClient(
        (_) async => http.Response(
          jsonEncode({'name': 'places/p/photos/a/media', 'photoUri': uri}),
          200,
        ),
      );
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await expectLater(
        client.fetchPhotoMedia('places/p/photos/a', maxHeightPx: 4800),
        throwsA(
          isA<PlacesApiException>().having(
            (e) => e.kind,
            'kind',
            PlacesErrorKind.invalidResponse,
          ),
        ),
      );
      transport.close();
    });
  }
  for (final status in [400, 429]) {
    test('expired or throttled photo $status remains an API error', () async {
      final transport = MockClient(
        (_) async => http.Response(
          '{"error":{"message":"expired or throttled"}}',
          status,
        ),
      );
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await expectLater(
        client.fetchPhotoMedia('places/p/photos/a', maxWidthPx: 400),
        throwsA(
          isA<PlacesApiException>().having(
            (e) => e.httpStatus,
            'status',
            status,
          ),
        ),
      );
      transport.close();
    });
  }
}
