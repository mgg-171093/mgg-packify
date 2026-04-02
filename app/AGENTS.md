# AGENTS.md — Flutter App

Context for AI agents working on the Flutter desktop app of mgg-packgen v3.

## Overview

Flutter Windows desktop app. Spawns the Python FastAPI backend as a child process and
communicates via HTTP REST on `localhost:8787`.

## Running

```bash
cd app
flutter run -d windows         # run in debug mode
flutter build windows          # production build
flutter test                   # run all 96 tests
flutter test test/path/file.dart  # single test file
```

## Package Layout

```
app/lib/
├── main.dart          ← Entry point: WidgetsFlutterBinding, ProviderScope, lifecycle
├── app.dart           ← go_router config + ThemeData (Material3, seed #70AD47)
├── core/
│   ├── api_client.dart    ← ApiClient class + apiClientProvider
│   ├── constants.dart     ← kApiPort, kBaseUrl, brand colors
│   └── server_manager.dart← Process spawn/kill, dev-mode port check
├── models/
│   ├── component_config.dart  ← ComponentConfig (UI model)
│   ├── generate_result.dart   ← GenerateResult (API response)
│   ├── options_model.dart     ← OptionsModel (estatus/tipo lists)
│   ├── package_config.dart    ← PackageConfig (form data)
│   ├── package_list_item.dart ← PackageListItem (for clone screen)
│   └── settings_model.dart    ← SettingsModel (server config)
├── providers/
│   ├── clone_list_provider.dart   ← package list for CloneScreen
│   ├── options_provider.dart      ← OptionsNotifier (estatus/tipo lists)
│   ├── package_form_provider.dart ← PackageFormNotifier (new package form)
│   ├── server_status_provider.dart← API health polling
│   └── settings_provider.dart     ← SettingsNotifier (server config)
├── screens/
│   ├── splash_screen.dart    ← health poll → go('/home')
│   ├── home_screen.dart      ← package list + action buttons
│   ├── new_package_screen.dart← main form: ticket, ambiente, componentes
│   ├── clone_screen.dart     ← pick existing package, new iteracion
│   ├── settings_screen.dart  ← Servidores tab + Opciones tab
│   └── success_screen.dart   ← result display, open in Explorer
└── widgets/
    ├── component_detail_card.dart ← per-component form (estatus, tipo dropdowns)
    ├── component_selector.dart    ← component type picker
    ├── package_name_preview.dart  ← live preview of generated name
    └── server_form.dart           ← server URL input fields
```

## Critical Rules

### Navigation — FLAT router, NO stack

```dart
// ✅ CORRECT
context.go('/home');
context.go('/settings');
context.go('/success', extra: result);

// ❌ WRONG — NEVER DO THIS
Navigator.pop(context);
context.pop();
```

go_router is configured flat in `app.dart`. There is no navigation stack.
Every "back" button must call `context.go('/home')` or the appropriate parent route.

### State Management — Riverpod AsyncNotifier

```dart
// ✅ CORRECT — custom save() method
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

// ❌ WRONG — update() is a reserved Riverpod framework method
await update((current) => newValue);  // DO NOT USE
```

All providers follow the same pattern: `AsyncNotifier<T>` with a `build()` that loads
from the API, and a `save()` / action methods for mutations.

## Provider Pattern Example

```dart
class SettingsNotifier extends AsyncNotifier<SettingsModel> {
  @override
  Future<SettingsModel> build() async {
    try {
      return await ref.read(apiClientProvider).getSettings();
    } catch (_) {
      return SettingsModel.empty();  // fallback when API not ready
    }
  }

  Future<void> save(SettingsModel settings) async { ... }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsModel>(
  SettingsNotifier.new,
);
```

## Route Table

| Route | Screen | `state.extra` | "Back" target |
|-------|--------|---------------|---------------|
| `/splash` | `SplashScreen` | — | — |
| `/home` | `HomeScreen` | — | — |
| `/new-package` | `NewPackageScreen` | — | `/home` |
| `/success` | `SuccessScreen` | `GenerateResult` | `/home` |
| `/clone` | `CloneScreen` | — | `/home` |
| `/settings` | `SettingsScreen` | — | `/home` |

## API Client Usage

All API calls go through `ApiClient` (injected via `apiClientProvider`).
Always use `ref.read(apiClientProvider)` — never instantiate `ApiClient` directly.

```dart
// In a notifier
final result = await ref.read(apiClientProvider).generatePackage(config);

// Error handling — ApiException is thrown on non-2xx
try {
  await ref.read(apiClientProvider).putSettings(settings);
} on ApiException catch (e) {
  // e.message — human-readable message
  // e.statusCode — HTTP status code (nullable)
}
```

## ServerManager — Process Lifecycle

`ServerManager` is created in `main()` and injected via `ProviderScope.overrides`.
The `_AppWithLifecycle` widget observes `AppLifecycleState.detached` to call `stop()`.

Dev mode behavior:
1. Checks if port 8787 is already listening (300ms timeout)
2. If yes → skips launching (you can run API separately from VS Code)
3. If no → launches `python -m mgg_packgen_api.main` from `api/` working directory
4. Env var `MGG_API_PATH` overrides path resolution

## Theme

Material 3, seed color `#70AD47` (verde Skandia). Key brand colors in `constants.dart`:

```dart
const Color kGreenPrimary   = Color(0xFF70AD47);  // primary
const Color kGreenLight     = Color(0xFFC5E0B3);  // accents
const Color kGreenVeryLight = Color(0xFFE2EFD9);  // backgrounds
const Color kBlue           = Color(0xFF4472C4);  // secondary
```

## Test Structure

```
app/test/
├── models/
│   ├── package_config_test.dart
│   ├── settings_model_test.dart
│   └── ...
├── providers/
│   ├── settings_provider_test.dart
│   └── ...
├── screens/
│   ├── home_screen_test.dart
│   └── ...
└── widgets/
    ├── component_detail_card_test.dart
    └── ...
```

Tests use `mockito` for mocking (generated with `build_runner`).
After adding/changing mocks: `dart run build_runner build --delete-conflicting-outputs`

## Gotchas

- `AsyncNotifier.update()` is a Riverpod-reserved method — calling it causes an error
- go_router is flat: `Navigator.pop()` will crash or behave unexpectedly
- `ServerManager` is overridden in `ProviderScope` in `main.dart` — do NOT add a default implementation that creates a process
- `SuccessScreen` requires `state.extra as GenerateResult` — always pass it via `context.go('/success', extra: result)`
- `ComponentDetailCard` uses `TextEditingController`s stored in widget state (not local build vars) — critical for avoiding input reversal bugs
