import ".."
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Scope {
  id: root

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData

      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true

      color: "black"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-background"

      // awww wipe — angle from Config, like `awww --transition-type wipe --transition-angle 30`
      // (awww maps Right→0, Top→90, Left→180, Bottom→270)
      readonly property int deg: Settings.wallpaper.wipeDeg
      property string stableSource: ""
      property string pendingSource: ""
      readonly property bool hasPending: pendingSource !== ""
      property real revealProgress: 1
      property string oldSource: ""

      Component.onCompleted: {
        if (Wallpapers.current) stableSource = "file://" + Wallpapers.current
      }

      onHasPendingChanged: {
        if (!hasPending) {
          revealProgress = 1
          oldSource = ""
        }
      }

      Connections {
        target: Wallpapers
        function onCurrentChanged() {
          let cur = Wallpapers.current
          if (!cur) {
            win.stableSource = ""
            win.pendingSource = ""
            win.oldSource = ""
            win.revealProgress = 1
            revealAnim.stop()
            return
          }
          let url = "file://" + cur
          if (url === win.stableSource || url === win.pendingSource) return
          if (win.stableSource === "") {
            win.stableSource = url
            win.pendingSource = ""
            win.oldSource = ""
            win.revealProgress = 1
            revealAnim.stop()
            return
          }
          revealAnim.stop()
          win.oldSource = win.stableSource
          win.pendingSource = url
          win.revealProgress = 0
          if (incomingImg.status === Image.Ready) {
            Qt.callLater(() => { if (win.hasPending && win.revealProgress === 0) revealAnim.restart() })
          }
        }
      }

      NumberAnimation {
        id: revealAnim
        target: win
        property: "revealProgress"
        from: 0
        to: 1
        duration: 700
        easing.type: Easing.Bezier
        easing.bezierCurve: [0.54, 0.0, 0.34, 0.99]
        onFinished: {
          if (win.hasPending) {
            win.stableSource = win.pendingSource
            Qt.callLater(() => {
              win.pendingSource = ""
              win.oldSource = ""
              win.revealProgress = 1
            })
          }
        }
      }

      Image {
        id: baseImg
        anchors.fill: parent
        source: win.hasPending ? win.oldSource : win.stableSource
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: win.screen ? win.screen.width : 1920
        sourceSize.height: win.screen ? win.screen.height : 1080
        asynchronous: true
        cache: true
        smooth: true
        mipmap: false
        autoTransform: false
        visible: source !== ""
      }

      Item {
        id: incomingLayer
        anchors.fill: parent
        visible: win.hasPending && incomingImg.status === Image.Ready
        layer.enabled: win.hasPending && win.revealProgress < 1
        layer.smooth: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: wipeMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.02
        }

        Image {
          id: incomingImg
          anchors.fill: parent
          source: win.pendingSource
          fillMode: Image.PreserveAspectCrop
          sourceSize.width: win.screen ? win.screen.width : 1920
          sourceSize.height: win.screen ? win.screen.height : 1080
          asynchronous: true
          cache: true
          smooth: true
          mipmap: false
          autoTransform: false
          onStatusChanged: {
            if (status === Image.Ready && win.hasPending && win.revealProgress === 0) {
              Qt.callLater(() => { if (win.hasPending && win.revealProgress === 0) revealAnim.restart() })
            } else if (status === Image.Error && win.hasPending) {
              win.stableSource = win.pendingSource
              win.pendingSource = ""
              win.oldSource = ""
              win.revealProgress = 1
              revealAnim.stop()
            }
          }
        }
      }

      /*
       * Mask implementing awww's Wave/Wipe reveal condition exactly:
       *
       *   lhs = y_rel*sin - x_rel*cos   (y_rel, x_rel relative to center)
       *   rhs = offset/r - r
       *   reveal where lhs <= rhs
       *
       * with offset animating (|sin|*w + |cos|*h)*2 → r²*2 and r = diag/2.
       * The boundary line has unit normal n = (-cos, sin) and passes through
       * center + rhs*n; the revealed half-plane points along (cos, -sin).
       * That is one huge rectangle whose left edge sits on the boundary,
       * rotated by -deg so its local +x axis is the reveal direction.
       */
      Item {
        id: wipeMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        readonly property real rad: win.deg * Math.PI / 180
        readonly property real sn: Math.sin(rad)
        readonly property real cs: Math.cos(rad)
        readonly property real r: Math.sqrt(width * width + height * height) / 2
        readonly property real offset0: (Math.abs(sn) * width + Math.abs(cs) * height) * 2
        readonly property real offset: offset0 + win.revealProgress * (r * r * 2 - offset0)
        readonly property real rhs: offset / r - r
        // foot of perpendicular from center onto the boundary line
        readonly property real p0x: width / 2 - rhs * cs
        readonly property real p0y: height / 2 + rhs * sn
        readonly property real cover: r * 3

        Rectangle {
          width: wipeMask.cover
          height: wipeMask.cover
          rotation: -win.deg
          transformOrigin: Item.TopLeft
          // top-left corner = p0 - (cover/2) * local-y-axis, local y = (sin, cos)
          x: wipeMask.p0x - (wipeMask.cover / 2) * wipeMask.sn
          y: wipeMask.p0y - (wipeMask.cover / 2) * wipeMask.cs
          color: "white"
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Colors.background
        visible: !Wallpapers.current && !win.stableSource
        z: -1
      }
    }
  }
}
