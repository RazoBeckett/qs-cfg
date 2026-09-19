import "../.."
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.LeftButton
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  property var shell: null
  property var barWindow: null

  property string device: "intel_backlight"
  readonly property string dir: `/sys/class/backlight/${device}`
  readonly property bool ready: brightness.loaded && maxBrightness.loaded
  readonly property real raw: brightness.loaded ? parseFloat(brightness.text()) : 0
  readonly property real max: maxBrightness.loaded ? parseFloat(maxBrightness.text()) : 1
  readonly property int level: ready ? Math.round((raw / max) * 100) : 0
  readonly property string icon: {
    if (!ready) return "sun"
    if (level <= 33) return "sun-dim"
    return "sun"
  }
  readonly property string tipText: root.ready ? root.level + "%" : "-"
  readonly property bool tipHovered: root.containsMouse && !(root.shell && root.shell.activePopoutOwner === root)

  child: PressableItem {
    implicitWidth: row.implicitWidth + 26
    implicitHeight: Sizing.barHeight
    pressed: root.pressed

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: Colors.foreground
        font.family: Typography.icons.family
        font.pixelSize: 14
      }
    }
  }

  function adjustBrightness(delta) {
    if (!root.ready) return
    var sign = delta >= 0 ? "+" : "-"
    Quickshell.execDetached(["brightnessctl", "set", `${Math.abs(delta)}%${sign}`])
  }

  function togglePopout() {
    if (root.shell && typeof root.shell.togglePopout === "function") root.shell.togglePopout("brightness", root)
  }

  onClicked: root.togglePopout()

  onWheel: wheel => {
    if (wheel.angleDelta.y > 0) root.adjustBrightness(5)
    else if (wheel.angleDelta.y < 0) root.adjustBrightness(-5)
  }

  FileView {
    id: brightness
    path: `${root.dir}/brightness`
    watchChanges: true
    onFileChanged: reload()
  }

  FileView {
    id: maxBrightness
    path: `${root.dir}/max_brightness`
  }

  Tooltip {
    anchorItem: root
    barWindow: root.barWindow
    text: root.tipText
    hovered: root.tipHovered && root.barWindow !== null
    useMono: true
  }
}
