import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_google_places_2/google_maps_webservice_places.dart'
    as transition;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Compile the standalone consumer example without another package.
// ignore: avoid_relative_lib_imports
import '../example/lib/places_picker.dart';

void main() {
  for (final shape in ['complete', 'missing', 'partial']) {
    final hasLocation = shape == 'complete';
    testWidgets(
      'public example preserves session and handles masked location $shape',
      (tester) async {
        String? token;
        var calls = 0;
        final errors = <PlacesApiException>[];
        final transport = MockClient((r) async {
          calls++;
          if (r.method == 'POST') {
            final body = jsonDecode(r.body) as Map<String, dynamic>;
            token = body['sessionToken'] as String;
            expect(body['includedRegionCodes'], ['mx']);
            expect(body['locationRestriction']['circle']['radius'], 50000);
            return http.Response(
              '{"suggestions":[{"placePrediction":{"placeId":"p","text":{"text":"Selected"}}}]}',
              200,
            );
          }
          expect(r.url.queryParameters['sessionToken'], token);
          expect(r.headers['x-goog-fieldmask'], 'id,location');
          return http.Response(
            hasLocation
                ? '{"id":"p","location":{"latitude":32.5,"longitude":-117}}'
                : shape == 'partial'
                ? '{"id":"p","location":{"latitude":32.5}}'
                : '{"id":"p"}',
            200,
          );
        });
        final client = transition.PlacesClient(
          apiKey: 'key',
          httpClient: transport,
          identityHeaders: () async => {},
        );
        Future<PlaceLocation?>? result;
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () {
                      result = pickDeliveryLocation(
                        context,
                        client,
                        center: const PlaceLocation(
                          latitude: 32.5,
                          longitude: -117,
                        ),
                        onError: errors.add,
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'query');
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Selected'));
          await tester.pumpAndSettle();
          final location = await result;
          expect(location?.latitude, hasLocation ? 32.5 : null);
          expect(errors, hasLocation ? isEmpty : hasLength(1));
          expect(calls, 2);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          client.close();
          transport.close();
        }
      },
    );
  }
}
