import 'package:flutter/material.dart';
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
      expect(SduiRoutes.screenPrefix, '/sdui');
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
          renderer: _FakeRenderer(),
        );

        expect(Sdui.repository, same(custom));
        final document = await Sdui.repository.load('home');
        expect(document.body['data'], 'custom');
        expect(document.schemaVersion, ScreenDocument.legacySchemaVersion);
      },
    );
  });

  group('action parsers', () {
    testWidgets('sduiNavigate calls the injected callback, not Sdui.config', (
      tester,
    ) async {
      String? navigated;
      String? navStyle;
      final observer = _RecordingObserver();
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

  group('SduiScreen', () {
    testWidgets('renders through injected repository and renderer', (
      tester,
    ) async {
      final repository = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'Hello SDUI'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: _FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello SDUI'), findsOneWidget);
    });

    testWidgets('shows error and retries with the injected repository', (
      tester,
    ) async {
      final repository = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'Recovered'},
      })..errorForNextLoad = StateError('network down');

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: _FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('network down'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered'), findsOneWidget);
    });

    testWidgets('notifies the observer on a successful load', (tester) async {
      final observer = _RecordingObserver();
      final repository = MemoryScreenRepository({
        'home': {
          'schemaVersion': 1,
          'name': 'home',
          'body': {'type': 'text', 'data': 'From envelope'},
        },
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: _FakeRenderer(),
            observer: observer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('From envelope'), findsOneWidget);
      expect(observer.loads, ['home:1']);
      expect(observer.errors, isEmpty);
    });

    testWidgets('shows a fallback when the renderer fails', (tester) async {
      final observer = _RecordingObserver();
      final repository = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'unused'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: _ThrowingRenderer(),
            observer: observer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to render screen'), findsOneWidget);
      expect(observer.renderFailures, ['home']);
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
  });
}

class _FakeRenderer implements SduiRenderer {
  @override
  Widget? render(BuildContext context, ScreenDocument document) {
    final data = document.body['data'];
    if (data is String) {
      return Text(data);
    }
    return const SizedBox.shrink();
  }
}

class _ThrowingRenderer implements SduiRenderer {
  @override
  Widget? render(BuildContext context, ScreenDocument document) {
    throw StateError('Unable to render screen "${document.name}"');
  }
}

class _RecordingObserver extends SduiObserver {
  final List<String> actions = [];
  final List<String> loads = [];
  final List<String> errors = [];
  final List<String> renderFailures = [];

  @override
  void onAction(String actionType, {String? screen}) {
    actions.add(actionType);
  }

  @override
  void onScreenLoad(
    String name,
    Duration latency, {
    required int schemaVersion,
  }) {
    loads.add('$name:$schemaVersion');
  }

  @override
  void onScreenError(String name, Object error) {
    errors.add(name);
  }

  @override
  void onRenderFailed(String name, Object error) {
    renderFailures.add(name);
  }
}
