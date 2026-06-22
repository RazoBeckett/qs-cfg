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

  PwObjectTracker {
    objects: [root.sink]
  }

}
