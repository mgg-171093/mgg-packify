import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/package_template.dart';

const _kTemplatesKey = 'templates_list';

class TemplatesNotifier extends AsyncNotifier<List<PackageTemplate>> {
  @override
  Future<List<PackageTemplate>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTemplatesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PackageTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(PackageTemplate template) async {
    final current = state.valueOrNull ?? [];
    final updated = [...current, template];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kTemplatesKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(updated);
  }

  Future<void> delete(int index) async {
    final current = List<PackageTemplate>.from(state.valueOrNull ?? []);
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kTemplatesKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(current);
  }
}

final templatesProvider =
    AsyncNotifierProvider<TemplatesNotifier, List<PackageTemplate>>(
      TemplatesNotifier.new,
    );
