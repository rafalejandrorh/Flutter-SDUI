import 'dart:convert';

/// Normalizes a JSON decode / HTTP body into a JSON object.
Map<String, dynamic> asJsonObject(Object? data, {required String source}) {
  var value = data;
  if (value is String) {
    value = jsonDecode(value);
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw FormatException('Screen JSON must be an object ($source).');
}
