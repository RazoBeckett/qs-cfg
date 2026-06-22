pragma Singleton
import QtQuick

QtObject {
  readonly property int margin: 12
  readonly property int height: 30
  readonly property int spacing: 20

  readonly property font font: Qt.font({
    family: "SF Pro Text",
    pixelSize: 13,
    weight: 600
  })

  readonly property font iconFont: Qt.font({
    family: "JetBrainsMono Nerd Font Propo",
  })
}
