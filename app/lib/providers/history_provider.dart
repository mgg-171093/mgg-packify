import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/package_history_entry.dart';

const _kHistoryKey = 'history_entries';
const _kHistoryCap = 50;

class HistoryNotifier extends AsyncNotifier<List<PackageHistoryEntry>> {
  @override
  Future<List<PackageHistoryEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHistoryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PackageHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(PackageHistoryEntry entry) async {
    final current = state.valueOrNull ?? [];
    final updated = [entry, ...current];
    final capped = updated.length > _kHistoryCap
        ? updated.sublist(0, _kHistoryCap)
        : updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(capped.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(capped);
  }

  Future<void> delete(int index) async {
    final current = List<PackageHistoryEntry>.from(state.valueOrNull ?? []);
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(current);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistoryKey);
    state = const AsyncData([]);
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<PackageHistoryEntry>>(
      HistoryNotifier.new,
    );
