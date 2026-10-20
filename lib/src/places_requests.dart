import 'places_models.dart';

sealed class PlacesArea {
  const PlacesArea();
  Map<String, dynamic> toJson();
}

final class CircleArea extends PlacesArea {
  final PlaceLocation center;
  final double radiusMeters;
  const CircleArea({required this.center, required this.radiusMeters});
  @override
  Map<String, dynamic> toJson() {
    center.validate();
    if (!radiusMeters.isFinite || radiusMeters < 0 || radiusMeters > 50000) {
      throw ArgumentError('Circle radius must be between 0 and 50000 meters.');
    }
    return {
      'circle': {'center': center.toJson(), 'radius': radiusMeters},
    };
  }
}

final class RectangleArea extends PlacesArea {
  final PlaceLocation low;
  final PlaceLocation high;
  const RectangleArea({required this.low, required this.high});
  @override
  Map<String, dynamic> toJson() {
    low.validate();
    high.validate();
    if (low.latitude! > high.latitude! ||
        (low.longitude == 180 && high.longitude == -180)) {
      throw ArgumentError('Rectangle must not be empty.');
    }
    return {
      'rectangle': {'low': low.toJson(), 'high': high.toJson()},
    };
  }
}

final class AutocompleteRequest {
  final String input;
  final String? languageCode;
  final String? regionCode;
  final String? sessionToken;
  final int? inputOffset;
  final PlaceLocation? origin;
  final PlacesArea? locationBias;
  final PlacesArea? locationRestriction;
  final List<String> includedPrimaryTypes;
  final List<String> includedRegionCodes;
  final bool includeQueryPredictions;
  const AutocompleteRequest({
    required this.input,
    this.languageCode,
    this.regionCode,
    this.sessionToken,
    this.inputOffset,
    this.origin,
    this.locationBias,
    this.locationRestriction,
    this.includedPrimaryTypes = const [],
    this.includedRegionCodes = const [],
    this.includeQueryPredictions = false,
  });

  Map<String, dynamic> toJson() {
    if (input.trim().isEmpty) throw ArgumentError('Input must not be empty.');
    if (locationBias != null && locationRestriction != null) {
      throw ArgumentError('Use locationBias or locationRestriction, not both.');
    }
    if (locationRestriction case CircleArea(radiusMeters: final radius)
        when radius <= 0) {
      throw ArgumentError('A restriction circle must have a positive radius.');
    }
    if (inputOffset != null &&
        (inputOffset! < 0 || inputOffset! > input.runes.length)) {
      throw ArgumentError(
        'inputOffset must index Unicode characters of input.',
      );
    }
    if (includedPrimaryTypes.length > 5 ||
        includedPrimaryTypes.any((type) => type.isEmpty || type == 'address') ||
        (includedPrimaryTypes.length > 1 &&
            includedPrimaryTypes.any(
              (type) => type == '(cities)' || type == '(regions)',
            ))) {
      throw ArgumentError(
        'Use up to five New primary types or one type collection.',
      );
    }
    if (includedRegionCodes.length > 15 ||
        includedRegionCodes.any(
          (code) => !RegExp(r'^[a-zA-Z]{2}$').hasMatch(code),
        )) {
      throw ArgumentError('Use up to fifteen two-letter region codes.');
    }
    origin?.validate();
    return {
      'input': input,
      if (languageCode != null) 'languageCode': languageCode,
      if (regionCode != null) 'regionCode': regionCode,
      if (sessionToken != null) 'sessionToken': sessionToken,
      if (inputOffset != null) 'inputOffset': inputOffset,
      if (origin != null) 'origin': origin!.toJson(),
      if (locationBias != null) 'locationBias': locationBias!.toJson(),
      if (locationRestriction != null)
        'locationRestriction': locationRestriction!.toJson(),
      if (includedPrimaryTypes.isNotEmpty)
        'includedPrimaryTypes': includedPrimaryTypes,
      if (includedRegionCodes.isNotEmpty)
        'includedRegionCodes': includedRegionCodes,
      'includeQueryPredictions': includeQueryPredictions,
    };
  }
}

enum NearbyRankPreference { popularity, distance }

enum TextRankPreference { relevance, distance }

final class NearbySearchRequest {
  final CircleArea locationRestriction;
  final List<String> includedTypes;
  final List<String> excludedTypes;
  final List<String> includedPrimaryTypes;
  final List<String> excludedPrimaryTypes;
  final String? languageCode;
  final String? regionCode;
  final int? maxResultCount;
  final NearbyRankPreference? rankPreference;
  const NearbySearchRequest({
    required this.locationRestriction,
    this.includedTypes = const [],
    this.excludedTypes = const [],
    this.includedPrimaryTypes = const [],
    this.excludedPrimaryTypes = const [],
    this.languageCode,
    this.regionCode,
    this.maxResultCount,
    this.rankPreference,
  });

  Map<String, dynamic> toJson() {
    final area = locationRestriction.toJson();
    for (final types in [
      includedTypes,
      excludedTypes,
      includedPrimaryTypes,
      excludedPrimaryTypes,
    ]) {
      if (types.length > 50 || types.any((type) => type.trim().isEmpty)) {
        throw ArgumentError('Use at most fifty non-empty types per filter.');
      }
    }
    if (includedTypes.any(excludedTypes.contains) ||
        includedPrimaryTypes.any(excludedPrimaryTypes.contains)) {
      throw ArgumentError('Included and excluded types must not conflict.');
    }
    if (maxResultCount != null &&
        (maxResultCount! < 1 || maxResultCount! > 20)) {
      throw ArgumentError('maxResultCount must be between 1 and 20.');
    }
    return {
      'locationRestriction': area,
      if (includedTypes.isNotEmpty) 'includedTypes': includedTypes,
      if (excludedTypes.isNotEmpty) 'excludedTypes': excludedTypes,
      if (includedPrimaryTypes.isNotEmpty)
        'includedPrimaryTypes': includedPrimaryTypes,
      if (excludedPrimaryTypes.isNotEmpty)
        'excludedPrimaryTypes': excludedPrimaryTypes,
      if (languageCode != null) 'languageCode': languageCode,
      if (regionCode != null) 'regionCode': regionCode,
      if (maxResultCount != null) 'maxResultCount': maxResultCount,
      if (rankPreference != null)
        'rankPreference': rankPreference!.name.toUpperCase(),
    };
  }
}

final class TextSearchRequest {
  final String textQuery;
  final String? languageCode;
  final String? regionCode;
  final String? includedType;
  final bool? strictTypeFiltering;
  final bool? openNow;
  final TextRankPreference? rankPreference;
  final List<String> priceLevels;
  final int? pageSize;
  final String? pageToken;
  final PlacesArea? locationBias;
  final RectangleArea? locationRestriction;
  const TextSearchRequest({
    required this.textQuery,
    this.languageCode,
    this.regionCode,
    this.includedType,
    this.strictTypeFiltering,
    this.openNow,
    this.rankPreference,
    this.priceLevels = const [],
    this.pageSize,
    this.pageToken,
    this.locationBias,
    this.locationRestriction,
  });

  Map<String, dynamic> toJson() {
    if (textQuery.trim().isEmpty) {
      throw ArgumentError('textQuery must not be empty.');
    }
    if (pageSize != null && (pageSize! < 0 || pageSize! > 20)) {
      throw ArgumentError('pageSize must be between 0 and 20.');
    }
    if (locationBias != null && locationRestriction != null) {
      throw ArgumentError('Use locationBias or locationRestriction, not both.');
    }
    final restriction = locationRestriction?.toJson();
    if (locationRestriction case final RectangleArea area) {
      final width = area.high.longitude! >= area.low.longitude!
          ? area.high.longitude! - area.low.longitude!
          : area.high.longitude! + 360 - area.low.longitude!;
      if (width > 180) {
        throw ArgumentError(
          'Text Search restriction must be at most 180 degrees wide.',
        );
      }
    }
    return {
      'textQuery': textQuery,
      if (languageCode != null) 'languageCode': languageCode,
      if (regionCode != null) 'regionCode': regionCode,
      if (includedType != null) 'includedType': includedType,
      if (strictTypeFiltering != null)
        'strictTypeFiltering': strictTypeFiltering,
      if (openNow != null) 'openNow': openNow,
      if (rankPreference != null)
        'rankPreference': rankPreference!.name.toUpperCase(),
      if (priceLevels.isNotEmpty) 'priceLevels': priceLevels,
      if (pageSize != null) 'pageSize': pageSize,
      if (pageToken != null) 'pageToken': pageToken,
      if (locationBias != null) 'locationBias': locationBias!.toJson(),
      'locationRestriction': ?restriction,
    };
  }
}
