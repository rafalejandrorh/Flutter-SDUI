import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  final sharedTexts = <String>[];

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sharedTexts.clear();
    BoundValueStore.instance.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, (call) async {
          final args = call.arguments;
          if (args is Map) {
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
    BoundValueStore.instance.clear();
    Sdui.reset();
  });

  test('response.formatted is substituted in the result action', () {
    final action = applyResponseTemplate(
      {
        'actionType': 'setValue',
        'values': [
          {'key': 'convertResult', 'value': '{{response.formatted}}'},
        ],
      },
      {'formatted': 'Bs. 100,00 son \$ 2,00'},
    );

    expect(action, {
      'actionType': 'setValue',
      'values': [
        {'key': 'convertResult', 'value': 'Bs. 100,00 son \$ 2,00'},
      ],
    });
  });

  testWidgets('boundText updates when setValue runs', (tester) async {
    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: MemoryScreenRepository({
          'convert': {
            'type': 'column',
            'children': [
              {
                'type': 'boundText',
                'valueKey': 'convertResult',
                'placeholder': 'El resultado aparece aquí',
              },
              {
                'type': 'filledButton',
                'child': {'type': 'text', 'data': 'Convertir'},
                'onPressed': {
                  'actionType': 'setValue',
                  'values': [
                    {'key': 'convertResult', 'value': 'Bs. 100,00 son \$ 2,00'},
                  ],
                },
              },
              {
                'type': 'outlinedButton',
                'child': {'type': 'text', 'data': 'Compartir'},
                'onPressed': {
                  'actionType': 'sduiShare',
                  'text': '{{convertResult}}',
                },
              },
            ],
          },
        }),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: SduiScreen(name: 'convert')),
    );
    await tester.pumpAndSettle();

    expect(find.text('El resultado aparece aquí'), findsOneWidget);

    await tester.tap(find.text('Convertir'));
    await tester.pumpAndSettle();

    expect(find.text('Bs. 100,00 son \$ 2,00'), findsOneWidget);

    await tester.tap(find.text('Compartir'));
    await tester.pump();

    expect(sharedTexts, ['Bs. 100,00 son \$ 2,00']);
  });
}
