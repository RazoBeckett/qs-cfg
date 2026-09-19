import "../.."
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.LeftButton
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  property var shell: null

  property var battery: UPower.displayDevice
  readonly property bool charging: battery ? battery.state === UPowerDeviceState.Charging : false
  readonly property bool ready: battery != null
  readonly property int level: ready ? Math.round(battery.percentage * 100) : 0
  readonly property bool critical: !charging && level <= 15
  readonly property string icon: {
    if (!ready) return "battery-warning"
    if (charging) return "battery-charging"
    if (critical) return "battery-warning"
    if (level >= 95) return "battery-full"
    if (level >= 70) return "battery-high"
    if (level >= 40) return "battery-medium"
    if (level >= 15) return "battery-low"
    return "battery-empty"
  }

  SequentialAnimation {
    id: blink
    running: root.critical
    loops: Animation.Infinite
    NumberAnimation { target: blinkTarget; property: "opacity"; from: 1; to: 0.6; duration: 250 }
    NumberAnimation { target: blinkTarget; property: "opacity"; from: 0.6; to: 1; duration: 250 }
  }

  function togglePopout() {
    if (root.shell && typeof root.shell.togglePopout === "function") root.shell.togglePopout("battery", root)
  }

  onClicked: root.togglePopout()

  child: PressableItem {
    id: blinkTarget
    implicitWidth: row.implicitWidth + 26
    implicitHeight: Sizing.barHeight
    pressed: root.pressed
    dimOnPress: !root.critical

    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: 3
      anchors.rightMargin: 3
      radius: Settings.rounding.sm
      color: root.critical ? Colors.waybarCriticalBg : Colors.transparent
      visible: root.critical
    }

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: root.charging ? Colors.waybarCharging : root.critical ? Colors.foreground : Colors.foreground
        font.family: Typography.icons.family
        font.pixelSize: 15
      }

      Label {
        text: root.ready ? root.level + "%" : "-"
        color: root.charging ? Colors.waybarCharging : root.critical ? Colors.foreground : Colors.foreground
        weight: Font.Bold
      }
    }
  }
}
