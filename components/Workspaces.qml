import ".."
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 6

  Repeater {
    model: Hyprland.workspaces.values

    Rectangle {
      id: wsButton
      required property var modelData

      property var ws: modelData
      property bool isActive: Hyprland.focusedWorkspace?.id === ws.id

      implicitWidth: label.implicitWidth + 14
      implicitHeight: 22
      radius: 6

      color: isActive ? Colors.yellow : Colors.transparent

      Behavior on color {
        ColorAnimation { duration: 150 }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.ws.id
        color: wsButton.isActive ? Colors.black : Colors.foreground
        font: Config.font
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsButton.ws.id + " })")
      }

    }
  }
}
