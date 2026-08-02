import ".."
import Quickshell.Networking
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
  property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
  readonly property real signal: active ? active.signalStrength : 0
  readonly property string icon: {
    if (!Networking.wifiEnabled) return String.fromCodePoint(0xF05AA)
    if (!active) return String.fromCodePoint(0xF092D)
    let tier = signal >= 0.75 ? 4 : signal >= 0.50 ? 3 : signal >= 0.25 ? 2 : 1
    return String.fromCodePoint(0xF091F + (tier - 1) * 3)
  }

  child: RowLayout {
    spacing: 6

    Text {
      text: root.icon
      color: Networking.wifiEnabled ? Colors.magenta : Colors.white
      font: Config.iconFont
    }

    Text {
      text: !Networking.wifiEnabled ? "OFF" : root.active ? root.active.name : "Disconnected"
      color: Colors.foreground
      font: Config.font
    }
  }

  onClicked: NetworkMenuState.visible = !NetworkMenuState.visible
}
