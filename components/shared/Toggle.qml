import "../.."
import QtQuick

Item {
  id: root

  property bool checked: false
  property color onColor: Colors.blue
  property color offColor: Colors.card
  property color thumbColor: Colors.foreground

  signal toggled(bool checked)
  signal clicked()

  implicitWidth: 44
  implicitHeight: 24

  Rectangle {
    id: track
    anchors.fill: parent
    radius: Settings.rounding.md
    color: root.checked ? root.onColor : root.offColor
    border.color: toggleMa.containsMouse ? Colors.border : Colors.transparent
    border.width: 1
    Behavior on color { ColorAnimation { duration: 120 } }
  }

  Rectangle {
    id: thumb
    width: 18
    height: 18
    radius: Settings.rounding.sm
    color: root.thumbColor
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? parent.width - width - 3 : 3
    scale: 1
    transformOrigin: Item.Center
    Behavior on x {
      NumberAnimation {
        duration: 320
        easing.type: Easing.OutBack
        easing.overshoot: 1.16
      }
    }
  }

  SequentialAnimation {
    id: thumbScaleAnim
    NumberAnimation { target: thumb; property: "scale"; to: 1.14; duration: 110; easing.type: Easing.OutCubic }
    NumberAnimation { target: thumb; property: "scale"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
  }

  onCheckedChanged: thumbScaleAnim.restart()

  MouseArea {
    id: toggleMa
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    enabled: root.enabled
    onClicked: {
      root.toggled(!root.checked)
      root.clicked()
    }
  }
}
