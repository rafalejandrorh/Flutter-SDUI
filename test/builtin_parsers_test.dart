import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';
import 'package:stac_framework/stac_framework.dart';

import 'support/fakes.dart';

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  final sharedTexts = <String>[];

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sharedTexts.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (call) async {
          final args = call.arguments;
          if (args is Map<Object?, Object?>) {
            final text = args['text'];
            if (text is String) {
              sharedTexts.add(text);
            }
          }
          return 'dev.fluttercommunity.plus/share/unavailable';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
    Sdui.reset();
  });

  test('sduiShare model keeps the text', () {
    final parser = SduiShareActionParser();

    expect(parser.actionType, 'sduiShare');
    expect(parser.getModel({'text': 'Hoy: \$ 12,00'}).text, 'Hoy: \$ 12,00');
  });

  testWidgets('initialize resolves sduiShare without extra parsers', (
    tester,
  ) async {
    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: MemoryScreenRepository({
          'home': {
            'type': 'filledButton',
            'child': {'type': 'text', 'data': 'Compartir'},
            'onPressed': {'actionType': 'sduiShare', 'text': 'Hoy: \$ 12,00'},
          },
        }),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SduiScreen(name: 'home')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir'));
    await tester.pump();

    expect(sharedTexts, ['Hoy: \$ 12,00']);
  });

  testWidgets('an extra sduiShare parser does not replace the library one', (
    tester,
  ) async {
    final host = _HostShareParser();
    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: MemoryScreenRepository({
          'home': {
            'type': 'filledButton',
            'child': {'type': 'text', 'data': 'Compartir'},
            'onPressed': {'actionType': 'sduiShare', 'text': 'USD 2,00'},
          },
        }),
      ),
      extraActionParsers: [host],
    );

    await tester.pumpWidget(const MaterialApp(home: SduiScreen(name: 'home')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir'));
    await tester.pump();

    expect(host.calls, 0);
    expect(sharedTexts, ['USD 2,00']);
  });

  testWidgets('sduiReload skips the cache and rerenders', (tester) async {
    final inner = _CountingRepo({'home': _reloadScreen('v1')});
    final repo = CachedScreenRepository(
      inner: inner,
      staleAfter: const Duration(hours: 1),
    );

    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: repo,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SduiScreen(name: 'home')));
    await tester.pumpAndSettle();
    expect(find.text('v1'), findsOneWidget);
    expect(inner.loads, 1);

    inner.put('home', _reloadScreen('v2'));
    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();

    expect(inner.loads, 2);
    expect(find.text('v2'), findsOneWidget);
    expect(find.text('v1'), findsNothing);
  });

  testWidgets('a failed sduiReload keeps the current screen', (tester) async {
    final inner = MemoryScreenRepository({'home': _reloadScreen('v1')});
    final observer = RecordingObserver();

    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: inner,
        observer: observer,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: SduiScreen(name: 'home')));
    await tester.pumpAndSettle();

    inner.errorForNextLoad = Exception('down');
    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();

    expect(find.text('v1'), findsOneWidget);
    expect(observer.errors, ['home']);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _reloadScreen(String data) {
  return {
    'type': 'column',
    'children': [
      {'type': 'text', 'data': data},
      {
        'type': 'filledButton',
        'child': {'type': 'text', 'data': 'Reload'},
        'onPressed': {'actionType': 'sduiReload'},
      },
    ],
  };
}

class _HostShareParser implements StacActionParser<String> {
  int calls = 0;

  @override
  String get actionType => 'sduiShare';

  @override
  String getModel(Map<String, dynamic> json) => '';

  @override
  Future<void> onCall(BuildContext context, String model) async {
    calls++;
  }
}

class _CountingRepo extends MemoryScreenRepository {
  _CountingRepo(super.screens);

  int loads = 0;

  @override
  Future<ScreenDocument> load(String name) {
    loads++;
    return super.load(name);
  }
}
