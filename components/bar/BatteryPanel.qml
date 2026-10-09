import "../.."
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "battery"
  contentWidth: 384
  contentHeight: 218

  readonly property var battery: UPower.displayDevice
  readonly property bool ready: battery != null && battery.isPresent
  readonly property bool isCharging: ready && battery.state === UPowerDeviceState.Charging
  readonly property bool isDischarging: ready && battery.state === UPowerDeviceState.Discharging
  readonly property bool isFullyCharged: ready && battery.state === UPowerDeviceState.FullyCharged
  readonly property bool isPendingCharge: ready && battery.state === UPowerDeviceState.PendingCharge
  readonly property bool isEmpty: ready && battery.state === UPowerDeviceState.Empty
  readonly property int level: ready ? Math.round(battery.percentage * 100) : 0
  readonly property real fraction: ready ? Math.max(0, Math.min(1, battery.percentage)) : 0
  readonly property double rawTimeToEmpty: ready ? Number(battery.timeToEmpty) : 0
  readonly property double rawTimeToFull: ready ? Number(battery.timeToFull) : 0

  function normalizeSeconds(v) {
    if (!v || isNaN(v) || v <= 0) return 0
    // UPower reports seconds; if value looks like hours fraction (< 200) treat as hours
    if (v < 300) return v * 3600
    return v
  }

  function formatDuration(seconds) {
    let s = normalizeSeconds(seconds)
    if (s <= 0) return ""
    let h = Math.floor(s / 3600)
    let m = Math.floor((s % 3600) / 60)
    if (h > 0 && m > 0) return h + " hour" + (h !== 1 ? "s" : "") + " " + m + " minute" + (m !== 1 ? "s" : "")
    if (h > 0) return h + " hour" + (h !== 1 ? "s" : "")
    if (m > 0) return m + " minute" + (m !== 1 ? "s" : "")
    return "less than a minute"
  }

  readonly property string timeToEmptyLabel: formatDuration(rawTimeToEmpty)
  readonly property string timeToFullLabel: formatDuration(rawTimeToFull)

  readonly property string statusLine1: {
    if (!ready) return "No battery"
    if (isFullyCharged) return "Fully charged"
    if (isPendingCharge) return "Plugged in"
    if (isCharging) {
      if (timeToFullLabel !== "") return timeToFullLabel
      return "Charging"
    }
    if (isDischarging) {
      if (timeToEmptyLabel !== "") return timeToEmptyLabel
      return "On battery"
    }
    if (isEmpty) return "Empty"
    return UPowerDeviceState.toString(battery.state)
  }

  readonly property string statusLine2: {
    if (!ready) return ""
    if (isFullyCharged) return ""
    if (isPendingCharge) return "not charging"
    if (isCharging) {
      if (timeToFullLabel !== "") return "until full"
      return ""
    }
    if (isDischarging) {
      if (timeToEmptyLabel !== "") return "remaining"
      return ""
    }
    return ""
  }

  readonly property string icon: {
    if (!ready) return "battery-warning"
    if (isPendingCharge) return "plug-charging"
    if (isCharging) return "battery-charging"
    if (isFullyCharged || level >= 95) return "battery-full"
    if (level <= 15) return "battery-warning"
    if (level >= 70) return "battery-high"
    if (level >= 40) return "battery-medium"
    return "battery-low"
  }
  readonly property double energy: ready ? Number(battery.energy) : 0
  readonly property double energyCapacity: ready ? Number(battery.energyCapacity) : 0
  readonly property double rateRaw: ready ? Number(battery.changeRate) : 0
  readonly property double healthRaw: ready ? Number(battery.healthPercentage) : 0
  readonly property bool healthSupported: ready ? Boolean(battery.healthSupported) : false
  readonly property var profiles: [
    { profile: PowerProfile.PowerSaver, label: "Power Save", icon: "leaf" },
    { profile: PowerProfile.Balanced, label: "Balanced", icon: "scales" },
    { profile: PowerProfile.Performance, label: "Performance", icon: "lightning" }
  ]
  readonly property int activeProfileIndex: {
    for (let i = 0; i < profiles.length; i++) if (PowerProfiles.profile === profiles[i].profile) return i
    return -1
  }

  function formatRate(v) {
    if (!ready || isNaN(v) || Math.abs(v) < 0.05) return "—"
    let rounded = Number(v).toFixed(1)
    if (rounded.endsWith(".0")) rounded = rounded.slice(0, -2)
    return rounded + "W"
  }

  function formatHealth(v, supported) {
    if (!ready || !supported || isNaN(v) || v <= 0) return "—"
    let pct = v > 1.5 ? v : v * 100
    return Math.round(pct) + "%"
  }

  function formatEnergy(e, cap) {
    if (!ready || isNaN(e) || isNaN(cap) || cap <= 0) return "—"
    return e.toFixed(1) + " / " + cap.toFixed(1) + " Wh"
  }

  readonly property string rateLabel: formatRate(rateRaw)
  readonly property string healthLabel: formatHealth(healthRaw, healthSupported)
  readonly property string energyLabel: formatEnergy(energy, energyCapacity)

  Rectangle {
    id: bg
    width: 384
    height: 218
    color: Colors.background
    border.color: Colors.border
    border.width: 1
    radius: Settings.rounding.lg
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      anchors.topMargin: 16
      anchors.bottomMargin: 14
      spacing: 14

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

      Text {
        text: root.icon
        color: Colors.foreground
        font.family: Typography.icons.family
        font.pixelSize: 28
        Layout.preferredWidth: 36
        Layout.alignment: Qt.AlignVCenter
      }

      // Percentage — large thin number like Win10
      Text {
        id: percentText
        text: root.ready ? root.level + "%" : "--"
        color: Colors.foreground
        font.family: Typography.mono.family
        // scale-exempt: hero numeral pinned to this fixed 360x148 card; the text scale tops out at sizeLG
        font.pixelSize: 32
        font.weight: Font.Light
        font.letterSpacing: -0.5
        Layout.alignment: Qt.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
      }

      // Status text — two lines: duration + suffix (remaining / until full), right-aligned
      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 2

        Label {
          id: line1
          text: root.statusLine1
          color: root.isFullyCharged ? Colors.white : Colors.foreground
          elide: Text.ElideRight
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignRight
          opacity: root.ready ? 0.92 : 0.5
        }

        Label {
          id: line2
          text: root.statusLine2
          color: Colors.white
          elide: Text.ElideRight
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignRight
          visible: text !== ""
          opacity: 0.72
        }
      }
      }

      // Energy progress bar — thin track with fill at fraction
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 6

        Rectangle {
          id: energyTrack
          anchors.fill: parent
          radius: Settings.rounding.md
          color: Colors.card
        }

        Rectangle {
          id: energyGlow
          visible: root.isCharging
          anchors.left: energyTrack.left
          anchors.verticalCenter: energyTrack.verticalCenter
          height: energyTrack.height + 10
          width: energyFill.width
          radius: Settings.rounding.lg
          color: Colors.waybarCharging
          opacity: 0.18
          z: -1
          Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        Rectangle {
          id: energyFill
          anchors.left: energyTrack.left
          anchors.verticalCenter: energyTrack.verticalCenter
          height: energyTrack.height
          radius: Settings.rounding.md
          width: Math.max(energyTrack.height, Math.round(energyTrack.width * root.fraction))
          color: root.isCharging ? Colors.waybarCharging : root.level <= 15 && !root.isFullyCharged ? Colors.waybarCriticalBg : Colors.foreground
          transformOrigin: Item.Left
          scale: 1
          Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        // macOS battery menu breathe — slow 0.92 -> 1.02 scale + glow
        SequentialAnimation {
          id: chargePulse
          running: root.isCharging
          loops: Animation.Infinite
          NumberAnimation { target: energyFill; property: "scale"; from: 0.92; to: 1.02; duration: 1200; easing.type: Easing.InOutSine }
          NumberAnimation { target: energyFill; property: "scale"; from: 1.02; to: 0.92; duration: 1200; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
          id: chargeGlowPulse
          running: root.isCharging
          loops: Animation.Infinite
          NumberAnimation { target: energyGlow; property: "opacity"; from: 0.10; to: 0.30; duration: 1200; easing.type: Easing.InOutSine }
          NumberAnimation { target: energyGlow; property: "opacity"; from: 0.30; to: 0.10; duration: 1200; easing.type: Easing.InOutSine }
        }

        Connections {
          target: root
          function onIsChargingChanged() { if (!root.isCharging) { energyFill.scale = 1; energyGlow.opacity = 0.18 } }
        }
      }

      // Power profiles via the native PowerProfiles service; Performance dims when unsupported
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: Settings.rounding.md
        color: Colors.transparent
        border.color: Colors.border
        border.width: 1

        Rectangle {
          id: profileHighlight
          visible: root.activeProfileIndex >= 0
          width: (parent.width - 20) / 3
          height: 32
          x: 6 + root.activeProfileIndex * (width + 4)
          y: 6
          color: Colors.card
          border.color: Colors.blue
          border.width: 1
          radius: Settings.rounding.sm
          Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
          Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 6
          anchors.rightMargin: 6
          anchors.topMargin: 6
          anchors.bottomMargin: 6
          spacing: 4

          Repeater {
            model: root.profiles
            delegate: Rectangle {
              id: chip
              required property var modelData
              readonly property bool isActive: PowerProfiles.profile === modelData.profile
              readonly property bool isUnavailable: modelData.profile === PowerProfile.Performance && !PowerProfiles.hasPerformanceProfile
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: Settings.rounding.sm
              color: chipMa.pressed ? Colors.card : (chipMa.containsMouse && !isActive) ? Colors.surface : Colors.transparent
              opacity: isUnavailable ? 0.4 : 1

              RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  text: chip.modelData.icon
                  color: chip.isActive ? Colors.blue : Colors.white
                  font.family: Typography.icons.family
                  font.pixelSize: 15
                }

                Label {
                  text: chip.modelData.label
                  color: chip.isActive ? Colors.blue : (chipMa.containsMouse ? Colors.foreground : Colors.white)
                }
              }

              MouseArea {
                id: chipMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !chip.isUnavailable
                onClicked: PowerProfiles.profile = chip.modelData.profile
              }
            }
          }
        }
      }

      // Details row: energy · rate · health
      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          Label {
            text: "Energy"
            color: Colors.white
            size: Typography.sizeXS
            opacity: 0.55
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
          Label {
            text: root.energyLabel
            color: Colors.foreground
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          Label {
            text: "Power"
            color: Colors.white
            size: Typography.sizeXS
            opacity: 0.55
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
          }
          Label {
            text: root.rateLabel
            color: root.isCharging ? Colors.waybarCharging : Colors.foreground
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          Label {
            text: "Health"
            color: Colors.white
            size: Typography.sizeXS
            opacity: 0.55
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
          }
          Label {
            text: root.healthLabel
            color: Colors.foreground
            elide: Text.ElideRight
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
          }
        }
      }
    }
  }
}
