import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packgen/models/generate_result.dart';

void main() {
  // ─────────────────────────────────────────────
  // GenerateResult — copyErrors field
  // ─────────────────────────────────────────────

  group('GenerateResult — copyErrors', () {
    test('copyErrors parses from copy_errors key', () {
      final result = GenerateResult.fromJson({
        'ok': true,
        'package_name': 'INC-1234-PortalRetail_QA-01',
        'package_dir': r'C:\Packages\INC-1234',
        'doc_path': r'C:\Packages\INC-1234\doc.docx',
        'folders_created': [],
        'copy_errors': ['Script not found: V001.sql'],
      });
      expect(result.copyErrors, ['Script not found: V001.sql']);
    });

    test('copyErrors defaults to empty when key missing', () {
      final result = GenerateResult.fromJson({
        'ok': true,
        'package_name': 'INC-1234-PortalRetail_QA-01',
        'package_dir': r'C:\Packages\INC-1234',
        'doc_path': r'C:\Packages\INC-1234\doc.docx',
        'folders_created': [],
      });
      expect(result.copyErrors.isEmpty, isTrue);
    });
  });
}
