# Settings menu

Small primer for future you. The menu lives in `components/settings/` and
reads/writes the `Settings` singleton, which persists to `kettshell.json`.

## Files

- `SettingsWindow.qml` — fullscreen overlay on the primary screen. Owns the
  IPC handler (`qs ipc call settings toggle|open|close`) and the
  `settings-toggle` global shortcut. Outside click and Escape play the close
  animation instead of hiding instantly.
- `SettingsMenu.qml` — the card itself. Sidebar tabs on the left, page
  content on the right. Owns the open/close animations and the sliding
  active-tab highlight.
- `SettingsRow.qml` — one row: title plus subtitle on the left, a
  caller-supplied control in a 240px box on the right.
- `UiTab.qml`, `WallpaperTab.qml`, `FontsTab.qml`, `AITab.qml`, `AboutTab.qml` — the five pages.

All seven types are registered in the root `qmldir`, and `shell.qml`
instantiates `SettingsWindow {}` next to `Background`.

## Settings keys you can bind to

From `services/Settings.qml`:

- `Settings.wallpaper.directory` (string)
- `Settings.wallpaper.current` (string, read-only in practice, write it
  through `Wallpapers.setWallpaper()`)
- `Settings.wallpaper.wipeDeg` (int, 0-360)
- `Settings.ui.genie` (bool)
- `Settings.ui.rounding` (int, 0-24, default 5)
- `Settings.rounding.lg/md/sm/xs` (derived from `ui.rounding` by φ, not persisted)
- `Settings.ui.fontFamily` (string, default "SF Pro Text")
- `Settings.ui.fontScale` (real, default 13, feeds `Typography.rootSize`)
- `Settings.ui.monoFamily` (string, default "JetBrains Mono")
- `Settings.ai.deepgramKey` (string, default "")
- `Settings.ai.model` (string, default "nova-3")
- `Settings.ai.language` (string, default "en")
- `Settings.ai.smartFormat` (bool, default true)
- `Settings.ai.punctuate` (bool, default true)
- `Settings.ai.autoCopy` (bool, default false)
- `Settings.ai.retentionDays` (int, default 30, 0 keeps forever)

Writing any of these from QML saves `kettshell.json` automatically.

## Add a tab

Four steps, all required:

1. Create `components/settings/MyTab.qml`. Root it in a `ColumnLayout`
   with `spacing: 4` and fill it with `SettingsRow` items. Copy `UiTab.qml`
   if you want a toggle, `WallpaperTab.qml` if you want a slider.
2. Add one entry to `tabsModel` in `SettingsMenu.qml`:
   `{ name: "Mine", icon: "sliders-horizontal" }`. The icon is a Phosphor
   ligature, same set the bar uses.
3. Add the page next to the other three in `SettingsMenu.qml`, matching the
   index: `MyTab { visible: root.currentTab === 3; Layout.fillWidth: true }`.
4. Register it in the root `qmldir`:
   `MyTab 1.0 components/settings/MyTab.qml`.

Then restart the shell (`qs kill` plus your normal start). New files and
new `qmldir` lines are only picked up at startup, hot reload will not see
them and the config will fail to load until you restart.

## Remove a tab

Reverse of adding: delete the page line in `SettingsMenu.qml`, drop the
`tabsModel` entry, delete the file, drop the `qmldir` line. Restart.

## Add a row to a tab

```qml
SettingsRow {
  title: "My option"
  subtitle: "What it does, in a few words"
  Layout.fillWidth: true

  /* one control goes here: Text, Slider, Toggle... */
}
```

Three control patterns already in use:

- Static text, right aligned: `WallpaperTab.qml` library row.
- Toggle switch: `UiTab.qml` genie row. Shared `Toggle` from
  `components/shared/` with `checked` bound to the bool, `onToggled`
  writes back: `onToggled: c => Settings.ui.genie = c`. It also takes
  `onColor`, `offColor`, and `thumbColor`, all defaulting to the current
  look, so new uses rarely need to touch the file.
- Slider: `WallpaperTab.qml` wipe row. Shared `Slider` with
  `Layout.fillWidth: true`, `Layout.preferredHeight: 32`, `fraction` bound
  to the value, `onMoved` writes back with rounding:
  `onMoved: f => Settings.wallpaper.wipeDeg = Math.round(f * 360)`.

Size row controls with `Layout` props. Anchored controls inside the row
slot do not render reliably, so the slot is a right-aligned `RowLayout`
and every control carries its own `Layout.preferredWidth/Height`.

Keep the control inside the row's box. If you need a label plus slider side
by side, wrap them in an `Item` with `anchors.fill: parent` first.

## Remove a row

Delete the `SettingsRow` block. No registration to clean up. Hot reload
applies it, no restart needed.

## Animations

Open and close sequences live in `SettingsMenu.qml` as `openSequence` and
`closeSequence`. Open staggers three progress values: `introBase` drives the
card fade and scale, `introSidebar` slides the sidebar in, `introContent`
slides the page up. Close collapses content and sidebar first, then the
card, and fires `closeFinished` which the window uses to actually hide.

`SettingsWindow` keeps the window mapped while
`root.open || menu.busy` is true, so the close animation always finishes
before the window unmaps.

## Library path editing

The pencil button on the Wallpaper tab flips the Library row into edit
mode: a text field pre-filled with the current path. Enter writes
`Settings.wallpaper.directory`, Esc cancels. `Wallpapers` re-lists from
the new location on its own. A native folder picker was tried and
dropped: without a GTK platform theme Qt falls back to an in-window
dialog that misbehaves on a layer-shell overlay, so typing the path won.

## Gotchas

- Editing an existing file hot reloads. Adding or renaming a file, or
  touching `qmldir`, needs a restart.
- If the config fails to load after your change, `tail quickshell.log`
  names the file, line, and missing type.
- Settings pages must not import each other by path. They all
  `import "../.."`, which is the root module with `Colors`, `Typography`,
  `Settings`, `Wallpapers`, and the shared components.
