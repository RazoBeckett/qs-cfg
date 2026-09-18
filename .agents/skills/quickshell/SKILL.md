---
name: quickshell
description: Quickshell Wayland shells in QML. Build, fix, or extend bars and panels, PanelWindow anchors and layouts, services and singletons, multimonitor Variants, animations, and config structure.
---

# Quickshell

Quickshell is a QML toolkit for Wayland desktop shells. Bars, launchers, notifications, lock screens, and control centers are QML documents rooted at `shell.qml`.

Scope here is Quickshell v0.3.1 with Qt 6 QML. Docs live at `https://quickshell.org/docs/v0.3.1/`. QML language reference lives at `https://doc.qt.io/qt-6/qtqml-documents-topic.html`.

## When to use this skill

Use it when the task touches `shell.qml`, a `PanelWindow`, a Quickshell service such as audio or battery, QML bindings or layouts, or the run and reload loop. For pure Qt Quick questions with no shell involved, read `references/qml-essentials.md` only.

For visible styling, type, icons, corner scale, and shared components, also read the `quickshell-ui` skill. This skill owns structure and data. That skill owns looks.

## Workflow

Do the steps in order. Each step states when it is done.

### 1. Get a visible window first

Confirm the config path and the reload loop before changing behavior.

Default config root is `~/.config/quickshell/shell.qml`. A named config is a subfolder with its own `shell.qml`, selected with `quickshell --config <name>`. An arbitrary path loads with `quickshell --path <path>`. Saves hot reload by default through `Quickshell.watchFiles`.

Start from a minimal bar, not a cloned shell:

```qml
import Quickshell
import QtQuick

ShellRoot {
  PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "#121212"
    Text {
      text: "hello"
      color: "#e8e8ed"
      anchors.centerIn: parent
    }
  }
}
```

Done when a save visibly changes the bar and errors show in the terminal running Quickshell.

Details: `references/surfaces.md`.

### 2. Learn top down, one brick at a time

Treat QML as config with relationships, not a script. Paste a small working snippet, change one value, watch the screen. Explain the lines from the outside in: what the whole block does, roughly how, which lines play which part, then lookup of single terms.

Keep the first goal tiny: a bar with a live clock. Add one module at a time after that.

Done when the user can point at any line in the new code and say what part it plays.

### 3. Build surfaces before services before looks

Order matters. Surfaces decide where pixels may go. Services supply system truth. Components decide how it looks. Styling first leaves a bar with no data. Motion and architecture come last.

For surfaces, pick anchors, then layer, then reservation. A top full width bar anchors top plus left plus right and sets `implicitHeight`. A floating pill or island anchors top only. Reserve space with `exclusiveZone` only on an anchored edge.

Done when the bar docks where asked and tiled windows respect it or float over it by intent.

Details: `references/surfaces.md`.

### 4. Add one service through a singleton

Read system state from Quickshell services, not shell commands. Prefer `SystemClock` for time, `Quickshell.Hyprland` for workspaces, `Quickshell.Services.UPower` for battery, `Quickshell.Services.Pipewire` for audio, `Quickshell.Networking` for wifi. Use `Process` from `Quickshell.Io` only when no service exists.

Share one instance per service. A file with `pragma Singleton` and a `Singleton` root is read everywhere by filename, for example `Time.time`. Never put a timer or process inside a per screen block.

Done when the value updates on screen with no manual refresh code.

Details: `references/services.md`.

### 5. Handle screens early

Wrap each window in `Variants` with `model: Quickshell.screens` and pass `screen: modelData` into the window. Keep shared state in a `Scope` or singleton outside the `Variants` block so timers and processes run once.

Done when unplugging a monitor keeps one bar per remaining screen and no duplicated polling exists.

Details: `references/surfaces.md`.

### 6. Animate one number

Drive motion from a single 0 to 1 value and derive position, radius, and opacity from it with arithmetic. Put a `Behavior` with a `NumberAnimation` or color animation on that driver. Competing animations on dependent properties freeze then jump.

Done when the transition runs smooth twice in a row, open and close.

### 7. Split files when one file strains

One file works to roughly 600 to 1000 lines. After that use four folders: `components/` for reusable primitives, `services/` for singletons, `modules/` for features, `theme/` for color and spacing tokens. Data flows one way toward the interface. Components read tokens and never write them. Defer rarely opened panels such as launchers and calendars with `LazyLoader`.

Done when a restyle touches `theme/` only and a new widget reuses a component without copy paste.

Pitfalls checklist and commands: `references/patterns-pitfalls.md`.

## QML rules that shape every step

- `height: width * 2` is a live binding. It reevaluates when dependencies change. A plain assignment inside `Component.onCompleted` or a JS function runs once and breaks the binding. Rebind at runtime with `Qt.binding`.
- One type per file. A capitalized file such as `Battery.qml` becomes a `Battery {}` type for neighbors. Module imports use `import qs.<path>` relative to the `shell.qml` folder. Avoid the old `root:/` form. It breaks the language server and singletons.
- Single placement uses anchors. A group in a row or column uses `RowLayout`, `ColumnLayout`, or `GridLayout` from `QtQuick.Layouts`, then anchor the layout container itself. Set `Layout.fillWidth` spacers to push left and right groups apart.
- Size flows two ways. A child reports desired size through `implicitWidth` and `implicitHeight`. A parent gives actual `width` and `height`. Unanchored window dimensions come from implicit size, so bars set `implicitHeight`, not `height`.
- Lists stamp copies. `Repeater` stamps items, `Variants` stamps non items such as windows, `ListView` virtualizes long lists, `Loader` and `LazyLoader` defer work.

Full QML notes: `references/qml-essentials.md`.

## Reference map

- `references/qml-essentials.md`. Properties, bindings, signals, anchors and layouts, repeaters and loaders.
- `references/surfaces.md`. `PanelWindow`, anchors, margins, layers, exclusive zone, multimonitor `Variants`, fullscreen masks.
- `references/services.md`. `SystemClock`, Hyprland, UPower, Pipewire, Networking, singletons, `Process` escape hatch.
- `references/patterns-pitfalls.md`. Run loop, file layout, theme tokens, animation pattern, gotcha checklist, source URLs.
