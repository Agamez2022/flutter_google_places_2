import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'helpers/places_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final mode in Mode.values) {
    for (final brightness in Brightness.values) {
      for (final phase in ['empty', 'loading', 'results']) {
        testWidgets('golden $mode $brightness $phase', (tester) async {
          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final harness = PlacesHarness();
          const boundary = ValueKey('screen');
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(brightness: brightness),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => harness.open(context, mode),
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          if (phase != 'empty') {
            await tester.enterText(find.byType(TextField), 'Tijuana');
            await tester.pump(const Duration(milliseconds: 350));
            await tester.pump();
            expect(find.byType(LinearProgressIndicator), findsOneWidget);
          }
          if (phase == 'results') {
            harness.complete();
            await tester.pumpAndSettle();
            expect(find.text('Tijuana, Baja California'), findsOneWidget);
          }
          await expectLater(
            find.byKey(boundary),
            matchesGoldenFile(
              'goldens/places/${mode.name}-${brightness.name}-$phase.png',
            ),
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }
    testWidgets('$mode selection and cancel', (tester) async {
      final harness = PlacesHarness();
      Future<Object?>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  result = harness.open(context, mode);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'Tijuana');
      await tester.pump(const Duration(milliseconds: 350));
      harness.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tijuana, Baja California'));
      await tester.pumpAndSettle();
      expect(harness.selectedId(await result), 'test-place');
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(await result, isNull);
    });
  }
}
