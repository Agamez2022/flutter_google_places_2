import 'package:json_annotation/json_annotation.dart';

part 'places_models.g.dart';

/// A suggestion from Autocomplete (New); queries do not identify a place.
sealed class AutocompleteSuggestion {
  const AutocompleteSuggestion();
  factory AutocompleteSuggestion.fromJson(Map<String, dynamic> json) {
    final place = json['placePrediction'];
    final query = json['queryPrediction'];
    if ((place is Map<String, dynamic>) == (query is Map<String, dynamic>)) {
      throw const FormatException('Expected one autocomplete suggestion kind.');
    }
    return place is Map<String, dynamic>
        ? PlacePrediction.fromJson(place)
        : QueryPrediction.fromJson(query as Map<String, dynamic>);
  }
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
/// Missing response components stay null; requests require both via [validate].
final class PlaceLocation {
  final double? latitude;
  final double? longitude;

  const PlaceLocation({this.latitude, this.longitude});

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    final value = _$PlaceLocationFromJson(json);
    value._validatePresent();
    return value;
  }

  void validate() {
    if (latitude == null || longitude == null) {
      throw ArgumentError('Requests require both latitude and longitude.');
    }
    _validatePresent();
  }

  void _validatePresent() {
    if ((latitude != null &&
            (!latitude!.isFinite || latitude! < -90 || latitude! > 90)) ||
        (longitude != null &&
            (!longitude!.isFinite || longitude! < -180 || longitude! > 180))) {
      throw ArgumentError(
        'Coordinates must be finite and within geographic bounds.',
      );
    }
  }

  Map<String, dynamic> toJson() => _$PlaceLocationToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class PlaceViewport {
  final PlaceLocation? low;
  final PlaceLocation? high;

  const PlaceViewport({this.low, this.high});

  factory PlaceViewport.fromJson(Map<String, dynamic> json) =>
      _$PlaceViewportFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceViewportToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class LocalizedText {
  final String? text;
  final String? languageCode;

  const LocalizedText({this.text, this.languageCode});

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);
  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class StringRange {
  final int? startOffset;
  final int? endOffset;

  const StringRange({this.startOffset, this.endOffset});

  factory StringRange.fromJson(Map<String, dynamic> json) =>
      _$StringRangeFromJson(json);
  Map<String, dynamic> toJson() => _$StringRangeToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class FormattableText {
  final String text;
  final List<StringRange>? matches;

  const FormattableText({required this.text, this.matches});

  factory FormattableText.fromJson(Map<String, dynamic> json) =>
      _$FormattableTextFromJson(json);
  Map<String, dynamic> toJson() => _$FormattableTextToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class StructuredFormat {
  final FormattableText? mainText;
  final FormattableText? secondaryText;

  const StructuredFormat({this.mainText, this.secondaryText});

  factory StructuredFormat.fromJson(Map<String, dynamic> json) =>
      _$StructuredFormatFromJson(json);
  Map<String, dynamic> toJson() => _$StructuredFormatToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class PlacePrediction extends AutocompleteSuggestion {
  final String placeId;
  final FormattableText text;
  final String? place;
  final StructuredFormat? structuredFormat;
  final int? distanceMeters;
  final List<String>? types;

  const PlacePrediction({
    required this.placeId,
    required this.text,
    this.place,
    this.structuredFormat,
    this.distanceMeters,
    this.types,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) =>
      _$PlacePredictionFromJson(json);
  Map<String, dynamic> toJson() => _$PlacePredictionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class QueryPrediction extends AutocompleteSuggestion {
  final FormattableText text;
  final StructuredFormat? structuredFormat;

  const QueryPrediction({required this.text, this.structuredFormat});

  factory QueryPrediction.fromJson(Map<String, dynamic> json) =>
      _$QueryPredictionFromJson(json);
  Map<String, dynamic> toJson() => _$QueryPredictionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class AddressComponent {
  final String? longText;
  final String? shortText;
  final List<String>? types;
  final String? languageCode;

  const AddressComponent({
    this.longText,
    this.shortText,
    this.types,
    this.languageCode,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) =>
      _$AddressComponentFromJson(json);
  Map<String, dynamic> toJson() => _$AddressComponentToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class PlaceDate {
  final int? year;
  final int? month;
  final int? day;

  const PlaceDate({this.year, this.month, this.day});

  factory PlaceDate.fromJson(Map<String, dynamic> json) =>
      _$PlaceDateFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceDateToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class OpeningTime {
  final int? day;
  final int? hour;
  final int? minute;
  final PlaceDate? date;
  final bool? truncated;

  const OpeningTime({
    this.day,
    this.hour,
    this.minute,
    this.date,
    this.truncated,
  });

  factory OpeningTime.fromJson(Map<String, dynamic> json) =>
      _$OpeningTimeFromJson(json);
  Map<String, dynamic> toJson() => _$OpeningTimeToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class OpeningHoursPeriod {
  final OpeningTime? open;
  final OpeningTime? close;

  const OpeningHoursPeriod({this.open, this.close});

  factory OpeningHoursPeriod.fromJson(Map<String, dynamic> json) =>
      _$OpeningHoursPeriodFromJson(json);
  Map<String, dynamic> toJson() => _$OpeningHoursPeriodToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class OpeningHours {
  final bool? openNow;
  final List<OpeningHoursPeriod>? periods;
  final List<String>? weekdayDescriptions;
  final String? nextOpenTime;
  final String? nextCloseTime;

  const OpeningHours({
    this.openNow,
    this.periods,
    this.weekdayDescriptions,
    this.nextOpenTime,
    this.nextCloseTime,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) =>
      _$OpeningHoursFromJson(json);
  Map<String, dynamic> toJson() => _$OpeningHoursToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class AuthorAttribution {
  final String? displayName;
  final String? uri;
  final String? photoUri;

  const AuthorAttribution({this.displayName, this.uri, this.photoUri});

  factory AuthorAttribution.fromJson(Map<String, dynamic> json) =>
      _$AuthorAttributionFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorAttributionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class Attribution {
  final String? provider;
  final String? providerUri;

  const Attribution({this.provider, this.providerUri});

  factory Attribution.fromJson(Map<String, dynamic> json) =>
      _$AttributionFromJson(json);
  Map<String, dynamic> toJson() => _$AttributionToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class PlacePhoto {
  final String? name;
  final int? widthPx;
  final int? heightPx;
  final List<AuthorAttribution>? authorAttributions;

  const PlacePhoto({
    this.name,
    this.widthPx,
    this.heightPx,
    this.authorAttributions,
  });

  factory PlacePhoto.fromJson(Map<String, dynamic> json) =>
      _$PlacePhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PlacePhotoToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class PlaceReview {
  final String? name;
  final double? rating;
  final LocalizedText? text;
  final LocalizedText? originalText;
  final AuthorAttribution? authorAttribution;
  final String? publishTime;
  final String? relativePublishTimeDescription;

  const PlaceReview({
    this.name,
    this.rating,
    this.text,
    this.originalText,
    this.authorAttribution,
    this.publishTime,
    this.relativePublishTimeDescription,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) =>
      _$PlaceReviewFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceReviewToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class Place {
  final String? id;
  final String? name;
  final LocalizedText? displayName;
  final PlaceLocation? location;
  final PlaceViewport? viewport;
  final String? formattedAddress;
  final String? shortFormattedAddress;
  final String? adrFormatAddress;
  final List<AddressComponent>? addressComponents;
  final String? nationalPhoneNumber;
  final String? internationalPhoneNumber;
  final OpeningHours? regularOpeningHours;
  final List<PlacePhoto>? photos;
  final String? priceLevel;
  final double? rating;
  final List<String>? types;
  final String? googleMapsUri;
  final String? websiteUri;
  final int? utcOffsetMinutes;
  final List<PlaceReview>? reviews;
  final String? businessStatus;
  final String? iconMaskBaseUri;
  final String? iconBackgroundColor;
  final List<Attribution>? attributions;

  const Place({
    this.id,
    this.name,
    this.displayName,
    this.location,
    this.viewport,
    this.formattedAddress,
    this.shortFormattedAddress,
    this.adrFormatAddress,
    this.addressComponents,
    this.nationalPhoneNumber,
    this.internationalPhoneNumber,
    this.regularOpeningHours,
    this.photos,
    this.priceLevel,
    this.rating,
    this.types,
    this.googleMapsUri,
    this.websiteUri,
    this.utcOffsetMinutes,
    this.reviews,
    this.businessStatus,
    this.iconMaskBaseUri,
    this.iconBackgroundColor,
    this.attributions,
  });

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class NearbySearchResponse {
  final List<Place> places;

  const NearbySearchResponse({this.places = const []});

  factory NearbySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$NearbySearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NearbySearchResponseToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class TextSearchResponse {
  final List<Place> places;
  final String? nextPageToken;

  const TextSearchResponse({this.places = const [], this.nextPageToken});

  factory TextSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$TextSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TextSearchResponseToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
final class PhotoMedia {
  final String name;
  final Uri photoUri;

  const PhotoMedia({required this.name, required this.photoUri});

  factory PhotoMedia.fromJson(Map<String, dynamic> json) =>
      _$PhotoMediaFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoMediaToJson(this);
}

final class AutocompleteResponse {
  final List<AutocompleteSuggestion> suggestions;
  const AutocompleteResponse({this.suggestions = const []});

  factory AutocompleteResponse.fromJson(Map<String, dynamic> json) =>
      AutocompleteResponse(
        suggestions: List.unmodifiable(
          (json['suggestions'] as List<dynamic>? ?? const []).map(
            (item) =>
                AutocompleteSuggestion.fromJson(item as Map<String, dynamic>),
          ),
        ),
      );

  List<PlacePrediction> get placePredictions =>
      suggestions.whereType<PlacePrediction>().toList(growable: false);
}

final class PlaceSelection {
  final PlacePrediction prediction;
  final String sessionToken;
  const PlaceSelection({required this.prediction, required this.sessionToken});
}

enum PlacesErrorKind { api, transport, invalidResponse, identity, validation }

final class PlacesApiException implements Exception {
  final PlacesErrorKind kind;
  final int? httpStatus;
  final String? code;
  final String message;
  final Object? details;
  const PlacesApiException({
    required this.kind,
    this.httpStatus,
    this.code,
    required this.message,
    this.details,
  });
  @override
  String toString() =>
      'PlacesApiException($kind, $httpStatus, $code): $message';
}
