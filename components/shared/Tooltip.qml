import "../.."
import Quickshell
import QtQuick

// Hover tooltip mapped from Astryx Tooltip: inverted surface, 200ms
// hover-intent delay, instant hide, no arrow, short non-interactive text.
PopupWindow {
  id: root

  required property Item anchorItem
  required property var barWindow

  property string text: ""
  property bool hovered: false
  property int delay: 200
  property int hideDelay: 0
  property bool useMono: false
  property int margin: 6
  property bool open: false

  readonly property bool showing: open || holder.opacity > 0
  property real reveal: open ? 1 : 0

  visible: showing
  color: Colors.transparent
  implicitWidth: bg.width
  implicitHeight: bg.height

  Behavior on reveal { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

  function updateTip() {
    showTimer.stop()
    hideTimer.stop()
    if (root.hovered && root.text !== "") {
      if (root.delay <= 0) root.open = true
      else showTimer.start()
    } else {
      if (root.hideDelay <= 0) root.open = false
      else hideTimer.start()
    }
  }

  onHoveredChanged: root.updateTip()
  onTextChanged: root.updateTip()

  Timer {
    id: showTimer
    interval: root.delay
    onTriggered: root.open = root.hovered && root.text !== ""
  }

  Timer {
    id: hideTimer
    interval: root.hideDelay
    onTriggered: root.open = false
  }

  anchor {
    id: tipAnchor
    window: root.barWindow
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1

    onAnchoring: {
      if (!root.anchorItem || !root.barWindow || !root.barWindow.contentItem) return

      let popupWidth = root.implicitWidth
      let point = root.barWindow.contentItem.mapFromItem(
        root.anchorItem,
        (root.anchorItem.width - popupWidth) / 2,
        root.anchorItem.height + root.margin
      )
      let maxX = root.barWindow.width - popupWidth - root.margin

      tipAnchor.rect.x = Math.round(Math.max(root.margin, Math.min(point.x, maxX)))
      tipAnchor.rect.y = Math.round(point.y)
    }
  }

  Item {
    id: holder
    width: bg.width
    height: bg.height
    y: (1 - root.reveal) * -8
    scale: 0.95 + 0.05 * root.reveal
    opacity: root.reveal
    transformOrigin: Item.Top

    Rectangle {
      id: bg
      width: Math.min(tipLabel.implicitWidth + 16, 220)
      height: tipLabel.implicitHeight + 8
      color: Colors.black
      border.color: Colors.border
      border.width: 1
      radius: Settings.rounding.sm
      clip: true

      Label {
        id: tipLabel
        anchors.centerIn: parent
        width: parent.width - 16
        text: root.text
        color: Colors.foreground
        useMono: root.useMono
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
      }
    }
  }
}
