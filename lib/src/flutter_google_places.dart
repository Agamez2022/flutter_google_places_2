import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:listenable_stream/listenable_stream.dart';
import 'package:rxdart_ext/state_stream.dart';

import 'places_client.dart';
import 'places_models.dart';
import 'places_requests.dart';

/// Places API (New) autocomplete with the package's original presentation.
class PlacesAutocompleteWidget extends StatefulWidget {
  final PlacesClient client;
  final Mode mode;
  final String? hint;
  final String? startText;
  final BorderRadius? overlayBorderRadius;
  final PlacesArea? locationBias;
  final PlacesArea? locationRestriction;
  final PlaceLocation? origin;
  final int? inputOffset;
  final String? languageCode;
  final String? sessionToken;
  final List<String> includedPrimaryTypes;
  final List<String> includedRegionCodes;
  final String? regionCode;
  final Widget? logo;
  final ValueChanged<PlacesApiException>? onError;
  final Duration? debounce;
  final EdgeInsets? insetPadding;
  final Widget? backArrowIcon;
  final InputDecoration? textDecoration;
  final TextStyle? textStyle;
  final Color? cursorColor;
  final TextStyle? resultTextStyle;
  const PlacesAutocompleteWidget({
    super.key,
    required this.client,
    this.mode = Mode.fullscreen,
    this.hint = 'Search',
    this.startText,
    this.overlayBorderRadius,
    this.locationBias,
    this.locationRestriction,
    this.origin,
    this.inputOffset,
    this.languageCode,
    this.sessionToken,
    this.includedPrimaryTypes = const [],
    this.includedRegionCodes = const [],
    this.regionCode,
    this.logo,
    this.onError,
    this.debounce,
    this.insetPadding,
    this.backArrowIcon,
    this.textDecoration,
    this.textStyle,
    this.cursorColor,
    this.resultTextStyle,
  });
  @override
  // The original presentation uses a different State for each mode.
  // ignore: no_logic_in_create_state
  State<PlacesAutocompleteWidget> createState() => mode == Mode.fullscreen
      ? _PlacesAutocompleteScaffoldState()
      : _PlacesAutocompleteOverlayState();

  static PlacesAutocompleteState of(BuildContext context) =>
      context.findAncestorStateOfType<PlacesAutocompleteState>()!;
}

class _PlacesAutocompleteScaffoldState extends PlacesAutocompleteState {
  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: AppBarPlacesAutoCompleteTextField(
        textDecoration: widget.textDecoration,
        textStyle: widget.textStyle,
        cursorColor: widget.cursorColor,
      ),
    );
    final body = PlacesAutocompleteResult(
      onTap: _selectPrediction,
      logo: widget.logo,
      resultTextStyle: widget.resultTextStyle,
    );
    return _observeRoutePop(Scaffold(appBar: appBar, body: body));
  }
}

class _PlacesAutocompleteOverlayState extends PlacesAutocompleteState {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final headerTopLeftBorderRadius =
        widget.overlayBorderRadius?.topLeft ?? const Radius.circular(2);

    final headerTopRightBorderRadius =
        widget.overlayBorderRadius?.topRight ?? const Radius.circular(2);

    final header = Column(
      children: <Widget>[
        Material(
          color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: headerTopLeftBorderRadius,
            topRight: headerTopRightBorderRadius,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconButton(
                padding: const EdgeInsets.all(8.0).copyWith(top: 12.0),
                color: theme.brightness == Brightness.light
                    ? Colors.black45
                    : null,
                icon: _iconBack,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0, left: 10.0),
                  child: _textField(context),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );

    final bodyBottomLeftBorderRadius =
        widget.overlayBorderRadius?.bottomLeft ?? const Radius.circular(2);

    final bodyBottomRightBorderRadius =
        widget.overlayBorderRadius?.bottomRight ?? const Radius.circular(2);

    final container = Container(
      margin: EdgeInsets.fromLTRB(
        16.0,
        30.0,
        16.0,
        30.0 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Stack(
        children: <Widget>[
          header,
          Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: StreamBuilder<_SearchState>(
              stream: _state$,
              initialData: _state$.value,
              builder: (context, snapshot) {
                final state = snapshot.requireData;
                final response = state.response;

                if (state.isSearching) {
                  return Stack(
                    alignment: FractionalOffset.bottomCenter,
                    children: <Widget>[_Loader()],
                  );
                } else if (state.text.isEmpty ||
                    response == null ||
                    response.placePredictions.isEmpty) {
                  return Material(
                    color:
                        theme.dialogTheme.backgroundColor ??
                        theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      bottomLeft: bodyBottomLeftBorderRadius,
                      bottomRight: bodyBottomRightBorderRadius,
                    ),
                    child: widget.logo ?? const PoweredByGoogleImage(),
                  );
                } else {
                  return Material(
                    borderRadius: BorderRadius.only(
                      bottomLeft: bodyBottomLeftBorderRadius,
                      bottomRight: bodyBottomRightBorderRadius,
                    ),
                    color:
                        theme.dialogTheme.backgroundColor ??
                        theme.colorScheme.surface,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: ListBody(
                              children: response.placePredictions
                                  .map(
                                    (p) => PredictionTile(
                                      prediction: p,
                                      onTap: _selectPrediction,
                                      resultTextStyle: widget.resultTextStyle,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                          ),
                        ),
                        widget.logo ?? const PoweredByGoogleImage(),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return _observeRoutePop(
        Padding(
          padding: widget.insetPadding ?? const EdgeInsets.only(top: 8.0),
          child: container,
        ),
      );
    }

    return _observeRoutePop(
      Padding(
        padding: widget.insetPadding ?? EdgeInsets.zero,
        child: container,
      ),
    );
  }

  Widget get _iconBack {
    if (widget.backArrowIcon != null) return widget.backArrowIcon!;
    return Theme.of(context).platform == TargetPlatform.iOS
        ? const Icon(Icons.arrow_back_ios)
        : const Icon(Icons.arrow_back);
  }

  Widget _textField(BuildContext context) => TextField(
    controller: _queryTextController,
    autofocus: true,
    style:
        widget.textStyle ??
        TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black87
              : null,
          fontSize: 16.0,
        ),
    decoration: InputDecoration(
      hintText: widget.hint,
      hintStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black45
            : null,
        fontSize: 16.0,
      ),
      border: InputBorder.none,
    ),
  );
}

class _Loader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 2.0),
      child: LinearProgressIndicator(
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

class PlacesAutocompleteResult extends StatelessWidget {
  final ValueChanged<PlacePrediction> onTap;
  final Widget? logo;
  final TextStyle? resultTextStyle;

  const PlacesAutocompleteResult({
    super.key,
    required this.onTap,
    required this.logo,
    this.resultTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final state = PlacesAutocompleteWidget.of(context);

    return StreamBuilder<_SearchState>(
      stream: state._state$,
      initialData: state._state$.value,
      builder: (context, snapshot) {
        final state = snapshot.requireData;
        final response = state.response;

        if (state.text.isEmpty ||
            response == null ||
            response.placePredictions.isEmpty) {
          return Stack(
            children: [
              if (state.isSearching) _Loader(),
              logo ?? const PoweredByGoogleImage(),
            ],
          );
        }
        return Column(
          children: [
            Expanded(
              child: PredictionsListView(
                predictions: response.placePredictions,
                onTap: onTap,
                resultTextStyle: resultTextStyle,
              ),
            ),
            SafeArea(top: false, child: logo ?? const PoweredByGoogleImage()),
          ],
        );
      },
    );
  }
}

class AppBarPlacesAutoCompleteTextField extends StatefulWidget {
  final InputDecoration? textDecoration;
  final TextStyle? textStyle;
  final Color? cursorColor;

  const AppBarPlacesAutoCompleteTextField({
    super.key,
    required this.textDecoration,
    required this.textStyle,
    required this.cursorColor,
  });

  @override
  State<AppBarPlacesAutoCompleteTextField> createState() =>
      _AppBarPlacesAutoCompleteTextFieldState();
}

class _AppBarPlacesAutoCompleteTextFieldState
    extends State<AppBarPlacesAutoCompleteTextField> {
  @override
  Widget build(BuildContext context) {
    final state = PlacesAutocompleteWidget.of(context);

    return Container(
      alignment: Alignment.topLeft,
      margin: const EdgeInsets.only(top: 2.0),
      child: TextField(
        controller: state._queryTextController,
        autofocus: true,
        style: widget.textStyle ?? _defaultStyle(),
        decoration:
            widget.textDecoration ?? _defaultDecoration(state.widget.hint),
        cursorColor: widget.cursorColor,
      ),
    );
  }

  InputDecoration _defaultDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white30
          : Colors.black38,
      hintStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black38
            : Colors.white30,
        fontSize: 16.0,
      ),
      border: InputBorder.none,
    );
  }

  TextStyle _defaultStyle() {
    return TextStyle(
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.9)
          : Colors.white.withValues(alpha: 0.9),
      fontSize: 16.0,
    );
  }
}

class PoweredByGoogleImage extends StatelessWidget {
  final _poweredByGoogleWhite =
      'packages/flutter_google_places_2/assets/google_white.png';
  final _poweredByGoogleBlack =
      'packages/flutter_google_places_2/assets/google_black.png';

  const PoweredByGoogleImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset(
            Theme.of(context).brightness == Brightness.light
                ? _poweredByGoogleWhite
                : _poweredByGoogleBlack,
            scale: 2.5,
          ),
        ),
      ],
    );
  }
}

class PredictionsListView extends StatelessWidget {
  final List<PlacePrediction> predictions;
  final ValueChanged<PlacePrediction> onTap;
  final TextStyle? resultTextStyle;

  const PredictionsListView({
    super.key,
    required this.predictions,
    required this.onTap,
    this.resultTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: predictions
          .map(
            (PlacePrediction p) => PredictionTile(
              prediction: p,
              onTap: onTap,
              resultTextStyle: resultTextStyle,
            ),
          )
          .toList(growable: false),
    );
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePrediction prediction;
  final ValueChanged<PlacePrediction> onTap;
  final TextStyle? resultTextStyle;

  const PredictionTile({
    super.key,
    required this.prediction,
    required this.onTap,
    this.resultTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Text(prediction.text.text, style: resultTextStyle),
      onTap: () => onTap(prediction),
    );
  }
}

enum Mode { overlay, fullscreen }

abstract class PlacesAutocompleteState extends State<PlacesAutocompleteWidget> {
  late final TextEditingController _queryTextController =
      TextEditingController(text: widget.startText)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.startText?.length ?? 0,
        );
  late final String _sessionToken =
      widget.sessionToken ?? _createSessionToken();
  int _generation = 0;
  int _resultGeneration = -1;
  TextEditingValue? _resultQuery;
  bool _finished = false;
  late final StateConnectableStream<_SearchState> _state$ = _queryTextController
      .toValueStream(replayValue: true)
      .distinct((a, b) => a.text == b.text && a.selection == b.selection)
      .doOnData((_) => _generation++)
      .flatMap((value) {
        final generation = _generation;
        if (value.text.isEmpty) {
          return Stream.value(const _SearchState(false, null, ''));
        }
        return TimerStream(
              value,
              widget.debounce ?? const Duration(milliseconds: 300),
            )
            .where((_) => !_finished && generation == _generation)
            .flatMap(_doSearch)
            .startWith(_SearchState(false, null, value.text));
      })
      .publishState(const _SearchState(false, null, ''));

  StreamSubscription<_SearchState>? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = _state$.connect();
  }

  Stream<_SearchState> _doSearch(TextEditingValue value) {
    final generation = _generation;
    if (_finished || value.text.isEmpty) {
      return Stream.value(const _SearchState(false, null, ''));
    }
    // Generations discard stale results without serializing pending HTTP requests.
    final result = () async {
      try {
        final offset =
            widget.inputOffset ??
            (value.selection.isValid
                ? value.text
                      .substring(0, value.selection.extentOffset)
                      .runes
                      .length
                : null);
        final response = await widget.client.autocomplete(
          AutocompleteRequest(
            input: value.text,
            inputOffset: offset,
            locationBias: widget.locationBias,
            locationRestriction: widget.locationRestriction,
            origin: widget.origin,
            languageCode: widget.languageCode,
            regionCode: widget.regionCode,
            sessionToken: _sessionToken,
            includedPrimaryTypes: widget.includedPrimaryTypes,
            includedRegionCodes: widget.includedRegionCodes,
          ),
        );
        if (mounted && !_finished && generation == _generation) {
          _resultGeneration = generation;
          _resultQuery = value;
        }
        return _SearchState(
          false,
          AutocompleteResponse(suggestions: _sorted(response.placePredictions)),
          value.text,
        );
      } catch (error) {
        final failure = error is PlacesApiException
            ? error
            : const PlacesApiException(
                kind: PlacesErrorKind.validation,
                code: 'INVALID_ARGUMENT',
                message: 'Invalid autocomplete options.',
              );
        if (mounted && !_finished && generation == _generation) {
          try {
            onResponseError(failure);
          } catch (callbackError, stack) {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: callbackError,
                stack: stack,
                library: 'flutter_google_places_2',
              ),
            );
          }
        }
        return _SearchState(false, null, value.text);
      }
    }();
    return Stream.fromFuture(result)
        .where((_) => mounted && !_finished && generation == _generation)
        .startWith(_SearchState(true, null, value.text));
  }

  void _selectPrediction(PlacePrediction prediction) {
    if (_finished ||
        _resultGeneration != _generation ||
        _queryTextController.text != _resultQuery?.text ||
        _queryTextController.selection != _resultQuery?.selection) {
      return;
    }
    _finish();
    Navigator.pop(
      context,
      PlaceSelection(prediction: prediction, sessionToken: _sessionToken),
    );
  }

  @mustCallSuper
  void onResponseError(PlacesApiException error) {
    if (mounted && !_finished) widget.onError?.call(error);
  }

  Widget _observeRoutePop(Widget child) => PopScope<PlaceSelection>(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) _finish();
    },
    child: child,
  );

  void _finish() {
    if (_finished) return;
    _finished = true;
    _generation++;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  @override
  void dispose() {
    _finish();
    _queryTextController.dispose();
    super.dispose();
  }

  static List<PlacePrediction> _sorted(List<PlacePrediction> predictions) {
    if (predictions.isEmpty ||
        predictions.every((e) => e.distanceMeters == null)) {
      return predictions;
    }
    return predictions.sortedBy<num>((e) => e.distanceMeters ?? 0);
  }

  static String _createSessionToken() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

class _SearchState {
  final String text;
  final bool isSearching;
  final AutocompleteResponse? response;
  const _SearchState(this.isSearching, this.response, this.text);
}

abstract class PlacesAutocomplete {
  PlacesAutocomplete._();

  /// Opens autocomplete without fetching Details; returns the session with the selection.
  static Future<PlaceSelection?> show({
    required BuildContext context,
    required PlacesClient client,
    Mode mode = Mode.fullscreen,
    String? hint = 'Search',
    String? startText,
    BorderRadius? overlayBorderRadius,
    PlacesArea? locationBias,
    PlacesArea? locationRestriction,
    PlaceLocation? origin,
    int? inputOffset,
    String? languageCode,
    String? sessionToken,
    List<String> includedPrimaryTypes = const [],
    List<String> includedRegionCodes = const [],
    String? regionCode,
    Widget? logo,
    ValueChanged<PlacesApiException>? onError,
    Duration? debounce,
    EdgeInsets? insetPadding,
    Widget? backArrowIcon,
    InputDecoration? textDecoration,
    TextStyle? textStyle,
    Color? cursorColor,
    TextStyle? resultTextStyle,
  }) {
    PlacesAutocompleteWidget builder(BuildContext context) =>
        PlacesAutocompleteWidget(
          client: client,
          mode: mode,
          hint: hint,
          startText: startText,
          overlayBorderRadius: overlayBorderRadius,
          locationBias: locationBias,
          locationRestriction: locationRestriction,
          origin: origin,
          inputOffset: inputOffset,
          languageCode: languageCode,
          sessionToken: sessionToken,
          includedPrimaryTypes: includedPrimaryTypes,
          includedRegionCodes: includedRegionCodes,
          regionCode: regionCode,
          logo: logo,
          onError: onError,
          debounce: debounce,
          insetPadding: insetPadding,
          backArrowIcon: backArrowIcon,
          textDecoration: textDecoration,
          textStyle: textStyle,
          cursorColor: cursorColor,
          resultTextStyle: resultTextStyle,
        );
    return switch (mode) {
      Mode.overlay => showDialog<PlaceSelection>(
        context: context,
        builder: builder,
      ),
      Mode.fullscreen => Navigator.push<PlaceSelection>(
        context,
        MaterialPageRoute(builder: builder),
      ),
    };
  }
}
