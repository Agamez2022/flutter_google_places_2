import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'authenticated REST requests never follow redirects to other hosts',
    () async {
      var calls = 0;
      final transport = MockClient((request) async {
        calls++;
        expect(request.followRedirects, isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://other.test/photo'},
        );
      });
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await expectLater(
        client.fetchPhotoMedia('places/p/photos/a', maxWidthPx: 400),
        throwsA(
          isA<PlacesApiException>().having((e) => e.httpStatus, 'status', 302),
        ),
      );
      expect(calls, 1);
      transport.close();
    },
  );
}
