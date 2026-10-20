import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:http/http.dart' as http;

import 'places_models.dart';
import 'places_requests.dart';

typedef PlacesIdentityHeaders = Future<Map<String, String>> Function();

/// REST client for Places API (New). Widgets never close a supplied client.
final class PlacesClient {
  final String? _apiKey;
  final Uri _baseUri;
  final http.Client _httpClient;
  final bool _ownsClient;
  final Map<String, String> _headers;
  final PlacesIdentityHeaders _identityHeaders;
  bool _closed = false;

  PlacesClient({
    String? apiKey,
    Uri? baseUri,
    http.Client? httpClient,
    Map<String, String> headers = const {},
    PlacesIdentityHeaders? identityHeaders,
  }) : _apiKey = apiKey,
       _baseUri = baseUri ?? Uri.parse('https://places.googleapis.com/v1'),
       _httpClient = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _headers = Map.unmodifiable(headers),
       _identityHeaders = identityHeaders ?? _defaultIdentityHeaders {
    if ((apiKey == null || apiKey.isEmpty) && baseUri == null) {
      throw ArgumentError(
        'An API key or an explicit authenticated proxy is required.',
      );
    }
    if (!_baseUri.hasAuthority ||
        !const ['http', 'https'].contains(_baseUri.scheme) ||
        _baseUri.hasQuery ||
        _baseUri.hasFragment ||
        _baseUri.userInfo.isNotEmpty) {
      throw ArgumentError(
        'baseUri must be an HTTP(S) API root without credentials, query or fragment.',
      );
    }
  }

  static Future<Map<String, String>> _defaultIdentityHeaders() async {
    const provider = GoogleApiHeaders();
    final headers = await provider.getHeaders();
    if (!kIsWeb &&
        ((provider.platform.isAndroid &&
                (!headers.containsKey('X-Android-Package') ||
                    !headers.containsKey('X-Android-Cert'))) ||
            (provider.platform.isIos &&
                !headers.containsKey('X-Ios-Bundle-Identifier')))) {
      throw StateError('Mobile application identity is unavailable.');
    }
    return headers;
  }

  Future<AutocompleteResponse> autocomplete(
    AutocompleteRequest request,
  ) async => _request(
    'POST',
    ['places:autocomplete'],
    body: request.toJson(),
    parse: AutocompleteResponse.fromJson,
  );

  Future<Place> fetchPlace(
    String placeId, {
    required Set<String> fields,
    String? sessionToken,
    String? languageCode,
    String? regionCode,
  }) async {
    _validatePlaceId(placeId);
    final mask = _fieldMask(fields);
    return _request(
      'GET',
      ['places', placeId],
      fields: mask,
      query: {
        'sessionToken': ?sessionToken,
        'languageCode': ?languageCode,
        'regionCode': ?regionCode,
      },
      parse: Place.fromJson,
    );
  }

  Future<NearbySearchResponse> searchNearby(
    NearbySearchRequest request, {
    required Set<String> fields,
  }) async => _request(
    'POST',
    ['places:searchNearby'],
    fields: _fieldMask(fields),
    body: request.toJson(),
    parse: NearbySearchResponse.fromJson,
  );

  Future<TextSearchResponse> searchText(
    TextSearchRequest request, {
    required Set<String> fields,
  }) async => _request(
    'POST',
    ['places:searchText'],
    fields: _fieldMask(fields),
    body: request.toJson(),
    parse: TextSearchResponse.fromJson,
  );

  /// Resolves fresh photo metadata; does not download or cache the returned image.
  Future<PhotoMedia> fetchPhotoMedia(
    String photoName, {
    int? maxWidthPx,
    int? maxHeightPx,
  }) async {
    final segments = photoName.split('/');
    if (segments.length != 4 ||
        segments[0] != 'places' ||
        segments[2] != 'photos') {
      throw ArgumentError(
        'Use a photo resource name: places/{id}/photos/{photo}.',
      );
    }
    _validatePlaceId(segments[1]);
    _validatePlaceId(segments[3]);
    if ((maxWidthPx == null && maxHeightPx == null) ||
        [
          maxWidthPx,
          maxHeightPx,
        ].any((size) => size != null && (size < 1 || size > 4800))) {
      throw ArgumentError(
        'Provide a width or height between 1 and 4800 pixels.',
      );
    }
    return _request(
      'GET',
      [...segments, 'media'],
      query: {
        if (maxWidthPx != null) 'maxWidthPx': '$maxWidthPx',
        if (maxHeightPx != null) 'maxHeightPx': '$maxHeightPx',
        'skipHttpRedirect': 'true',
      },
      parse: (json) {
        final media = PhotoMedia.fromJson(json);
        if (media.name != '$photoName/media' ||
            !media.photoUri.hasAuthority ||
            media.photoUri.host.isEmpty ||
            !const ['http', 'https'].contains(media.photoUri.scheme) ||
            media.photoUri.userInfo.isNotEmpty) {
          throw const FormatException('Invalid photo media resource.');
        }
        return media;
      },
    );
  }

  static void _validatePlaceId(String placeId) {
    if (placeId.isEmpty ||
        placeId == '.' ||
        placeId == '..' ||
        RegExp(r'[/\s?#]').hasMatch(placeId)) {
      throw ArgumentError(
        'Use a standalone place ID, not a URL or resource name.',
      );
    }
  }

  static String _fieldMask(Set<String> fields) {
    if (fields.isEmpty ||
        fields.any(
          (field) => field.isEmpty || RegExp(r'[\s,]').hasMatch(field),
        )) {
      throw ArgumentError(
        'Provide a non-empty set of field paths without whitespace or commas.',
      );
    }
    return fields.join(',');
  }

  Future<Map<String, String>> _requestHeaders(String? fields) async {
    try {
      final identity = <String, String>{
        for (final entry in (await _identityHeaders()).entries)
          entry.key.toLowerCase(): entry.value,
      };
      if (identity.containsKey('x-android-cert')) {
        final cert = identity['x-android-cert']!
            .replaceAll(':', '')
            .toUpperCase();
        if (!RegExp(r'^[0-9A-F]{40}$').hasMatch(cert) ||
            identity['x-android-package']?.trim().isNotEmpty != true) {
          throw StateError('Invalid Android signing identity.');
        }
        identity['x-android-cert'] = cert;
      } else if (identity.containsKey('x-android-package')) {
        throw StateError('Android signing certificate is missing.');
      }
      const reserved = {
        'x-goog-api-key',
        'x-goog-fieldmask',
        'content-type',
        'x-android-package',
        'x-android-cert',
        'x-ios-bundle-identifier',
      };
      return {
        for (final entry in _headers.entries)
          if (!reserved.contains(entry.key.toLowerCase()))
            entry.key.toLowerCase(): entry.value,
        ...identity,
        if (_apiKey != null) 'x-goog-api-key': _apiKey,
        'content-type': 'application/json',
        'x-goog-fieldmask': ?fields,
      };
    } catch (error) {
      throw PlacesApiException(
        kind: PlacesErrorKind.identity,
        message: _redact(error.toString()),
      );
    }
  }

  Future<T> _request<T>(
    String method,
    List<String> path, {
    Map<String, dynamic>? body,
    Map<String, String> query = const {},
    String? fields,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    if (_closed) throw StateError('PlacesClient is closed.');
    final headers = await _requestHeaders(fields);
    if (_closed) throw StateError('PlacesClient is closed.');
    final uri = _baseUri.replace(
      pathSegments: [
        ..._baseUri.pathSegments.where((s) => s.isNotEmpty),
        ...path,
      ],
      queryParameters: query.isEmpty ? null : query,
    );
    late final http.Response response;
    try {
      final request = http.Request(method, uri)
        ..followRedirects = false
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } catch (error) {
      throw PlacesApiException(
        kind: PlacesErrorKind.transport,
        message: _redact(error.toString()),
      );
    }
    Map<String, dynamic>? json;
    try {
      json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw PlacesApiException(
          kind: PlacesErrorKind.invalidResponse,
          httpStatus: response.statusCode,
          message: 'Places returned invalid JSON.',
        );
      }
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json?['error'] != null) {
      final error = json?['error'];
      final data = error is Map<String, dynamic> ? error : <String, dynamic>{};
      throw PlacesApiException(
        kind: PlacesErrorKind.api,
        httpStatus: response.statusCode,
        code: _redact(
          (data['status'] ?? data['code'] ?? 'HTTP_ERROR').toString(),
        ),
        message: _redact(
          (data['message'] ?? 'Places request failed.').toString(),
        ),
        details: _safeDetails(data['details']),
      );
    }
    try {
      return parse(json!);
    } catch (_) {
      throw PlacesApiException(
        kind: PlacesErrorKind.invalidResponse,
        httpStatus: response.statusCode,
        message: 'Places returned an unexpected response shape.',
      );
    }
  }

  String _redact(String value) => _apiKey == null || _apiKey.isEmpty
      ? value
      : value.replaceAll(_apiKey, '[REDACTED]');

  Object? _safeDetails(Object? value) {
    if (value is String) return _redact(value);
    if (value is List) return value.map(_safeDetails).toList(growable: false);
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(_redact(key.toString()), _safeDetails(item)),
      );
    }
    return value;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _httpClient.close();
  }
}
