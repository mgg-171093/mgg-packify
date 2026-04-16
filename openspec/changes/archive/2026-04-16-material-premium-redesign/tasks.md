# Tasks: Material Premium Redesign

## Phase 1: Theme Foundation and Shared Tokens

Goal: establish one premium Material baseline used by all screens.
Scope: app-wide theme, color identity, typography, shape, motion tokens.
File groups: `app/lib/app.dart`, `app/lib/core/theme/*.dart`, `app/test/core/theme/*.dart`.
Validation checkpoint: light/dark themes render with Deep Orange identity and extensions loaded; `flutter test` green.
Releasable/versionable outcome: **v1 Theme Foundation** (all screens inherit premium branding without behavior changes).

- [x] 1.1 Create `app/lib/core/theme/app_theme.dart` with `appTheme(Brightness)` using `ColorScheme.fromSeed(seedColor: Colors.deepOrange)` and shared input/card/app bar defaults.
- [x] 1.2 Create `app/lib/core/theme/theme_extensions.dart` with `PremiumEffects` and `SurfaceTokens` (`copyWith`/`lerp` included).
- [x] 1.3 Refactor `app/lib/app.dart` to consume `appTheme()` for light/dark and register theme extensions.
- [x] 1.4 Add/adjust theme tests in `app/test/core/theme/app_theme_test.dart` to verify seed identity, extension presence, and brightness safety.

## Phase 2: Shell, Navigation Hierarchy, and Desktop Interaction States

Goal: make global navigation clearly premium and desktop-native.
Scope: sidebar hierarchy, active-route indicator, hover/focus/disabled/cursor treatment.
File groups: `app/lib/widgets/app_shell.dart`, `app/test/widgets/app_shell_test.dart`.
Validation checkpoint: active destination is always obvious, hover/focus states are distinct, route behavior unchanged (`context.go`).
Releasable/versionable outcome: **v2 Premium Navigation Shell**.

- [x] 2.1 Update `_SidebarItem` styling in `app_shell.dart` to use `SurfaceTokens.sidebarActive`, stronger typography hierarchy, and premium section headers.
- [x] 2.2 Implement hover/focus feedback and pointer cursors in sidebar items using `PremiumEffects` timings/curve.
- [x] 2.3 Add widget tests in `app_shell_test.dart` for active marker visibility, hover visual delta, and selection persistence by route.

## Phase 3: Forms and Action Controls Across Workflows

Goal: elevate all data-entry and control-heavy flows.
Scope: form fields, chips, tabs, selectors, primary/secondary action hierarchy.
File groups: `app/lib/screens/new_package_screen.dart`, `app/lib/screens/appearance_screen.dart`, `app/lib/screens/catalogos/*.dart`, `app/lib/widgets/component_selector.dart`, `app/lib/widgets/component_detail_card.dart`, `app/lib/widgets/server_form.dart`, related widget tests.
Validation checkpoint: focused/error/disabled states are legible, chips/tabs selected states are clear, no form-state regressions.
Releasable/versionable outcome: **v3 Premium Forms & Controls**.

- [x] 3.1 Replace hardcoded greys in `component_selector.dart` and `component_detail_card.dart` with `SurfaceTokens`/`colorScheme` tokens.
- [x] 3.2 Align input density, label hierarchy, helper/error presentation, and cursor affordances in `new_package_screen.dart`, `server_form.dart`, and catalog screens.
- [x] 3.3 Standardize tab/chip/button emphasis in `appearance_screen.dart` and catalog editors so primary actions remain dominant.
- [x] 3.4 Add/update widget tests for selector colors, detail-card surfaces/animation behavior, and form state legibility.

## Phase 4: Content Surfaces, Feedback, and Full-App Polish

Goal: complete premium cohesion across content and feedback surfaces.
Scope: dashboard cards, list density, dialogs/progress, about/log/history/success/clone/templates/splash consistency.
File groups: `app/lib/screens/dashboard_screen.dart`, `history_screen.dart`, `log_viewer_screen.dart`, `about_screen.dart`, `clone_screen.dart`, `templates_screen.dart`, `success_screen.dart`, `splash_screen.dart`, `app/lib/widgets/generation_progress_dialog.dart`, `package_name_preview.dart`, `update_dialog.dart`, final test suites.
Validation checkpoint: no overflow/assertions; visual hierarchy consistent on all routes; feedback components follow token system.
Releasable/versionable outcome: **v4 Full Premium Material Desktop**.

- [x] 4.1 Apply surface/elevation/typography spacing polish to all remaining screens and shared feedback widgets.
- [x] 4.2 Ensure progress, snackbar/toast, and empty-state emphasis maps to primary/secondary semantic colors.
- [x] 4.3 Update cross-screen/widget golden or behavior tests where styling contracts changed.
- [x] 4.4 Run full validation (`flutter test`) and record a phase completion checklist against spec scenarios before handoff to `/sdd-apply`.
