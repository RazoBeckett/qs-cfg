import "components"
import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
  id: root

  property string activePopoutKind: ""
  property var activePopoutOwner: null

  function requestPopout(kind, owner) {
    if (activePopoutKind === kind && activePopoutOwner === owner) return

    activePopoutKind = kind
    activePopoutOwner = owner
    NetworkMenuState.visible = kind === "wifi"
    BluetoothMenuState.visible = kind === "bluetooth"
  }

  function releasePopout(kind, owner) {
    if (kind && activePopoutKind !== kind) return
    if (owner && activePopoutOwner !== owner) return
    closePopouts()
  }

  function isPopoutActive(kind, owner) {
    return activePopoutKind === kind && activePopoutOwner === owner
  }

  function togglePopout(kind, owner) {
    if (isPopoutActive(kind, owner)) releasePopout(kind, owner)
    else requestPopout(kind, owner)
  }

  function closePopouts() {
    activePopoutKind = ""
    activePopoutOwner = null
    NetworkMenuState.visible = false
    BluetoothMenuState.visible = false
  }

  function pointInsideItem(sourceItem, position, targetItem) {
    if (!sourceItem || !position || !targetItem) return false

    try {
      let point = targetItem.mapFromItem(sourceItem, position.x, position.y)
      return point.x >= 0 && point.y >= 0 && point.x <= targetItem.width && point.y <= targetItem.height
    } catch (error) {
      return false
    }
  }

  Background {}
  WallpaperPicker { id: wallpaperPicker }
  SettingsWindow {}
  DictationOsd {}

  Component.onCompleted: closePopouts()

  Variants {
    model: Quickshell.screens

    Scope {
      id: screenScope
      required property var modelData

      PanelWindow {
        id: barWindow
        screen: screenScope.modelData

        anchors {
          top: true
          left: true
          right: true
        }
        implicitHeight: Sizing.barHeight
        color: Colors.transparent

        Item {
          id: barContent
          anchors.fill: parent

          TapHandler {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onTapped: function(eventPoint, button) {
              if (!root.activePopoutOwner) return
              if (!root.pointInsideItem(barContent, eventPoint.position, root.activePopoutOwner)) root.closePopouts()
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Sizing.barMargin
            anchors.rightMargin: Sizing.barMargin
            spacing: 0

            Workspaces {}

            Item { Layout.fillWidth: true }

            RowLayout {
              spacing: Sizing.moduleSpacing

              Brightness {
                id: brightnessPill
                shell: root
              }
              Volume {
                id: volumePill
                shell: root
              }
              Network {
                id: networkPill
                shell: root
              }
              Battery {
                id: batteryPill
                shell: root
              }
              Clock {}
            }
          }
        }
      }

      WifiPanel {
        anchorItem: networkPill
        barWindow: barWindow
        shell: root
        open: root.activePopoutKind === "wifi" && root.activePopoutOwner === networkPill && NetworkMenuState.visible
      }

      BluetoothPanel {
        anchorItem: networkPill
        barWindow: barWindow
        shell: root
        open: root.activePopoutKind === "bluetooth" && root.activePopoutOwner === networkPill && BluetoothMenuState.visible
      }

      VolumePanel {
        anchorItem: volumePill
        barWindow: barWindow
        shell: root
        open: root.activePopoutKind === "volume" && root.activePopoutOwner === volumePill
      }

      BrightnessPanel {
        anchorItem: brightnessPill
        barWindow: barWindow
        shell: root
        open: root.activePopoutKind === "brightness" && root.activePopoutOwner === brightnessPill
      }

      BatteryPanel {
        anchorItem: batteryPill
        barWindow: barWindow
        shell: root
        open: root.activePopoutKind === "battery" && root.activePopoutOwner === batteryPill
      }
    }
  }
}
