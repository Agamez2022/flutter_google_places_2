import 'package:flutter/material.dart';

import 'places_client.dart';
import 'places_models.dart';
import 'places_requests.dart';
import 'flutter_google_places.dart';
import 'places_autocomplete_field.dart';

/// A FormField backed by the unchanged field presentation and Places New.
class PlacesAutocompleteFormField extends FormField<String> {
  final TextEditingController? controller;
  final PlacesClient client;
  PlacesAutocompleteFormField({
    super.key,
    required this.client,
    this.controller,
    String? initialValue,
    Icon? leading,
    String? hint = 'Search',
    Icon? trailing,
    VoidCallback? trailingOnTap,
    Mode mode = Mode.fullscreen,
    int? inputOffset,
    PlacesArea? locationBias,
    PlacesArea? locationRestriction,
    PlaceLocation? origin,
    String? languageCode,
    String? regionCode,
    String? sessionToken,
    List<String> includedPrimaryTypes = const [],
    List<String> includedRegionCodes = const [],
    ValueChanged<PlaceSelection>? onSelected,
    ValueChanged<PlacesApiException>? onError,
    InputDecoration? inputDecoration = const InputDecoration(),
    BorderRadius? overlayBorderRadius,
    TextStyle? textStyle,
    TextStyle? textStyleFormField,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
    super.onSaved,
    super.validator,
  }) : assert(initialValue == null || controller == null),
       super(
         initialValue: controller?.text ?? initialValue ?? '',
         builder: (field) {
           final state = field as _TextFormFieldState;
           final decoration = inputDecoration?.applyDefaults(
             Theme.of(state.context).inputDecorationTheme,
           );
           return PlacesAutocompleteField(
             client: client,
             controller: state._effectiveController,
             inputDecoration: decoration?.copyWith(errorText: state.errorText),
             onChanged: state.didChange,
             leading: leading,
             hint: hint,
             trailing: trailing,
             trailingOnTap: trailingOnTap,
             mode: mode,
             inputOffset: inputOffset,
             locationBias: locationBias,
             locationRestriction: locationRestriction,
             origin: origin,
             languageCode: languageCode,
             regionCode: regionCode,
             sessionToken: sessionToken,
             includedPrimaryTypes: includedPrimaryTypes,
             includedRegionCodes: includedRegionCodes,
             onSelected: onSelected,
             onError: onError,
             overlayBorderRadius: overlayBorderRadius,
             textStyle: textStyle,
             textStyleFormField: textStyleFormField,
           );
         },
       );
  @override
  FormFieldState<String> createState() => _TextFormFieldState();
}

class _TextFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;

  TextEditingController get _effectiveController =>
      widget.controller ?? _controller!;

  @override
  PlacesAutocompleteFormField get widget =>
      super.widget as PlacesAutocompleteFormField;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(PlacesAutocompleteFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);

      if (oldWidget.controller != null && widget.controller == null) {
        _controller = TextEditingController.fromValue(
          oldWidget.controller!.value,
        );
      }
      if (widget.controller != null) {
        setValue(widget.controller!.text);
        if (oldWidget.controller == null) {
          _controller?.dispose();
          _controller = null;
        }
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void reset() {
    super.reset();
    setState(() {
      _effectiveController.text = widget.initialValue ?? '';
    });
  }

  void _handleControllerChanged() {
    // Suppress changes that originated from within this class.
    //
    // In the case where a controller has been passed in to this widget, we
    // register this change listener. In these cases, we'll also receive change
    // notifications for changes originating from within this class -- for
    // example, the reset() method. In such cases, the FormField value will
    // already have been set.
    if (_effectiveController.text != value) {
      didChange(_effectiveController.text);
    }
  }
}
