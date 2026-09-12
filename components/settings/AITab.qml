import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 4

  property bool editingKey: false
  property real keyProgress: editingKey ? 1 : 0
  property bool showKey: false
  readonly property bool editingLang: langField.activeFocus

  Behavior on keyProgress { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function commitKey(): void {
    Settings.ai.deepgramKey = keyField.text.trim()
    editingKey = false
  }

  function cancelKey(): void {
    keyField.text = Settings.ai.deepgramKey
    editingKey = false
  }

  function startEditKey(): void {
    keyField.text = Settings.ai.deepgramKey
    keyField.cursorPosition = keyField.text.length
    editingKey = true
    keyField.forceActiveFocus()
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6

    Label {
      text: "Deepgram API key"
      color: Colors.foreground
      weight: Font.DemiBold
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Settings.rounding.md
        color: root.editingKey || keyMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: root.editingKey ? Colors.blue : Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        MouseArea {
          id: keyMa
          anchors.fill: parent
          enabled: !root.editingKey
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.startEditKey()
        }

        TextInput {
          id: keyField
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 34
          clip: true
          enabled: root.editingKey
          selectByMouse: true
          echoMode: root.showKey ? TextInput.Normal : TextInput.Password
          text: Settings.ai.deepgramKey
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.foreground
          selectionColor: Colors.blue
          selectedTextColor: Colors.black
          font.family: Typography.mono.family
          font.pixelSize: Typography.sizeSM
          font.weight: Typography.mono.weight
          onAccepted: root.commitKey()
          Keys.onEscapePressed: event => {
            root.cancelKey()
            event.accepted = true
          }
        }

        Text {
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          text: root.showKey ? "eye-slash" : "eye"
          color: eyeMa.containsMouse ? Colors.foreground : Colors.white
          font.family: Typography.icons.family
          font.pixelSize: 16
          Behavior on color { ColorAnimation { duration: 150 } }

          MouseArea {
            id: eyeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showKey = !root.showKey
          }
        }
      }

      Item {
        Layout.preferredWidth: 80 * root.keyProgress
        Layout.preferredHeight: 32
        clip: true
        visible: root.editingKey || root.keyProgress > 0.01

        Row {
          spacing: 8
          height: 32
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - 72 + (1 - root.keyProgress) * 28

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
              onClicked: root.cancelKey()
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
              onClicked: root.commitKey()
            }
          }
        }
      }
    }

    Label {
      text: "Stored as plain text in kettshell.json."
      color: Colors.white
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      elide: Text.ElideRight
    }
  }

  SettingsRow {
    title: "Model"
    subtitle: "Deepgram transcription model"
    Layout.fillWidth: true
    Layout.topMargin: 8

    Row {
      spacing: 6
      Layout.alignment: Qt.AlignVCenter

      Repeater {
        model: ["nova-3", "nova-2", "enhanced", "base"]

        delegate: Rectangle {
          id: chip
          required property string modelData
          readonly property bool active: Settings.ai.model === modelData

          width: chipLabel.implicitWidth + 16
          height: 26
          radius: Settings.rounding.sm
          color: active ? Colors.blue : (chipMa.containsMouse ? Colors.card : Colors.transparent)
          border.color: active ? Colors.blue : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }
          Behavior on border.color { ColorAnimation { duration: 150 } }

          Label {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.modelData
            color: chip.active ? Colors.black : Colors.white
            size: Typography.sizeXS
            weight: Font.DemiBold
          }

          MouseArea {
            id: chipMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Settings.ai.model = chip.modelData
          }
        }
      }
    }
  }

  SettingsRow {
    title: "Language"
    subtitle: "BCP-47 code like en or en-US; multi for auto-detect"
    Layout.fillWidth: true

    Rectangle {
      Layout.preferredWidth: 100
      Layout.preferredHeight: 32
      Layout.alignment: Qt.AlignVCenter
      radius: Settings.rounding.md
      color: langField.activeFocus || langMa.containsMouse ? Colors.surface : Colors.transparent
      border.color: langField.activeFocus ? Colors.blue : Colors.border
      border.width: 1
      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      MouseArea {
        id: langMa
        anchors.fill: parent
        enabled: !langField.activeFocus
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: langField.forceActiveFocus()
      }

      TextInput {
        id: langField
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        clip: true
        selectByMouse: true
        text: Settings.ai.language
        verticalAlignment: TextInput.AlignVCenter
        color: Colors.foreground
        selectionColor: Colors.blue
        selectedTextColor: Colors.black
        font.family: Typography.sans.family
        font.pixelSize: Typography.sizeSM
        font.weight: Typography.sans.weight
        onAccepted: {
          const t = text.trim()
          if (t !== "") Settings.ai.language = t
          else text = Settings.ai.language
          focus = false
        }
        Keys.onEscapePressed: event => {
          text = Settings.ai.language
          focus = false
          event.accepted = true
        }
        onActiveFocusChanged: if (!activeFocus) text = Settings.ai.language
      }
    }
  }

  SettingsRow {
    title: "Smart formatting"
    subtitle: "Deepgram cleans up numbers, dates, and paragraphs"
    Layout.fillWidth: true

    RowToggle {
      checked: Settings.ai.smartFormat
      onToggled: c => Settings.ai.smartFormat = c
    }
  }

  SettingsRow {
    title: "Punctuation"
    subtitle: "Add punctuation to the transcript"
    Layout.fillWidth: true

    RowToggle {
      checked: Settings.ai.punctuate
      onToggled: c => Settings.ai.punctuate = c
    }
  }

  SettingsRow {
    title: "Copy to clipboard"
    subtitle: "Also keep the transcript on the clipboard after typing"
    Layout.fillWidth: true

    RowToggle {
      checked: Settings.ai.autoCopy
      onToggled: c => Settings.ai.autoCopy = c
    }
  }

  component RowToggle: Rectangle {
    id: rowToggle
    property alias checked: toggle.checked
    signal toggled(bool checked)

    Layout.preferredWidth: 44
    Layout.preferredHeight: 24
    Layout.alignment: Qt.AlignVCenter
    color: Colors.transparent
    border.color: Colors.border
    border.width: 1
    radius: Settings.rounding.md

    Toggle {
      id: toggle
      anchors.fill: parent
      onToggled: c => rowToggle.toggled(c)
    }
  }
}
