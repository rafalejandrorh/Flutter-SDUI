import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

void main() {
  group('ScreenDocument.parse', () {
    test('treats a Stac root as legacy schemaVersion 0', () {
      final document = ScreenDocument.parse({
        'type': 'scaffold',
        'body': 'n/a',
      }, name: 'home');

      expect(document.name, 'home');
      expect(document.schemaVersion, ScreenDocument.legacySchemaVersion);
      expect(document.body['type'], 'scaffold');
    });

    test('unwraps a versioned envelope', () {
      final document = ScreenDocument.parse({
        'schemaVersion': 1,
        'name': 'details',
        'body': {'type': 'text', 'data': 'Hi'},
      }, name: 'ignored');

      expect(document.name, 'details');
      expect(document.schemaVersion, 1);
      expect(document.body, {'type': 'text', 'data': 'Hi'});
    });

    test('rejects a schemaVersion newer than the client', () {
      expect(
        () => ScreenDocument.parse({
          'schemaVersion': 2,
          'body': {'type': 'text', 'data': 'future'},
        }, name: 'home'),
        throwsA(
          isA<SduiUnsupportedVersionException>()
              .having((e) => e.schemaVersion, 'schemaVersion', 2)
              .having(
                (e) => e.maxSupported,
                'maxSupported',
                ScreenDocument.currentSchemaVersion,
              ),
        ),
      );
    });

    test('rejects JSON that is neither Stac nor an envelope', () {
      expect(
        () => ScreenDocument.parse({'foo': 'bar'}, name: 'home'),
        throwsA(isA<SduiLoadFailedException>()),
      );
    });

    test('rejects an envelope without a Stac body', () {
      expect(
        () => ScreenDocument.parse({
          'schemaVersion': 1,
          'body': 'not-an-object',
        }, name: 'home'),
        throwsA(isA<SduiLoadFailedException>()),
      );
    });

    test('rejects a negative schemaVersion', () {
      expect(
        () => ScreenDocument.parse({
          'schemaVersion': -1,
          'body': {'type': 'text', 'data': 'nope'},
        }, name: 'home'),
        throwsA(isA<SduiLoadFailedException>()),
      );
    });

    test('accepts a whole-number schemaVersion encoded as a double', () {
      final document = ScreenDocument.parse({
        'schemaVersion': 1.0,
        'body': {'type': 'text', 'data': 'ok'},
      }, name: 'home');

      expect(document.schemaVersion, 1);
      expect(document.body['data'], 'ok');
    });

    test('rejects an envelope body without a Stac type', () {
      expect(
        () => ScreenDocument.parse({
          'schemaVersion': 1,
          'body': {'foo': 'bar'},
        }, name: 'home'),
        throwsA(isA<SduiLoadFailedException>()),
      );
    });

    test('uses the requested name when the envelope omits name', () {
      final document = ScreenDocument.parse({
        'schemaVersion': 1,
        'body': {'type': 'text', 'data': 'ok'},
      }, name: 'home');

      expect(document.name, 'home');
    });

    test('rejects a non-numeric schemaVersion', () {
      expect(
        () => ScreenDocument.parse({
          'schemaVersion': 'one',
          'body': {'type': 'text', 'data': 'nope'},
        }, name: 'home'),
        throwsA(isA<SduiLoadFailedException>()),
      );
    });
  });
}
