# Services

System truth. Read this when a widget needs live data.

## Singleton pattern

One source of truth per service. A file with `pragma Singleton` and a `Singleton` root is created once and read everywhere by filename.

```qml
// Time.qml
pragma Singleton
import Quickshell
import QtQuick

Singleton {
  readonly property string time: Qt.formatDateTime(clock.date, "ddd MMM d hh:mm:ss AP t yyyy")
  SystemClock { id: clock; precision: SystemClock.Seconds }
}
```

Any file then reads `Time.time`. Keep the timer inside the singleton so ten bars still tick once. Same shape fits volume, network, theme, and icon helpers. Core modules are `Quickshell`, `Quickshell.Io`, `Quickshell.Widgets`, `Quickshell.Hyprland`, `Quickshell.Networking`, plus `Quickshell.Services.*` for desktop services.

## Clock

Use `SystemClock`, not a polled date command.

```qml
SystemClock { id: clock; precision: SystemClock.Minutes }
Text { text: Qt.formatDateTime(clock.date, "HH:mm") }
```

Set precision to the displayed unit. Minutes precision for a minute clock saves wakeups. A `Process` plus `StdioCollector` plus `Timer` version works but spawns a command every tick and gets thrown away once `SystemClock` appears, so skip it for real clocks.

## Workspaces on Hyprland

Import `Quickshell.Hyprland`. The compositor hands a sorted, self updating list. A common bar stamps nine slots and looks each one up:

```qml
import Quickshell.Hyprland

RowLayout {
  spacing: 6
  Repeater {
    model: 9
    Rectangle {
      required property int index
      property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
      property bool isActive: Hyprland.focusedWorkspace?.id === index + 1
      implicitWidth: label.width + 14
      implicitHeight: 22
      color: isActive ? "#0F211F" : "transparent"
      Behavior on color { ColorAnimation { duration: 150 } }
      Text { id: label; anchors.centerIn: parent; text: parent.index + 1 }
      MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("workspace " + (parent.index + 1)) }
    }
  }
}
```

Notes from working configs:

- Slot math is `index + 1`. Repeater counts from zero, workspaces from one.
- `Hyprland.focusedWorkspace` is briefly null during switches, so guard with `?.`.
- Filter special workspaces by id and filter per monitor before sorting by number.
- Busy state often reads `modelData.toplevels.values.length`.
- Dispatch strings follow the compositor config dialect. A string that works on classic Hyprland config silently fails on newer Lua based dispatch, so verify the exact call on the target machine.

## Battery with UPower

Import `Quickshell.Services.UPower`. Read the display device and derive display state with readonly props.

```qml
property var battery: UPower.displayDevice
readonly property int level: Math.round(battery.percentage * 100)
readonly property bool charging: battery.state === UPowerDeviceState.Charging
```

Watch the capitals in `UPowerDeviceState.Charging`. Percentage is 0 to 1, so scale for display. Icon fonts such as Material Design list battery tiers at consecutive codepoints, so sequential math walks them and one off states use direct addresses. Verify codepoints against the font release in use, since gaps exist.

## Audio with Pipewire

Import `Quickshell.Services.Pipewire`. Live updates need an explicit tracker, or the view freezes at load values.

```qml
property var sync: Pipewire.defaultAudioSink
readonly property bool ready: sync && sync.ready
readonly property bool muted: ready && sync.audio.muted
readonly property int vol: ready ? Math.round(sync.audio.volume * 100) : 0
PwObjectTracker { objects: [root.sync] }
```

Guard every read with `ready`. The sink is null or unready at startup.

## Network

Import `Quickshell.Networking`. There is no single current wifi object. Drill from devices to the connected network:

```qml
property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
property var active: wifiDevice?.networks.values.find(n => n.connected) ?? null
readonly property real strength: active?.signalStrength ?? 0
```

Watch the capital in `DeviceType.Wifi`. Signal is 0 to 1. Guard for missing wifi hardware, disconnects, and wired only machines, where each level is null. Tiered wifi icons follow the same consecutive codepoint trick as battery, with some fonts spacing tiers by steps instead of ones.

## Media, tray, and the rest

`Quickshell.Services.Mpris` tracks players for album art, title, and transport. `Quickshell.Services.SystemTray` feeds tray icons. Keep raw album art behind an accent tint so clashing covers do not break the theme. Media cards show title, artist, progress, and prev, play, next controls bound to the active player.

## Process escape hatch

`Quickshell.Io` covers what services miss. `Process` with a `command` array plus `running`, `StdioCollector` for output text, and `Timer` for polling form the classic trio. Parse in the collector callback and expose a property, so widgets bind to data and never touch the process. Example shape is date polling during learning only. Production code prefers the typed service.

Use POSIX `sh` for shell syntax, never bash-only syntax. Pass pipes and redirects through `sh -c`. For a fixed command without shell syntax, give every argument directly to `Process.command`.
