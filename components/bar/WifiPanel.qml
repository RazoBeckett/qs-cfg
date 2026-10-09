import "../.."
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

PopupCard {
  id: root
  popoutKind: "wifi"
  contentWidth: 360
  contentHeight: 460

  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) || null
  property var pendingNetwork: null
  property string password: ""
  property var expandedNetwork: null
  property bool showPassword: false
  property bool connectAutomatically: false
  property string pendingAutoconnectName: ""
  property bool pendingAutoconnectValue: false
  property int autoconnectApplyAttempts: 0

  readonly property var wifiCenter: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values.find(n => n.connected) : null
  property var cachedCenter: null
  readonly property var connectingNetwork: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values.find(n => n.stateChanging) : null
  readonly property var effectiveCenter: wifiCenter ?? (connectingNetwork && cachedCenter ? cachedCenter : connectingNetwork)
  readonly property bool hasCenter: !!effectiveCenter && (wifiCenter !== null || connectingNetwork !== null) && (((effectiveCenter.name || "").trim()) !== "")
  readonly property var wifiAvailable: {
    if (!wifiDevice || !wifiDevice.networks) return []
    let all = [...wifiDevice.networks.values].filter(n => !n.connected).sort((a, b) => b.signalStrength - a.signalStrength)
    // always exclude the current/connecting network (shown in current-connection) and dedupe by name
    if (effectiveCenter) {
      let en = (effectiveCenter.name || "").trim()
      if (en !== "") all = all.filter(n => (n.name || "").trim() !== en)
    }
    let seen = new Set()
    let deduped = []
    for (let n of all) {
      let k = (n.name || "").trim()
      if (k === "") { deduped.push(n); continue }
      if (!seen.has(k)) { seen.add(k); deduped.push(n) }
    }
    return deduped
  }
  readonly property bool wifiOn: Networking.wifiEnabled

  onWifiCenterChanged: if (wifiCenter) cachedCenter = wifiCenter
  onOpenChanged: {
    if (open && wifiOn && wifiDevice) wifiDevice.scannerEnabled = true
    if (!open) {
      expandedNetwork = null
      pendingNetwork = null
      password = ""
      showPassword = false
      connectAutomatically = false
    }
  }

  Timer {
    interval: 4000
    running: root.open && root.wifiOn && root.wifiDevice !== null
    repeat: true
    onTriggered: if (root.wifiDevice) root.wifiDevice.scannerEnabled = true
  }

  Timer {
    id: autoconnectApplyTimer
    interval: 500
    repeat: true
    onTriggered: {
      let network = root.networkByName(root.pendingAutoconnectName)
      if (root.writeAutoconnect(network, root.pendingAutoconnectValue) || root.autoconnectApplyAttempts >= 10) {
        stop()
        root.pendingAutoconnectName = ""
        return
      }
      root.autoconnectApplyAttempts += 1
    }
  }

  function signalIcon(network) {
    let s = network ? network.signalStrength : 0
    let tier = s >= 0.75 ? 4 : s >= 0.50 ? 3 : s >= 0.25 ? 2 : 1
    if (tier === 4) return "wifi-high"
    if (tier === 3) return "wifi-medium"
    if (tier === 2) return "wifi-low"
    return "wifi-none"
  }

  function needsSecret(network) {
    if (!network) return false
    if (network.known) return false
    return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe
  }

  function securityLabel(network) {
    if (!network) return "—"
    switch (network.security) {
      case WifiSecurityType.Open: return "Open"
      case WifiSecurityType.Owe: return "OWE"
      case WifiSecurityType.Wep: return "WEP"
      case WifiSecurityType.WpaPsk: return "WPA-PSK"
      case WifiSecurityType.Wpa2Psk: return "WPA2-PSK"
      case WifiSecurityType.WpaEap: return "WPA-EAP"
      case WifiSecurityType.Wpa2Eap: return "WPA2-EAP"
      case WifiSecurityType.Sae: return "WPA3-SAE"
      case WifiSecurityType.Wpa3Eap: return "WPA3-EAP"
      default: return "Secured"
    }
  }

  function statusText(network) {
    if (!network) return ""
    if (network.stateChanging) return "Connecting..."
    if (network.connected) {
      if (network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) return "Connected, open"
      return "Connected, secured"
    }
    if (network.known) return "Secured"
    if (network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) return "Open"
    return "Secured"
  }

  function networkByName(name) {
    if (!name || !wifiDevice || !wifiDevice.networks) return null
    return wifiDevice.networks.values.find(n => n && n.name === name) || null
  }

  function writeAutoconnect(network, enabled) {
    if (!network || !network.nmSettings || network.nmSettings.length === 0) return false
    let wrote = false
    for (let settings of network.nmSettings) {
      if (!settings || typeof settings.write !== "function") continue
      settings.write({ connection: { autoconnect: enabled } })
      wrote = true
    }
    return wrote
  }

  function queueAutoconnectApply(network, enabled) {
    if (!network) return
    pendingAutoconnectName = network.name || ""
    pendingAutoconnectValue = enabled
    autoconnectApplyAttempts = 0
    if (pendingAutoconnectName !== "") autoconnectApplyTimer.restart()
  }

  function connectTo(network) {
    if (!network) return
    if (network.connected) {
      network.disconnect()
      expandedNetwork = null
      return
    }
    if (needsSecret(network)) {
      pendingNetwork = network
      expandedNetwork = network
      password = ""
      connectAutomatically = false
      return
    }
    network.connect()
    expandedNetwork = null
  }

  function confirmConnect() {
    if (pendingNetwork && password.length > 0) {
      let network = pendingNetwork
      let autoconnect = connectAutomatically
      network.connectWithPsk(password)
      queueAutoconnectApply(network, autoconnect)
      expandedNetwork = null
      pendingNetwork = null
      password = ""
    }
  }

  function forgetNetwork(network) {
    if (!network) return
    network.forget()
    if (expandedNetwork === network) expandedNetwork = null
    if (pendingNetwork === network) {
      pendingNetwork = null
      password = ""
    }
  }

  Rectangle {
    id: bg
    width: 360
    height: 460
    color: Colors.background
    border.color: Colors.border
    border.width: 1
    radius: Settings.rounding.lg
    clip: true

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        spacing: 8

        Label {
          text: "Wi-Fi"
          color: Colors.foreground
          size: Typography.sizeMD
        }
        Item { Layout.fillWidth: true }

        Toggle {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 24
          checked: root.wifiOn
          onToggled: isChecked => Networking.wifiEnabled = isChecked
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Colors.border
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ColumnLayout {
          visible: !root.wifiOn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.leftMargin: 16
          anchors.rightMargin: 16
          anchors.topMargin: 24
          spacing: 12

          RowLayout {
            spacing: 12
            Layout.fillWidth: true
            Text {
              text: "wifi-slash"
              color: Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 22
            }
            ColumnLayout {
              spacing: 1
              Layout.fillWidth: true
              Label { text: "Wi-Fi is turned off"; color: Colors.foreground }
              Label { text: "Turn on to see available networks"; color: Colors.white; size: Typography.sizeXS }
            }
          }
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: Settings.rounding.md
            color: Colors.blue
            Label { anchors.centerIn: parent; text: "Turn Wi-Fi back on"; color: Colors.black }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              hoverEnabled: true
              onEntered: parent.color = Qt.lighter(Colors.blue, 1.08)
              onExited: parent.color = Colors.blue
              onClicked: Networking.wifiEnabled = true
            }
          }
        }

        Flickable {
          id: flick
          visible: root.wifiOn
          anchors.fill: parent
          contentHeight: contentCol.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          interactive: contentHeight > height

          ColumnLayout {
            id: contentCol
            width: flick.width
            spacing: 0

            ColumnLayout {
              visible: root.hasCenter
              Layout.fillWidth: true
              spacing: 0

              Label {
                visible: root.wifiAvailable.length > 0
                text: "Current connection"
                color: Colors.white
                size: Typography.sizeXS
                Layout.leftMargin: 16
                Layout.topMargin: 8
                Layout.bottomMargin: 4
              }

              Rectangle {
                id: connectedRow
                Layout.fillWidth: true
                Layout.preferredHeight: 62 + expandedInfoWrap.height
                color: connHover.hovered ? Colors.surface : (root.expandedNetwork === root.effectiveCenter ? Colors.card : Colors.transparent)
                opacity: root.wifiCenter ? 1.0 : 0.72
                Behavior on color { ColorAnimation { duration: 90 } }
                clip: true
                HoverHandler { id: connHover }

                Item {
                  anchors.fill: parent

                  Item {
                    id: connectedHeader
                    width: parent.width
                    height: 62
                    anchors.top: parent.top
                    MouseArea {
                      id: connectedHeaderMa
                      anchors.fill: parent
                      z: 0
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (root.expandedNetwork === root.effectiveCenter) root.expandedNetwork = null
                        else root.expandedNetwork = root.effectiveCenter
                      }
                    }
                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 16
                      anchors.rightMargin: 12
                      spacing: 12
                      z: 1
                      Text { text: root.signalIcon(root.effectiveCenter); color: Colors.foreground; font.family: Typography.icons.family; font.pixelSize: 20 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Label { text: root.effectiveCenter ? ((root.effectiveCenter.name || "").trim() || "Hidden Network") : ""; color: Colors.foreground; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: root.statusText(root.effectiveCenter); color: Colors.white; size: Typography.sizeXS }
                      }
                      Item { Layout.fillWidth: true }
                      RowLayout {
                        opacity: (connHover.hovered || root.expandedNetwork === root.effectiveCenter) ? 1 : 0
                        enabled: connHover.hovered || root.expandedNetwork === root.effectiveCenter
                        spacing: 6
                        Behavior on opacity { NumberAnimation { duration: 90 } }

                        Rectangle {
                          width: 28
                          height: 28
                          radius: Settings.rounding.sm
                          color: wifiDiscHover.containsMouse ? Colors.red : Colors.card
                          border.color: wifiDiscHover.containsMouse ? Colors.red : Colors.border
                          border.width: 1
                          Behavior on color { ColorAnimation { duration: 90 } }
                          Text { anchors.centerIn: parent; text: "link-break"; color: wifiDiscHover.containsMouse ? Colors.black : Colors.foreground; font.family: Typography.icons.family; font.pixelSize: 14 }
                          MouseArea { id: wifiDiscHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: root.wifiCenter !== null; onClicked: root.connectTo(root.effectiveCenter) }
                        }
                        Rectangle {
                          visible: root.effectiveCenter ? root.effectiveCenter.known : false
                          width: 28
                          height: 28
                          radius: Settings.rounding.sm
                          color: wifiForgetHover.containsMouse ? Colors.yellow : Colors.card
                          border.color: wifiForgetHover.containsMouse ? Colors.yellow : Colors.border
                          border.width: 1
                          Behavior on color { ColorAnimation { duration: 90 } }
                          Text { anchors.centerIn: parent; text: "trash-simple"; color: wifiForgetHover.containsMouse ? Colors.black : Colors.foreground; font.family: Typography.icons.family; font.pixelSize: 13 }
                          MouseArea { id: wifiForgetHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.forgetNetwork(root.effectiveCenter) }
                        }
                      }
                    }
                  }
                  Item {
                    id: expandedInfoWrap
                    width: parent.width
                    anchors.top: connectedHeader.bottom
                    height: root.expandedNetwork === root.effectiveCenter ? expandedInfo.implicitHeight + 16 : 0
                    clip: true
                    opacity: root.expandedNetwork === root.effectiveCenter ? 1 : 0
                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    ColumnLayout {
                      id: expandedInfo
                      width: parent.width - 60
                      anchors.left: parent.left
                      anchors.leftMargin: 48
                      anchors.right: parent.right
                      anchors.rightMargin: 12
                      anchors.top: parent.top
                      anchors.topMargin: 6
                      spacing: 4
                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label { text: "Interface"; color: Colors.white; size: Typography.sizeXS; Layout.preferredWidth: 72 }
                        Label { text: root.wifiDevice ? root.wifiDevice.name : "—"; color: Colors.foreground; size: Typography.sizeXS; elide: Text.ElideRight; Layout.fillWidth: true; Layout.maximumWidth: 200 }
                      }
                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label { text: "MAC"; color: Colors.white; size: Typography.sizeXS; Layout.preferredWidth: 72 }
                        Label { text: root.wifiDevice ? root.wifiDevice.address : "—"; color: Colors.foreground; size: Typography.sizeXS; elide: Text.ElideRight; Layout.fillWidth: true; Layout.maximumWidth: 200 }
                      }
                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label { text: "Signal"; color: Colors.white; size: Typography.sizeXS; Layout.preferredWidth: 72 }
                        Label { text: root.effectiveCenter ? Math.round(root.effectiveCenter.signalStrength * 100) + "%" : "—"; color: Colors.foreground; size: Typography.sizeXS; Layout.fillWidth: true }
                      }
                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label { text: "Security"; color: Colors.white; size: Typography.sizeXS; Layout.preferredWidth: 72 }
                        Label { text: root.effectiveCenter ? securityLabel(root.effectiveCenter) : "—"; color: Colors.foreground; size: Typography.sizeXS; elide: Text.ElideRight; Layout.fillWidth: true; Layout.maximumWidth: 200 }
                      }
                    }
                  }
                }
              }

              Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Colors.border; visible: root.wifiAvailable.length > 0 }
            }

            Repeater {
              model: root.wifiOn ? root.wifiAvailable.slice(0, 20) : []

              delegate: Rectangle {
                id: netRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: 62 + netDetailWrap.height + 1
                color: rowHover.hovered ? Colors.surface : (root.expandedNetwork === modelData ? Colors.card : Colors.transparent)
                clip: true
                Behavior on color { ColorAnimation { duration: 90 } }
                HoverHandler { id: rowHover }

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  height: 1
                  color: Colors.border
                }

                Item {
                  anchors.fill: parent

                  Item {
                    id: netHeader
                    width: parent.width
                    height: 62
                    anchors.top: parent.top
                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 16
                      anchors.rightMargin: 12
                      spacing: 12
                      z: 1
                      Text { text: root.signalIcon(netRow.modelData); color: Colors.foreground; font.family: Typography.icons.family; font.pixelSize: 20 }
                      ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Label { text: netRow.modelData.name || "Hidden Network"; color: Colors.foreground; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { text: netRow.modelData === root.connectingNetwork ? "Connecting..." : root.statusText(netRow.modelData); color: Colors.white; size: Typography.sizeXS }
                      }
                      Rectangle {
                        visible: netRow.modelData ? netRow.modelData.known && (rowHover.hovered || root.expandedNetwork === netRow.modelData) : false
                        width: 28
                        height: 28
                        radius: Settings.rounding.sm
                        color: availWifiForgetHover.containsMouse ? Colors.red : Colors.card
                        border.color: availWifiForgetHover.containsMouse ? Colors.red : Colors.border
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 90 } }
                        Text { anchors.centerIn: parent; text: "trash-simple"; color: availWifiForgetHover.containsMouse ? Colors.black : Colors.foreground; font.family: Typography.icons.family; font.pixelSize: 13 }
                        MouseArea { id: availWifiForgetHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.forgetNetwork(netRow.modelData) }
                      }
                    }
                    MouseArea {
                      id: headerMa
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      z: 0
                      onClicked: {
                        if (root.expandedNetwork === netRow.modelData) {
                          root.expandedNetwork = null
                          if (root.pendingNetwork === netRow.modelData) { root.pendingNetwork = null; root.password = "" }
                        } else {
                          root.expandedNetwork = netRow.modelData
                          if (root.needsSecret(netRow.modelData)) { root.pendingNetwork = netRow.modelData; root.password = ""; root.connectAutomatically = false }
                          else root.pendingNetwork = null
                        }
                      }
                    }
                  }

                  Item {
                    id: netDetailWrap
                    width: parent.width
                    anchors.top: netHeader.bottom
                    height: root.expandedNetwork === netRow.modelData ? netDetailContent.implicitHeight + 10 : 0
                    clip: true
                    opacity: root.expandedNetwork === netRow.modelData ? 1 : 0
                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                      id: netDetailContent
                      width: parent.width - 60
                      anchors.left: parent.left
                      anchors.leftMargin: 48
                      anchors.right: parent.right
                      anchors.rightMargin: 12
                      anchors.top: parent.top
                      spacing: 8

                      Rectangle {
                        visible: netRow.modelData ? root.needsSecret(netRow.modelData) : false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: Settings.rounding.md
                        color: Colors.surface
                        border.color: passInput.activeFocus ? Colors.blue : Colors.border
                        border.width: passInput.activeFocus ? 2 : 1

                        RowLayout {
                          anchors.fill: parent
                          anchors.leftMargin: 8
                          anchors.rightMargin: 6
                          spacing: 6

                          TextInput {
                            id: passInput
                            Layout.fillWidth: true
                            text: root.pendingNetwork === netRow.modelData ? root.password : ""
                            color: Colors.foreground
                            font.pixelSize: Typography.sizeSM
                            font.family: Typography.sans.family
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            selectByMouse: true
                            readonly property bool wantsFocus: netRow.modelData ? (root.expandedNetwork === netRow.modelData && root.needsSecret(netRow.modelData)) : false
                            property int focusAttempts: 0
                            focus: wantsFocus
                            activeFocusOnTab: true
                            onWantsFocusChanged: if (wantsFocus) { focusAttempts = 0; focusTimer.restart() } else focusTimer.stop()
                            onVisibleChanged: if (visible && wantsFocus) { focusAttempts = 0; focusTimer.restart() }
                            Component.onCompleted: if (visible && wantsFocus) { focusAttempts = 0; focusTimer.restart() }
                            onTextChanged: if (root.pendingNetwork === netRow.modelData) root.password = text
                            onAccepted: root.confirmConnect()

                            Timer {
                              id: focusTimer
                              interval: 30
                              repeat: true
                              onTriggered: {
                                if (!passInput.visible || !passInput.wantsFocus) { stop(); return }
                                if (root && typeof root.forceActiveFocus === "function") root.forceActiveFocus()
                                passInput.forceActiveFocus()
                                passInput.focusAttempts += 1
                                if (passInput.activeFocus || passInput.focusAttempts > 20) stop()
                              }
                            }
                            Label {
                              anchors.verticalCenter: parent.verticalCenter
                              text: "Enter network security key"
                              color: Colors.white
                              opacity: 0.6
                              visible: passInput.text.length === 0 && !passInput.activeFocus
                            }
                            MouseArea {
                              anchors.fill: parent
                              cursorShape: Qt.IBeamCursor
                              preventStealing: true
                              propagateComposedEvents: true
                              onPressed: mouse => { if (root && typeof root.forceActiveFocus === "function") root.forceActiveFocus(); passInput.forceActiveFocus(); mouse.accepted = false }
                              onClicked: mouse => { if (root && typeof root.forceActiveFocus === "function") root.forceActiveFocus(); passInput.forceActiveFocus(); mouse.accepted = false }
                            }
                          }
                          Text {
                            id: eyeIcon
                            text: root.showPassword ? "eye" : "eye-slash"
                            color: eyeMa.containsMouse ? Colors.foreground : Colors.white
                            font.family: Typography.icons.family
                            font.pixelSize: 16
                            MouseArea {
                              id: eyeMa
                              anchors.fill: parent
                              hoverEnabled: true
                              cursorShape: Qt.PointingHandCursor
                              onClicked: root.showPassword = !root.showPassword
                            }
                          }
                        }
                        MouseArea {
                          anchors.fill: parent
                          z: -1
                          cursorShape: Qt.IBeamCursor
                          preventStealing: true
                          onPressed: { if (root && typeof root.forceActiveFocus === "function") root.forceActiveFocus(); passInput.forceActiveFocus() }
                          onClicked: { if (root && typeof root.forceActiveFocus === "function") root.forceActiveFocus(); passInput.forceActiveFocus() }
                        }
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                          width: 16
                          height: 16
                          radius: Settings.rounding.xs
                          color: autoConnectHover.containsMouse ? Colors.surface : Colors.transparent
                          border.color: root.connectAutomatically ? Colors.blue : Colors.white
                          border.width: 1
                          Behavior on color { ColorAnimation { duration: 90 } }
                          Text {
                            anchors.centerIn: parent
                            visible: root.connectAutomatically
                            text: "check"
                            color: Colors.blue
                            font.family: Typography.icons.family
                            font.pixelSize: 13
                          }
                          MouseArea {
                            id: autoConnectHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.connectAutomatically = !root.connectAutomatically
                          }
                        }
                        Label {
                          text: "Connect automatically"
                          color: autoLabelHover.containsMouse ? Colors.foreground : Colors.white
                          MouseArea {
                            id: autoLabelHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.connectAutomatically = !root.connectAutomatically
                          }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                          Layout.preferredWidth: 72
                          Layout.preferredHeight: 28
                          radius: Settings.rounding.sm
                          color: connMa.containsMouse ? Qt.lighter(Colors.blue, 1.08) : Colors.blue
                          visible: netRow.modelData ? !netRow.modelData.stateChanging : true
                          Label { anchors.centerIn: parent; text: "Connect"; color: Colors.black }
                          MouseArea { id: connMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.needsSecret(netRow.modelData)) root.confirmConnect(); else root.connectTo(netRow.modelData) } }
                        }
                        Label { visible: netRow.modelData ? netRow.modelData.stateChanging : false; text: "Connecting..."; color: Colors.white; size: Typography.sizeXS }
                      }
                    }
                  }
                }
              }
            }

            Label {
              visible: root.wifiAvailable.length === 0 && !root.hasCenter
              Layout.alignment: Qt.AlignHCenter
              Layout.topMargin: 24
              text: "No Wi-Fi networks found"
              color: Colors.white
            }
          }
        }
      }
    }
  }
}
