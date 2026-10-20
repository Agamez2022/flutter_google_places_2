import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late PlacesClient client;
  setUp(() {
    client = PlacesClient(
      apiKey: 'key',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      identityHeaders: () async => {},
    );
  });
  testWidgets('Field respects external controller and hint', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlacesAutocompleteField(
            client: client,
            controller: controller,
            hint: 'Buscar',
          ),
        ),
      ),
    );
    expect(find.text('Buscar'), findsOneWidget);
    controller.text = 'Tijuana';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlacesAutocompleteField(
            client: client,
            controller: controller,
            hint: 'Buscar',
          ),
        ),
      ),
    );
    expect(find.text('Tijuana'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.text = 'Still usable';
  });

  testWidgets('FormField initialValue reset and validator', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            child: PlacesAutocompleteFormField(
              client: client,
              initialValue: 'Tijuana',
              validator: (value) => value == 'Tijuana' ? null : 'Invalid',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Tijuana'), findsOneWidget);
    expect(key.currentState!.validate(), isTrue);
    key.currentState!.reset();
    await tester.pump();
    expect(find.text('Tijuana'), findsOneWidget);
  });
}
