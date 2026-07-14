# Coding Standards

This repository is a small Quickshell/QML configuration. Keep code compact,
declarative, and consistent with the existing bar components.

## Project Shape

- Keep the root shell composition in `shell.qml`.
- Keep reusable bar widgets in `components/`.
- Keep shared style and sizing values in the singleton files:
  - `Colors.qml` for color tokens.
  - `Config.qml` for spacing, dimensions, and fonts.
- Register new public QML types in `qmldir` when they should be imported by
  name.
- Prefer one focused component per file. A component should own one visible bar
  concern, such as volume, battery, network, clock, brightness, or workspaces.

## QML Style

- Use two-space indentation.
- Put imports at the top of each file, grouped simply and without blank lines.
  Local imports come first when needed:

  ```qml
  import ".."
  import Quickshell.Services.Pipewire
  import Quickshell.Widgets
  import QtQuick
  import QtQuick.Layouts
  ```

- Use `id: root` for top-level components when child bindings or handlers need
  to reference parent state.
- Use `readonly property` for derived values such as formatted levels, icon
  choices, and readiness flags.
- Use plain `property var` when binding directly to service objects.
- Prefer bindings over imperative updates. Imperative code should be reserved
  for user actions, shell commands, or service writes.
- Keep helper functions local to the component that uses them.
- Use braces for multi-branch computed properties:

  ```qml
  readonly property string icon: {
    if (!ready) return String.fromCodePoint(0xF0581)
    if (muted) return String.fromCodePoint(0xF0E08)
    return String.fromCodePoint(0xF057E)
  }
  ```

## Layout

- Use `RowLayout` for horizontal bar groups.
- Use `Item { Layout.fillWidth: true }` as the flexible spacer between left and
  right bar regions.
- Keep repeated inline spacing values small and local only when they are part of
  a component's internal visual rhythm. Use `Config.spacing` for top-level
  spacing between bar modules.
- Keep bar height, outer margins, fonts, and shared dimensions centralized in
  `Config.qml`.
- Avoid wrapper elements unless they provide a concrete behavior such as hover,
  wheel handling, or mouse interaction.

## Visual Design

- Use `Colors` tokens instead of hard-coded colors in components.
- Add new colors to `Colors.qml` before using them in multiple places.
- Use `Config.font` for text labels.
- Use `Config.iconFont` for Nerd Font icon glyphs.
- Use `String.fromCodePoint(...)` for icon glyphs instead of pasting private-use
  characters directly into source files.
- Keep component text minimal and status-oriented: percentages, short labels,
  connection names, and fallback states such as `"-"` or `"Muted"`.
- Use color to communicate state, but keep the foreground text color stable
  unless the state itself needs emphasis.

## Interaction

- Use `WrapperMouseArea` when a component needs hover, cursor, or wheel support
  around layout content.
- Set `acceptedButtons: Qt.NoButton` for wheel-only controls that should not
  consume clicks.
- Use `cursorShape: Qt.PointingHandCursor` only on interactive areas.
- Clamp numeric values before writing them back to services.
- Keep interaction steps small and predictable. Existing wheel controls adjust
  volume and brightness in 5 percent increments.
- Prefer Quickshell service APIs for state changes. Use `Quickshell.execDetached`
  only when the underlying system requires an external command.

## Services And State

- Bind directly to Quickshell services where possible:
  - `Quickshell.Services.Pipewire` for volume.
  - `Quickshell.Services.UPower` for battery.
  - `Quickshell.Networking` for network state.
  - `Quickshell.Hyprland` for workspaces.
- Include explicit readiness checks before reading service-dependent values.
- Provide simple fallback UI for unavailable services or missing data.
- Use `PwObjectTracker` for Pipewire objects that need tracking.
- Use `FileView` with `watchChanges: true` when displaying state from files
  that can change externally.

## Comments

- Keep comments rare and useful.
- Add comments for non-obvious platform details, permissions, codepoint ranges,
  or external command choices.
- Do not comment obvious QML structure or simple bindings.

## Naming

- Use PascalCase for component files: `Battery.qml`, `Workspaces.qml`.
- Use lower camel case for properties, functions, and ids:
  `ready`, `level`, `adjustVolume`, `wsButton`.
- Use direct domain names for service-backed state:
  `battery`, `sink`, `wifiDevice`, `active`.
- Keep names short when their scope is small.

## Error Handling And Fallbacks

- Do not assume a service object exists. Check readiness or nullability first.
- Display stable fallback values rather than leaving bindings undefined.
- Avoid throwing from bindings or handlers during normal missing-device states.
- When a system-specific value is required, keep it isolated in one property
  near the top of the component, as with the brightness backlight device.

## Adding New Components

When adding a new bar module:

1. Create a focused file in `components/`.
2. Import `".."`
   so the component can use `Colors` and `Config`.
3. Use a small root item such as `RowLayout`, `Text`, or `WrapperMouseArea`.
4. Define service bindings and derived `readonly property` values near the top.
5. Render icon and text children with `Config.iconFont` and `Config.font`.
6. Add fallback states for missing data.
7. Add the component to `qmldir` if it should be imported by name.
8. Compose it into `shell.qml` in the appropriate row.

## Verification

- use 'qmllint' to find errors and warnings.
- Keep changes scoped. Avoid unrelated formatting churn in existing files.
