import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

void main() {
  setUpAll(() async {
    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: MemoryScreenRepository({
          'bars': {
            'type': 'barChart',
            'bars': [
              {'label': 'Comida', 'value': 42.5, 'color': '#1B6B4A'},
              {'label': 'Transporte', 'value': 10},
            ],
          },
          'empty': {'type': 'barChart', 'bars': <Map<String, dynamic>>[]},
        }),
      ),
    );
  });

  tearDownAll(Sdui.reset);

  test('empty bars fall back to the Spanish label', () {
    final model = const BarChartParser().getModel({
      'type': 'barChart',
      'bars': <Map<String, dynamic>>[],
    });

    expect(model.emptyLabel, 'Sin movimientos');
    expect(model.bars, isEmpty);
  });

  test('emptyLabel from JSON replaces the fallback', () {
    final model = const BarChartParser().getModel({
      'type': 'barChart',
      'emptyLabel': 'Nada esta semana',
    });

    expect(model.emptyLabel, 'Nada esta semana');
  });

  testWidgets('two bars render labels and a fixed chart height', (
    tester,
  ) async {
    await _pump(tester, 'bars');

    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.height == BarChartView.chartHeight,
      ),
      findsOneWidget,
    );

    await expectLater(
      find.byType(BarChartView),
      matchesGoldenFile('goldens/bar_chart_bars.png'),
    );
  });

  testWidgets('an empty bar chart shows the fallback label', (tester) async {
    await _pump(tester, 'empty');

    expect(find.text('Sin movimientos'), findsOneWidget);
    expect(find.byType(BarChartView), findsOneWidget);

    await expectLater(
      find.byType(BarChartView),
      matchesGoldenFile('goldens/bar_chart_empty.png'),
    );
  });
}

Future<void> _pump(WidgetTester tester, String name) async {
  final originalDisableShadows = debugDisableShadows;
  debugDisableShadows = true;
  addTearDown(() => debugDisableShadows = originalDisableShadows);

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6B4A)),
      ),
      home: SduiScreen(name: name),
    ),
  );
  await tester.pumpAndSettle();
}
