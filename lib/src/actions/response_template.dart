/// Replaces `{{response}}` and `{{response.formatted}}` inside an action tree.
Object? applyResponseTemplate(Object? node, Object? response) {
  if (node is String) {
    return node.replaceAllMapped(_placeholder, (match) {
      final path = match.group(1)?.trim();
      final value = (path == null || path.isEmpty)
          ? response
          : _readPath(response, path);
      return _asText(value) ?? match.group(0) ?? '';
    });
  }
  if (node is Map) {
    return <String, Object?>{
      for (final entry in node.entries)
        entry.key.toString(): applyResponseTemplate(
          _asObject(entry.value),
          response,
        ),
    };
  }
  if (node is List) {
    return <Object?>[
      for (final item in node) applyResponseTemplate(_asObject(item), response),
    ];
  }
  return node;
}

String? resolveBoundText(String text, String? Function(String key) read) {
  final resolved = text.replaceAllMapped(_boundKey, (match) {
    final key = match.group(1)?.trim() ?? '';
    if (key.isEmpty || key.startsWith('response')) {
      return match.group(0) ?? '';
    }
    return read(key) ?? '';
  });
  return resolved;
}

final _placeholder = RegExp(r'\{\{\s*response(?:\.([^{}]+))?\s*\}\}');
final _boundKey = RegExp(r'\{\{\s*([^{}]+)\s*\}\}');

Object? _readPath(Object? node, String path) {
  Object? current = node;
  for (final key in path.split('.')) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final map = _asMap(current);
    if (map == null || !map.containsKey(trimmed)) {
      return null;
    }
    current = map[trimmed];
  }
  return current;
}

Map<String, Object?>? _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _asObject(entry.value),
    };
  }
  return null;
}

Object? _asObject(Object? value) => value;

String? _asText(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return '$value';
  }
  return null;
}
