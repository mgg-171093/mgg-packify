# visual-theme Specification

## Purpose

Define the Material Premium desktop UI language for MGG-Packify so the redesign is consistent, testable, and shippable in phases without changing product behavior.

## Requirements

### Requirement: Design Tokens and Identity

The system MUST provide one app-wide theme using Deep Orange 500 as the primary identity and shared tokens for color, typography, spacing, shape, elevation, and motion. Light and dark presentation SHALL preserve semantic roles and WCAG AA contrast. Navigation rules, provider behavior, and port 8787 MUST NOT change.

#### Scenario: Apply branded tokens everywhere

- GIVEN any app screen is rendered
- WHEN the shared theme is active
- THEN primary emphasis uses Deep Orange 500 semantics
- AND text, surfaces, and feedback use shared tokens rather than per-screen ad hoc styling

### Requirement: Desktop Interaction States

The system MUST expose desktop-first interaction feedback: hover state for interactive elements, hand cursor for clickable controls, text cursor for text entry, visible focus state for keyboard navigation, and non-hover treatment for disabled controls.

#### Scenario: Distinguish interaction affordances

- GIVEN a user moves pointer and keyboard focus across the UI
- WHEN elements are actionable, editable, focused, or disabled
- THEN each state is visually distinct and cursor-appropriate
- AND disabled elements never appear actionable

### Requirement: Shell and Sidebar Hierarchy

The system MUST present a redesigned shell/sidebar with clear brand presence, active-route indication, readable density, and consistent hover/focus treatment for navigation items while keeping existing routes unchanged.

#### Scenario: Identify active navigation target

- GIVEN the user is on any routed screen
- WHEN the shell is visible
- THEN the current destination is clearly marked as active
- AND other destinations remain discoverable without competing with the active item

### Requirement: Action Controls

The system MUST standardize buttons, icon buttons, chips, tabs, and segmented choices with shared sizing, emphasis hierarchy, selected state, hover/focus behavior, and disabled presentation. Primary actions SHALL be visually stronger than secondary and tertiary actions.

#### Scenario: Compare primary and secondary actions

- GIVEN a screen contains multiple control types
- WHEN the user scans available actions
- THEN the intended primary action is visually dominant
- AND selected chips, tabs, or segmented options are distinguishable from unselected ones

### Requirement: Form Controls

The system MUST standardize text fields, dropdowns, selectors, labels, helper text, and validation states. Focused, error, valid, and disabled states SHALL be visually distinct, and labels MUST remain readable at desktop density.

#### Scenario: Validate form states

- GIVEN a form contains empty, valid, and invalid inputs
- WHEN the user edits or submits fields
- THEN labels, focus treatment, and validation messages remain legible
- AND error states are distinguishable without changing business rules

### Requirement: Content Surfaces and Feedback

The system MUST align cards, lists, list items, dialogs, progress indicators, empty states, snackbars, and toast-style feedback to the shared surface, elevation, spacing, and color tokens so information hierarchy is consistent across home, settings, history, logs, and about views.

#### Scenario: Present consistent surfaces

- GIVEN the user opens cards, lists, dialogs, progress, or empty states
- WHEN those components are displayed
- THEN spacing, elevation, and color treatment feel consistent across screens
- AND progress and feedback states use the same semantic emphasis system

### Requirement: Motion and Phased Rollout

The system MUST use consistent motion durations and easing for route transitions, expansion, hover/focus state changes, and loading feedback. The redesign SHALL ship in four phases—theme foundation, shell/navigation, forms/inputs, and content surfaces—and each phase MUST deliver a user-visible result that is independently shippable and verifiable before the next phase.

#### Scenario: Ship an intermediate phase safely

- GIVEN only the current phase is implemented
- WHEN the app is reviewed before the next phase starts
- THEN the delivered area is visually coherent and usable on its own
- AND later phases remain optional follow-up work rather than blockers to shipping
