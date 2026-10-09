import "../.."
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  property var peaks: []
  property bool muted: false
  property bool showTicks: true
  // fixed stereo (2) — avoids recalculation flicker when switching devices (was 1↔2 based on peaks.length)
  property int channelCount: 2
  // OBS levels
  property real minimumDb: -60
  property real warningDb: -20
  property real errorDb: -9
  property real clipDb: 0

  readonly property real greenFrac: (warningDb - minimumDb) / (clipDb - minimumDb)
  readonly property real yellowFrac: (errorDb - warningDb) / (clipDb - minimumDb)
  readonly property real redFrac: 1 - greenFrac - yellowFrac

  implicitHeight: showTicks ? 28 : channelCount * 4 + (channelCount - 1) * 1
  implicitWidth: 200

  function linearToDb(v) {
    if (v <= 0.00001) return minimumDb - 20
    return 20 * Math.log(v) / Math.LN10
  }

  function dbToFrac(db) {
    if (db <= minimumDb) return 0
    if (db >= clipDb) return 1
    return (db - minimumDb) / (clipDb - minimumDb)
  }

  function fracForPeak(p) {
    if (root.muted) return 0
    let db = linearToDb(p)
    return dbToFrac(db)
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 0

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: 1

      Repeater {
        model: root.channelCount

        Item {
          required property int index
          Layout.fillWidth: true
          Layout.preferredHeight: 4
          Layout.fillHeight: false

          // background zones
          Row {
            id: bgRow
            anchors.fill: parent
            Rectangle { width: parent.width * root.greenFrac; height: parent.height; color: root.muted ? Colors.card : Qt.darker(Colors.green, 2.4) }
            Rectangle { width: parent.width * root.yellowFrac; height: parent.height; color: root.muted ? Colors.card : Qt.darker(Colors.yellow, 2.2) }
            Rectangle { width: parent.width * root.redFrac; height: parent.height; color: root.muted ? Colors.card : Qt.darker(Colors.red, 2.2) }
          }

          // foreground clipped
          Item {
            id: fgClip
            height: parent.height
            clip: true
            width: {
              let p = 0
              if (root.peaks && root.peaks.length > index) p = root.peaks[index]
              else p = 0
              return bgRow.width * root.fracForPeak(p)
            }
            Behavior on width { NumberAnimation { duration: 70; easing.type: Easing.OutCubic } }

            Row {
              width: bgRow.width
              height: parent.height
              Rectangle { width: bgRow.width * root.greenFrac; height: parent.height; color: root.muted ? Colors.white : Colors.green }
              Rectangle { width: bgRow.width * root.yellowFrac; height: parent.height; color: root.muted ? Colors.white : Colors.yellow }
              Rectangle { width: bgRow.width * root.redFrac; height: parent.height; color: Colors.red }
            }
          }

          Rectangle {
            anchors.fill: parent
            radius: Settings.rounding.xs
            color: "transparent"
            border.color: Colors.border
            border.width: 1
            opacity: 0.9
          }
        }
      }
    }

    // ticks and labels
    Item {
      visible: root.showTicks
      Layout.fillWidth: true
      Layout.preferredHeight: 14

      // tick line
      Rectangle {
        id: tickLine
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 2
        height: 1
        color: Colors.border
      }

      Repeater {
        model: [
          { db: -60, label: "-60" },
          { db: -48, label: "-48" },
          { db: -36, label: "-36" },
          { db: -24, label: "-24" },
          { db: -18, label: "-18" },
          { db: -12, label: "-12" },
          { db: -6, label: "-6" },
          { db: 0, label: "0" }
        ]
        delegate: Item {
          required property var modelData
          width: 1
          height: parent.height
          x: Math.round(tickLine.width * ((modelData.db - root.minimumDb) / (root.clipDb - root.minimumDb)))

          Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            width: 1
            height: modelData.db === -20 || modelData.db === -9 || modelData.db === 0 ? 4 : 2
            color: Colors.white
            opacity: 0.7
          }
          Text {
            anchors.top: parent.top
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.label
            color: Colors.white
            // scale-exempt: dense tick strip is 14px tall; even sizeXS overflows it
            font.pixelSize: 7
            font.family: Typography.sans.family
            opacity: 0.9
          }
        }
      }
    }
  }
}
