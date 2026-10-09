import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 4

  property string commitDisplay: "KettShell @development"

  property bool editingFont: false
  property real editProgress: editingFont ? 1 : 0
  Behavior on editProgress { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  property bool editingMono: false
  property real monoProgress: editingMono ? 1 : 0
  Behavior on monoProgress { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function commitFont(): void {
    let t = fontField.text.trim()
    if (t !== "") Settings.ui.fontFamily = t
    else fontField.text = Settings.ui.fontFamily
    editingFont = false
  }

  function cancelFont(): void {
    fontField.text = Settings.ui.fontFamily
    editingFont = false
  }

  function startEdit(): void {
    fontField.text = Settings.ui.fontFamily
    fontField.cursorPosition = fontField.text.length
    editingFont = true
    fontField.forceActiveFocus()
  }

  function commitMono(): void {
    let t = monoField.text.trim()
    if (t !== "") Settings.ui.monoFamily = t
    else monoField.text = Settings.ui.monoFamily
    editingMono = false
  }

  function cancelMono(): void {
    monoField.text = Settings.ui.monoFamily
    editingMono = false
  }

  function startEditMono(): void {
    monoField.text = Settings.ui.monoFamily
    monoField.cursorPosition = monoField.text.length
    editingMono = true
    monoField.forceActiveFocus()
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Label {
        text: "Interface font"
        color: Colors.foreground
        weight: Font.DemiBold
        Layout.fillWidth: true
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Rectangle {
        id: fontBox
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Settings.rounding.md
        color: root.editingFont || fieldMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: root.editingFont ? Colors.blue : Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
          id: fontField
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          clip: true
          enabled: root.editingFont
          selectByMouse: true
          text: Settings.ui.fontFamily
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.foreground
          selectionColor: Colors.blue
          selectedTextColor: Colors.black
          font.family: Typography.sans.family
          font.pixelSize: Typography.sizeSM
          font.weight: Typography.sans.weight
          onAccepted: root.commitFont()
          Keys.onEscapePressed: event => {
            root.cancelFont()
            event.accepted = true
          }
        }

        MouseArea {
          id: fieldMa
          anchors.fill: parent
          enabled: !root.editingFont
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.startEdit()
        }
      }

      Item {
        id: buttonsWrap
        Layout.preferredWidth: 80 * root.editProgress
        Layout.preferredHeight: 32
        clip: true
        visible: root.editingFont || root.editProgress > 0.01

        Row {
          spacing: 8
          height: 32
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - 72 + (1 - root.editProgress) * 28

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: cancelMa.containsMouse ? Colors.red : Colors.transparent
            border.color: cancelMa.containsMouse ? Colors.red : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "x"
              color: cancelMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: cancelMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cancelFont()
            }
          }

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: saveMa.containsMouse ? Colors.green : Colors.transparent
            border.color: saveMa.containsMouse ? Colors.green : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "check"
              color: saveMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: saveMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.commitFont()
            }
          }
        }
      }
    }

    Label {
      text: "Type a family installed on your system. Applies everywhere at once."
      color: Colors.white
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      elide: Text.ElideRight
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 64
      Layout.topMargin: 6
      radius: Settings.rounding.md
      color: Colors.surface
      border.color: Colors.border
      border.width: 1
      clip: true

      Text {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: Text.AlignVCenter
        text: root.commitDisplay
        color: Colors.foreground
        font.family: Settings.ui.fontFamily
        font.pixelSize: Typography.sizeLG
        font.weight: Font.Normal
        elide: Text.ElideRight
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.topMargin: 8
    spacing: 6

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Label {
        text: "Monospace font"
        color: Colors.foreground
        weight: Font.DemiBold
        Layout.fillWidth: true
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Rectangle {
        id: monoBox
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Settings.rounding.md
        color: root.editingMono || fieldMonoMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: root.editingMono ? Colors.blue : Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
          id: monoField
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          clip: true
          enabled: root.editingMono
          selectByMouse: true
          text: Settings.ui.monoFamily
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.foreground
          selectionColor: Colors.blue
          selectedTextColor: Colors.black
          font.family: Typography.mono.family
          font.pixelSize: Typography.sizeSM
          font.weight: Typography.mono.weight
          onAccepted: root.commitMono()
          Keys.onEscapePressed: event => {
            root.cancelMono()
            event.accepted = true
          }
        }

        MouseArea {
          id: fieldMonoMa
          anchors.fill: parent
          enabled: !root.editingMono
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.startEditMono()
        }
      }

      Item {
        id: monoButtonsWrap
        Layout.preferredWidth: 80 * root.monoProgress
        Layout.preferredHeight: 32
        clip: true
        visible: root.editingMono || root.monoProgress > 0.01

        Row {
          spacing: 8
          height: 32
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - 72 + (1 - root.monoProgress) * 28

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: cancelMonoMa.containsMouse ? Colors.red : Colors.transparent
            border.color: cancelMonoMa.containsMouse ? Colors.red : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "x"
              color: cancelMonoMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: cancelMonoMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cancelMono()
            }
          }

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: saveMonoMa.containsMouse ? Colors.green : Colors.transparent
            border.color: saveMonoMa.containsMouse ? Colors.green : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "check"
              color: saveMonoMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: saveMonoMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.commitMono()
            }
          }
        }
      }
    }

    Label {
      text: "Used for clocks, percentages, and numbers."
      color: Colors.white
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      elide: Text.ElideRight
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 64
      Layout.topMargin: 6
      radius: Settings.rounding.md
      color: Colors.surface
      border.color: Colors.border
      border.width: 1
      clip: true

      Text {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: Text.AlignVCenter
        text: root.commitDisplay
        color: Colors.foreground
        font.family: Settings.ui.monoFamily
        font.pixelSize: Typography.sizeLG
        font.weight: Font.Normal
        elide: Text.ElideRight
      }
    }
  }

  SettingsRow {
    title: "Text size"
    subtitle: "Scales all body text, like rem on the web"
    Layout.fillWidth: true
    Layout.topMargin: 8

    Item {
      Layout.preferredWidth: 240
      Layout.preferredHeight: 32
      Layout.alignment: Qt.AlignVCenter

      RowLayout {
        anchors.fill: parent
        spacing: 12

        Label {
          text: Settings.ui.fontScale + "px"
          color: Colors.foreground
          useMono: true
          Layout.preferredWidth: 42
          horizontalAlignment: Text.AlignRight
        }

        Slider {
          Layout.fillWidth: true
          Layout.preferredHeight: 32
          Layout.alignment: Qt.AlignVCenter
          // 10..20 range around the 13 default
          fraction: Math.max(0, Math.min(1, (Settings.ui.fontScale - 10) / 10))
          ready: true
          onMoved: f => Settings.ui.fontScale = Math.round(10 + f * 10)
        }
      }
    }
  }
}
