import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/settings_model.dart';

class SettingsNotifier extends AsyncNotifier<SettingsModel> {
  @override
  Future<SettingsModel> build() async {
    try {
      return await ref.read(apiClientProvider).getSettings();
    } catch (_) {
      // API may not be ready yet on first load — return empty
      return SettingsModel.empty();
    }
  }

  Future<void> save(SettingsModel settings) async {
    state = const AsyncLoading();
    try {
      await ref.read(apiClientProvider).putSettings(settings);
      state = AsyncData(settings);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  void clear() {
    state = AsyncData(SettingsModel.empty());
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsModel>(
  SettingsNotifier.new,
);
