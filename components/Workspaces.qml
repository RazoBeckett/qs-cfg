import ".."
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 6

  Repeater {
    model: 9

    Rectangle {
      id: wsButton
      required property int index

      property var ws: Hyprland.workspaces.values.find(w => w.id  === index + 1)
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

      implicitWidth: label.implicitWidth + 14
      implicitHeight: 22
      radius: 6

      color: isActive ? Colors.yellow : (ws ? Colors.black : "transparent")

      Behavior on color {
        ColorAnimation { duration: 150 }
      }

      Text {
        id: label
        anchors.centerIn: parent
        text: wsButton.index + 1
        color: wsButton.isActive ? Colors.black : (wsButton.ws ? Colors.foreground : Colors.white)
        font: Config.font
      }

      MouseArea {
        anchors.fill: parent
        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })")
      }

    }
  }
}
