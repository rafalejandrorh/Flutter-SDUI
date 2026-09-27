import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';
import 'package:stac/stac.dart';

void main() {
  setUp(() async {
    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: MemoryScreenRepository({
          'amount': _amountScreen(),
          'email': _emailScreen(),
        }),
      ),
    );
  });

  tearDown(Sdui.reset);

  testWidgets('decimal keyboardType opens a decimal pad', (tester) async {
    await _pump(tester, 'amount');

    expect(find.text('Stac Parse Error'), findsNothing);
    expect(find.text('Monto'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );

    await tester.enterText(find.byType(TextField), '12,50');
    await tester.pump();

    expect(find.text('El monto tiene que ser un número'), findsNothing);
    final scope = StacFormScope.of(tester.element(find.byType(TextFormField)));
    expect(scope?.formData['amount'], '12.50');
  });

  testWidgets('a non-numeric amount still fails isNumeric', (tester) async {
    await _pump(tester, 'amount');

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();

    expect(find.text('El monto tiene que ser un número'), findsOneWidget);
  });

  testWidgets('emailAddress still uses the Stac keyboard', (tester) async {
    await _pump(tester, 'email');

    expect(find.text('Stac Parse Error'), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.keyboardType, TextInputType.emailAddress);
  });
}

Map<String, dynamic> _amountScreen() {
  return {
    'type': 'form',
    'autovalidateMode': 'onUserInteraction',
    'child': {
      'type': 'textFormField',
      'id': 'amount',
      'keyboardType': 'decimal',
      'decoration': {'labelText': 'Monto'},
      'validatorRules': [
        {
          'rule': 'isLength',
          'options': {'min': 1},
          'message': 'Escribe un monto',
        },
        {'rule': 'isNumeric', 'message': 'El monto tiene que ser un número'},
      ],
    },
  };
}

Map<String, dynamic> _emailScreen() {
  return {
    'type': 'form',
    'child': {
      'type': 'textFormField',
      'id': 'email',
      'keyboardType': 'emailAddress',
      'decoration': {'labelText': 'Email'},
    },
  };
}

Future<void> _pump(WidgetTester tester, String name) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SduiScreen(name: name)),
    ),
  );
  await tester.pumpAndSettle();
}
