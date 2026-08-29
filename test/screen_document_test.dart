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
  });
}
