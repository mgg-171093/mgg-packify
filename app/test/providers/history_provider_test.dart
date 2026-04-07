import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packify/models/package_history_entry.dart';
import 'package:mgg_packify/providers/history_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper — builds a PackageHistoryEntry with only packageName required,
// filling the rest with sensible defaults.
PackageHistoryEntry _entry({
  String ticket = 'TKT-001',
  String ambiente = 'QA',
  String iteracion = '01',
  String? packageName,
  String packageDir = r'C:\Packages',
  DateTime? generatedAt,
}) {
  return PackageHistoryEntry(
    ticket: ticket,
    ambiente: ambiente,
    iteracion: iteracion,
    packageName: packageName ?? '$ticket-PortalRetail_${ambiente}-$iteracion',
    packageDir: packageDir,
    generatedAt: generatedAt ?? DateTime.utc(2026, 4, 1),
  );
}

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() {
    // Reset SharedPreferences to empty state before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('HistoryNotifier — build()', () {
    test('returns empty list when no stored history', () async {
      final container = _makeContainer();
      final entries = await container.read(historyProvider.future);
      expect(entries, isEmpty);
    });

    test('loads entries persisted in SharedPreferences', () async {
      final stored = [
        _entry(ticket: 'INC-100').toJson(),
        _entry(ticket: 'INC-200').toJson(),
      ];
      SharedPreferences.setMockInitialValues({
        'history_entries': jsonEncode(stored),
      });

      final container = _makeContainer();
      final entries = await container.read(historyProvider.future);

      expect(entries.length, 2);
      expect(entries[0].ticket, 'INC-100');
      expect(entries[1].ticket, 'INC-200');
    });
  });

  group('HistoryNotifier — add()', () {
    test('add() prepends entry to the list', () async {
      final container = _makeContainer();
      await container.read(historyProvider.future); // settle build

      final first = _entry(ticket: 'INC-001');
      final second = _entry(ticket: 'INC-002');

      await container.read(historyProvider.notifier).add(first);
      await container.read(historyProvider.notifier).add(second);

      final entries = await container.read(historyProvider.future);
      // Most recent is first
      expect(entries[0].ticket, 'INC-002');
      expect(entries[1].ticket, 'INC-001');
    });

    test('add() caps list at 50 entries, dropping oldest', () async {
      final container = _makeContainer();
      await container.read(historyProvider.future);

      // Add 52 entries
      for (int i = 0; i < 52; i++) {
        await container
            .read(historyProvider.notifier)
            .add(_entry(ticket: 'TKT-${i.toString().padLeft(3, '0')}'));
      }

      final entries = await container.read(historyProvider.future);
      expect(entries.length, 50);
      // The newest (TKT-051) should be first
      expect(entries.first.ticket, 'TKT-051');
      // The oldest added (TKT-000) and (TKT-001) should be dropped
      expect(
        entries.any((e) => e.ticket == 'TKT-000'),
        isFalse,
        reason: 'TKT-000 should have been evicted',
      );
    });

    test('add() persists to SharedPreferences', () async {
      final container = _makeContainer();
      await container.read(historyProvider.future);

      await container
          .read(historyProvider.notifier)
          .add(_entry(ticket: 'PERSIST-001'));

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('history_entries');
      expect(raw, isNotNull);
      final list = jsonDecode(raw!) as List;
      expect(list.first['ticket'], 'PERSIST-001');
    });
  });

  group('HistoryNotifier — delete()', () {
    test('delete() removes entry at given index', () async {
      final container = _makeContainer();
      await container.read(historyProvider.future);

      await container.read(historyProvider.notifier).add(_entry(ticket: 'A'));
      await container.read(historyProvider.notifier).add(_entry(ticket: 'B'));
      await container.read(historyProvider.notifier).add(_entry(ticket: 'C'));
      // List order: [C, B, A]

      await container.read(historyProvider.notifier).delete(1); // remove B

      final entries = await container.read(historyProvider.future);
      expect(entries.length, 2);
      expect(entries.map((e) => e.ticket).toList(), ['C', 'A']);
    });

    test('delete() ignores out-of-bounds index', () async {
      final container = _makeContainer();
      await container.read(historyProvider.future);
      await container.read(historyProvider.notifier).add(_entry(ticket: 'X'));

      // Should not throw
      await container.read(historyProvider.notifier).delete(99);

      final entries = await container.read(historyProvider.future);
      expect(entries.length, 1);
    });
  });

  group('HistoryNotifier — clear()', () {
    test('clear() empties the list', () async {
      final container = _makeContainer();
      await container.read(historyProvider.future);

      await container.read(historyProvider.notifier).add(_entry(ticket: 'A'));
      await container.read(historyProvider.notifier).add(_entry(ticket: 'B'));
      await container.read(historyProvider.notifier).clear();

      final entries = await container.read(historyProvider.future);
      expect(entries, isEmpty);
    });

    test('clear() removes key from SharedPreferences', () async {
      final container = _makeContainer();
      await container.read(historyProvider.future);
      await container.read(historyProvider.notifier).add(_entry(ticket: 'X'));
      await container.read(historyProvider.notifier).clear();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('history_entries'), isNull);
    });
  });
}
