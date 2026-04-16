# Proposal: Material Premium Redesign

## Intent

The current UI uses `Colors.blue` seed with default Material 3 styling. This produces a generic, low-identity interface that lacks visual cohesion for a professional desktop tool. The redesign establishes a **Material Premium** direction using **Deep Orange 500** as the primary identity color, introduces deliberate elevation, spacing, and motion standards, and resolves desktop-specific interaction gaps (hover states, focus rings, sidebar density).

## Scope

### In Scope
- Global theme seed → Deep Orange 500 (`ColorScheme.fromSeed`)
- `AppShell` sidebar: visual hierarchy, active-route indicator, hover/focus states
- `HomeScreen` action cards: elevation, spacing, icon treatment
- Form inputs (`NewPackageScreen`, `SettingsScreen`): label density, error styles, focus ring
- `ComponentDetailCard` / `ComponentSelector`: chip color, card surface, expansion animation
- `SettingsScreen` tabs: tab indicator, content padding
- `HistoryScreen` / `LogViewerScreen` / `AboutScreen`: typography scale, list tile density
- `GenerationProgressDialog`: Deep Orange progress indicator
- Toast / snackbar color alignment

### Out of Scope
- Business logic or state management changes
- New features or screens
- API or backend changes
- Cross-platform (web/mobile) support

## Capabilities

### New Capabilities
- `visual-theme`: Centralized Material Premium theme definition (colors, typography, shape, motion tokens)

### Modified Capabilities
- None (visual changes only — no spec-level behavior changes)

## Approach

**Four phased deliverables**, each producing a visible, shippable result:

| Phase | Scope | Milestone |
|-------|-------|-----------|
| P1 — Theme Foundation | `app.dart` seed → Deep Orange 500, shape tokens, typography scale | All screens branded, tests green |
| P2 — Shell & Navigation | Sidebar hierarchy, active indicator, hover/focus, `AppShell` polish | Navigation feels premium |
| P3 — Forms & Inputs | `NewPackageScreen`, `SettingsScreen`, `ComponentDetailCard`, chips | Form experience elevated |
| P4 — Content Surfaces | Cards, dialogs, lists, history, logs, toasts, about | Full visual cohesion |

Each phase is independently mergeable and testable.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `app/lib/app.dart` | Modified | Theme seed, shape, typography definitions |
| `app/lib/widgets/app_shell.dart` | Modified | Sidebar density, active state, hover |
| `app/lib/screens/home_screen.dart` | Modified | Card elevation, action button treatment |
| `app/lib/screens/new_package_screen.dart` | Modified | Input density, focus ring, error states |
| `app/lib/screens/settings_screen.dart` | Modified | Tab indicator, server form, option lists |
| `app/lib/widgets/component_detail_card.dart` | Modified | Surface, chip color, animation |
| `app/lib/widgets/component_selector.dart` | Modified | FilterChip color |
| `app/lib/widgets/generation_progress_dialog.dart` | Modified | Progress indicator color |
| `app/lib/screens/history_screen.dart` | Modified | List tile density, typography |
| `app/lib/screens/log_viewer_screen.dart` | Modified | Tab, typography |
| `app/lib/screens/about_screen.dart` | Modified | Typography, spacing |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `ComponentDetailCard` focus regression in 211 Flutter tests | Med | Run `flutter test` after each phase; P3 is isolated |
| Deep Orange on white fails WCAG AA contrast | Low | Verify `onPrimary` and `onSurface` pairs before P1 merge |
| Form state broken by widget rebuild from theme changes | Low | Theme changes are `InheritedWidget` — no state reset |

## Rollback Plan

Each phase ships as a separate commit/branch. Rollback = revert that commit. `app.dart` is the single source of truth for the theme — reverting it to `Colors.blue` seed restores original appearance without touching any other file.

## Dependencies

- Flutter SDK ≥ 3.x (Material 3 already active in project)
- No new packages required

## Why Hybrid Storage

This change spans 11 files and 4 phases. Hybrid mode (Engram + filesystem) ensures:
- **Engram**: fast retrieval by downstream phase agents (spec, design, tasks, verify) across sessions and compactions
- **OpenSpec filesystem**: human-readable artifact in the repo, reviewable in PRs, survives tool outages

## Success Criteria

- [ ] All 211 Flutter tests pass after each phase merge
- [ ] Deep Orange 500 primary visible across all screens
- [ ] WCAG AA contrast maintained on all text/background pairs
- [ ] Sidebar active route indicator visible and correct
- [ ] No `Navigator.pop()` or `AsyncNotifier.update()` violations introduced
- [ ] No API port, business logic, or state management changes
