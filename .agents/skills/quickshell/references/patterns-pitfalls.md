# Patterns and pitfalls

Loop, layout, motion, and the gotcha list.

## Run loop

- Config root is `~/.config/quickshell/`. Each subfolder with `shell.qml` is one config. Base `shell.qml` wins over subfolders when both exist.
- Run a named config with `quickshell --config <name>` and an arbitrary path with `quickshell --path <path>`. Preview throwaway work in a test dir with the path form and keep the terminal visible.
- Saves hot reload through `Quickshell.watchFiles`. Check logs when a change does nothing. Kill a stuck instance before starting a second one so two shells do not fight over layers.
- Imports to pin per file are `Quickshell`, `QtQuick`, `QtQuick.Layouts`, plus service modules such as `Quickshell.Hyprland` or `Quickshell.Services.UPower`. Relative project imports use `import qs.<path>` from the `shell.qml` folder. Avoid the legacy `root:/` form.
- Editor setup is a QML grammar plus `qmlls`. Create an empty `.qmlls.ini` next to `shell.qml`, let Quickshell replace it with a managed config, and gitignore it since it is per machine. Expect the server to go quiet while braces are unbalanced and to miss Quickshell types such as `PanelWindow`. That is tooling, not broken code.
- Confirm the docs version switcher reads v0.3.1 before copying a snippet. Search often lands on older pages where `ShellRoot` wrapping, `height` versus `implicitHeight`, and command output reading differ.

## File layout that scales

One file holds to about 600 to 1000 lines. Then split into four folders:

- `components/` holds reusable primitives such as buttons, sliders, and icons.
- `services/` holds singletons such as time, audio, and network.
- `modules/` holds features such as bar, launcher, notifications, and control center.
- `theme/` holds tokens for colors, radii, and spacing.

One type per file, filename matching the type. `shell.qml` becomes composition: workspaces left, a fill width spring middle, status group right. Data flows one way from config through theme to interface. Components read tokens and never mutate them, so a restyle edits one file.

Defer heavy rarely opened UI with `LazyLoader`. Launcher, control center, and calendar built eagerly delay startup by a visible hang even when closed.

## Motion pattern

Animate one driver from 0 to 1 and derive the rest. Position, corner radius, shape, and opacity become arithmetic on that value. Attach one `Behavior` with a `NumberAnimation` or color animation to the driver.

```qml
property real open: 0
Behavior on open { NumberAnimation { duration: 200 } }
width: 48 + open * 200
radius: 24 - open * 12
opacity: 0.01 + open * 0.99
```

Multiple behaviors on dependent properties chase each other and freeze then lurch. Get the single driver smooth first. Springs and damped oscillation come after, not before.

Design notes from a rebuilt island: keep satellite pills symmetric with the center pill, tint album art with the accent instead of showing it raw, keep back button plus label plus toggle in one row, and expect grid label collisions when toggle counts shift.

## Gotcha checklist

Check this list when the screen is blank, frozen, or dead to clicks:

- Bar behind windows means layer, not size. Most bars want above windows.
- Tiled windows sliding under the bar means `exclusiveZone` is unset or the anchors changed.
- Dead desktop with no error means a fullscreen transparent surface with no `mask`. Give backdrops and corner layers an empty or tight region.
- Entrance stutter with clean exits means an item parked at opacity zero. Idle near zero instead.
- Frozen audio level with a hyphen or stale value means a missing `PwObjectTracker`.
- Crash on workspace switch or wifi drop means an unguarded nullable. Guard `focusedWorkspace`, wifi device, active network, and pipewire sink with `?.` and `??`.
- Wrong workspace on click means zero based `index` used raw. Hyprland ids need `index + 1`.
- Silent dispatch failure means the string matches the wrong Hyprland config dialect.
- Clipped bar children mean `height` was set. Use `implicitHeight`.
- Broken singletons and language server means a `root:/` import. Use `import qs.*`.
- Wrong icon glyph means an assumed codepoint. Verify against the installed Nerd Font or Material font, since tiers skip and one offs sit apart.
- Case bugs: `UPowerDeviceState.Charging` and `DeviceType.Wifi` both capitalize the last word.

## Learning order that works

Surfaces, then services, then components, then motion, then architecture. Build the bar shell, add clock, workspaces, volume, battery, and network one at a time. Write each line by hand and say what it does aloud. Copy paste builds a bar nobody can debug. Replace one working piece at a time instead of rewriting from a large clone. Style early for momentum, but keep the palette in one place from the start.

## Sources

- Quickshell v0.3.1 docs at `https://quickshell.org/docs/v0.3.1/`, including install setup, introduction, size and position, QML language, and type pages for `Quickshell`, `PanelWindow`, `QsWindow`, `Singleton`, `Quickshell.Io`, `Quickshell.Widgets`, and `Quickshell.Hyprland`.
- Qt 6 QML docs at `https://doc.qt.io/qt-6/qtqml-documents-topic.html`, plus syntax basics, property bindings, signals, anchors, layouts overview, and `Repeater`.
