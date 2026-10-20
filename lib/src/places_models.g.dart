// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceLocation _$PlaceLocationFromJson(Map<String, dynamic> json) =>
    PlaceLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PlaceLocationToJson(PlaceLocation instance) =>
    <String, dynamic>{
      'latitude': ?instance.latitude,
      'longitude': ?instance.longitude,
    };

PlaceViewport _$PlaceViewportFromJson(Map<String, dynamic> json) =>
    PlaceViewport(
      low: json['low'] == null
          ? null
          : PlaceLocation.fromJson(json['low'] as Map<String, dynamic>),
      high: json['high'] == null
          ? null
          : PlaceLocation.fromJson(json['high'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlaceViewportToJson(PlaceViewport instance) =>
    <String, dynamic>{
      'low': ?instance.low?.toJson(),
      'high': ?instance.high?.toJson(),
    };

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) =>
    LocalizedText(
      text: json['text'] as String?,
      languageCode: json['languageCode'] as String?,
    );

Map<String, dynamic> _$LocalizedTextToJson(LocalizedText instance) =>
    <String, dynamic>{
      'text': ?instance.text,
      'languageCode': ?instance.languageCode,
    };

StringRange _$StringRangeFromJson(Map<String, dynamic> json) => StringRange(
  startOffset: (json['startOffset'] as num?)?.toInt(),
  endOffset: (json['endOffset'] as num?)?.toInt(),
);

Map<String, dynamic> _$StringRangeToJson(StringRange instance) =>
    <String, dynamic>{
      'startOffset': ?instance.startOffset,
      'endOffset': ?instance.endOffset,
    };

FormattableText _$FormattableTextFromJson(Map<String, dynamic> json) =>
    FormattableText(
      text: json['text'] as String,
      matches: (json['matches'] as List<dynamic>?)
          ?.map((e) => StringRange.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FormattableTextToJson(FormattableText instance) =>
    <String, dynamic>{
      'text': instance.text,
      'matches': ?instance.matches?.map((e) => e.toJson()).toList(),
    };

StructuredFormat _$StructuredFormatFromJson(Map<String, dynamic> json) =>
    StructuredFormat(
      mainText: json['mainText'] == null
          ? null
          : FormattableText.fromJson(json['mainText'] as Map<String, dynamic>),
      secondaryText: json['secondaryText'] == null
          ? null
          : FormattableText.fromJson(
              json['secondaryText'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$StructuredFormatToJson(StructuredFormat instance) =>
    <String, dynamic>{
      'mainText': ?instance.mainText?.toJson(),
      'secondaryText': ?instance.secondaryText?.toJson(),
    };

PlacePrediction _$PlacePredictionFromJson(Map<String, dynamic> json) =>
    PlacePrediction(
      placeId: json['placeId'] as String,
      text: FormattableText.fromJson(json['text'] as Map<String, dynamic>),
      place: json['place'] as String?,
      structuredFormat: json['structuredFormat'] == null
          ? null
          : StructuredFormat.fromJson(
              json['structuredFormat'] as Map<String, dynamic>,
            ),
      distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PlacePredictionToJson(PlacePrediction instance) =>
    <String, dynamic>{
      'placeId': instance.placeId,
      'text': instance.text.toJson(),
      'place': ?instance.place,
      'structuredFormat': ?instance.structuredFormat?.toJson(),
      'distanceMeters': ?instance.distanceMeters,
      'types': ?instance.types,
    };

QueryPrediction _$QueryPredictionFromJson(Map<String, dynamic> json) =>
    QueryPrediction(
      text: FormattableText.fromJson(json['text'] as Map<String, dynamic>),
      structuredFormat: json['structuredFormat'] == null
          ? null
          : StructuredFormat.fromJson(
              json['structuredFormat'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$QueryPredictionToJson(QueryPrediction instance) =>
    <String, dynamic>{
      'text': instance.text.toJson(),
      'structuredFormat': ?instance.structuredFormat?.toJson(),
    };

AddressComponent _$AddressComponentFromJson(Map<String, dynamic> json) =>
    AddressComponent(
      longText: json['longText'] as String?,
      shortText: json['shortText'] as String?,
      types: (json['types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      languageCode: json['languageCode'] as String?,
    );

Map<String, dynamic> _$AddressComponentToJson(AddressComponent instance) =>
    <String, dynamic>{
      'longText': ?instance.longText,
      'shortText': ?instance.shortText,
      'types': ?instance.types,
      'languageCode': ?instance.languageCode,
    };

PlaceDate _$PlaceDateFromJson(Map<String, dynamic> json) => PlaceDate(
  year: (json['year'] as num?)?.toInt(),
  month: (json['month'] as num?)?.toInt(),
  day: (json['day'] as num?)?.toInt(),
);

Map<String, dynamic> _$PlaceDateToJson(PlaceDate instance) => <String, dynamic>{
  'year': ?instance.year,
  'month': ?instance.month,
  'day': ?instance.day,
};

OpeningTime _$OpeningTimeFromJson(Map<String, dynamic> json) => OpeningTime(
  day: (json['day'] as num?)?.toInt(),
  hour: (json['hour'] as num?)?.toInt(),
  minute: (json['minute'] as num?)?.toInt(),
  date: json['date'] == null
      ? null
      : PlaceDate.fromJson(json['date'] as Map<String, dynamic>),
  truncated: json['truncated'] as bool?,
);

Map<String, dynamic> _$OpeningTimeToJson(OpeningTime instance) =>
    <String, dynamic>{
      'day': ?instance.day,
      'hour': ?instance.hour,
      'minute': ?instance.minute,
      'date': ?instance.date?.toJson(),
      'truncated': ?instance.truncated,
    };

OpeningHoursPeriod _$OpeningHoursPeriodFromJson(Map<String, dynamic> json) =>
    OpeningHoursPeriod(
      open: json['open'] == null
          ? null
          : OpeningTime.fromJson(json['open'] as Map<String, dynamic>),
      close: json['close'] == null
          ? null
          : OpeningTime.fromJson(json['close'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OpeningHoursPeriodToJson(OpeningHoursPeriod instance) =>
    <String, dynamic>{
      'open': ?instance.open?.toJson(),
      'close': ?instance.close?.toJson(),
    };

OpeningHours _$OpeningHoursFromJson(Map<String, dynamic> json) => OpeningHours(
  openNow: json['openNow'] as bool?,
  periods: (json['periods'] as List<dynamic>?)
      ?.map((e) => OpeningHoursPeriod.fromJson(e as Map<String, dynamic>))
      .toList(),
  weekdayDescriptions: (json['weekdayDescriptions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  nextOpenTime: json['nextOpenTime'] as String?,
  nextCloseTime: json['nextCloseTime'] as String?,
);

Map<String, dynamic> _$OpeningHoursToJson(OpeningHours instance) =>
    <String, dynamic>{
      'openNow': ?instance.openNow,
      'periods': ?instance.periods?.map((e) => e.toJson()).toList(),
      'weekdayDescriptions': ?instance.weekdayDescriptions,
      'nextOpenTime': ?instance.nextOpenTime,
      'nextCloseTime': ?instance.nextCloseTime,
    };

AuthorAttribution _$AuthorAttributionFromJson(Map<String, dynamic> json) =>
    AuthorAttribution(
      displayName: json['displayName'] as String?,
      uri: json['uri'] as String?,
      photoUri: json['photoUri'] as String?,
    );

Map<String, dynamic> _$AuthorAttributionToJson(AuthorAttribution instance) =>
    <String, dynamic>{
      'displayName': ?instance.displayName,
      'uri': ?instance.uri,
      'photoUri': ?instance.photoUri,
    };

Attribution _$AttributionFromJson(Map<String, dynamic> json) => Attribution(
  provider: json['provider'] as String?,
  providerUri: json['providerUri'] as String?,
);

Map<String, dynamic> _$AttributionToJson(Attribution instance) =>
    <String, dynamic>{
      'provider': ?instance.provider,
      'providerUri': ?instance.providerUri,
    };

PlacePhoto _$PlacePhotoFromJson(Map<String, dynamic> json) => PlacePhoto(
  name: json['name'] as String?,
  widthPx: (json['widthPx'] as num?)?.toInt(),
  heightPx: (json['heightPx'] as num?)?.toInt(),
  authorAttributions: (json['authorAttributions'] as List<dynamic>?)
      ?.map((e) => AuthorAttribution.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlacePhotoToJson(PlacePhoto instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'widthPx': ?instance.widthPx,
      'heightPx': ?instance.heightPx,
      'authorAttributions': ?instance.authorAttributions
          ?.map((e) => e.toJson())
          .toList(),
    };

PlaceReview _$PlaceReviewFromJson(Map<String, dynamic> json) => PlaceReview(
  name: json['name'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  text: json['text'] == null
      ? null
      : LocalizedText.fromJson(json['text'] as Map<String, dynamic>),
  originalText: json['originalText'] == null
      ? null
      : LocalizedText.fromJson(json['originalText'] as Map<String, dynamic>),
  authorAttribution: json['authorAttribution'] == null
      ? null
      : AuthorAttribution.fromJson(
          json['authorAttribution'] as Map<String, dynamic>,
        ),
  publishTime: json['publishTime'] as String?,
  relativePublishTimeDescription:
      json['relativePublishTimeDescription'] as String?,
);

Map<String, dynamic> _$PlaceReviewToJson(
  PlaceReview instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'rating': ?instance.rating,
  'text': ?instance.text?.toJson(),
  'originalText': ?instance.originalText?.toJson(),
  'authorAttribution': ?instance.authorAttribution?.toJson(),
  'publishTime': ?instance.publishTime,
  'relativePublishTimeDescription': ?instance.relativePublishTimeDescription,
};

Place _$PlaceFromJson(Map<String, dynamic> json) => Place(
  id: json['id'] as String?,
  name: json['name'] as String?,
  displayName: json['displayName'] == null
      ? null
      : LocalizedText.fromJson(json['displayName'] as Map<String, dynamic>),
  location: json['location'] == null
      ? null
      : PlaceLocation.fromJson(json['location'] as Map<String, dynamic>),
  viewport: json['viewport'] == null
      ? null
      : PlaceViewport.fromJson(json['viewport'] as Map<String, dynamic>),
  formattedAddress: json['formattedAddress'] as String?,
  shortFormattedAddress: json['shortFormattedAddress'] as String?,
  adrFormatAddress: json['adrFormatAddress'] as String?,
  addressComponents: (json['addressComponents'] as List<dynamic>?)
      ?.map((e) => AddressComponent.fromJson(e as Map<String, dynamic>))
      .toList(),
  nationalPhoneNumber: json['nationalPhoneNumber'] as String?,
  internationalPhoneNumber: json['internationalPhoneNumber'] as String?,
  regularOpeningHours: json['regularOpeningHours'] == null
      ? null
      : OpeningHours.fromJson(
          json['regularOpeningHours'] as Map<String, dynamic>,
        ),
  photos: (json['photos'] as List<dynamic>?)
      ?.map((e) => PlacePhoto.fromJson(e as Map<String, dynamic>))
      .toList(),
  priceLevel: json['priceLevel'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  types: (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
  googleMapsUri: json['googleMapsUri'] as String?,
  websiteUri: json['websiteUri'] as String?,
  utcOffsetMinutes: (json['utcOffsetMinutes'] as num?)?.toInt(),
  reviews: (json['reviews'] as List<dynamic>?)
      ?.map((e) => PlaceReview.fromJson(e as Map<String, dynamic>))
      .toList(),
  businessStatus: json['businessStatus'] as String?,
  iconMaskBaseUri: json['iconMaskBaseUri'] as String?,
  iconBackgroundColor: json['iconBackgroundColor'] as String?,
  attributions: (json['attributions'] as List<dynamic>?)
      ?.map((e) => Attribution.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlaceToJson(Place instance) => <String, dynamic>{
  'id': ?instance.id,
  'name': ?instance.name,
  'displayName': ?instance.displayName?.toJson(),
  'location': ?instance.location?.toJson(),
  'viewport': ?instance.viewport?.toJson(),
  'formattedAddress': ?instance.formattedAddress,
  'shortFormattedAddress': ?instance.shortFormattedAddress,
  'adrFormatAddress': ?instance.adrFormatAddress,
  'addressComponents': ?instance.addressComponents
      ?.map((e) => e.toJson())
      .toList(),
  'nationalPhoneNumber': ?instance.nationalPhoneNumber,
  'internationalPhoneNumber': ?instance.internationalPhoneNumber,
  'regularOpeningHours': ?instance.regularOpeningHours?.toJson(),
  'photos': ?instance.photos?.map((e) => e.toJson()).toList(),
  'priceLevel': ?instance.priceLevel,
  'rating': ?instance.rating,
  'types': ?instance.types,
  'googleMapsUri': ?instance.googleMapsUri,
  'websiteUri': ?instance.websiteUri,
  'utcOffsetMinutes': ?instance.utcOffsetMinutes,
  'reviews': ?instance.reviews?.map((e) => e.toJson()).toList(),
  'businessStatus': ?instance.businessStatus,
  'iconMaskBaseUri': ?instance.iconMaskBaseUri,
  'iconBackgroundColor': ?instance.iconBackgroundColor,
  'attributions': ?instance.attributions?.map((e) => e.toJson()).toList(),
};

NearbySearchResponse _$NearbySearchResponseFromJson(
  Map<String, dynamic> json,
) => NearbySearchResponse(
  places:
      (json['places'] as List<dynamic>?)
          ?.map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$NearbySearchResponseToJson(
  NearbySearchResponse instance,
) => <String, dynamic>{
  'places': instance.places.map((e) => e.toJson()).toList(),
};

TextSearchResponse _$TextSearchResponseFromJson(Map<String, dynamic> json) =>
    TextSearchResponse(
      places:
          (json['places'] as List<dynamic>?)
              ?.map((e) => Place.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nextPageToken: json['nextPageToken'] as String?,
    );

Map<String, dynamic> _$TextSearchResponseToJson(TextSearchResponse instance) =>
    <String, dynamic>{
      'places': instance.places.map((e) => e.toJson()).toList(),
      'nextPageToken': ?instance.nextPageToken,
    };

PhotoMedia _$PhotoMediaFromJson(Map<String, dynamic> json) => PhotoMedia(
  name: json['name'] as String,
  photoUri: Uri.parse(json['photoUri'] as String),
);

Map<String, dynamic> _$PhotoMediaToJson(PhotoMedia instance) =>
    <String, dynamic>{
      'name': instance.name,
      'photoUri': instance.photoUri.toString(),
    };
