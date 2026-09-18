# Coding Standards

This repository is a small Quickshell/QML configuration. Keep code compact,
declarative, and consistent with the existing bar components.

## Project Shape

- Keep the root shell composition in `shell.qml`.
- Keep bar widgets in `components/bar/`.
- Keep shared primitives in `components/shared/`.
- Keep feature clusters in their own folders (`components/settings/`, `components/wallpaper/`).
- Keep shared UI state singletons in `states/`.
- Keep system-truth singletons in `services/`.
- Keep shared style and sizing values in the singleton files:
  - `theme/Colors.qml` for color tokens.
  - `theme/Typography.qml` for fonts, sizes, and type scale.
  - `theme/Sizing.qml` for bar dimensions and shared layout metrics.
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
  a component's internal visual rhythm.
- Keep bar height, outer margins, fonts, and shared dimensions centralized in
  the theme singletons (`theme/Sizing.qml`, `theme/Colors.qml`,
  `theme/Typography.qml`).
- Avoid wrapper elements unless they provide a concrete behavior such as hover,
  wheel handling, or mouse interaction.

## Visual Design

- Use `Colors` tokens instead of hard-coded colors in components.
- Add new colors to `theme/Colors.qml` before using them in multiple places.
- Use `Typography.sans` / `Typography.mono` for text (via `Label` where possible).
- Use `Typography.icons` for glyphs.
- Use `String.fromCodePoint(...)` for icon glyphs instead of pasting private-use
  characters directly into source files.
- Keep component text minimal and status-oriented: percentages, short labels,
  connection names, and fallback states such as `"-"` or `"Muted"`.
- Use color to communicate state, but keep the foreground text color stable
  unless the state itself needs emphasis.
- Use one corner scale. `Settings.ui.rounding` (int, 0-24, default 5) is the
  only saved value. `Settings.rounding.{lg,md,sm,xs}` derive from it by
  phi 1.618 outside the adapter so they never persist. At default 5 that is
  5/3/2/1. Zero stays zero at every level.
- Assign corner levels consistently. Lg is for outer cards, popups, pills, and
  the settings shell. Md is for tab highlights, device rows, stream cards,
  preview boxes, wallpaper thumbs, and mid-size buttons. Sm is for small
  controls such as 28px icon buttons, preset chips, toggle thumbs, and slider
  tracks. Xs is for the tiniest outlines and dots. Toggle tracks default to
  md with sm thumbs, Slider thumbs default to md with sm tracks. New code
  names the scale at call sites instead of writing literal radii.
- Clip what bleeds. A container whose children reach its edges (images,
  sidebar fills, wipe previews) becomes `ClippingRectangle` with
  `contentUnderBorder: true`. Simple cards stay `Rectangle` with `clip: true`.
- Follow the type scale. `Typography.rootSize` follows `Settings.ui.fontScale`
  (default 13). `sizeXS` is base * 0.85, `sizeSM` is base, `sizeMD` is
  base * 1.15, `sizeLG` is base * 1.4. Defaults are sans `SF Pro Text`, mono
  `JetBrains Mono`, icons `Phosphor`. Prefer `Label` with `useMono`, `size`,
  and `weight`, and set `font.family`, `font.pixelSize`, and `font.weight`
  individually. Never pair a grouped `font: Typography.x` binding with a
  `font.*` override on the same item. Literal `pixelSize` is only for icon
  glyphs or fixed-density exceptions marked `scale-exempt`.
- Keep small text readable and pair decisions. Small text holds high contrast
  against its background, and a new color in `Colors.qml` plus a new size in
  `Typography.qml` is one paired decision, not two.

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

## Settings Persistence

- Persist user preferences in `services/Settings.qml` through `FileView` with
  `watchChanges: true` to `kettshell.json` under the shell state path.
  Adapter initializers are the defaults and missing keys fall back to them.
- Declare derived values on the `Settings` root beside the adapter, never
  inside the `ui` `JsonObject`. Every property inside that object saves to
  `kettshell.json` and reloads over its binding, so a derived value placed
  there freezes after one restart. The rounding scale lives beside the
  adapter for this reason.
- Writing a `Settings` key from QML saves automatically. The settings pages,
  rows, tabs, and full key list live in `components/settings/DOCS.md`, which
  is the source of truth for settings UI. Settings pages import `"../.."`
  and never import each other by path.

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

1. Create a focused file in `components/bar/`, `components/shared/`, or `components/wallpaper/`.
2. Import `".."` (or `"../.."` from a subfolder)
   so the component can use `Colors`, `Typography`, and `Settings`.
3. Use a small root item such as `RowLayout`, `Text`, or `WrapperMouseArea`.
4. Define service bindings and derived `readonly property` values near the top.
5. Render icon and text children with `Typography.icons` and `Typography.sans`/`Typography.mono` (or `Label`).
6. Add fallback states for missing data.
7. Add the component to `qmldir` if it should be imported by name.
8. Compose it into `shell.qml` in the appropriate row.

For settings tabs and rows, follow `components/settings/DOCS.md` instead of
this list. Editing an existing file hot reloads, while adding or renaming a
file or touching `qmldir` needs a restart.

## Verification

- use 'qmllint' to find errors and warnings.
- Keep new `radius:` values on the `Settings.rounding` scale, with no
  literals at new call sites.
- Keep every touched `Text` free of `font: Typography.x` paired with a
  `font.*` override on the same item.
- Keep changes scoped. Avoid unrelated formatting churn in existing files.
