import "../.."
import Quickshell
import Quickshell.Hyprland
import QtQuick

PopupWindow {
  id: root

  required property Item anchorItem
  required property var barWindow
  property var shell: null
  property string popoutKind: ""
  property int margin: 6
  property int contentWidth: 360
  property int contentHeight: 460

  default property alias contentItem: contentHolder.data

  readonly property bool showing: open || contentHolder.opacity > 0

  visible: showing
  color: Colors.transparent
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  property bool open: false

  function close() {
    if (root.shell && typeof root.shell.releasePopout === "function") root.shell.releasePopout(root.popoutKind, root.anchorItem)
    else root.open = false
  }

  Shortcut {
    sequence: "Escape"
    onActivated: root.close()
  }

  HyprlandFocusGrab {
    id: grab
    active: root.open
    windows: [root]
    onCleared: root.close()
  }

  onOpenChanged: {
    if (open) {
      // ensure Hyprland gives keyboard focus to the popup even when
      // the cursor is already inside the popup at open time
      Qt.callLater(() => {
        grab.active = false
        grab.active = true
        contentHolder.forceActiveFocus()
      })
    }
  }

  // when the popup window actually maps, re-prime the grab and Qt focus
  // (mirrors KeyboardPanel's backingWindowVisible prime)
  onBackingWindowVisibleChanged: if (open && backingWindowVisible) Qt.callLater(() => {
    grab.active = false
    grab.active = true
    contentHolder.forceActiveFocus()
  })

  anchor {
    id: popupAnchor
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
        root.anchorItem.width - popupWidth,
        root.anchorItem.height + root.margin
      )
      let maxX = root.barWindow.width - popupWidth - root.margin

      popupAnchor.rect.x = Math.round(Math.max(root.margin, Math.min(point.x, maxX)))
      popupAnchor.rect.y = Math.round(point.y)
    }
  }

  Item {
    id: contentHolder
    width: root.implicitWidth
    height: root.implicitHeight
    y: root.open ? 0 : -8
    opacity: root.open ? 1 : 0
    clip: true
    // genie — when Settings.ui.genie false, behaves like normal (no distort)
    transform: Scale {
      id: genieScale
      origin.x: contentHolder.width * 0.88
      origin.y: 0
      xScale: Settings.ui.genie ? (root.open ? 1 : 0.22) : 1
      yScale: Settings.ui.genie ? (root.open ? 1 : 0.58) : 1
      Behavior on xScale { NumberAnimation { duration: Settings.ui.genie ? 280 : 0; easing.type: Easing.InOutCubic } }
      Behavior on yScale { NumberAnimation { duration: Settings.ui.genie ? 280 : 0; easing.type: Easing.InOutCubic } }
    }

    Behavior on y {
      NumberAnimation { duration: Settings.ui.genie ? 220 : 150; easing.type: Easing.OutCubic }
    }

    Behavior on opacity {
      NumberAnimation { duration: Settings.ui.genie ? 200 : 120; easing.type: Easing.OutCubic }
    }
  }
}
