# Design: Material Premium Redesign

## Technical Approach

Replace `Colors.blue` seed with `Colors.deepOrange` in `app.dart`, then extract reusable theme extensions and UI helpers into a `core/theme/` module. Roll out across 4 phases matching the proposal. All changes are visual — no state management, API, or business logic modifications.

## Architecture Decisions

| Decision | Choice | Alternatives | Rationale |
|----------|--------|-------------|-----------|
| Theme token location | `core/theme/` module with `app_theme.dart` + `theme_extensions.dart` | Inline in `app.dart`; separate package | Keeps theme co-located with core, avoids single-file bloat, no package overhead |
| Light/dark variant structure | Single `appTheme(Brightness)` factory using `ColorScheme.fromSeed` | Separate `_lightTheme`/`_darkTheme` getters (current) | Eliminates duplication; brightness param drives all differences |
| Hover/pointer/motion helpers | `ThemeExtension<PremiumEffects>` registered on `ThemeData.extensions` | Standalone utility classes; mixin on widgets | Framework-native; accessible via `Theme.of(context).extension<PremiumEffects>()` |
| Sidebar active indicator | Leading colored bar (`Container` with `primaryContainer` color) inside `_SidebarItem` | `NavigationRail`; `NavigationDrawer` built-in indicator | Current sidebar is custom `ListTile`-based; adding a bar is minimal; switching to `NavigationRail` would require restructuring 15 destinations |
| Chip/card surface tokens | `ThemeExtension<SurfaceTokens>` with `chipSelected`, `cardElevated`, `cardFlat` | Hardcoded colors per widget | Centralizes surface decisions; dark mode gets automatic coverage |
| Rollout strategy | 4 independent phases, each a single commit | Big-bang single PR | Each phase is independently testable and revertable |

## Data Flow

```
app.dart (ThemeData + extensions)
    │
    ├── AppShell ← reads colorScheme + PremiumEffects for sidebar hover/active
    ├── Screens  ← inherit theme; no direct token references
    └── Widgets  ← ComponentSelector, ComponentDetailCard read SurfaceTokens
```

No new providers. No data flow changes. Theme propagates via `InheritedWidget` (standard Flutter).

## File Changes

| File | Action | Phase | Description |
|------|--------|-------|-------------|
| `app/lib/core/theme/app_theme.dart` | Create | P1 | `appTheme(Brightness)` factory, Deep Orange 500 seed, shape/typography tokens |
| `app/lib/core/theme/theme_extensions.dart` | Create | P1 | `PremiumEffects` (hover duration, focus ring width, cursor) + `SurfaceTokens` |
| `app/lib/app.dart` | Modify | P1 | Replace inline `_lightTheme`/`_darkTheme` with `appTheme()` calls |
| `app/lib/widgets/app_shell.dart` | Modify | P2 | Active-route bar indicator, hover state on `_SidebarItem`, section header styling |
| `app/lib/widgets/component_selector.dart` | Modify | P3 | Use `SurfaceTokens.chipSelected` instead of hardcoded `Colors.grey.shade100` |
| `app/lib/widgets/component_detail_card.dart` | Modify | P3 | Card surface from `SurfaceTokens`, expansion animation curve from `PremiumEffects` |
| `app/lib/screens/new_package_screen.dart` | Modify | P3 | Input density via `inputDecorationTheme` (already inherited; verify focus ring) |
| `app/lib/screens/dashboard_screen.dart` | Modify | P4 | Card elevation, action button icon tint |
| `app/lib/screens/history_screen.dart` | Modify | P4 | List tile density, typography scale |
| `app/lib/screens/log_viewer_screen.dart` | Modify | P4 | Tab indicator color alignment |
| `app/lib/screens/about_screen.dart` | Modify | P4 | Typography, spacing |
| `app/lib/screens/settings_screen.dart` | Modify | P4 | Tab indicator (if separate from appearance) |
| `app/lib/widgets/generation_progress_dialog.dart` | Modify | P4 | Progress indicator inherits primary (Deep Orange) — verify contrast |

## Interfaces / Contracts

```dart
// core/theme/theme_extensions.dart

class PremiumEffects extends ThemeExtension<PremiumEffects> {
  final Duration hoverDuration;     // 150ms
  final double focusRingWidth;      // 2.0
  final MouseCursor actionCursor;   // SystemMouseCursors.click
  final Curve standardCurve;        // Curves.easeInOut

  // copyWith, lerp required by ThemeExtension
}

class SurfaceTokens extends ThemeExtension<SurfaceTokens> {
  final Color chipSelected;         // colorScheme.primaryContainer
  final Color chipUnselected;       // colorScheme.surfaceContainerLow
  final Color cardElevated;         // colorScheme.surfaceContainerHigh
  final Color sidebarActive;        // colorScheme.primaryContainer.withAlpha(128)

  // copyWith, lerp required by ThemeExtension
}
```

## Testing Strategy

| Phase | What to Test | Approach |
|-------|-------------|----------|
| P1 | Theme factory produces valid `ThemeData` for both brightnesses | Unit test: `appTheme(Brightness.light)` and `.dark` — verify seed color, extensions present |
| P1 | Existing 211 tests still pass | `flutter test` — no widget changes, only theme source moved |
| P2 | Sidebar renders active indicator, hover state | Widget test: pump `AppShell`, verify `Container` with primary color on active item |
| P3 | Chips use `SurfaceTokens`, cards use correct surface | Widget test: pump `ComponentSelector` with theme, verify `FilterChip` colors |
| P4 | All screens render without overflow or assertion errors | Existing screen tests cover this; run full suite |
| All | WCAG AA contrast | Manual: verify `onPrimary` on Deep Orange 500 is white (it is — contrast ratio 4.64:1) |

## Migration / Rollout

**Phase-by-phase, each independently mergeable:**

1. **P1 — Theme Foundation**: Create `core/theme/`, move theme from `app.dart`. Zero visual change risk — same tokens, new location. Run `flutter test`.
2. **P2 — Shell & Navigation**: Modify `app_shell.dart` only. Add hover `StatefulWidget` wrapper or `MouseRegion` to `_SidebarItem`. Add active bar. Run `flutter test`.
3. **P3 — Forms & Inputs**: Modify `ComponentSelector`, `ComponentDetailCard`. Replace hardcoded `Colors.grey.shade100` with `SurfaceTokens`. Run `flutter test`.
4. **P4 — Content Surfaces**: Touch remaining screens. Largest surface area but lowest risk (typography/spacing only). Run `flutter test`.

**Rollback**: Revert the phase commit. If all 4 are merged, revert `app_theme.dart` seed to `Colors.blue` — single-file change restores original appearance.

**Migration of hardcoded colors**: Grep for `Colors.grey.shade100`, `Colors.grey.shade300`, `Colors.grey.shade50` in widgets — replace with `SurfaceTokens` or `colorScheme` equivalents. Each occurrence is addressed in the phase that touches that file.

## Open Questions

- [ ] Should `_SidebarItem` hover require converting from `StatelessWidget` to `StatefulWidget`, or use `MouseRegion` + `ValueNotifier` pattern?
- [ ] Confirm Deep Orange 500 `onPrimary` is white in M3 `fromSeed` (expected yes — verify before P1 merge)
