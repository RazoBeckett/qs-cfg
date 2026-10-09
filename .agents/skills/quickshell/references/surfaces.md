# Surfaces

Where pixels may go. Read this before adding data or style.

## PanelWindow basics

`PanelWindow` is a layer shell surface docked to a screen edge. It reserves space so tiled windows do not slide under it. `FloatingWindow` is the plain toplevel alternative. Type pages live under `https://quickshell.org/docs/v0.3.1/types/`.

A top full width bar looks like this:

```qml
import Quickshell
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    color: "#040E0D"
    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      Workspaces {}
      Item { Layout.fillWidth: true }
      RowLayout { spacing: 25
        Volume {} Network {} Battery {} Clock {}
      }
    }
  }
}
```

Anchors default to all false so a misconfigured window does not go fullscreen. Anchoring opposite edges, left plus right or top plus bottom, stretches that dimension across the screen minus margins. An unanchored dimension comes from `implicitWidth` or `implicitHeight`, so bars set implicit size, not `height`. Setting `height` clips children that stretch the bar.

`color` defaults to white. An opaque window shown once cannot turn transparent later unless the surface format allows it, so start transparent when fade behavior is planned.

## Anchors, margins, layers, reservation

Four settings decide placement:

- Anchors pick edges. Top plus left plus right is a bar. Top only is a floating pill or island.
- `margins` inset from anchored edges only. A top bar with `margins { top: 8 }` floats below the edge.
- Layer picks stacking. Background, bottom, top, and overlay order from lowest to highest. Overlay sits above fullscreen. A bar hidden behind windows is almost always a layer setting, not a size bug.
- `exclusiveZone` reserves space for tiled windows. It needs one or three anchored edges. Setting it switches exclusion handling on. A Waybar style bar sets it near the bar height. A floating island leaves it at zero.

Other window props worth knowing are `focusable`, which defaults off and maps to layer shell keyboard focus, `aboveWindows`, which defaults on, and `screen`, which picks the output.

## Multimonitor with Variants

`Variants` stamps one copy of a non item per model entry. Screens use it because windows are not items and `Repeater` cannot hold them.

```qml
Variants {
  model: Quickshell.screens
  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
  }
}
```

The `required property var modelData` line is load bearing. It names the current screen. Set `screen: modelData` on every stamped window.

Anything declared inside the block duplicates per screen. A timer or process inside runs N times for N monitors. Shared state belongs outside in a `Scope` or singleton:

```qml
ShellRoot {
  Scope {
    SystemClock { id: clock; precision: SystemClock.Minutes }
  }
  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      Text { text: Qt.formatDateTime(clock.date, "HH:mm") }
    }
  }
}
```

This also keeps a bar alive across hotplug. Add `Variants` and `Scope` before the config grows, since retrofit touches every window.

## Fullscreen overlays and input

A fullscreen transparent surface eats every click unless it exposes a mask. Set an empty or tight `mask` from `Quickshell`, often a `Region` around the real item, on backdrops, screen corners, and lock layers. Symptom of a missing mask is a dead desktop with no error in logs.

## Opacity warmup

The renderer skips fully transparent items. An item parked at opacity zero builds its first frame while the fade runs, so entrances stutter while exits look fine. Idle hidden items a hair above zero to keep them warm, then animate to full.
