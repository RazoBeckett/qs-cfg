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
    color: Colors.transparent

    RowLayout {
      anchors.fill: parent
      spacing: Config.spacing
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
