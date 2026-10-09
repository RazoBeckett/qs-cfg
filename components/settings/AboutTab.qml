import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 0

  RowLayout {
    Layout.fillWidth: true
    spacing: 18
    Layout.topMargin: 6

    Image {
      id: logo
      source: Qt.resolvedUrl("../../assets/kettshell-logo.png")
      sourceSize: Qt.size(72, 72)
      Layout.preferredWidth: 72
      Layout.preferredHeight: 72
      Layout.alignment: Qt.AlignTop
      fillMode: Image.PreserveAspectFit
      smooth: true
      mipmap: true
      cache: true
      asynchronous: false
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      spacing: 2

      Label {
        text: "KettShell"
        color: Colors.foreground
        size: Typography.sizeLG
        weight: Font.Bold
      }

      Label {
        text: "A personal desktop shell for Linux"
        color: Colors.white
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
      }

      Label {
        text: "built with Quickshell."
        color: Colors.white
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        elide: Text.ElideRight
      }

      Rectangle {
        id: repoButton
        Layout.fillWidth: true
        Layout.topMargin: 14
        Layout.preferredHeight: 36
        radius: Settings.rounding.md
        color: repoMa.containsMouse ? Colors.card : Colors.transparent
        border.color: repoMa.containsMouse ? Colors.blue : Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "code"
            color: repoMa.containsMouse ? Colors.foreground : Colors.white
            font.family: Typography.icons.family
            font.pixelSize: 18
            Behavior on color { ColorAnimation { duration: 150 } }
          }

          Label {
            text: "GitHub Repository"
            color: repoMa.containsMouse ? Colors.foreground : Colors.white
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 150 } }
          }

          Text {
            text: "arrow-square-out"
            color: repoMa.containsMouse ? Colors.foreground : Colors.white
            font.family: Typography.icons.family
            font.pixelSize: 18
            opacity: repoMa.containsMouse ? 1 : 0.7
            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
          }
        }

        MouseArea {
          id: repoMa
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Qt.openUrlExternally("https://github.com/razobeckett/kettshell")
        }
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 1
    Layout.topMargin: 22
    Layout.bottomMargin: 18
    color: Colors.border
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 4

    Label {
      text: "Built with"
      color: Colors.foreground
    }

    Label {
      text: "Quickshell, Qt Quick / QML"
      color: Colors.white
    }
  }
}
