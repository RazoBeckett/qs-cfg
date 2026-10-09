import "../.."
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
  id: root
  implicitWidth: layout.implicitWidth
  implicitHeight: Sizing.barHeight

  readonly property var sortedWorkspaces: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)
  readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? -1
  property int _pendingPopId: -1
  property var _knownIds: []
  // active delegate for sliding indicator
  readonly property int activeIndex: {
    for (let i = 0; i < sortedWorkspaces.length; i++) if (sortedWorkspaces[i].id === focusedId) return i
    return -1
  }
  readonly property Item activeItem: activeIndex >= 0 && activeIndex < wsRepeater.count ? wsRepeater.itemAt(activeIndex) : null
  property bool showIndicator: false
  Timer { id: hideTimer; interval: 1000; onTriggered: showIndicator = false }

  function _tryPop() {
    if (_pendingPopId === -1) return
    for (let i = 0; i < wsRepeater.count; i++) {
      let d = wsRepeater.itemAt(i)
      if (d && d.ws && d.ws.id === _pendingPopId) {
        if (d.pop) d.pop.restart()
        _pendingPopId = -1
        return
      }
    }
    Qt.callLater(_tryPop)
  }

  // pop only numbers that just appeared — a workspace exists once a window maps on it
  onSortedWorkspacesChanged: {
    for (const ws of sortedWorkspaces) {
      if (!_knownIds.includes(ws.id)) {
        _pendingPopId = ws.id
        Qt.callLater(_tryPop)
      }
    }
    _knownIds = sortedWorkspaces.map(ws => ws.id)
  }

  onFocusedIdChanged: {
    if (focusedId === -1) return
    showIndicator = true
    hideTimer.restart()
  }

  Component.onCompleted: if (focusedId !== -1) { showIndicator = true; hideTimer.restart() }

  RowLayout {
    id: layout
    anchors.fill: parent
    spacing: 0

    Repeater {
      id: wsRepeater
      model: root.sortedWorkspaces

      Item {
        id: wsButton
        required property var modelData
        property var ws: modelData
        property bool isActive: Hyprland.focusedWorkspace?.id === ws.id
        property bool isHovered: ma.containsMouse

        implicitWidth: label.implicitWidth + 18
        implicitHeight: Sizing.barHeight
        property alias pop: popAnim

        SequentialAnimation {
          id: popAnim
          NumberAnimation { target: label; property: "scale"; from: 1; to: 1.14; duration: 110; easing.type: Easing.OutCubic }
          NumberAnimation { target: label; property: "scale"; to: 1; duration: 130; easing.type: Easing.OutCubic }
        }

        Label {
          id: label
          anchors.centerIn: parent
          text: wsButton.ws.id
          color: wsButton.isActive ? Colors.waybarActive : Colors.foreground
          weight: Font.Bold
          transformOrigin: Item.Center
          scale: 1
          Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: 3
          color: Colors.foreground
          visible: wsButton.isHovered && !wsButton.isActive
          opacity: wsButton.isHovered ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Rectangle {
          anchors.fill: parent
          radius: Settings.rounding.sm
          color: Colors.waybarHover
          opacity: wsButton.isHovered ? 1 : 0
          z: -1
          Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        MouseArea {
          id: ma
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${wsButton.ws.id} })`])
        }
      }
    }
  }

  // sliding pill indicator — glides between numbers like iOS dots / macOS tab, auto-hides after 1s
  Rectangle {
    id: indicator
    height: 3
    y: root.height - height
    width: root.activeItem ? root.activeItem.width : 0
    x: root.activeItem ? root.activeItem.x : 0
    color: Colors.foreground
    opacity: root.showIndicator && root.activeItem !== null ? 1 : 0
    visible: opacity > 0
    z: 0
    Behavior on x { SpringAnimation { spring: 3.5; damping: 0.22 } }
    Behavior on width { SpringAnimation { spring: 3.5; damping: 0.22 } }
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
  }
}
