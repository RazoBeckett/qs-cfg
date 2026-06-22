import ".."
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  spacing: 4
  Repeater {
    model: 9
    Text {
      required property int index
      property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
      text: index + 1
      color: isActive ? "#ffffff" : "#eed5d9"
      font: Config.font
    }
  }
}
