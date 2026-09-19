import "../.."
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

WrapperMouseArea {
  id: root
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor

  property var shell: null
  property var barWindow: null

  property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink && sink.ready
  readonly property bool muted: ready && sink.audio.muted
  readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0
  readonly property string icon: {
    if (!ready) return "speaker-slash"
    if (muted || vol === 0) return "speaker-slash"
    if (vol < 34) return "speaker-low"
    return "speaker-high"
  }
  readonly property string tipText: {
    if (!root.ready) return "-"
    if (root.muted) return "Muted"
    return root.vol + "%"
  }
  readonly property bool tipHovered: root.containsMouse && !(root.shell && root.shell.activePopoutOwner === root)

  child: PressableItem {
    implicitWidth: row.implicitWidth + 26
    implicitHeight: Sizing.barHeight
    pressed: root.pressed

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: 6

      Text {
        text: root.icon
        color: Colors.foreground
        font.family: Typography.icons.family
        font.pixelSize: 14
      }
    }
  }

  function adjustVolume(delta) {
    if (!root.ready) return
    var next = Math.min(1.0, Math.max(0.0, root.sink.audio.volume + delta / 100))
    root.sink.audio.volume = next
  }

  function togglePopout() {
    if (root.shell && typeof root.shell.togglePopout === "function") root.shell.togglePopout("volume", root)
  }

  function toggleMute() {
    if (!root.ready) return
    root.sink.audio.muted = !root.muted
  }

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) root.toggleMute()
    else if (mouse.button === Qt.LeftButton) root.togglePopout()
  }

  onWheel: wheel => {
    if (wheel.angleDelta.y > 0) root.adjustVolume(5)
    else if (wheel.angleDelta.y < 0) root.adjustVolume(-5)
  }

  PwObjectTracker {
    objects: [root.sink]
  }

  Tooltip {
    anchorItem: root
    barWindow: root.barWindow
    text: root.tipText
    hovered: root.tipHovered && root.barWindow !== null
    useMono: true
  }
}
