import "../.."
import QtQuick
import QtQuick.Layouts

// Segmented control ported from COSS UI: a muted well with a sliding
// indicator over the checked segment. The rest stay flat and only
// brighten on hover.
Item {
  id: root

  property var segments: []
  property int currentIndex: 0
  property string size: "default"

  signal selected(int index)

  readonly property int itemHeight: size === "sm" ? 24 : size === "lg" ? 32 : 28

  implicitWidth: segRow.implicitWidth + 4
  implicitHeight: root.itemHeight + 4

  Rectangle {
    anchors.fill: parent
    radius: Settings.rounding.md
    color: Colors.surface
  }

  Rectangle {
    id: slide
    visible: segRepeater.count > 0 && root.currentIndex >= 0 && root.currentIndex < segRepeater.count
    x: {
      segRepeater.count
      let item = segRepeater.itemAt(root.currentIndex)
      return 2 + (item ? item.x : 0)
    }
    y: 2
    width: {
      segRepeater.count
      let item = segRepeater.itemAt(root.currentIndex)
      return item ? item.width : 0
    }
    height: root.itemHeight
    radius: Settings.rounding.sm
    color: Colors.background
    border.color: Colors.border
    border.width: 1
    Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
  }

  RowLayout {
    id: segRow
    anchors.fill: parent
    anchors.margins: 2
    spacing: 2

    Repeater {
      id: segRepeater
      model: root.segments

      delegate: Rectangle {
        required property var modelData
        required property int index
        readonly property bool isActive: root.currentIndex === index
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Colors.transparent

        Label {
          anchors.centerIn: parent
          text: modelData
          size: Typography.sizeXS
          color: isActive ? Colors.foreground : (segMa.containsMouse ? Colors.foreground : Colors.white)
        }

        MouseArea {
          id: segMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.selected(index)
        }
      }
    }
  }
}
