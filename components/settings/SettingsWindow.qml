import "../.."
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

/*
 * Host window for the settings menu. Real toplevel window titled
 * "Settings" so it shows in Alt Tab and stays open until closed.
 * Close with the window X button, Escape, or Win+I toggle.
 * Toggle with `qs ipc call settings toggle` (bound to Win+I in Hyprland).
 */
Scope {
  id: root

  property bool open: false

  function toggle(): void {
    if (root.open) menu.playClose()
    else root.open = true
  }

  IpcHandler {
    target: "settings"

    function toggle(): void {
      root.toggle()
    }

    function open(): void {
      root.open = true
    }

    function close(): void {
      if (root.open) menu.playClose()
    }
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "settings-toggle"
    description: "Toggle settings menu"
    onPressed: root.toggle()
  }

  FloatingWindow {
    id: win
    title: "Settings"
    minimumSize: Qt.size(640, 520)
    implicitWidth: 880
    implicitHeight: 600
    visible: root.open || menu.busy
    color: Colors.background

    onClosed: {
      root.open = false
      menu.resetIntro()
    }

    SettingsMenu {
      id: menu
      anchors.fill: parent
      open: root.open
      settingsWindow: win
      onCloseFinished: root.open = false
    }
  }
}
