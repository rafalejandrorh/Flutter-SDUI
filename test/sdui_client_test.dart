import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';
import 'package:sdui_client/src/auth/auth_interceptor.dart';

import 'support/fakes.dart';

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
      expect(SduiRoutes.screenPrefix, '/sdui');
    });

    test('rejects empty and nested screen names', () {
      expect(SduiRoutes.screenNameFromPath('/sdui/'), isNull);
      expect(SduiRoutes.screenNameFromPath('/sdui/a/b'), isNull);
    });
  });

  group('Sdui facade', () {
    test('throws StateError before initialize', () {
      Sdui.reset();
      expect(Sdui.isInitialized, isFalse);
      expect(() => Sdui.client, throwsA(isA<StateError>()));
      expect(() => Sdui.config, throwsA(isA<StateError>()));
      expect(() => Sdui.dio, throwsA(isA<StateError>()));
      expect(() => Sdui.repository, throwsA(isA<StateError>()));
      expect(() => Sdui.renderer, throwsA(isA<StateError>()));
      expect(() => Sdui.observer, throwsA(isA<StateError>()));
      expect(() => Sdui.viewPolicy, throwsA(isA<StateError>()));
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

  group('Sdui.initialize', () {
    tearDown(Sdui.reset);

    test('applies baseUrl and Accept header on Dio', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await Sdui.initialize(
        config: const SduiConfig(
          source: SduiScreenSource.network,
          baseUrl: 'http://127.0.0.1:8000',
        ),
      );

      expect(Sdui.dio.options.baseUrl, 'http://127.0.0.1:8000');
      expect(Sdui.dio.options.headers['Accept'], 'application/json');
      expect(
        Sdui.dio.options.headers[ScreenDocument.clientVersionHeader],
        '${ScreenDocument.currentSchemaVersion}',
      );
      expect(Sdui.renderer, isNotNull);
    });

    test(
      'uses an injected ScreenRepository instead of the source switch',
      () async {
        final custom = MemoryScreenRepository({
          'home': {'type': 'text', 'data': 'custom'},
        });

        await Sdui.initialize(
          config: SduiConfig(
            source: SduiScreenSource.asset,
            screenRepository: custom,
          ),
          renderer: const FakeRenderer(),
        );

        expect(Sdui.repository, same(custom));
        final document = await Sdui.repository.load('home');
        expect(document.body['data'], 'custom');
        expect(document.schemaVersion, ScreenDocument.legacySchemaVersion);
      },
    );

    test('wraps the default network repository with cache', () async {
      await Sdui.initialize(
        config: const SduiConfig(
          source: SduiScreenSource.network,
          baseUrl: 'http://127.0.0.1:8000',
        ),
        renderer: const FakeRenderer(),
      );

      expect(Sdui.repository, isA<CachedScreenRepository>());
    });

    test('skips cache when cacheScreens is false', () async {
      await Sdui.initialize(
        config: const SduiConfig(
          source: SduiScreenSource.network,
          cacheScreens: false,
        ),
        renderer: const FakeRenderer(),
      );

      expect(Sdui.repository, isA<NetworkScreenRepository>());
    });

    test('registers SduiAuthInterceptor when tokenStore is set', () async {
      final store = MemoryTokenStore();
      await store.write('tok');
      var unauthorized = 0;

      await Sdui.initialize(
        config: SduiConfig(
          source: SduiScreenSource.network,
          baseUrl: 'http://127.0.0.1:8000',
          tokenStore: store,
          onUnauthorized: () => unauthorized++,
        ),
        renderer: const FakeRenderer(),
      );

      expect(
        Sdui.dio.interceptors.whereType<SduiAuthInterceptor>(),
        isNotEmpty,
      );
      expect(unauthorized, 0);
      expect(Sdui.isInitialized, isTrue);
      expect(Sdui.config.baseUrl, 'http://127.0.0.1:8000');
      expect(Sdui.observer, isA<SduiObserver>());
      expect(Sdui.viewPolicy, isA<SduiViewPolicy>());
    });
  });

  group('action parsers', () {
    test('sduiNavigate getModel defaults style to push', () {
      final parser = SduiNavigateActionParser(
        onNavigate: (context, screen, {style = 'push'}) {},
      );

      expect(parser.actionType, 'sduiNavigate');
      final model = parser.getModel({'screen': 'details'});
      expect(model.screen, 'details');
      expect(model.style, 'push');
    });

    test('sduiLogout getModel ignores JSON', () {
      final parser = SduiLogoutActionParser();

      expect(parser.actionType, 'sduiLogout');
      expect(parser.getModel({'ignored': true}), isA<SduiLogoutAction>());
    });

    testWidgets(
      'sduiNavigate without onNavigateScreen hits the bootstrap StateError',
      (tester) async {
        addTearDown(Sdui.reset);
        final observer = RecordingObserver();

        await Sdui.initialize(
          config: SduiConfig(
            source: SduiScreenSource.asset,
            observer: observer,
            screenRepository: MemoryScreenRepository({
              'home': {
                'type': 'filledButton',
                'child': {'type': 'text', 'data': 'Go'},
                'onPressed': {
                  'actionType': 'sduiNavigate',
                  'screen': 'details',
                },
              },
            }),
          ),
        );

        await tester.pumpWidget(
          const MaterialApp(home: SduiScreen(name: 'home')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Go'));
        await tester.pump();

        expect(observer.actions, ['sduiNavigate']);
        // Stac catches the default onNavigateScreen StateError and logs it.
        expect(tester.takeException(), isNull);
        expect(find.text('Go'), findsOneWidget);
      },
    );

    testWidgets('sduiNavigate calls the injected callback, not Sdui.config', (
      tester,
    ) async {
      String? navigated;
      String? navStyle;
      final observer = RecordingObserver();
      final parser = SduiNavigateActionParser(
        onNavigate: (context, screen, {style = 'push'}) {
          navigated = screen;
          navStyle = style;
        },
        observer: observer,
      );

      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      );

      await parser.onCall(
        context,
        SduiNavigateAction.fromJson({'screen': 'details', 'style': 'replace'}),
      );

      expect(navigated, 'details');
      expect(navStyle, 'replace');
      expect(observer.actions, ['sduiNavigate']);
    });

    testWidgets('sduiLogout calls the injected callback', (tester) async {
      var loggedOut = false;
      final parser = SduiLogoutActionParser(onLogout: () => loggedOut = true);

      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      );

      await parser.onCall(context, const SduiLogoutAction());
      expect(loggedOut, isTrue);
    });
  });

  group('MemoryScreenRepository', () {
    test('parses a versioned envelope into the Stac body', () async {
      final repository = MemoryScreenRepository({
        'home': {
          'schemaVersion': 1,
          'name': 'home',
          'body': {'type': 'scaffold', 'body': 'ok'},
        },
      });

      final document = await repository.load('home');
      expect(document.schemaVersion, 1);
      expect(document.body['type'], 'scaffold');
    });

    test('rejects a future schemaVersion', () async {
      final repository = MemoryScreenRepository({
        'home': {
          'schemaVersion': 99,
          'body': {'type': 'text', 'data': 'nope'},
        },
      });

      expect(
        repository.load('home'),
        throwsA(isA<SduiUnsupportedVersionException>()),
      );
    });

    test('throws SduiLoadFailedException for an unknown screen', () async {
      final repository = MemoryScreenRepository({});

      expect(
        repository.load('missing'),
        throwsA(
          isA<SduiLoadFailedException>().having(
            (e) => e.message,
            'message',
            contains('Unknown screen'),
          ),
        ),
      );
    });
  });
}
