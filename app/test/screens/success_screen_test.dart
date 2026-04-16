import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/models/generate_result.dart';
import 'package:mgg_packify/screens/success_screen.dart';

void main() {
  testWidgets('uses semantic colors for warning and folder accents', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const result = GenerateResult(
      ok: true,
      packageName: 'INC-1234-Proyecto_QA-01',
      packageDir: r'C:\packages\INC-1234-Proyecto_QA-01',
      docPath: r'C:\packages\INC-1234-Proyecto_QA-01\archivo.docx',
      foldersCreated: [],
      copyErrors: ['script_01.sql no se pudo copiar'],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SuccessScreen(result: result)),
      ),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(SuccessScreen)));

    final folderIcon = tester.widget<Icon>(
      find.byIcon(Icons.folder_open_outlined),
    );
    expect(folderIcon.color, theme.colorScheme.secondary);

    final warningIcon = tester.widget<Icon>(
      find.byIcon(Icons.warning_amber_rounded),
    );
    expect(warningIcon.color, theme.colorScheme.onSecondaryContainer);

    final errorIcon = tester.widget<Icon>(
      find.byIcon(Icons.error_outline).first,
    );
    expect(errorIcon.color, theme.colorScheme.onSecondaryContainer);
  });
}
