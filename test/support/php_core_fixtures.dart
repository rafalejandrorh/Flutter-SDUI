import 'dart:convert';
import 'dart:io';

/// Screen names covered by SDUI-Core `tests/ScreenSnapshotTest.php`.
const phpCoreScreenNames = ['home', 'details', 'form'];

/// Bundled copy of a PHP Core snapshot (`tests/fixtures/{name}.json`).
File phpCoreFixtureFile(String name) =>
    File('test/fixtures/php_core/$name.json');

/// Parses a bundled Core snapshot into a JSON object.
Map<String, dynamic> loadPhpCoreFixture(String name) {
  final decoded = jsonDecode(phpCoreFixtureFile(name).readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('PHP Core fixture "$name" is not a JSON object.');
  }
  return Map<String, dynamic>.from(decoded);
}

/// Live SDUI-Core snapshot when this repo is a sibling of Backend/Owner.
File? siblingPhpCoreFixture(String name) {
  final file = File.fromUri(
    Directory.current.uri.resolve(
      '../../../Backend/Owner/SDUI-Core/tests/fixtures/$name.json',
    ),
  );
  return file.existsSync() ? file : null;
}

Map<String, dynamic> decodeJsonObject(String raw, {required String source}) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw FormatException('Expected a JSON object ($source).');
  }
  return Map<String, dynamic>.from(decoded);
}

/// Walks a Stac tree and returns every node whose `type` matches [type].
List<Map<String, dynamic>> findWidgetsByType(Object? node, String type) {
  final found = <Map<String, dynamic>>[];
  void walk(Object? value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map['type'] == type) {
        found.add(map);
      }
      for (final child in map.values) {
        walk(child);
      }
    } else if (value is List) {
      for (final child in value) {
        walk(child);
      }
    }
  }

  walk(node);
  return found;
}
