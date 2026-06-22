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
    implicitHeight: 30
    // color: "transparent"
    color: Colors.background

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14

      Workspaces {}

      Item { Layout.fillWidth: true }

      Clock {}
    }
  }
}
