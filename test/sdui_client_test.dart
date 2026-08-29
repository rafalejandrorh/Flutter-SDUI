import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

void main() {
  group('SduiConfig', () {
    test('resolves asset and network templates', () {
      const config = SduiConfig(
        source: SduiScreenSource.network,
        baseUrl: 'https://api.example.com',
        screenPath: '/sdui/screens/{name}',
        assetPath: 'assets/screens/{name}.json',
      );

      expect(config.resolveAssetPath('home'), 'assets/screens/home.json');
      expect(
        config.resolveScreenUrl('home'),
        'https://api.example.com/sdui/screens/home',
      );
    });
  });

  group('SduiRoutes', () {
    test('builds and parses screen paths', () {
      expect(SduiRoutes.screen('home'), '/sdui/home');
      expect(SduiRoutes.screenNameFromPath('/sdui/home'), 'home');
      expect(SduiRoutes.screenNameFromPath('/login'), isNull);
    });
  });

  group('MemoryTokenStore', () {
    test('round-trips a token', () async {
      final store = MemoryTokenStore();
      expect(await store.read(), isNull);
      await store.write('abc');
      expect(await store.read(), 'abc');
      await store.clear();
      expect(await store.read(), isNull);
    });
  });
}
