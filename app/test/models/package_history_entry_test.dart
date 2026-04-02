import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packgen/models/package_history_entry.dart';

void main() {
  group('PackageHistoryEntry', () {
    // ── fromJson ─────────────────────────────────

    test('fromJson parses all fields correctly', () {
      final entry = PackageHistoryEntry.fromJson({
        'ticket': 'INC-1234',
        'ambiente': 'QA',
        'iteracion': '03',
        'packageName': 'INC-1234-PortalRetail_QA-03',
        'packageDir': r'C:\Packages\INC-1234-PortalRetail_QA-03',
        'generatedAt': '2026-04-01T10:30:00.000Z',
      });

      expect(entry.ticket, 'INC-1234');
      expect(entry.ambiente, 'QA');
      expect(entry.iteracion, '03');
      expect(entry.packageName, 'INC-1234-PortalRetail_QA-03');
      expect(entry.packageDir, r'C:\Packages\INC-1234-PortalRetail_QA-03');
      expect(entry.generatedAt, DateTime.parse('2026-04-01T10:30:00.000Z'));
    });

    // ── toJson ───────────────────────────────────

    test('toJson serializes all fields correctly', () {
      final dt = DateTime.utc(2026, 4, 1, 10, 30);
      final entry = PackageHistoryEntry(
        ticket: 'MX01-9999',
        ambiente: 'PROD',
        iteracion: '01',
        packageName: 'MX01-9999-PortalRetail_PROD-01',
        packageDir: r'C:\Packages\MX01-9999-PortalRetail_PROD-01',
        generatedAt: dt,
      );

      final json = entry.toJson();

      expect(json['ticket'], 'MX01-9999');
      expect(json['ambiente'], 'PROD');
      expect(json['iteracion'], '01');
      expect(json['packageName'], 'MX01-9999-PortalRetail_PROD-01');
      expect(json['packageDir'], r'C:\Packages\MX01-9999-PortalRetail_PROD-01');
      expect(json['generatedAt'], dt.toIso8601String());
    });

    // ── round-trip ───────────────────────────────

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = {
        'ticket': 'TKT-0042',
        'ambiente': 'UAT',
        'iteracion': '02',
        'packageName': 'TKT-0042-PortalRetail_UAT-02',
        'packageDir': r'C:\Packages\TKT-0042-PortalRetail_UAT-02',
        'generatedAt': '2026-03-15T08:00:00.000',
      };

      final entry = PackageHistoryEntry.fromJson(original);
      final roundTripped = entry.toJson();

      expect(roundTripped['ticket'], original['ticket']);
      expect(roundTripped['ambiente'], original['ambiente']);
      expect(roundTripped['iteracion'], original['iteracion']);
      expect(roundTripped['packageName'], original['packageName']);
      expect(roundTripped['packageDir'], original['packageDir']);
      // generatedAt may differ slightly in format (ISO8601) — compare as DateTime
      expect(
        DateTime.parse(roundTripped['generatedAt'] as String),
        DateTime.parse(original['generatedAt'] as String),
      );
    });

    // ── generatedAt ISO8601 ───────────────────────

    test('generatedAt is stored as ISO8601 string in toJson', () {
      final dt = DateTime(2026, 1, 15, 9, 5, 0);
      final entry = PackageHistoryEntry(
        ticket: 'T',
        ambiente: 'QA',
        iteracion: '01',
        packageName: 'T-PortalRetail_QA-01',
        packageDir: '/tmp',
        generatedAt: dt,
      );

      final json = entry.toJson();
      final iso = json['generatedAt'] as String;
      // Must be parseable back to same DateTime
      expect(DateTime.parse(iso), dt);
      // Must contain the ISO8601 separator 'T'
      expect(iso, contains('T'));
    });
  });
}
