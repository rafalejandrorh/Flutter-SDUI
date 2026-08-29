import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

void main() {
  group('AssetScreenRepository', () {
    test('parses a bundled Stac tree', () async {
      final repo = AssetScreenRepository(
        const SduiConfig(source: SduiScreenSource.asset),
        bundle: _MemoryAssetBundle({
          'assets/screens/home.json': jsonEncode({
            'type': 'text',
            'data': 'from asset',
          }),
        }),
      );

      final document = await repo.load('home');
      expect(document.schemaVersion, ScreenDocument.legacySchemaVersion);
      expect(document.body['data'], 'from asset');
    });

    test('wraps missing assets as SduiLoadFailedException', () async {
      final repo = AssetScreenRepository(
        const SduiConfig(source: SduiScreenSource.asset),
        bundle: _MemoryAssetBundle({}),
      );

      expect(repo.load('missing'), throwsA(isA<SduiLoadFailedException>()));
    });

    test('rethrows typed parse failures', () async {
      final repo = AssetScreenRepository(
        const SduiConfig(source: SduiScreenSource.asset),
        bundle: _MemoryAssetBundle({
          'assets/screens/home.json': jsonEncode({
            'schemaVersion': 99,
            'body': {'type': 'text', 'data': 'future'},
          }),
        }),
      );

      expect(
        repo.load('home'),
        throwsA(isA<SduiUnsupportedVersionException>()),
      );
    });
  });
}

class _MemoryAssetBundle extends AssetBundle {
  _MemoryAssetBundle(this._files);

  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) {
    throw FlutterError('load() is not used; loadString is overridden.');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _files[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: "$key".');
    }
    return value;
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) {
    throw UnimplementedError();
  }
}
