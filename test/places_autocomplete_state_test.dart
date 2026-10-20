import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response prediction(String name) => http.Response(
  jsonEncode({
    'suggestions': [
      {
        'placePrediction': {
          'placeId': name,
          'text': {'text': name},
        },
      },
    ],
  }),
  200,
);

Future<void> showSearch(
  WidgetTester tester,
  PlacesClient client, {
  ValueChanged<PlacesApiException>? onError,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => PlacesAutocomplete.show(
              context: context,
              client: client,
              onError: onError,
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

Future<void> enter(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  testWidgets(
    'new query does not wait for previous HTTP and ignores its response',
    (tester) async {
      final pending = <String, Completer<http.Response>>{};
      final transport = MockClient((r) {
        final text =
            (jsonDecode(r.body) as Map<String, dynamic>)['input'] as String;
        return (pending[text] = Completer<http.Response>()).future;
      });
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await showSearch(tester, client);
      await enter(tester, 'old');
      await enter(tester, 'new');
      expect(pending.keys, containsAll(['old', 'new']));
      pending['new']!.complete(prediction('new'));
      await tester.pumpAndSettle();
      pending['old']!.complete(prediction('old'));
      await tester.pumpAndSettle();
      expect(find.text('old'), findsNothing);
      expect(find.text('new'), findsNWidgets(2)); // query and row.
      await tester.pumpWidget(const SizedBox.shrink());
      transport.close();
    },
  );
  testWidgets('clearing input empties results and invalidates pending errors', (
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
    await showSearch(tester, client, onError: (_) => errors++);
    await enter(tester, 'old');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    pending.completeError(http.ClientException('late error'));
    await tester.pumpAndSettle();
    expect(errors, 0);
    expect(find.byType(PredictionTile), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    transport.close();
  });
  testWidgets(
    'cursor offsets use Unicode characters and errors finish loading',
    (tester) async {
      final requests = <Map<String, dynamic>>[];
      final errors = <PlacesApiException>[];
      final transport = MockClient((r) async {
        requests.add(jsonDecode(r.body) as Map<String, dynamic>);
        return http.Response(
          '{"error":{"status":"PERMISSION_DENIED","message":"denied"}}',
          403,
        );
      });
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      await showSearch(tester, client, onError: errors.add);
      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'A😀B',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(requests.single['inputOffset'], 2);
      expect(errors.single.httpStatus, 403);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      transport.close();
    },
  );
  testWidgets('dismissing search ignores late errors and keeps client usable', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var errors = 0;
    var calls = 0;
    final transport = MockClient((_) {
      calls++;
      return calls == 1
          ? pending.future
          : Future.value(http.Response('{}', 200));
    });
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {},
    );
    await showSearch(tester, client, onError: (_) => errors++);
    await enter(tester, 'old');
    await tester.pageBack();
    await tester.pumpAndSettle();
    pending.completeError(http.ClientException('late'));
    await tester.pumpAndSettle();
    expect(errors, 0);
    expect((await client.fetchPlace('test', fields: {'id'})).id, isNull);
    transport.close();
  });
  testWidgets('selection retains session and each new search gets a UUID', (
    tester,
  ) async {
    final tokens = <String>[];
    final transport = MockClient((r) async {
      tokens.add(
        (jsonDecode(r.body) as Map<String, dynamic>)['sessionToken'] as String,
      );
      return prediction('Selected');
    });
    final client = PlacesClient(
      apiKey: 'key',
      httpClient: transport,
      identityHeaders: () async => {},
    );
    Future<PlaceSelection?>? selection;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                selection = PlacesAutocomplete.show(
                  context: context,
                  client: client,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await enter(tester, 'query');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selected'));
      await tester.pumpAndSettle();
      expect((await selection)!.sessionToken, tokens.last);
      expect(
        tokens.last,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
    expect(tokens.toSet(), hasLength(2));
    transport.close();
  });
}
