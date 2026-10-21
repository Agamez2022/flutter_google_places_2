import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_2/flutter_google_places_2.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class PlacesHarness {
  final pending = Completer<http.Response>();
  final requests = <http.Request>[];
  late final http.Client httpClient = MockClient((request) {
    requests.add(request);
    return pending.future;
  });
  late final PlacesClient client = PlacesClient(
    apiKey: 'synthetic-key',
    httpClient: httpClient,
    identityHeaders: () async => {},
  );

  Future<Object?> open(BuildContext context, Mode mode, {Widget? logo}) =>
      PlacesAutocomplete.show(
        context: context,
        client: client,
        mode: mode,
        hint: 'Buscar',
        logo: logo,
        sessionToken: 'synthetic-session',
        overlayBorderRadius: BorderRadius.circular(8),
        textStyle: const TextStyle(fontSize: 16),
        resultTextStyle: const TextStyle(fontSize: 14),
      );
  void complete() => pending.complete(
    http.Response(
      jsonEncode({
        'suggestions': [
          {
            'placePrediction': {
              'text': {'text': 'Tijuana, Baja California'},
              'placeId': 'test-place',
            },
          },
          {
            'placePrediction': {
              'text': {'text': 'Rosarito, Baja California'},
              'placeId': 'other-place',
            },
          },
        ],
      }),
      200,
    ),
  );
  String? selectedId(Object? result) =>
      (result as PlaceSelection?)?.prediction.placeId;
}
