import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_client/sdui_client.dart';

import 'support/php_core_fixtures.dart';

void main() {
  setUpAll(() async {
    final screens = {
      for (final name in ['home', 'details']) name: loadPhpCoreFixture(name),
    };
    await Sdui.initialize(
      config: SduiConfig(
        source: SduiScreenSource.asset,
        screenRepository: MemoryScreenRepository(screens),
        onNavigateScreen: (context, screen, {style = 'push'}) {},
        onLogout: () {},
      ),
    );
  });

  tearDownAll(Sdui.reset);

  testWidgets('home PHP snapshot renders through Stac', (tester) async {
    await _pumpFixture(tester, 'home');

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/php_core_home.png'),
    );
  });

  testWidgets('details PHP snapshot renders through Stac', (tester) async {
    await _pumpFixture(tester, 'details');

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('This screen was opened from JSON.'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/php_core_details.png'),
    );
  });
}

Future<void> _pumpFixture(WidgetTester tester, String name) async {
  final originalDisableShadows = debugDisableShadows;
  debugDisableShadows = true;
  addTearDown(() => debugDisableShadows = originalDisableShadows);

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: SduiScreen(name: name),
    ),
  );
  await tester.pumpAndSettle();
}
