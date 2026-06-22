import "components"
import Quickshell
import QtQuick
import QtQuick.Layouts

ShellRoot {
  PanelWindow {
    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: Config.height
    // color: "transparent"
    color: "transparent"

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Config.margin
      anchors.rightMargin: Config.margin

      Workspaces {}

      Item { Layout.fillWidth: true }

      Volume {}

      Network {}

      Battery {}

      Clock {}
    }
  }
}
