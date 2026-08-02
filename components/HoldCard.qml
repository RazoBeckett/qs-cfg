import ".."
import QtQuick
import QtQuick.Layouts

// A card that fires `triggered()` only after a press-and-hold fill completes.
// Releasing early cancels the action and drains the fill back to zero.
Rectangle {
  id: root
  radius: 14
  clip: true
  color: accent ? accentColor : Colors.card
  border.color: accent ? Colors.transparent : Colors.border
  border.width: 1

  signal triggered()
  signal pressStarted()
  signal pressEnded()

  property color accentColor: Colors.magenta
  property bool accent: false
  property bool busy: false
  property bool held: false
  property bool centered: false
  property int iconSize: 21
  property real fillLevel: 0.0
  property real flashOpacity: 0.0
  property string label: ""
  property string iconText: ""
  property string idleHint: ""
  property string holdHint: "Hold..."
  property string busyHint: "Connecting..."

  readonly property string hint: {
    if (busy) return busyHint
    if (fillLevel > 0.01 && fillLevel < 1.0) return holdHint
    return idleHint
  }

  Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

  Rectangle {
    x: 0
    y: parent.height - parent.height * root.fillLevel
    width: parent.width
    height: parent.height * root.fillLevel
    color: root.accentColor
    opacity: 0.35
  }

  Rectangle {
    anchors.fill: parent
    radius: parent.radius
    color: Colors.foreground
    opacity: root.flashOpacity
  }

  ColumnLayout {
    visible: root.centered
    anchors.centerIn: parent
    spacing: 3

    Text {
      text: root.iconText
      color: root.accent ? Colors.black : root.accentColor
      font.family: Config.iconFont.family
      font.pixelSize: root.iconSize
      Layout.alignment: Qt.AlignHCenter
    }

    Text {
      text: root.label
      color: root.accent ? Colors.black : Colors.foreground
      font: Config.font
      horizontalAlignment: Text.AlignHCenter
      Layout.alignment: Qt.AlignHCenter
      Layout.maximumWidth: root.width - 28
      elide: Text.ElideRight
    }

    Text {
      text: root.hint
      color: root.accent ? Colors.black : Colors.white
      font: Config.font
      Layout.alignment: Qt.AlignHCenter
    }
  }

  RowLayout {
    visible: !root.centered
    anchors.fill: parent
    anchors.margins: 10
    spacing: 9

    Text {
      text: root.iconText
      color: root.accent ? Colors.black : root.accentColor
      font.family: Config.iconFont.family
      font.pixelSize: root.iconSize
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1

      Text {
        Layout.fillWidth: true
        text: root.label
        color: root.accent ? Colors.black : Colors.foreground
        font: Config.font
        elide: Text.ElideRight
      }

      Text {
        text: root.hint
        color: root.accent ? Colors.black : Colors.white
        font: Config.font
      }
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: {
      root.scale = 1.04
      if (!root.busy) {
        root.held = true
        root.pressStarted()
        fillAnim.restart()
      }
    }
    onReleased: {
      root.scale = ma.containsMouse ? 1.02 : 1.0
      if (root.held) {
        root.held = false
        root.pressEnded()
      }
      if (!root.busy && root.fillLevel < 1.0) {
        fillAnim.stop()
        drainAnim.restart()
      }
    }
    onContainsMouseChanged: root.scale = ma.containsMouse ? 1.02 : 1.0
  }

  NumberAnimation {
    id: fillAnim
    target: root
    property: "fillLevel"
    to: 1.0
    duration: 600 * (1.0 - root.fillLevel)
    easing.type: Easing.InSine
    onFinished: {
      if (root.held) {
        root.held = false
        root.pressEnded()
      }
      root.triggered()
      flashAnim.restart()
      drainAnim.restart()
    }
  }

  NumberAnimation {
    id: drainAnim
    target: root
    property: "fillLevel"
    to: 0.0
    duration: 700 * root.fillLevel
    easing.type: Easing.OutQuad
  }

  NumberAnimation {
    id: flashAnim
    target: root
    property: "flashOpacity"
    from: 0.5
    to: 0.0
    duration: 400
    easing.type: Easing.OutQuad
  }
}
