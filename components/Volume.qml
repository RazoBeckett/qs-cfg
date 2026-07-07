import ".."
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  spacing: 6

  property var sink: Pipewire.defaultAudioSink

  readonly property bool ready: sink && sink.ready
  readonly property bool muted: ready && sink.audio.muted
  readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0


  readonly property string icon: {
    if (!ready) return String.fromCodePoint(0xF0581)
    if (muted) return String.fromCodePoint(0xF0E08)
    if (vol === 0) return String.fromCodePoint(0xF0E08)
    if (vol < 34) return String.fromCodePoint(0xF057F)
    if (vol < 67) return String.fromCodePoint(0xF0580)

    return String.fromCodePoint(0xF057E)
  }

  Text {
    text: root.icon
    color: Colors.yellow
    font: Config.iconFont
  }

  Text {
    text: {
      if(!root.ready) return "-"
      if(root.muted) return "Muted"
      return root.vol + "%"
    }

    color: root.muted ? Colors.white : Colors.foreground

    font: Config.font
  }

  function adjustVolume(delta) {
    if (!root.ready) return
    var next = Math.min(1.0, Math.max(0.0, root.sink.audio.volume + delta / 100))
    root.sink.audio.volume = next
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: wheel => {
      if (wheel.angleDelta.y > 0) root.adjustVolume(5)
      else if (wheel.angleDelta.y < 0) root.adjustVolume(-5)
    }
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
  }

  PwObjectTracker {
    objects: [root.sink]
  }

}
