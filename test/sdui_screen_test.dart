import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

import 'support/fakes.dart';

void main() {
  group('SduiScreen', () {
    testWidgets('shows loading until the repository resolves', (tester) async {
      final completer = Completer<ScreenDocument>();

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: PendingScreenRepository(completer),
            renderer: const FakeRenderer(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      completer.complete(
        ScreenDocument.parse({'type': 'text', 'data': 'Ready'}, name: 'home'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ready'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses loadingBuilder while the first load is in flight', (
      tester,
    ) async {
      final completer = Completer<ScreenDocument>();

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: PendingScreenRepository(completer),
            renderer: const FakeRenderer(),
            loadingBuilder: (_) => const Text('Please wait'),
          ),
        ),
      );

      expect(find.text('Please wait'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      completer.complete(
        ScreenDocument.parse({'type': 'text', 'data': 'Ready'}, name: 'home'),
      );
      await tester.pumpAndSettle();
    });

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
            renderer: const FakeRenderer(),
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
            renderer: const FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('network down'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered'), findsOneWidget);
    });

    testWidgets('uses errorBuilder for a failed load', (tester) async {
      final repository = MemoryScreenRepository()
        ..errorForNextLoad = const SduiLoadFailedException(
          'boom',
          screen: 'home',
        );

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: const FakeRenderer(),
            errorBuilder: (context, error, retry) {
              return Column(
                children: [
                  const Text('Custom error'),
                  TextButton(onPressed: retry, child: const Text('Try again')),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom error'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('notifies the observer on a successful load', (tester) async {
      final observer = RecordingObserver();
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
            renderer: const FakeRenderer(),
            observer: observer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('From envelope'), findsOneWidget);
      expect(observer.loads, ['home:1']);
      expect(observer.errors, isEmpty);
    });

    testWidgets('uses SduiViewPolicy copies on error', (tester) async {
      final repository = MemoryScreenRepository()
        ..errorForNextLoad = const SduiLoadFailedException(
          'boom',
          screen: 'home',
        );

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: const FakeRenderer(),
            viewPolicy: const SduiViewPolicy(
              errorMessage: 'Pantalla no disponible',
              retryLabel: 'Reintentar',
              showErrorDetails: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pantalla no disponible'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('uses SduiViewPolicy builders for loading and error', (
      tester,
    ) async {
      final completer = Completer<ScreenDocument>();
      const policy = SduiViewPolicy(
        loadingBuilder: _policyLoading,
        errorBuilder: _policyError,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: PendingScreenRepository(completer),
            renderer: const FakeRenderer(),
            viewPolicy: policy,
          ),
        ),
      );

      expect(find.text('Policy loading'), findsOneWidget);

      completer.completeError(
        const SduiLoadFailedException('nope', screen: 'home'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Policy error'), findsOneWidget);
    });

    testWidgets('applies a SWR update from ScreenChangeSource', (tester) async {
      final repository = StreamingRepo({
        'home': {'type': 'text', 'data': 'v1'},
      });
      addTearDown(repository.close);

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: const FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('v1'), findsOneWidget);

      repository.emit('home', {'type': 'text', 'data': 'v2'});
      await tester.pumpAndSettle();

      expect(find.text('v2'), findsOneWidget);
    });

    testWidgets('shows a fallback when the renderer throws', (tester) async {
      final observer = RecordingObserver();
      final repository = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'unused'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: const ThrowingRenderer(),
            observer: observer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to render screen'), findsOneWidget);
      expect(observer.renderFailures, ['home']);
    });

    testWidgets('shows a fallback when the renderer returns null', (
      tester,
    ) async {
      final observer = RecordingObserver();
      final repository = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'unused'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: const NullRenderer(),
            observer: observer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Unable to render screen "home"'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(observer.renderFailures, ['home']);
    });

    testWidgets('reloads when the screen name changes', (tester) async {
      final repository = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'Home screen'},
        'details': {'type': 'text', 'data': 'Details screen'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: const FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home screen'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'details',
            repository: repository,
            renderer: const FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Details screen'), findsOneWidget);
      expect(find.text('Home screen'), findsNothing);
    });

    testWidgets('reloads when the repository instance changes', (tester) async {
      final first = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'from first'},
      });
      final second = MemoryScreenRepository({
        'home': {'type': 'text', 'data': 'from second'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: first,
            renderer: const FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('from first'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: second,
            renderer: const FakeRenderer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('from second'), findsOneWidget);
      expect(find.text('from first'), findsNothing);
    });

    testWidgets('notifies the observer on a failed load', (tester) async {
      final observer = RecordingObserver();
      final repository = MemoryScreenRepository()
        ..errorForNextLoad = const SduiLoadFailedException(
          'boom',
          screen: 'home',
        );

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScreen(
            name: 'home',
            repository: repository,
            renderer: const FakeRenderer(),
            observer: observer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('boom'), findsOneWidget);
      expect(observer.errors, ['home']);
      expect(observer.loads, isEmpty);
    });

    testWidgets('falls back to the facade repository and renderer', (
      tester,
    ) async {
      final observer = RecordingObserver();
      addTearDown(Sdui.reset);

      await Sdui.initialize(
        config: SduiConfig(
          source: SduiScreenSource.asset,
          screenRepository: MemoryScreenRepository({
            'home': {'type': 'text', 'data': 'via facade'},
          }),
          observer: observer,
        ),
        renderer: const FakeRenderer(),
      );

      await tester.pumpWidget(
        const MaterialApp(home: SduiScreen(name: 'home')),
      );
      await tester.pumpAndSettle();

      expect(find.text('via facade'), findsOneWidget);
      expect(observer.loads, ['home:0']);
    });
  });
}

Widget _policyLoading(BuildContext context) => const Text('Policy loading');

Widget _policyError(BuildContext context, Object error, VoidCallback retry) =>
    const Text('Policy error');
