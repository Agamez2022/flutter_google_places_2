import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<void> open(
  WidgetTester tester,
  PlacesClient client,
  Mode mode, {
  ValueChanged<PlacesApiException>? onError,
  Duration? debounce,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => PlacesAutocomplete.show(
              context: context,
              client: client,
              mode: mode,
              onError: onError,
              debounce: debounce,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

http.Response result() => http.Response(
  jsonEncode({
    'suggestions': [
      {
        'placePrediction': {
          'placeId': 'old',
          'text': {'text': 'Old result'},
        },
      },
    ],
  }),
  200,
);

void main() {
  for (final mode in Mode.values) {
    for (final exit in [
      'system',
      'button',
      if (mode == Mode.overlay) 'barrier',
    ]) {
      testWidgets('$mode $exit suppresses errors during reverse transition', (
        tester,
      ) async {
        final pending = Completer<http.Response>();
        var errors = 0;
        final transport = MockClient((_) => pending.future);
        final client = PlacesClient(
          apiKey: 'key',
          httpClient: transport,
          identityHeaders: () async => {},
        );
        await open(tester, client, mode, onError: (_) => errors++);
        await tester.enterText(find.byType(TextField), 'query');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();
        if (exit == 'system') {
          Navigator.of(tester.element(find.byType(TextField))).pop();
        } else if (exit == 'barrier') {
          await tester.tapAt(const Offset(2, 2));
        } else {
          await tester.tap(find.byIcon(Icons.arrow_back));
        }
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.byType(PlacesAutocompleteWidget), findsOneWidget);
        pending.completeError(http.ClientException('late canceled request'));
        await tester.pump();
        await tester.pump();
        expect(errors, 0);
        await tester.pumpAndSettle();
        transport.close();
      });
    }
    testWidgets('$mode closing prevents debounce request during transition', (
      tester,
    ) async {
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
      await open(
        tester,
        client,
        mode,
        debounce: const Duration(milliseconds: 20),
      );
      await tester.enterText(find.byType(TextField), 'query');
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await tester.pump(const Duration(milliseconds: 25));
      await tester.pump();
      expect(calls, 0);
      await tester.pumpAndSettle();
      transport.close();
    });
    testWidgets('$mode editing invalidates rendered rows before debounce', (
      tester,
    ) async {
      var calls = 0;
      final transport = MockClient((_) async {
        calls++;
        return result();
      });
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await open(tester, client, mode);
      await tester.enterText(find.byType(TextField), 'old');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      final staleTile = tester.widget<PredictionTile>(
        find.byType(PredictionTile),
      );
      await tester.enterText(find.byType(TextField), 'new');
      // A pointer callback may outlive the frame in which its row was painted.
      staleTile.onTap(staleTile.prediction);
      await tester.pump();
      expect(find.byType(PlacesAutocompleteWidget), findsOneWidget);
      expect(find.byType(PredictionTile), findsNothing);
      expect(
        ModalRoute.of(tester.element(find.byType(TextField)))!.isCurrent,
        isTrue,
      );
      expect(calls, 1);
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await tester.pumpAndSettle();
      transport.close();
    });
  }
  test('partial geographic masks preserve missing coordinates; requests require complete input', () async {
    final transport = MockClient(
      (r) async => http.Response(
        jsonEncode(
          r.method == 'GET'
              ? {
                  'id': 'p',
                  'location': {'latitude': 32.5},
                  'viewport': {
                    'low': {'longitude': -117},
                    'high': {},
                  },
                }
              : {
                  'places': [
                    {
                      'id': 'p',
                      'location': {'longitude': -117},
                    },
                  ],
                },
        ),
        200,
      ),
    );
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {},
    );
    final place = await client.fetchPlace(
      'p',
      fields: {
        'id',
        'location.latitude',
        'viewport.low.longitude',
        'viewport.high',
      },
    );
    expect(place.location!.latitude, 32.5);
    expect(place.location!.longitude, isNull);
    expect(place.viewport!.low!.latitude, isNull);
    expect(place.viewport!.high!.latitude, isNull);
    final search = await client.searchText(
      const TextSearchRequest(textQuery: 'a'),
      fields: {'places.location.longitude'},
    );
    expect(search.places.single.location!.latitude, isNull);
    expect(search.places.single.location!.longitude, -117);
    expect(
      () => CircleArea(center: place.location!, radiusMeters: 100).toJson(),
      throwsArgumentError,
    );
    expect(
      () =>
          AutocompleteRequest(input: 'a', origin: place.viewport!.low).toJson(),
      throwsArgumentError,
    );
    expect(
      () => PlaceLocation.fromJson({'latitude': double.nan}),
      throwsArgumentError,
    );
    transport.close();
  });
}
