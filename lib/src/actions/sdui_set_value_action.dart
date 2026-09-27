import 'package:flutter/widgets.dart';
import 'package:stac/stac.dart';

import '../widgets/bound_value_store.dart';

class SetValueCall {
  const SetValueCall({required this.values, this.action});

  final List<SetValueEntry> values;
  final Map<String, dynamic>? action;

  factory SetValueCall.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    final values = <SetValueEntry>[];
    if (rawValues is List) {
      for (final item in rawValues) {
        if (item is! Map) {
          continue;
        }
        final key = item['key'];
        if (key is! String || key.isEmpty) {
          continue;
        }
        values.add(SetValueEntry(key: key, value: _text(item['value'])));
      }
    }
    final action = json['action'];
    Map<String, dynamic>? followUp;
    if (action is Map<String, dynamic>) {
      followUp = action;
    } else if (action is Map) {
      followUp = Map<String, dynamic>.from(action);
    }
    return SetValueCall(values: values, action: followUp);
  }
}

class SetValueEntry {
  const SetValueEntry({required this.key, required this.value});

  final String key;
  final String value;
}

/// Stac `setValue` that also notifies [BoundValueStore].
class SduiSetValueActionParser implements StacActionParser<SetValueCall> {
  const SduiSetValueActionParser({this.store});

  final BoundValueStore? store;

  @override
  String get actionType => 'setValue';

  @override
  SetValueCall getModel(Map<String, dynamic> json) =>
      SetValueCall.fromJson(json);

  @override
  Future<Object?> onCall(BuildContext context, SetValueCall model) async {
    final values = store ?? BoundValueStore.instance;
    for (final entry in model.values) {
      values.write(entry.key, entry.value);
      StacRegistry.instance.setValue(entry.key, entry.value);
    }
    final action = model.action;
    if (action == null || !context.mounted) {
      return null;
    }
    return Stac.onCallFromJson(action, context);
  }
}

String _text(Object? value) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return '';
  }
  if (value is num || value is bool) {
    return '$value';
  }
  return value.toString();
}
