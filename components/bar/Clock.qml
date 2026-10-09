import "../.."
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  implicitWidth: row.implicitWidth + 26
  implicitHeight: Sizing.barHeight

  property string displayText: Qt.formatDateTime(clock.date, "hh:mm")
  property var barWindow: null

  readonly property string tipText: Qt.formatDateTime(clock.date, "hh:mm:ss") + "\n" + Qt.formatDateTime(clock.date, "MMM d, yyyy")

  HoverHandler { id: hover }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 6

    // crossfade host — previous fades out upward, new fades in from below
    Item {
      id: tickHost
      implicitWidth: incoming.implicitWidth
      implicitHeight: incoming.implicitHeight
      clip: true

      property string pendingText: root.displayText
      // triggers tick when minute changes
      onPendingTextChanged: if (outgoing.text !== "" && pendingText !== outgoing.text) tickAnim.restart()

      Label {
        id: outgoing
        anchors.centerIn: parent
        text: root.displayText
        color: Colors.foreground
        weight: Font.Bold
        opacity: 1
        y: 0
      }

      Label {
        id: incoming
        anchors.centerIn: parent
        text: root.displayText
        color: Colors.foreground
        weight: Font.Bold
        opacity: 0
        y: 6
        visible: false
      }

      SequentialAnimation {
        id: tickAnim
        onStarted: {
          incoming.text = tickHost.pendingText
          incoming.visible = true
          incoming.opacity = 0
          incoming.y = 6
          outgoing.y = 0
          outgoing.opacity = 1
        }
        ParallelAnimation {
          NumberAnimation { target: outgoing; property: "opacity"; to: 0; duration: 230; easing.type: Easing.OutCubic }
          NumberAnimation { target: outgoing; property: "y"; to: -4; duration: 230; easing.type: Easing.OutCubic }
          NumberAnimation { target: incoming; property: "opacity"; to: 1; duration: 230; easing.type: Easing.OutCubic }
          NumberAnimation { target: incoming; property: "y"; to: 0; duration: 230; easing.type: Easing.OutCubic }
        }
        onStopped: {
          outgoing.text = tickHost.pendingText
          outgoing.opacity = 1
          outgoing.y = 0
          incoming.visible = false
          incoming.opacity = 0
          incoming.y = 6
        }
      }

      Component.onCompleted: outgoing.text = root.displayText
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Tooltip {
    anchorItem: root
    barWindow: root.barWindow
    text: root.tipText
    hovered: hover.hovered && root.barWindow !== null
    useMono: true
  }
}
