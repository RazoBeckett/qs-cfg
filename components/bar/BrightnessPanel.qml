import "../.."
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "brightness"
  contentWidth: 360
  contentHeight: 108

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
  readonly property real fraction: ready ? level / 100 : 0
  readonly property var presets: [1, 25, 50, 75, 100]
  readonly property int activePresetIndex: {
    if (!ready) return -1
    for (let i = 0; i < presets.length; i++) if (presets[i] === level) return i
    return -1
  }

  function setBrightnessFraction(f) {
    if (!root.ready) return
    let pct = Math.round(Math.max(0, Math.min(1, f)) * 100)
    pct = Math.max(1, Math.min(100, pct))
    Quickshell.execDetached(["brightnessctl", "set", pct + "%"])
  }

  function setBrightnessPct(pct) {
    if (!root.ready) return
    let clamped = Math.max(1, Math.min(100, Math.round(pct)))
    Quickshell.execDetached(["brightnessctl", "set", clamped + "%"])
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

  Rectangle {
    id: bg
    width: 360
    height: 108
    color: Colors.background
    border.color: Colors.border
    border.width: 1
    radius: Settings.rounding.lg
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      anchors.topMargin: 12
      anchors.bottomMargin: 10
      spacing: 12

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: 12

        Text {
          text: root.icon
          color: Colors.foreground
          font.family: Typography.icons.family
          font.pixelSize: 18
          Layout.preferredWidth: 22
        }

        Slider {
          id: sliderRoot
          Layout.fillWidth: true
          Layout.preferredHeight: 24
          fraction: root.fraction
          ready: root.ready
          trackHeight: 4
          thumbBaseWidth: 20
          thumbBaseHeight: 14
          fillColor: Colors.blue
          onMoved: f => root.setBrightnessFraction(f)
        }

        Label {
          text: root.ready ? root.level + "%" : "-"
          color: Colors.white
          Layout.preferredWidth: 36
          horizontalAlignment: Text.AlignRight
        }
      }

      Item {
        id: presetContainer
        Layout.fillWidth: true
        Layout.preferredHeight: 28

        Rectangle {
          id: presetHighlight
          visible: root.activePresetIndex >= 0
          width: (parent.width - 24) / 5
          height: 28
          x: root.activePresetIndex * (width + 6)
          color: Colors.card
          border.color: Colors.blue
          border.width: 1
          radius: Settings.rounding.sm
          Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
          Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }

        RowLayout {
          anchors.fill: parent
          spacing: 6

          Repeater {
            model: root.presets
            delegate: Rectangle {
              required property var modelData
              required property int index
              readonly property bool isActive: root.ready && root.level === modelData
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              radius: Settings.rounding.sm
              color: (chipMa.containsMouse && !isActive) ? Colors.surface : Colors.transparent
              border.color: isActive ? Colors.transparent : Colors.border
              border.width: 1

            Label {
              anchors.centerIn: parent
              text: modelData + "%"
              color: isActive ? Colors.blue : (chipMa.containsMouse ? Colors.foreground : Colors.white)
            }

            MouseArea {
              id: chipMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.ready
              onClicked: root.setBrightnessPct(modelData)
            }
          }
        }
        }
      }
    }
  }
}
