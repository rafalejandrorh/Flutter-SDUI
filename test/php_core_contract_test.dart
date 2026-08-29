import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

import 'support/php_core_fixtures.dart';

void main() {
  group('PHP Core snapshots', () {
    test(
      'bundled fixtures stay in sync with SDUI-Core when it is a sibling',
      () {
        if (siblingPhpCoreFixture('home') == null) {
          return;
        }
        for (final name in phpCoreScreenNames) {
          final sibling = siblingPhpCoreFixture(name)!;
          expect(
            loadPhpCoreFixture(name),
            decodeJsonObject(sibling.readAsStringSync(), source: sibling.path),
            reason: 'test/fixtures/php_core/$name.json drifted from SDUI-Core',
          );
        }
      },
    );

    test('json_encode trees parse as legacy Stac ScreenDocuments', () {
      for (final name in phpCoreScreenNames) {
        final json = loadPhpCoreFixture(name);
        final document = ScreenDocument.parse(json, name: name);

        expect(document.name, name);
        expect(document.schemaVersion, ScreenDocument.legacySchemaVersion);
        expect(document.body['type'], 'scaffold');
        expect(findWidgetsByType(document.body, 'appBar'), isNotEmpty);
      }
    });

    test('the same trees parse as envelope body (schemaVersion 1)', () {
      for (final name in phpCoreScreenNames) {
        final json = loadPhpCoreFixture(name);
        final document = ScreenDocument.parse({
          'schemaVersion': ScreenDocument.currentSchemaVersion,
          'name': name,
          'body': json,
        }, name: 'ignored');

        expect(document.name, name);
        expect(document.schemaVersion, ScreenDocument.currentSchemaVersion);
        expect(document.body['type'], 'scaffold');
      }
    });

    test('home snapshot exposes sduiNavigate and sduiLogout actions', () {
      final body = ScreenDocument.parse(
        loadPhpCoreFixture('home'),
        name: 'home',
      ).body;
      final texts = findWidgetsByType(
        body,
        'text',
      ).map((widget) => widget['data']).toList();

      expect(texts, containsAll(['Home', 'Welcome']));
      expect(_actionTypes(body), containsAll(['sduiNavigate', 'sduiLogout']));
      expect(_navigateScreens(body), ['details', 'form']);
    });

    test('details snapshot pops via navigate', () {
      final body = ScreenDocument.parse(
        loadPhpCoreFixture('details'),
        name: 'details',
      ).body;

      expect(
        findWidgetsByType(body, 'text').map((widget) => widget['data']),
        containsAll(['Details', 'This screen was opened from JSON.']),
      );
      expect(_actionTypes(body), contains('navigate'));
    });

    test('form snapshot keeps Stac form ids and validateForm', () {
      final body = ScreenDocument.parse(
        loadPhpCoreFixture('form'),
        name: 'form',
      ).body;
      final fields = findWidgetsByType(body, 'textFormField');

      expect(fields.map((field) => field['id']), ['name', 'email']);
      expect(_actionTypes(body), contains('validateForm'));
    });
  });
}

List<String> _actionTypes(Object? node) {
  final types = <String>[];
  void walk(Object? value) {
    if (value is Map) {
      final actionType = value['actionType'];
      if (actionType is String) {
        types.add(actionType);
      }
      for (final child in value.values) {
        walk(child);
      }
    } else if (value is List) {
      for (final child in value) {
        walk(child);
      }
    }
  }

  walk(node);
  return types;
}

List<String> _navigateScreens(Object? node) {
  final screens = <String>[];
  void walk(Object? value) {
    if (value is Map) {
      if (value['actionType'] == 'sduiNavigate' && value['screen'] is String) {
        screens.add(value['screen'] as String);
      }
      for (final child in value.values) {
        walk(child);
      }
    } else if (value is List) {
      for (final child in value) {
        walk(child);
      }
    }
  }

  walk(node);
  return screens;
}
