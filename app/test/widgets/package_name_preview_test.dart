import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/widgets/package_name_preview.dart';

void main() {
  Widget buildPreview({
    required String ticket,
    required String projectNombre,
    required String ambiente,
    required String iteracion,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PackageNamePreview(
          ticket: ticket,
          projectNombre: projectNombre,
          ambiente: ambiente,
          iteracion: iteracion,
        ),
      ),
    );
  }

  group('PackageNamePreview — name display', () {
    testWidgets('shows full package name when all fields filled', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'MX01-274906',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );
      expect(find.text('MX01-274906-MiProyecto_QA-01'), findsOneWidget);
    });

    testWidgets('zero-pads single-digit iteracion', (tester) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'MX01-001',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '5',
        ),
      );
      expect(find.textContaining('-05'), findsOneWidget);
    });

    testWidgets('shows placeholder dashes when ticket is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: '',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );
      expect(find.textContaining('---'), findsOneWidget);
    });

    testWidgets('shows placeholder dashes when projectNombre is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'MX01-999',
          projectNombre: '',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );
      expect(find.textContaining('---'), findsOneWidget);
    });

    testWidgets('shows placeholder when iteracion is empty', (tester) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'MX01-999',
          projectNombre: 'MiProyecto',
          ambiente: 'PROD',
          iteracion: '',
        ),
      );
      expect(find.textContaining('--'), findsOneWidget);
    });

    testWidgets('updates on different ambiente values', (tester) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'T001',
          projectNombre: 'MiProyecto',
          ambiente: 'PROD',
          iteracion: '02',
        ),
      );
      expect(find.text('T001-MiProyecto_PROD-02'), findsOneWidget);
    });
  });

  group('PackageNamePreview — AnimatedSwitcher', () {
    testWidgets('AnimatedSwitcher is present in widget tree', (tester) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'T001',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('Text child has ValueKey matching the package name', (
      tester,
    ) async {
      const ticket = 'INC-1234';
      const expectedName = 'INC-1234-MiProyecto_QA-01';

      await tester.pumpWidget(
        buildPreview(
          ticket: ticket,
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );

      final textWidget = tester.widget<Text>(find.text(expectedName));
      expect(textWidget.key, equals(const ValueKey(expectedName)));
    });

    testWidgets('ValueKey changes when ticket changes', (tester) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'A-001',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );

      final keyBefore = tester
          .widget<Text>(find.text('A-001-MiProyecto_QA-01'))
          .key;

      await tester.pumpWidget(
        buildPreview(
          ticket: 'B-999',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );
      await tester.pump();

      final keyAfter = tester
          .widget<Text>(find.text('B-999-MiProyecto_QA-01'))
          .key;

      expect(keyBefore, isNot(equals(keyAfter)));
    });
  });

  group('PackageNamePreview — copy button', () {
    testWidgets('copy IconButton is present in widget tree', (tester) async {
      await tester.pumpWidget(
        buildPreview(
          ticket: 'TKT-001',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('tapping copy button shows SnackBar with "Nombre copiado"', (
      tester,
    ) async {
      // Set up clipboard mock
      final List<MethodCall> log = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          log.add(call);
          return null;
        },
      );

      await tester.pumpWidget(
        buildPreview(
          ticket: 'TKT-002',
          projectNombre: 'MiProyecto',
          ambiente: 'QA',
          iteracion: '01',
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.text('Nombre copiado'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, theme.colorScheme.primaryContainer);
    });
  });
}
