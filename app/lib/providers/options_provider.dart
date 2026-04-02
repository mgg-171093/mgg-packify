import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/options_model.dart';

class OptionsNotifier extends AsyncNotifier<OptionsModel> {
  @override
  Future<OptionsModel> build() async {
    try {
      return await ref.read(apiClientProvider).getOptions();
    } catch (_) {
      // API may not be ready yet on first load — return defaults
      return OptionsModel.empty();
    }
  }

  Future<void> save(OptionsModel options) async {
    state = const AsyncLoading();
    try {
      final updated = await ref.read(apiClientProvider).putOptions(options);
      state = AsyncData(updated);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final optionsProvider = AsyncNotifierProvider<OptionsNotifier, OptionsModel>(
  OptionsNotifier.new,
);
