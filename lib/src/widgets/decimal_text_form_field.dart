import 'package:flutter/material.dart';
import 'package:stac/stac.dart';
// Stac keeps InputValidators in src/. Decimal fields reuse that table after
// rewriting a comma, so isNumeric matches the server.
// ignore: implementation_imports
import 'package:stac/src/utils/input_validations.dart';

/// `textFormField` that accepts `keyboardType: decimal`.
///
/// Stac 1.5 rejects that token. Money fields keep sending it. This parser
/// opens [TextInputType.numberWithOptions] with a decimal separator and
/// leaves every other keyboard type to [StacTextFormFieldParser].
class DecimalTextFormFieldParser
    implements StacParser<DecimalTextFormFieldModel> {
  const DecimalTextFormFieldParser();

  static const StacTextFormFieldParser _delegate = StacTextFormFieldParser();

  @override
  String get type => 'textFormField';

  @override
  DecimalTextFormFieldModel getModel(Map<String, dynamic> json) {
    if (json['keyboardType'] != 'decimal') {
      return DecimalTextFormFieldModel(
        field: _delegate.getModel(json),
        decimal: false,
      );
    }

    final normalized = Map<String, dynamic>.from(json);
    normalized['keyboardType'] = 'number';
    return DecimalTextFormFieldModel(
      field: StacTextFormField.fromJson(normalized),
      decimal: true,
    );
  }

  @override
  Widget parse(BuildContext context, DecimalTextFormFieldModel model) {
    if (!model.decimal) {
      return _delegate.parse(context, model.field);
    }
    return DecimalTextFormField(
      model: model.field,
      formScope: StacFormScope.of(context),
    );
  }
}

class DecimalTextFormFieldModel {
  const DecimalTextFormFieldModel({required this.field, required this.decimal});

  final StacTextFormField field;
  final bool decimal;
}

/// Amount field. A comma is stored as a dot so `getFormValue` and `isNumeric`
/// see the same string the API accepts.
class DecimalTextFormField extends StatefulWidget {
  const DecimalTextFormField({
    super.key,
    required this.model,
    required this.formScope,
  });

  final StacTextFormField model;
  final StacFormScope? formScope;

  @override
  State<DecimalTextFormField> createState() => _DecimalTextFormFieldState();
}

class _DecimalTextFormFieldState extends State<DecimalTextFormField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    var resolved = widget.model.initialValue ?? '';
    final id = widget.model.id;
    final scope = widget.formScope;
    if (id != null && scope != null) {
      final existing = scope.formData[id];
      if (existing != null && existing.toString().trim().isNotEmpty) {
        resolved = existing.toString();
      }
      scope.formData[id] = _decimalAmount(resolved);
    }
    _controller = TextEditingController(text: resolved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: widget.model.decoration?.parse(context),
      enabled: widget.model.enabled,
      autovalidateMode: widget.model.autovalidateMode?.parse,
      onChanged: _publish,
      validator: _onValidate,
    );
  }

  String? _onValidate(String? value) {
    return _validate(value, widget.model, widget.formScope);
  }

  void _publish(String value) {
    final id = widget.model.id;
    if (id == null) {
      return;
    }
    widget.formScope?.formData[id] = _decimalAmount(value);
  }
}

/// Rewrites a decimal comma to a dot. `12,50` becomes `12.50`.
String _decimalAmount(String value) => value.replaceAll(',', '.');

String? _validate(
  String? value,
  StacTextFormField model,
  StacFormScope? formScope,
) {
  final rules = model.validatorRules;
  if (value == null || rules == null || rules.isEmpty) {
    return null;
  }

  for (final validator in rules) {
    try {
      final isValid = validator.rule == 'compare'
          ? _compare(value, validator, formScope)
          : InputValidators.validate(
              validator.rule,
              validator.rule == 'isNumeric' ? _decimalAmount(value) : value,
              options: validator.options,
            );
      if (!isValid) {
        return validator.message ?? 'Invalid input';
      }
    } catch (_) {
      return validator.message ?? 'Invalid input';
    }
  }

  return null;
}

bool _compare(
  String value,
  StacFormFieldValidator validator,
  StacFormScope? formScope,
) {
  final targetId = validator.options?['fieldId'];
  if (targetId is! String) {
    return false;
  }
  return value == formScope?.formData[targetId]?.toString();
}
