import ".."
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root
  anchors {
    top: true
    right: true
  }
  margins.top: Config.height + Config.margin
  margins.right: Config.margin
  implicitWidth: 820
  implicitHeight: 600
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  color: Colors.transparent
  focusable: NetworkMenuState.visible
  visible: NetworkMenuState.visible

  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) || null
  property var bluetoothAdapter: Bluetooth.defaultAdapter || null
  property string activeMode: "wifi"
  property real enterProgress: visible ? 1 : 0
  property real orbitOffset: 0
  property real pulse: 0
  property var pendingNetwork: null
  property string password: ""

  readonly property var wifiCenter: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values.find(n => n.connected) : null
  readonly property var wifiAvailable: wifiDevice && wifiDevice.networks
    ? [...wifiDevice.networks.values].filter(n => !n.connected).sort((a, b) => b.signalStrength - a.signalStrength).slice(0, 6)
    : []
  readonly property var btCenter: bluetoothAdapter && bluetoothAdapter.devices ? (bluetoothAdapter.devices.values.find(d => d.connected) || null) : null
  readonly property var btOrbit: bluetoothAdapter && bluetoothAdapter.devices
    ? bluetoothAdapter.devices.values.filter(d => d !== root.btCenter).slice(0, 6)
    : []
  readonly property var centerDevice: activeMode === "wifi" ? wifiCenter : btCenter
  readonly property var orbitSource: activeMode === "wifi" ? wifiAvailable : btOrbit

  function strandStyle(dev) {
    if (!dev) return 0
    if (dev.connected) return 2
    if (activeMode === "wifi" ? dev.known : dev.paired) return 1
    return 0
  }

  function syncOrbit() {
    let list = root.orbitSource || []
    for (let i = orbitModel.count - 1; i >= 0; i--) {
      if (!list.includes(orbitModel.get(i).device)) orbitModel.remove(i)
    }
    for (let i = 0; i < list.length; i++) {
      let dev = list[i]
      let idx = -1
      for (let j = 0; j < orbitModel.count; j++) {
        if (orbitModel.get(j).device === dev) { idx = j; break }
      }
      if (idx === -1) orbitModel.insert(i, { device: dev })
      else if (idx !== i) orbitModel.move(idx, i, 1)
    }
    while (orbitModel.count > list.length) orbitModel.remove(orbitModel.count - 1)
  }
  readonly property bool currentPower: activeMode === "wifi"
    ? Networking.wifiEnabled
    : (bluetoothAdapter ? bluetoothAdapter.enabled : false)
  readonly property bool btPresent: bluetoothAdapter !== null
  readonly property color accent: activeMode === "wifi" ? Colors.magenta : Colors.blue
  readonly property color ink: Colors.black

  property int heldCount: 0
  readonly property real baseOrbitSpeed: 2 * Math.PI / 36000
  readonly property real orbitSpeed: heldCount > 0 ? baseOrbitSpeed / 5 : baseOrbitSpeed

  Behavior on enterProgress { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
  Timer {
    interval: 16
    running: root.visible
    repeat: true
    onTriggered: root.orbitOffset += root.orbitSpeed * 16
  }
  NumberAnimation on pulse { from: 0; to: 1; duration: 1800; loops: Animation.Infinite; easing.type: Easing.InOutSine }

  ListModel { id: orbitModel }

  Timer {
    interval: 1500
    running: root.visible
    repeat: true
    onTriggered: root.syncOrbit()
  }

  Shortcut {
    sequence: "Escape"
    onActivated: NetworkMenuState.visible = false
  }
  Shortcut {
    sequence: "Tab"
    onActivated: root.activeMode = root.activeMode === "wifi" ? "bt" : "wifi"
  }

  onVisibleChanged: {
    if (visible && activeMode === "wifi" && Networking.wifiEnabled && wifiDevice) wifiDevice.scannerEnabled = true
    if (visible) syncOrbit()
  }
  onActiveModeChanged: {
    pendingNetwork = null
    if (activeMode === "wifi" && Networking.wifiEnabled && wifiDevice) wifiDevice.scannerEnabled = true
    else if (activeMode === "bt" && bluetoothAdapter && bluetoothAdapter.enabled) bluetoothAdapter.discovering = true
    syncOrbit()
  }
  Component.onCompleted: syncOrbit()

  function signalIcon(network) {
    let s = network ? network.signalStrength : 0
    let tier = s >= 0.75 ? 4 : s >= 0.50 ? 3 : s >= 0.25 ? 2 : 1
    return String.fromCodePoint(0xF091F + (tier - 1) * 3)
  }

  function deviceLabel(device) {
    if (!device) return ""
    if (activeMode === "wifi") return device.name || "Hidden Network"
    return device.name || device.deviceName || device.address
  }

  function deviceIcon(device) {
    if (activeMode === "wifi") return signalIcon(device)
    return String.fromCodePoint(0xF00AF)
  }

  function wifiStatus(network) {
    if (!network) return ""
    if (network.stateChanging) return "Connecting"
    if (network.known) return "Saved"
    if (network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) return "Open"
    return "Secured"
  }

  function btStatus(device) {
    if (!device) return ""
    if (device.pairing) return "Pairing"
    if (device.connected) return "Connected"
    if (device.paired) return "Paired"
    return "Available"
  }

  function deviceStatus(device) {
    return activeMode === "wifi" ? wifiStatus(device) : btStatus(device)
  }

  function isBusy(device) {
    if (!device) return false
    return activeMode === "wifi" ? device.stateChanging : device.pairing
  }

  function needsSecret(network) {
    if (!network) return false
    if (network.known) return false
    return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe
  }

  function triggerOrbit(device) {
    if (activeMode === "wifi") {
      if (device.connected) device.disconnect()
      else if (needsSecret(device)) {
        pendingNetwork = device
        password = ""
        passwordInput.forceActiveFocus()
      } else device.connect()
    } else {
      if (device.connected) device.disconnect()
      else if (!device.paired && !device.pairing) device.pair()
      else device.connect()
    }
  }

  function triggerCenter() {
    if (activeMode === "wifi") {
      if (centerDevice) centerDevice.disconnect()
      else requestScan()
    } else {
      if (centerDevice) centerDevice.disconnect()
      else if (bluetoothAdapter) bluetoothAdapter.discovering = true
    }
  }

  function togglePower() {
    if (activeMode === "wifi") Networking.wifiEnabled = !Networking.wifiEnabled
    else if (bluetoothAdapter) bluetoothAdapter.enabled = !bluetoothAdapter.enabled
  }

  function requestScan() {
    if (activeMode === "wifi" && wifiDevice) wifiDevice.scannerEnabled = true
    else if (activeMode === "bt" && bluetoothAdapter) bluetoothAdapter.discovering = true
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    radius: 22
    opacity: root.enterProgress
    scale: 0.96 + root.enterProgress * 0.04

    MouseArea {
      anchors.fill: parent
      onClicked: NetworkMenuState.visible = false
    }

    Rectangle {
      width: Math.max(parent.width * 0.72, 620)
      height: width
      anchors.centerIn: parent
      radius: width / 2
      color: Colors.surface
      opacity: 0.6
      rotation: -24
    }

    Repeater {
      model: 4
      delegate: Rectangle {
        required property int index
        width: 260 + index * 150
        height: width
        anchors.centerIn: parent
        radius: width / 2
        color: Colors.transparent
        border.color: Colors.white
        border.width: 1
        opacity: 0.10 - index * 0.018
      }
    }

    Item {
      id: hub
      width: Math.min(parent.width - 80, 760)
      height: Math.min(parent.height - 60, 560)
      anchors.centerIn: parent
      opacity: root.enterProgress
      scale: 0.92 + root.enterProgress * 0.08

      Canvas {
        id: strands
        anchors.fill: parent
        z: -1
        opacity: root.currentPower && orbitModel.count > 0 ? 1.0 : 0.0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Timer {
          interval: 45
          running: strands.visible
          repeat: true
          onTriggered: strands.requestPaint()
        }

        Connections {
          target: root
          function onOrbitOffsetChanged() { if (strands.visible) strands.requestPaint() }
        }

        onPaint: {
          let ctx = getContext("2d")
          ctx.reset()
          ctx.clearRect(0, 0, width, height)
          if (!strands.visible) return

          let time = Date.now() / 1000
          let tWave1 = time * 2.5
          let tWave2 = time * -1.5
          ctx.lineJoin = "round"
          ctx.lineCap = "round"

          let startX = width / 2
          let startY = height / 2
          let coreRadius = core.width / 2
          let startOffset = coreRadius + 5
          let endOffset = 40

          for (let i = 0; i < orbitRepeater.count; i++) {
            let card = orbitRepeater.itemAt(i)
            if (!card) continue
            let style = root.strandStyle(card.device)
            if (style === 0) continue
            let targetX = card.x + card.width / 2
            let targetY = card.y + card.height / 2
            let dx = targetX - startX
            let dy = targetY - startY
            let fullDist = Math.sqrt(dx * dx + dy * dy)
            if (fullDist < 10) continue

            let a = Math.atan2(dy, dx)
            let cosA = Math.cos(a)
            let sinA = Math.sin(a)
            let perpX = -sinA
            let perpY = cosA

            let drawDist = fullDist - startOffset - endOffset
            if (drawDist <= 0) continue

            let sX = startX + cosA * startOffset
            let sY = startY + sinA * startOffset
            let distanceFactor = Math.max(0, 1.0 - fullDist / 400.0)
            let coreWidth = 1 + distanceFactor * 2
            let dynAlpha = 0.2 + distanceFactor * 0.7
            let steps = 8
            let bold = style === 2
            let strandAlpha = bold ? dynAlpha : dynAlpha * 0.25

            if (bold) {
              ctx.beginPath()
              ctx.moveTo(sX, sY)
              for (let j = 1; j <= steps; j++) {
                let t = j / steps
                let dist = drawDist * t
                let env = Math.sin(t * Math.PI)
                let off = Math.sin(tWave1 + t * 6) * 6 * env + (Math.random() - 0.5) * 5 * distanceFactor
                ctx.lineTo(sX + cosA * dist + perpX * off, sY + sinA * dist + perpY * off)
              }
              ctx.lineWidth = 4 + distanceFactor * 4
              ctx.strokeStyle = root.accent
              ctx.globalAlpha = strandAlpha * 0.18
              ctx.stroke()
            }

            ctx.beginPath()
            ctx.moveTo(sX, sY)
            for (let k = 1; k <= steps; k++) {
              let tk = k / steps
              let dist = drawDist * tk
              let env = Math.sin(tk * Math.PI)
              let off = (bold ? Math.sin(tWave1 + tk * 6) : Math.cos(tWave2 + tk * 8)) * 6 * env + (Math.random() - 0.5) * (bold ? 5 : 3) * distanceFactor
              ctx.lineTo(sX + cosA * dist + perpX * off, sY + sinA * dist + perpY * off)
            }
            ctx.lineWidth = bold ? coreWidth : coreWidth * 0.7
            ctx.strokeStyle = root.accent
            ctx.globalAlpha = strandAlpha
            ctx.stroke()

            ctx.globalAlpha = 1.0
          }
        }
      }

      Repeater {
        id: orbitRepeater
        model: orbitModel
        delegate: Item {
          id: orbitSlot
          required property var device
          required property int index
          readonly property real baseAngle: (index / Math.max(1, orbitModel.count)) * Math.PI * 2 - Math.PI / 2
          property real animatedBaseAngle: baseAngle
          Behavior on animatedBaseAngle { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }
          readonly property real angle: animatedBaseAngle + root.orbitOffset
          width: 190
          height: 64
          x: hub.width / 2 + Math.cos(angle) * Math.min(hub.width * 0.34, 290) * (0.25 + 0.75 * entryAnim) - width / 2
          y: hub.height / 2 + Math.sin(angle) * Math.min(hub.height * 0.34, 220) * (0.25 + 0.75 * entryAnim) - height / 2

          property bool isLoaded: false
          property real entryAnim: isLoaded ? 1.0 : 0.0
          opacity: isLoaded ? 1.0 : 0.0
          scale: isLoaded ? 1.0 : 0.0
          Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
          Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
          Behavior on entryAnim { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

          Timer {
            id: loadTimer
            interval: 40 + index * 30
            onTriggered: orbitSlot.isLoaded = true
          }
          Component.onCompleted: if (root.visible) loadTimer.restart()
          Connections {
            target: root
            function onVisibleChanged() {
              if (root.visible) {
                orbitSlot.isLoaded = false
                loadTimer.restart()
              }
            }
            function onActiveModeChanged() {
              if (root.visible) {
                orbitSlot.isLoaded = false
                loadTimer.restart()
              }
            }
          }

          HoldCard {
            anchors.fill: parent
            accentColor: root.accent
            accent: orbitSlot.device.connected
            busy: root.isBusy(orbitSlot.device)
            label: root.deviceLabel(orbitSlot.device)
            iconText: root.deviceIcon(orbitSlot.device)
            idleHint: root.deviceStatus(orbitSlot.device)
            holdHint: orbitSlot.device.connected ? "Hold to disconnect" : "Hold to connect"
            busyHint: "Connecting..."
            onPressStarted: root.heldCount++
            onPressEnded: root.heldCount--
            onTriggered: root.triggerOrbit(orbitSlot.device)
          }
        }
      }

      HoldCard {
        id: core
        width: 168
        height: width
        anchors.centerIn: parent
        radius: width / 2
        centered: true
        iconSize: 46
        accentColor: root.accent
        accent: root.centerDevice != null
        busy: root.isBusy(root.centerDevice)
        property real reveal: 0
        label: root.centerDevice
          ? root.deviceLabel(root.centerDevice)
          : root.activeMode === "wifi"
            ? (Networking.wifiEnabled ? "Wi-Fi" : "Wi-Fi Off")
            : (root.bluetoothAdapter && root.bluetoothAdapter.enabled ? "Bluetooth" : "Bluetooth Off")
        iconText: root.centerDevice
          ? root.deviceIcon(root.centerDevice)
          : root.activeMode === "wifi"
            ? (Networking.wifiEnabled ? String.fromCodePoint(0xF092D) : String.fromCodePoint(0xF05AA))
            : String.fromCodePoint(0xF00AF)
        idleHint: root.centerDevice
          ? "Connected"
          : (root.currentPower ? "Choose a network" : "Turn on to scan")
        holdHint: root.centerDevice ? "Hold to disconnect" : "Hold to scan"
        scale: (0.5 + 0.5 * reveal) * (1 + Math.sin(root.pulse * Math.PI * 2) * 0.025)
        opacity: reveal
        onPressStarted: root.heldCount++
        onPressEnded: root.heldCount--
        NumberAnimation {
          id: coreReveal
          target: core
          property: "reveal"
          from: 0
          to: 1
          duration: 500
          easing.type: Easing.OutBack
        }
        Connections {
          target: root
          function onVisibleChanged() {
            if (root.visible) {
              core.reveal = 0
              coreReveal.restart()
            }
          }
          function onActiveModeChanged() {
            if (root.visible) {
              core.reveal = 0
              coreReveal.restart()
            }
          }
        }
        onTriggered: root.triggerCenter()
      }

      Rectangle {
        id: scanCard
        width: 184
        height: 64
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        radius: 14
        color: Colors.card
        border.color: Colors.border
        border.width: 1

        RowLayout {
          anchors.centerIn: parent
          spacing: 10
          Text {
            text: String.fromCodePoint(0xF0349)
            color: root.accent
            font.family: Config.iconFont.family
            font.pixelSize: 22
          }
          ColumnLayout {
            spacing: 1
            Text { text: "Rescan"; color: root.accent; font: Config.font }
            Text { text: root.activeMode === "wifi" ? "Wi-Fi networks" : "BT devices"; color: Colors.white; font: Config.font }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestScan()
        }
      }

      Rectangle {
        id: bottomTabs
        width: 320
        height: 56
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        radius: 14
        color: Qt.rgba(1, 1, 1, 0.08)
        border.color: Colors.border
        border.width: 1

        Rectangle {
          id: activeTabHighlight
          height: bottomTabs.height - 12
          radius: 10
          y: 6
          x: 6 + (root.activeMode === "wifi" ? wifiTab.x : btTab.x)
          width: root.activeMode === "wifi" ? wifiTab.width : btTab.width
          color: root.accent
          Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
          Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
          Behavior on color { ColorAnimation { duration: 300 } }
        }

        RowLayout {
          anchors.fill: parent
          anchors.margins: 6
          spacing: 6

          Rectangle {
            id: wifiTab
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Colors.transparent
            RowLayout {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: String.fromCodePoint(0xF092D)
                color: root.activeMode === "wifi" ? root.ink : Colors.foreground
                font.family: Config.iconFont.family
                font.pixelSize: 18
                Behavior on color { ColorAnimation { duration: 200 } }
              }
              Text {
                text: "Wi-Fi"
                color: root.activeMode === "wifi" ? root.ink : Colors.foreground
                font: Config.font
                Behavior on color { ColorAnimation { duration: 200 } }
              }
            }
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activeMode = "wifi"
            }
          }

          Rectangle {
            id: btTab
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Colors.transparent
            opacity: root.btPresent ? 1 : 0.4
            RowLayout {
              anchors.centerIn: parent
              spacing: 8
              Text {
                text: String.fromCodePoint(0xF00AF)
                color: root.activeMode === "bt" ? root.ink : Colors.foreground
                font.family: Config.iconFont.family
                font.pixelSize: 18
                Behavior on color { ColorAnimation { duration: 200 } }
              }
              Text {
                text: "Bluetooth"
                color: root.activeMode === "bt" ? root.ink : Colors.foreground
                font: Config.font
                Behavior on color { ColorAnimation { duration: 200 } }
              }
            }
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              enabled: root.btPresent
              onClicked: root.activeMode = "bt"
            }
          }
        }
      }

      Rectangle {
        width: 56
        height: width
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        radius: width / 2
        color: root.currentPower ? root.accent : Colors.card
        border.color: root.currentPower ? Colors.transparent : Colors.border
        border.width: 1
        scale: powerMa.containsMouse ? 1.06 : 1.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 300 } }

        Text {
          anchors.centerIn: parent
          text: String.fromCodePoint(0xF0425)
          color: root.currentPower ? root.ink : Colors.foreground
          font.family: Config.iconFont.family
          font.pixelSize: 24
        }

        MouseArea {
          id: powerMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.togglePower()
        }
      }
    }

    Rectangle {
      anchors.centerIn: parent
      width: 320
      height: 178
      visible: root.pendingNetwork !== null
      radius: 14
      color: Colors.card
      border.color: root.accent
      border.width: 2

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
          Layout.fillWidth: true
          text: "Connect to " + (root.pendingNetwork ? root.pendingNetwork.name : "")
          color: root.accent
          font: Config.font
          elide: Text.ElideRight
        }

        TextInput {
          id: passwordInput
          Layout.fillWidth: true
          height: 34
          text: root.password
          color: Colors.foreground
          font: Config.font
          echoMode: TextInput.Password
          leftPadding: 8
          onTextChanged: root.password = text
          onAccepted: connectButton.clicked()
          Rectangle {
            anchors.fill: parent
            z: -1
            radius: 6
            color: Colors.surface
            border.color: Colors.border
            border.width: 1
          }
        }

        RowLayout {
          Layout.alignment: Qt.AlignRight
          Text {
            text: "Cancel"
            color: Colors.white
            font: Config.font
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.pendingNetwork = null
            }
          }
          Rectangle {
            id: connectButton
            width: 82
            height: 30
            radius: 6
            color: root.accent
            signal clicked()
            Text { anchors.centerIn: parent; text: "Connect"; color: root.ink; font: Config.font }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: parent.clicked()
            }
            onClicked: {
              if (root.pendingNetwork && root.password.length > 0) root.pendingNetwork.connectWithPsk(root.password)
              root.pendingNetwork = null
            }
          }
        }
      }
    }
  }
}
