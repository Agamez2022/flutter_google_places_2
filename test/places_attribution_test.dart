import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'helpers/places_test_harness.dart';

void main() {
  for (final mode in Mode.values) {
    for (final brightness in Brightness.values) {
      for (final keyboard in [0.0, 180.0]) {
        for (final custom in [false, true]) {
          testWidgets(
            '$mode $brightness attribution stays visible while scrolling '
            '(custom: $custom, keyboard: $keyboard)',
            (tester) async {
              tester.view.physicalSize = const Size(400, 400);
              tester.view.devicePixelRatio = 1;
              tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
              tester.view.viewPadding = const FakeViewPadding(bottom: 24);
              tester.view.padding = FakeViewPadding(
                bottom: keyboard == 0 ? 24 : 0,
              );
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              addTearDown(tester.view.resetViewInsets);
              addTearDown(tester.view.resetViewPadding);
              addTearDown(tester.view.resetPadding);
              final harness = PlacesHarness();
              addTearDown(harness.httpClient.close);
              Future<Object?>? result;
              await tester.pumpWidget(
                MaterialApp(
                  theme: ThemeData(brightness: brightness),
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () {
                          result = harness.open(
                            context,
                            mode,
                            logo: custom
                                ? const SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: Text('Custom attribution'),
                                    ),
                                  )
                                : null,
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
              if (!custom) {
                await tester.runAsync(
                  () => precacheImage(
                    AssetImage(
                      brightness == Brightness.light
                          ? 'packages/flutter_google_places_2/assets/google_white.png'
                          : 'packages/flutter_google_places_2/assets/google_black.png',
                    ),
                    tester.element(find.byType(TextField)),
                  ),
                );
              }
              await tester.enterText(find.byType(TextField), 'Place');
              await tester.pump(const Duration(milliseconds: 350));
              harness.pending.complete(
                http.Response(
                  jsonEncode({
                    'suggestions': [
                      for (var i = 0; i < 5; i++)
                        {
                          'placePrediction': {
                            'text': {'text': 'Place $i'},
                            'placeId': 'place-$i',
                          },
                        },
                    ],
                  }),
                  200,
                ),
              );
              await tester.pumpAndSettle();
              final attribution = custom
                  ? find.text('Custom attribution')
                  : find.byType(PoweredByGoogleImage);
              expect(attribution, findsOneWidget);
              expect(attribution.hitTestable(), findsOneWidget);
              final before = tester.getRect(attribution);
              expect(
                before.bottom,
                lessThanOrEqualTo(keyboard == 0 ? 376 : 220),
              );
              await tester.drag(find.text('Place 0'), const Offset(0, -400));
              await tester.pumpAndSettle();
              expect(attribution.hitTestable(), findsOneWidget);
              expect(tester.getRect(attribution), before);
              expect(find.text('Place 4').hitTestable(), findsOneWidget);
              expect(tester.takeException(), isNull);
              await tester.tap(find.text('Place 4'));
              await tester.pumpAndSettle();
              expect(harness.selectedId(await result), 'place-4');
            },
          );
        }
      }
    }
  }
}
