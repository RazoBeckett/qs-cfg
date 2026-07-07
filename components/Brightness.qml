import ".."
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  // sysfs backlight device name under /sys/class/backlight/
  property string device: "intel_backlight"
  readonly property string dir: `/sys/class/backlight/${device}`

  readonly property bool ready: brightness.loaded && maxBrightness.loaded
  readonly property real raw: brightness.loaded ? parseFloat(brightness.text()) : 0
  readonly property real max: maxBrightness.loaded ? parseFloat(maxBrightness.text()) : 1
  readonly property int level: ready ? Math.round((raw / max) * 100) : 0

  // 15 linear moon faces: new moon 0xe38d at 0% up to
  // full moon 0xe39b at 100%. The regular weather-moon series
  // is contiguous, so codepoint = 0xe38d + index.
  readonly property int moonIndex: Math.min(14, Math.max(0, Math.round((root.level / 100) * 14)))
  readonly property string icon: String.fromCodePoint(0xe38d + root.moonIndex)

  Text {
    text: root.icon
    color: Colors.yellow
    font: Config.iconFont
  }

  Text {
    text: root.ready ? root.level + "%" : "-"

    color: Colors.foreground

    font: Config.font
  }

  function adjustBrightness(delta) {
    if (!root.ready) return
    // Raw sysfs writes are permission-denied for non-root (intel_backlight's
    // brightness file is root:root 0644), so go through brightnessctl, which
    // uses systemd-logind's D-Bus SetBrightness (polkit-authenticated).
    var sign = delta >= 0 ? "+" : "-"
    Quickshell.execDetached(["brightnessctl", "set", `${Math.abs(delta)}%${sign}`])
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: wheel => {
      if (wheel.angleDelta.y > 0) root.adjustBrightness(5)
      else if (wheel.angleDelta.y < 0) root.adjustBrightness(-5)
    }
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
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

}
