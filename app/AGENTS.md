# AGENTS.md — Flutter App

Context for AI agents working on the Flutter desktop app of MGG-Packify.
See also: [Root AGENTS.md](../AGENTS.md) for domain rules, component types, and package name format.

---

## Critical Rules — READ FIRST

| Rule | What to do | What NOT to do |
|------|------------|----------------|
| **Navigation** | `context.go('/route')` always | `Navigator.pop(context)` / `context.pop()` — crashes flat router |
| **State mutation** | Custom `save()` / action methods | `await update(...)` — reserved Riverpod framework method |
| **ApiClient** | `ref.read(apiClientProvider)` | `ApiClient()` directly — breaks test injection |
| **ServerManager** | Injected via `ProviderScope.overrides` in `main.dart` | Default impl that spawns a process — will double-spawn |
| **Dialog close** | `Navigator.of(ctx).pop()` inside dialog builder ✅ | This is the ONLY permitted Navigator use — closes dialog, not route |

> **Dialog exception**: `Navigator.of(ctx).pop()` is correct and necessary inside `AlertDialog` / `showDialog` builders. It closes the dialog overlay, not the route. This does NOT violate the `context.go()` rule.

---

## Running

```bash
cd app
flutter run -d windows              # run in debug mode
flutter build windows               # production build
flutter test                        # run all 161 tests
flutter test test/path/file.dart    # single test file
dart run build_runner build --delete-conflicting-outputs  # regenerate mocks
```

---

## Package Layout

```
app/lib/
├── main.dart            ← Entry point: WidgetsFlutterBinding, ProviderScope, lifecycle
├── app.dart             ← go_router config + ThemeData (Material3, seed Colors.blue)
├── core/
│   ├── api_client.dart      ← ApiClient class + apiClientProvider
│   ├── constants.dart       ← kApiPort (8787), kBaseUrl
│   └── server_manager.dart  ← Process spawn/kill, dev-mode port check
├── models/              (8 files — see Models section)
├── providers/           (8 files — see Providers section)
├── screens/             (7 files — see Screens section)
└── widgets/             (5 files — see Widgets section)
```

---

## Route Table

| Route | Screen | `state.extra` | Back target | Transition |
|-------|--------|---------------|-------------|------------|
| `/splash` | `SplashScreen` | — | — | Fade 250ms |
| `/home` | `HomeScreen` | — | — | Fade 250ms |
| `/new-package` | `NewPackageScreen` | — | `/home` | Slide right 300ms |
| `/success` | `SuccessScreen` | `GenerateResult` (required) | `/home` | Slide right 300ms |
| `/clone` | `CloneScreen` | — | `/home` | Slide right 300ms |
| `/settings` | `SettingsScreen` | — | `/home` | Slide right 300ms |
| `/history` | `HistoryScreen` | — | `/home` | Slide right 300ms |

---

## Screens

### SplashScreen (`/splash`)

**Description**: Entry screen. Starts the Python FastAPI server and polls `GET /health` every 500ms.  
**Route**: `/splash`  
**Provider deps**: `serverManagerProvider`, `serverStatusProvider`, `apiClientProvider`  
**Key interactions**:
- Calls `serverManagerProvider.start()` on `initState`
- Polls up to 20 attempts (10 seconds) via `Timer.periodic(500ms)`
- On success → `context.go('/home')`; on timeout → shows error + retry button
- `serverStatusProvider` (`StateProvider<ServerStatus>`) is set to `starting`, `ready`, or `error`

---

### HomeScreen (`/home`)

**Description**: Landing screen with app branding, action buttons, and template quick-apply.  
**Route**: `/home`  
**Provider deps**: `packageFormProvider`, `templatesProvider`  
**Key interactions**:
- Buttons: New Package → `context.go('/new-package')`, Clone → `context.go('/clone')`, History → `context.go('/history')`, Settings → `context.go('/settings')`
- Shows saved templates list; tapping a template calls `packageFormProvider.notifier.applyTemplate(t)` then navigates to `/new-package`
- Constrained to `maxWidth: 480`

---

### NewPackageScreen (`/new-package`)

**Description**: Main form for creating a new installation package. The largest screen in the app.  
**Route**: `/new-package`  
**Provider deps**: `packageFormProvider`, `settingsProvider`, `optionsProvider`, `historyProvider`, `templatesProvider`, `apiClientProvider`  
**Key interactions**:
- Fields: ticket, HU nombre, ambiente (dropdown), iteracion, ruta packages (folder picker)
- Shows `PackageNamePreview` (live preview, copy button)
- Uses `ComponentSelector` to pick component types, then `ComponentDetailCard` per selected type
- "Generar" button opens `GenerationProgressDialog` → POST `/packages/generate`
- On success: saves to `historyProvider`, shows Windows toast (`local_notifier`), navigates to `/success`
- Has `TextEditingController`s for form fields; syncs with `packageFormProvider` state

---

### SuccessScreen (`/success`)

**Description**: Displays generation result with package name, output path, and action buttons.  
**Route**: `/success`  
**`state.extra`**: `GenerateResult` — **REQUIRED**; always pass via `context.go('/success', extra: result)`  
**Provider deps**: `packageFormProvider` (for reset)  
**Key interactions**:
- Shows package name (monospace), output folder path, component count
- "Abrir carpeta" button → `url_launcher` opens the folder in Windows Explorer
- "Nuevo package" → resets `packageFormProvider`, navigates to `/home`
- Back button → `context.go('/home')` (NOT `context.pop()`)

---

### CloneScreen (`/clone`)

**Description**: Picks an existing package folder and clones it with a new iteration number.  
**Route**: `/clone`  
**Provider deps**: `cloneListProvider` (family), `packageFormProvider`, `settingsProvider`  
**Key interactions**:
- Folder picker for source path; lists packages via `cloneListProvider(sourcePath)`
- User selects a package and enters a new `iteracion`; iteration default is `'02'`
- On submit: POST `/packages/clone` → `packageFormProvider.prefill(data)` → `context.go('/new-package')`
- Auto-increments iteration using regex `r'-(\d{2})$'` on the package name

---

### SettingsScreen (`/settings`)

**Description**: 5-tab configuration screen. Two tabs have save/clear action bar; three auto-save.  
**Route**: `/settings`  
**Provider deps**: `settingsProvider`, `optionsProvider`, `themeModeProvider`  
**Tabs**:

| # | Tab | Content | Save behavior |
|---|-----|---------|---------------|
| 0 | Servidores QA | 4 server fields (API, BD, Blob, Liferay) for QA env | Manual save button |
| 1 | Servidores PROD | 4 server fields for PROD env | Manual save button |
| 2 | Opciones | Estatus list, SQL tipo list, Blob tipo list editor | Auto-save on change |
| 3 | Servicios API | `api_iis_services`, `api_docker_services`, `sql_databases` lists | Auto-save on change |
| 4 | Apariencia | Dark/Light/System theme toggle | Auto-save on change |

**Key notes**:
- `ConsumerStatefulWidget` with `TabController(length: 5)` and 8 `TextEditingController`s for server fields
- `_ActionBar` (save/clear buttons) only renders for tabs 0–1; other tabs auto-save via `optionsProvider.notifier.save()` or `themeModeProvider.notifier.setMode()`
- Back button always `context.go('/home')`

---

### HistoryScreen (`/history`)

**Description**: Displays the last 50 generated packages. Swipe to delete, tap to re-generate.  
**Route**: `/history`  
**Provider deps**: `historyProvider`, `packageFormProvider`  
**Key interactions**:
- `ListView` of `Dismissible` cards (swipe `endToStart` to delete)
- Swipe shows confirmation `AlertDialog` (uses `Navigator.of(ctx).pop()` — valid dialog use)
- Tap on entry → `packageFormProvider.notifier.prefillFromHistory(entry)` → `context.go('/new-package')`
- "Limpiar historial" action button (trash icon) in AppBar — clears all entries after confirmation
- Empty state: shows history icon + descriptive message
- **`prefillFromHistory` only fills ticket, HU nombre, ambiente, iteracion, and ruta** — does NOT restore component types/instances

---

## Widgets

### ComponentDetailCard

**File**: `widgets/component_detail_card.dart` (1162 lines)  
**Type**: `StatefulWidget` with `SingleTickerProviderStateMixin`  
**Purpose**: Renders per-type form fields for each component type with collapsible card, instance management.

**Key implementation notes**:
- Uses `AnimationController` + `SizeTransition` for expand/collapse animation (250ms `easeInOut`)
- Header tap toggles `_isExpanded` and drives `_animController.forward()` / `reverse()`
- Per-type field dispatch happens in `_InstanceFields` — each `ComponentType` renders different fields
- Multi-instance types show "Instancia N" headers and "Eliminar instancia" buttons
- `liferay_build` is single-instance (not multi-instance)
- **`TextEditingController`s are stored in `_InstanceFieldsState` — NOT created as local build vars** (critical: prevents input reversal bugs)
- `_InstanceFields.didUpdateWidget` syncs controllers when parent passes new instance data (e.g., after prefill from clone) — uses `.text = value` without cursor reset
- Accepts callbacks: `onAdd`, `onRemove(index)`, `onUpdate(index, updated)` — all delegate to `packageFormProvider.notifier`

---

### ComponentSelector

**File**: `widgets/component_selector.dart` (41 lines)  
**Type**: `StatelessWidget`  
**Purpose**: Renders a `Wrap` of `FilterChip` widgets for selecting component types.

**Key notes**:
- Iterates `kCanonicalComponentOrder` (defined in `models/component_config.dart`) — always renders chips in canonical type order
- Selected chips use `colorScheme.primary` background; unselected use `Colors.grey.shade100`
- Calls `onToggle(ComponentType)` callback — delegated to `packageFormProvider.notifier.toggleComponent(type)`
- Preserves instance data on deselect/reselect (handled at notifier level, not widget level)

---

### PackageNamePreview

**File**: `widgets/package_name_preview.dart` (80 lines)  
**Type**: `StatelessWidget`  
**Purpose**: Live preview of the generated package name; copy to clipboard button.

**Preview formula**:
```dart
'$ticket-PortalRetail_$ambiente-${iteracion.padLeft(2, '0')}'
// Placeholders: '---' for empty ticket/ambiente, '--' for empty iteracion
```

**Key notes**:
- Uses `AnimatedSwitcher(duration: 200ms)` with `ValueKey(name)` for smooth text transitions on each keystroke
- Copy button calls `Clipboard.setData` and shows a `SnackBar('Nombre copiado')`
- Pure display widget — receives `ticket`, `ambiente`, `iteracion` as params; no provider access

---

### GenerationProgressDialog

**File**: `widgets/generation_progress_dialog.dart` (306 lines)  
**Type**: `StatefulWidget`  
**Purpose**: Modal dialog with animated step list and progress bar while the generate API call runs.

**Key implementation notes**:
- Shows 4 optimistic steps: Validando, Creando carpetas, Generando documento, Guardando
- `Timer.periodic(600ms)` advances steps optimistically — independent of actual API completion time
- On `initState`: starts timer AND attaches `.then()` / `.catchError()` to `generateFuture`
- On API complete: cancels timer, marks remaining steps done (or error), then calls `widget.onDone(result)` after **300ms delay** (let user see final state)
- On error: marks all pending/inProgress steps as `StepStatus.error` with error message
- **Does NOT use `Navigator.pop()` internally** — parent is responsible for closing via `onDone` callback

```dart
// Usage in NewPackageScreen
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) => GenerationProgressDialog(
    stepLabels: [...],
    generateFuture: apiClient.generatePackage(config),
    onDone: (result) {
      Navigator.of(context).pop();  // ✅ valid — closes dialog, not route
      context.go('/success', extra: result);
    },
  ),
);
```

---

### ServerForm

**File**: `widgets/server_form.dart` (151 lines)  
**Type**: `StatefulWidget`  
**Purpose**: Dynamic server URL fields (API, BD, Blob, Liferay) shown contextually based on selected component types.

**Key notes**:
- Conditionally shows each field: API fields for `apiIis`/`apiDocker`/`apim`; BD for `sql`; Blob for `blob`; Liferay for `liferay`/`assets`
- `didUpdateWidget` updates controller `.text` when parent changes `serverConfig` (e.g., prefill from settings) — preserves cursor
- Shows "Seleccioná al menos un componente" when no relevant types are selected

---

## Providers

### Provider Reference Table

| Provider | File | Riverpod type | Persistence | Key methods |
|----------|------|---------------|-------------|-------------|
| `packageFormProvider` | `package_form_provider.dart` | `NotifierProvider<PackageFormNotifier, PackageFormState>` | In-memory only | `updateTicket`, `toggleComponent`, `addInstance`, `removeInstance`, `updateInstance`, `prefill`, `prefillFromHistory`, `applyTemplate`, `reset` |
| `settingsProvider` | `settings_provider.dart` | `AsyncNotifierProvider<SettingsNotifier, SettingsModel>` | API → `%APPDATA%\mgg_packgen_api\config.json` | `save(settings)`, `clear()` |
| `optionsProvider` | `options_provider.dart` | `AsyncNotifierProvider<OptionsNotifier, OptionsModel>` | API → `%APPDATA%\mgg_packgen_api\options.json` | `save(options)` |
| `historyProvider` | `history_provider.dart` | `AsyncNotifierProvider<HistoryNotifier, List<PackageHistoryEntry>>` | SharedPreferences key: `history_entries` (cap 50) | `add(entry)`, `delete(index)`, `clear()` |
| `templatesProvider` | `templates_provider.dart` | `AsyncNotifierProvider<TemplatesNotifier, List<PackageTemplate>>` | SharedPreferences key: `templates_list` | `save(template)`, `delete(index)` |
| `themeModeProvider` | `theme_mode_provider.dart` | `AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>` | SharedPreferences key: `theme_mode` | `setMode(mode)`, `toggle()` |
| `serverStatusProvider` | `server_status_provider.dart` | `StateProvider<ServerStatus>` | In-memory only | Set via `.notifier.state = ...` |
| `cloneListProvider` | `clone_list_provider.dart` | `FutureProvider.family<List<PackageListItem>, String>` | No persistence (API call) | Parameterized by `baseDir` string |

### Critical Provider Gotchas

- **`packageFormProvider` is `Notifier` (sync), NOT `AsyncNotifier`** — `build()` returns `PackageFormState` directly, no `async`. Do NOT treat it as async.
- **`cloneListProvider` is `FutureProvider.family`** — must pass `baseDir` as parameter: `ref.watch(cloneListProvider(baseDir))`
- **`serverStatusProvider` is `StateProvider`** — mutate directly: `ref.read(serverStatusProvider.notifier).state = ServerStatus.ready`
- **`AsyncNotifier.update()` is FORBIDDEN** — use custom `save()` methods in all `AsyncNotifier` subclasses
- **`historyProvider.add()`** prepends entries and caps at 50; older entries beyond 50 are dropped
- **`templatesProvider.save()`** appends; no cap — user manages manually

---

## Models

| Model | File | Description |
|-------|------|-------------|
| `ComponentConfig` | `component_config.dart` | `ComponentType` enum (8 types), `ComponentInstanceState`, `kCanonicalComponentOrder` list, `ServerConfig` |
| `PackageConfig` | `package_config.dart` | Form data for the generate API request; serializes to JSON |
| `SettingsModel` | `settings_model.dart` | Server config (QA/PROD) with `ServerEnvironment` nested model |
| `GenerateResult` | `generate_result.dart` | API response: `packageName`, `packageDir`, `docxPath`, `success`, `error` |
| `OptionsModel` | `options_model.dart` | Lists: `estatusList`, `tipoSqlList`, `tipoBlobList`, `apiIisServices`, `apiDockerServices`, `sqlDatabases` |
| `PackageHistoryEntry` | `package_history_entry.dart` | History record: `packageName`, `ticket`, `huNombre`, `ambiente`, `iteracion`, `packageDir`, `generatedAt` |
| `PackageTemplate` | `package_template.dart` | Template: `name`, `selectedTypes` (as List\<String\>); `instancesJson` saved as `[]` (instances not persisted) |
| `PackageListItem` | `package_list_item.dart` | Clone screen list item: `name`, `path` |

---

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

---

## ServerManager — Process Lifecycle

`ServerManager` is created in `main()` and injected via `ProviderScope.overrides`.
The `_AppWithLifecycle` widget observes `AppLifecycleState.detached` to call `stop()`.

Dev mode behavior:
1. Checks if port 8787 is already listening (300ms timeout)
2. If yes → skips launching (you can run API separately from VS Code)
3. If no → launches `python -m mgg_packgen_api.main` from `api/` working directory
4. Env var `MGG_API_PATH` overrides path resolution

---

## Theme

Material 3, seed `Colors.blue` (system-default blue). Light and dark themes defined in `app.dart`.

```dart
// app.dart — both light and dark themes
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blue,
  brightness: Brightness.light,  // or Brightness.dark
)
```

Dark/light/system mode controlled by `themeModeProvider` (Apariencia tab in Settings).

---

## Test Structure

```text
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

---

## Gotchas

- **`AsyncNotifier.update()` forbidden** — Riverpod-reserved method; calling it causes silent errors
- **`Navigator.pop()` crashes flat router** — only exception: inside `showDialog` builder (closes dialog, not route)
- **`SuccessScreen` requires `state.extra`** — always `context.go('/success', extra: result)` or it crashes on cast
- **`ComponentDetailCard` controllers in state, not `build()`** — creating `TextEditingController` in `build()` causes focus/cursor reversal on rebuild; always initialize in `initState()`
- **`cloneListProvider` requires `baseDir` param** — calling without param will not compile
- **`ServerManager` has no default impl** — overridden in `main.dart`; DO NOT add a fallback constructor that spawns a process
- **`PackageTemplate.instancesJson` is always `[]`** — templates save selected component types but NOT instance data (known limitation)
- **`constants.dart` only has `kApiPort` and `kBaseUrl`** — brand colors (`kGreenPrimary`, etc.) referenced in older docs are not present; theme uses `Colors.blue` seed
- **`prefillFromHistory` restores partial state only** — fills ticket/HU/ambiente/iteracion/ruta but not component types or instances
- **Settings tabs 0–1 require manual save; tabs 2–4 auto-save** — if you add a new settings field, match the appropriate save pattern
