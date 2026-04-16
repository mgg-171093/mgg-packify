import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/screens/about_screen.dart';

void main() {
  testWidgets('renders app identity and update action', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(0.3)),
            child: AboutScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MGG Packify'), findsOneWidget);
    expect(find.text('Buscar actualizaciones'), findsOneWidget);
  });
}
