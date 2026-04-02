import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgg_packgen/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeModeNotifier — build()', () {
    test('defaults to ThemeMode.system when no stored value', () async {
      final container = _makeContainer();
      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.system);
    });

    test('returns ThemeMode.dark when "dark" stored', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final container = _makeContainer();
      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.dark);
    });

    test('returns ThemeMode.light when "light" stored', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final container = _makeContainer();
      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.light);
    });

    test('returns ThemeMode.system for unknown stored value', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'bogus'});
      final container = _makeContainer();
      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.system);
    });
  });

  group('ThemeModeNotifier — setMode()', () {
    test('setMode(dark) updates state to dark', () async {
      final container = _makeContainer();
      await container.read(themeModeProvider.future);

      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.dark);
    });

    test('setMode(light) updates state to light', () async {
      final container = _makeContainer();
      await container.read(themeModeProvider.future);

      await container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.light);
    });

    test('setMode(dark) persists "dark" string to SharedPreferences', () async {
      final container = _makeContainer();
      await container.read(themeModeProvider.future);

      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test(
      'setMode(light) persists "light" string to SharedPreferences',
      () async {
        final container = _makeContainer();
        await container.read(themeModeProvider.future);

        await container
            .read(themeModeProvider.notifier)
            .setMode(ThemeMode.light);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'light');
      },
    );

    test(
      'setMode(system) persists "system" string to SharedPreferences',
      () async {
        final container = _makeContainer();
        await container.read(themeModeProvider.future);

        await container
            .read(themeModeProvider.notifier)
            .setMode(ThemeMode.system);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'system');
      },
    );
  });

  group('ThemeModeNotifier — toggle()', () {
    test('toggle() switches from light to dark', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final container = _makeContainer();
      await container.read(themeModeProvider.future);

      await container.read(themeModeProvider.notifier).toggle();

      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.dark);
    });

    test('toggle() switches from dark to light', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final container = _makeContainer();
      await container.read(themeModeProvider.future);

      await container.read(themeModeProvider.notifier).toggle();

      final mode = await container.read(themeModeProvider.future);
      expect(mode, ThemeMode.light);
    });
  });
}
