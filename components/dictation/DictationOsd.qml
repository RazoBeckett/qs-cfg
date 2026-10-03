import "../.."
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

/*
 * Dictation overlay. A bubble rises from the bottom edge, morphs into a
 * pill, and cycles the recording, transcribing, done, and error faces from
 * Dictation.state. The panel never takes keyboard focus and only the card
 * takes clicks, so wtype keeps targeting the user's window.
 */
Scope {
  id: root

  readonly property bool shown: Dictation.state !== "idle"
  readonly property string dictationState: Dictation.state
  // Last non-idle state, so the exit plays on the face that was showing.
  property string displayState: "recording"
  property real rise: 0
  property real fade: 0
  property bool expanded: false
  property bool closing: false
  property int elapsedSec: 0

  function formatElapsed(sec: int): string {
    const m = Math.floor(sec / 60)
    const s = sec % 60
    return (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" + s : "" + s)
  }

  readonly property color pillBorder: {
    switch (root.displayState) {
    case "recording": return Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.45)
    case "transcribing": return Qt.rgba(Colors.blue.r, Colors.blue.g, Colors.blue.b, 0.4)
    case "typing": return Qt.rgba(Colors.blue.r, Colors.blue.g, Colors.blue.b, 0.4)
    case "done": return Qt.rgba(Colors.green.r, Colors.green.g, Colors.green.b, 0.45)
    case "error": return Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.6)
    default: return Colors.border
    }
  }

  readonly property int faceWidth: {
    switch (root.displayState) {
    case "recording": return recordingFace.implicitWidth + 28
    case "transcribing": return transcribingFace.implicitWidth + 28
    case "typing": return typingFace.implicitWidth + 28
    case "done": return doneFace.implicitWidth + 28
    case "error": return errorFace.implicitWidth + 28
    default: return recordingFace.implicitWidth + 28
    }
  }

  onDictationStateChanged: {
    if (dictationState !== "idle") root.displayState = dictationState
    if (dictationState === "recording") root.elapsedSec = 0
  }

  onShownChanged: shown ? showOsd() : hideOsd()

  onDisplayStateChanged: if (root.displayState === "error") errorPulse.restart()

  function showOsd(): void {
    closeSequence.stop()
    collapseTimer.stop()
    errorPulse.stop()
    pill.scale = 1
    root.closing = false
    root.expanded = true
    openSequence.restart()
  }

  function hideOsd(): void {
    openSequence.stop()
    errorPulse.stop()
    pill.scale = 1
    root.closing = true
    closeSequence.restart()
    collapseTimer.restart()
  }

  IpcHandler {
    target: "dictation"

    function toggle(): void { Dictation.toggle() }
    function begin(): void { Dictation.begin() }
    function stop(): void { Dictation.stop() }
    function cancel(): void { Dictation.cancel() }
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "dictation-toggle"
    description: "Toggle dictation"
    onPressed: Dictation.toggle()
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "dictation-hold"
    description: "Dictate while held"
    onPressed: Dictation.begin()
    onReleased: Dictation.stop()
  }

  ParallelAnimation {
    id: openSequence
    NumberAnimation { target: root; property: "rise"; to: 1; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.12 }
    NumberAnimation { target: root; property: "fade"; to: 1; duration: 300; easing.type: Easing.OutCubic }
  }

  ParallelAnimation {
    id: closeSequence
    NumberAnimation { target: root; property: "rise"; to: 0; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.12 }
    NumberAnimation { target: root; property: "fade"; to: 0; duration: 300; easing.type: Easing.OutCubic }
  }

  // Error only, so the pop stays a signal instead of decoration.
  SequentialAnimation {
    id: errorPulse
    PauseAnimation { duration: 300 }
    NumberAnimation { target: pill; property: "scale"; to: 1.035; duration: 135; easing.type: Easing.OutCubic }
    NumberAnimation { target: pill; property: "scale"; to: 1.0; duration: 165; easing.type: Easing.OutCubic }
  }

  Timer {
    id: collapseTimer
    interval: 520
    onTriggered: {
      root.expanded = false
      root.closing = false
    }
  }

  Timer {
    id: elapsedTimer
    interval: 500
    repeat: true
    running: Dictation.state === "recording"
    triggeredOnStart: true
    onTriggered: root.elapsedSec = Math.max(0, Math.floor((Date.now() - Dictation.startMs) / 1000))
  }

  PanelWindow {
    id: win
    screen: Quickshell.primaryScreen || null
    visible: root.shown || root.closing
    anchors { top: true; bottom: true; left: true; right: true }
    color: Colors.transparent
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: pill }
    WlrLayershell.namespace: "kettshell-dictation"
    WlrLayershell.layer: WlrLayer.Overlay

    ClippingRectangle {
      id: pill
      anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 64 }
      height: 54
      width: root.expanded ? root.faceWidth : height
      radius: root.expanded ? Settings.rounding.lg : height / 2
      color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.96)
      border.width: 1
      border.color: root.pillBorder
      contentUnderBorder: true
      opacity: root.fade
      transform: Translate { y: 130 * (1 - root.rise) }

      Behavior on width {
        enabled: root.shown
        NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.18 }
      }
      Behavior on radius {
        enabled: root.shown
        NumberAnimation { duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.12 }
      }
      Behavior on border.color { ColorAnimation { duration: 300 } }

      HoverHandler { id: pillHover }

      RowLayout {
        id: recordingFace
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 10
        opacity: root.shown && root.displayState === "recording" ? 1 : 0
        scale: root.shown && root.displayState === "recording" ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

        BarVisualizer {
          Layout.preferredWidth: 78
          Layout.preferredHeight: 32
          Layout.alignment: Qt.AlignVCenter
          barCount: 9
          active: root.shown && Dictation.state === "recording"
          level: Dictation.voiceLevel
        }

        Label {
          Layout.alignment: Qt.AlignVCenter
          text: root.formatElapsed(root.elapsedSec)
          useMono: true
          color: Colors.white
        }

        Item {
          id: actions
          property real reveal: pillHover.hovered ? 1 : 0
          Behavior on reveal { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.18 } }
          visible: reveal > 0.02
          Layout.preferredWidth: Math.max(0, reveal * 70)
          Layout.preferredHeight: 30
          Layout.alignment: Qt.AlignVCenter
          clip: true

          Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 10

            FaceButton {
              icon: "x"
              tone: Colors.red
              reveal: actions.reveal
              onClicked: Dictation.cancel()
            }
            FaceButton {
              icon: "check"
              tone: Colors.green
              reveal: actions.reveal
              onClicked: Dictation.stop()
            }
          }
        }
      }

      StatusFace {
        id: transcribingFace
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        tone: Colors.blue
        glyph: "brain"
        iconOnly: true
        loadingMode: true
        cancellable: true
        onCancelled: Dictation.cancel()
        faceActive: root.shown && root.displayState === "transcribing"
      }

      StatusFace {
        id: typingFace
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        tone: Colors.yellow
        glyph: "keyboard"
        iconOnly: true
        loadingMode: true
        faceActive: root.shown && root.displayState === "typing"
      }

      StatusFace {
        id: doneFace
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        glyph: "check"
        tone: Colors.green
        label: Dictation.lastAction === "copied" ? "Copied" : "Pasted"
        faceActive: root.shown && root.displayState === "done"
      }

      StatusFace {
        id: errorFace
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        glyph: "smiley-blank"
        tone: Colors.red
        label: "No speech detected"
        faceActive: root.shown && root.displayState === "error"
      }
    }
  }

  component FaceButton: Rectangle {
    id: faceButton
    property string icon: ""
    property color tone: Colors.red
    property real reveal: 1
    signal clicked()

    width: 30
    height: 30
    radius: Settings.rounding.sm
    color: faceMa.containsMouse ? Qt.rgba(tone.r, tone.g, tone.b, 0.12) : Colors.transparent
    border.color: Qt.rgba(tone.r, tone.g, tone.b, 0.4)
    border.width: 1
    scale: 0.8 + 0.2 * reveal
    opacity: reveal
    Behavior on color { ColorAnimation { duration: 150 } }

    Text {
      anchors.centerIn: parent
      text: faceButton.icon
      color: faceButton.tone
      font.family: Typography.icons.family
      font.pixelSize: 14
    }

    MouseArea {
      id: faceMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: faceButton.clicked()
    }
  }

  component StatusFace: RowLayout {
    id: statusFace
    property string glyph: ""
    property color tone: Colors.foreground
    property string label: ""
    // Icon-only faces show the glyph and no word.
    property bool iconOnly: false
    property bool loadingMode: false
    property bool faceActive: false
    property bool cancellable: false
    signal cancelled()

    spacing: 10
    opacity: faceActive ? 1 : 0
    scale: faceActive ? 1 : 0.92
    Behavior on opacity { NumberAnimation { duration: 220 } }
    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

    // Icon takes the spinner's old spot at the left of the face.
    Text {
      visible: statusFace.glyph !== ""
      text: statusFace.glyph
      // Neutral on the icon-only faces so the tone lives in the bars.
      color: statusFace.iconOnly ? Colors.foreground : statusFace.tone
      font.family: Typography.icons.family
      font.pixelSize: 18
    }

    // Loading faces run the bar sweep in their tone color. There is no
    // mic signal during transcribing or typing, so level stays silent.
    BarVisualizer {
      visible: statusFace.loadingMode
      Layout.preferredWidth: 78
      Layout.preferredHeight: 32
      Layout.alignment: Qt.AlignVCenter
      barCount: 9
      idle: "static"
      loading: statusFace.loadingMode && statusFace.faceActive
      barColor: statusFace.tone
    }

    Label {
      visible: !statusFace.iconOnly
      text: statusFace.label
      color: statusFace.tone
      weight: Font.Medium
    }

    Item {
      id: cancelSlot
      property real reveal: pillHover.hovered ? 1 : 0
      Behavior on reveal { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.18 } }
      visible: statusFace.cancellable && reveal > 0.02
      Layout.preferredWidth: reveal * 30
      Layout.preferredHeight: 30
      Layout.alignment: Qt.AlignVCenter
      clip: true

      Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        FaceButton {
          icon: "x"
          tone: Colors.red
          reveal: cancelSlot.reveal
          onClicked: statusFace.cancelled()
        }
      }
    }
  }
}
