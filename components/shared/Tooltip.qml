import "../.."
import Quickshell
import QtQuick

// Hover tooltip mapped from Astryx Tooltip: inverted surface, 200ms
// hover-intent delay, instant hide, no arrow, short non-interactive text.
// placement picks the side it opens on: "top", "bottom", "left", "right".
PopupWindow {
  id: root

  required property Item anchorItem
  required property var barWindow

  property string text: ""
  property bool hovered: false
  property string placement: "bottom"
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

      const pw = root.implicitWidth
      const ph = root.implicitHeight
      const m = root.margin
      let ax = 0, ay = 0
      if (root.placement === "top") {
        ax = (root.anchorItem.width - pw) / 2
        ay = -ph - m
      } else if (root.placement === "left") {
        ax = -pw - m
        ay = (root.anchorItem.height - ph) / 2
      } else if (root.placement === "right") {
        ax = root.anchorItem.width + m
        ay = (root.anchorItem.height - ph) / 2
      } else {
        ax = (root.anchorItem.width - pw) / 2
        ay = root.anchorItem.height + m
      }
      const point = root.barWindow.contentItem.mapFromItem(root.anchorItem, ax, ay)
      if (root.placement === "left" || root.placement === "right") {
        const maxY = root.barWindow.height - ph - m
        tipAnchor.rect.x = Math.round(point.x)
        tipAnchor.rect.y = Math.round(Math.max(m, Math.min(point.y, Math.max(m, maxY))))
      } else {
        const maxX = root.barWindow.width - pw - m
        tipAnchor.rect.x = Math.round(Math.max(m, Math.min(point.x, Math.max(m, maxX))))
        tipAnchor.rect.y = Math.round(point.y)
      }
    }
  }

  Item {
    id: holder
    width: bg.width
    height: bg.height
    x: {
      if (root.placement === "right") return (1 - root.reveal) * -8
      if (root.placement === "left") return (1 - root.reveal) * 8
      return 0
    }
    y: {
      if (root.placement === "bottom") return (1 - root.reveal) * -8
      if (root.placement === "top") return (1 - root.reveal) * 8
      return 0
    }
    scale: 0.95 + 0.05 * root.reveal
    opacity: root.reveal
    transformOrigin: root.placement === "top" ? Item.Bottom : root.placement === "left" ? Item.Right : root.placement === "right" ? Item.Left : Item.Top

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
