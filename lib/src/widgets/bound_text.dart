import 'package:flutter/material.dart';
import 'package:stac_framework/stac_framework.dart';

import 'bound_value_store.dart';

class BoundTextModel {
  const BoundTextModel({
    required this.valueKey,
    required this.placeholder,
    this.fontSize,
  });

  final String valueKey;
  final String placeholder;
  final double? fontSize;

  factory BoundTextModel.fromJson(Map<String, dynamic> json) {
    final valueKey = json['valueKey'];
    final placeholder = json['placeholder'];
    final style = json['style'];
    double? fontSize;
    if (style is Map) {
      final rawSize = style['fontSize'];
      if (rawSize is num) {
        fontSize = rawSize.toDouble();
      }
    }
    return BoundTextModel(
      valueKey: valueKey is String ? valueKey : '',
      placeholder: placeholder is String ? placeholder : '',
      fontSize: fontSize,
    );
  }
}

class BoundTextParser implements StacParser<BoundTextModel> {
  const BoundTextParser();

  @override
  String get type => 'boundText';

  @override
  BoundTextModel getModel(Map<String, dynamic> json) =>
      BoundTextModel.fromJson(json);

  @override
  Widget parse(BuildContext context, BoundTextModel model) {
    return BoundTextView(model: model);
  }
}

class BoundTextView extends StatefulWidget {
  const BoundTextView({super.key, required this.model, this.store});

  final BoundTextModel model;
  final BoundValueStore? store;

  @override
  State<BoundTextView> createState() => _BoundTextViewState();
}

class _BoundTextViewState extends State<BoundTextView> {
  BoundValueStore get _store => widget.store ?? BoundValueStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onValue);
  }

  @override
  void dispose() {
    _store.removeListener(_onValue);
    super.dispose();
  }

  void _onValue() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = _store.read(widget.model.valueKey);
    final text = (value == null || value.isEmpty)
        ? widget.model.placeholder
        : value;
    final size = widget.model.fontSize;
    return Text(text, style: size == null ? null : TextStyle(fontSize: size));
  }
}
