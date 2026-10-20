import 'package:flutter/material.dart';

import 'places_client.dart';
import 'places_models.dart';
import 'places_requests.dart';
import 'flutter_google_places.dart';

/// A field that opens Places New autocomplete and retains the selected session.
class PlacesAutocompleteField extends StatefulWidget {
  final PlacesClient client;
  final TextEditingController? controller;
  final Icon? leading;
  final String? hint;
  final Icon? trailing;
  final VoidCallback? trailingOnTap;
  final Mode mode;
  final int? inputOffset;
  final PlacesArea? locationBias;
  final PlacesArea? locationRestriction;
  final PlaceLocation? origin;
  final String? languageCode;
  final String? regionCode;
  final String? sessionToken;
  final List<String> includedPrimaryTypes;
  final List<String> includedRegionCodes;
  final ValueChanged<String>? onChanged;
  final ValueChanged<PlaceSelection>? onSelected;
  final ValueChanged<PlacesApiException>? onError;
  final InputDecoration? inputDecoration;
  final BorderRadius? overlayBorderRadius;
  final TextStyle? textStyle;
  final TextStyle? textStyleFormField;
  const PlacesAutocompleteField({
    super.key,
    required this.client,
    this.controller,
    this.leading,
    this.hint = 'Search',
    this.trailing,
    this.trailingOnTap,
    this.mode = Mode.fullscreen,
    this.inputOffset,
    this.locationBias,
    this.locationRestriction,
    this.origin,
    this.languageCode,
    this.regionCode,
    this.sessionToken,
    this.includedPrimaryTypes = const [],
    this.includedRegionCodes = const [],
    this.onChanged,
    this.onSelected,
    this.onError,
    this.inputDecoration = const InputDecoration(),
    this.overlayBorderRadius,
    this.textStyle,
    this.textStyleFormField,
  });
  @override
  State<PlacesAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<PlacesAutocompleteField> {
  TextEditingController? _controller;

  TextEditingController get _effectiveController =>
      widget.controller ?? _controller!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _controller = TextEditingController();
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(PlacesAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      final oldController = oldWidget.controller ?? _controller!;
      oldController.removeListener(_handleControllerChanged);
      if (widget.controller == null) {
        _controller = TextEditingController.fromValue(oldController.value);
      } else {
        _controller?.dispose();
        _controller = null;
      }
      _effectiveController.addListener(_handleControllerChanged);
    }
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  Future<PlaceSelection?> _showAutocomplete() => PlacesAutocomplete.show(
    context: context,
    client: widget.client,
    hint: widget.hint,
    mode: widget.mode,
    inputOffset: widget.inputOffset,
    locationBias: widget.locationBias,
    locationRestriction: widget.locationRestriction,
    origin: widget.origin,
    languageCode: widget.languageCode,
    regionCode: widget.regionCode,
    sessionToken: widget.sessionToken,
    includedPrimaryTypes: widget.includedPrimaryTypes,
    includedRegionCodes: widget.includedRegionCodes,
    onError: widget.onError,
    overlayBorderRadius: widget.overlayBorderRadius,
    textStyle: widget.textStyle,
  );

  void _handleTap() async {
    final selection = await _showAutocomplete();
    if (!mounted || selection == null) return;
    _effectiveController.text = selection.prediction.text.text;
    if (!mounted) return;
    widget.onChanged?.call(selection.prediction.text.text);
    if (mounted) widget.onSelected?.call(selection);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _effectiveController;

    final text = controller.text.isNotEmpty
        ? Text(
            controller.text,
            softWrap: true,
            style:
                widget.textStyleFormField ??
                const TextStyle(color: Colors.black38),
          )
        : Text(
            widget.hint ?? '',
            style:
                widget.textStyleFormField ??
                const TextStyle(color: Colors.black38),
          );

    Widget child = Row(
      children: <Widget>[
        widget.leading ?? const SizedBox(),
        const SizedBox(width: 16.0),
        Expanded(child: text),
        widget.trailing != null
            ? GestureDetector(
                onTap: widget.trailingOnTap,
                child: widget.trailingOnTap != null
                    ? widget.trailing!
                    : Icon(widget.trailing!.icon, color: Colors.grey),
              )
            : const SizedBox(),
      ],
    );

    if (widget.inputDecoration != null) {
      child = InputDecorator(
        decoration: widget.inputDecoration!,
        isEmpty: controller.value.text.isEmpty,
        child: child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: child,
    );
  }
}
