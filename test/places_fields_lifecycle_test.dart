import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class CountingController extends TextEditingController {
  CountingController(String text) : super(text: text);
  bool wasDisposed = false;
  @override
  void dispose() {
    wasDisposed = true;
    super.dispose();
  }
}

void main() {
  for (final form in [false, true]) {
    testWidgets('$form internal to external respects new controller text', (
      tester,
    ) async {
      final external = CountingController('External');
      final transport = MockClient((_) async => http.Response('{}', 200));
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      TextEditingController? current;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return form
                    ? PlacesAutocompleteFormField(
                        client: client,
                        controller: current,
                        hint: 'Buscar',
                      )
                    : PlacesAutocompleteField(
                        client: client,
                        controller: current,
                        hint: 'Buscar',
                      );
              },
            ),
          ),
        ),
      );
      update(() => current = external);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('External'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(external.wasDisposed, isFalse);
      external.dispose();
      transport.close();
    });
    testWidgets(
      '$form replacing external preserves new text and caller ownership',
      (tester) async {
        final a = CountingController('Old');
        final b = CountingController('New');
        final transport = MockClient((_) async => http.Response('{}', 200));
        final client = PlacesClient(
          apiKey: 'key',
          httpClient: transport,
          identityHeaders: () async => {},
        );
        TextEditingController? current = a;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return form
                      ? PlacesAutocompleteFormField(
                          client: client,
                          controller: current,
                        )
                      : PlacesAutocompleteField(
                          client: client,
                          controller: current,
                        );
                },
              ),
            ),
          ),
        );
        update(() => current = b);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(b.text, 'New');
        expect(find.text('New'), findsOneWidget);
        update(() => current = null);
        await tester.pump();
        a.text = 'Detached old';
        b.text = 'Detached new';
        await tester.pump();
        expect(find.text('New'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(a.wasDisposed, isFalse);
        expect(b.wasDisposed, isFalse);
        a.dispose();
        b.dispose();
        transport.close();
      },
    );
    testWidgets(
      '$form external controller changes update field without parent rebuild',
      (tester) async {
        final external = CountingController('Before');
        final transport = MockClient((_) async => http.Response('{}', 200));
        final client = PlacesClient(
          apiKey: 'key',
          httpClient: transport,
          identityHeaders: () async => {},
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: form
                  ? PlacesAutocompleteFormField(
                      client: client,
                      controller: external,
                    )
                  : PlacesAutocompleteField(
                      client: client,
                      controller: external,
                    ),
            ),
          ),
        );
        external.text = 'After';
        await tester.pump();
        expect(find.text('After'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        external.dispose();
        transport.close();
      },
    );
  }
  testWidgets(
    'selection after field is removed cannot call setState or callbacks',
    (tester) async {
      final transport = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'suggestions': [
              {
                'placePrediction': {
                  'placeId': 'selected',
                  'text': {'text': 'Selected'},
                },
              },
            ],
          }),
          200,
        ),
      );
      final client = PlacesClient(
        apiKey: 'key',
        httpClient: transport,
        identityHeaders: () async => {},
      );
      var visible = true;
      var callbacks = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return visible
                    ? PlacesAutocompleteField(
                        client: client,
                        onSelected: (_) => callbacks++,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PlacesAutocompleteField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'query');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      update(() => visible = false);
      await tester.pump();
      await tester.tap(find.text('Selected'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(callbacks, 0);
      transport.close();
    },
  );
}
