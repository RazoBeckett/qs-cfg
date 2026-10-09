import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  spacing: 4

  SettingsRow {
    title: "Genie animation"
    subtitle: "Distort popups as they open and close"
    Layout.fillWidth: true

    Rectangle {
      Layout.preferredWidth: 44
      Layout.preferredHeight: 24
      Layout.alignment: Qt.AlignVCenter
      color: Colors.transparent
      border.color: Colors.border
      border.width: 1
      radius: Settings.rounding.md

      Toggle {
        anchors.fill: parent
        checked: Settings.ui.genie
        onToggled: c => Settings.ui.genie = c
      }
    }
  }

  SettingsRow {
    title: "Rounding"
    subtitle: "Outer radius, like Hyprland decoration:rounding. Inner pieces divide by 1.618."
    Layout.fillWidth: true

    Item {
      Layout.preferredWidth: 240
      Layout.preferredHeight: 32
      Layout.alignment: Qt.AlignVCenter

      RowLayout {
        anchors.fill: parent
        spacing: 12

        Label {
          text: Settings.ui.rounding + "px"
          color: Colors.foreground
          useMono: true
          Layout.preferredWidth: 42
          horizontalAlignment: Text.AlignRight
        }

        Slider {
          Layout.fillWidth: true
          Layout.preferredHeight: 32
          Layout.alignment: Qt.AlignVCenter
          // 0..24 range — covers typical Hyprland rounding (0-20) with a little headroom
          fraction: Math.max(0, Math.min(1, Settings.ui.rounding / 24))
          ready: true
          onMoved: f => Settings.ui.rounding = Math.round(f * 24)
        }
      }
    }
  }
}
