import 'package:flutter/foundation.dart';

/// Values written by `setValue` that [BoundTextView] can listen to.
///
/// Stac stores the same keys, but it does not rebuild widgets that already
/// resolved `{{key}}` at parse time.
class BoundValueStore extends ChangeNotifier {
  BoundValueStore._();

  static final BoundValueStore instance = BoundValueStore._();

  final Map<String, String> _values = {};

  String? read(String key) => _values[key];

  void write(String key, String value) {
    _values[key] = value;
    notifyListeners();
  }

  void clear() {
    _values.clear();
    notifyListeners();
  }
}
