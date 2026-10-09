import "../.."
import QtQuick

Item {
  id: root
  property real fraction: 0
  property bool ready: true
  property int trackHeight: 4
  property int thumbBaseWidth: 20
  property int thumbBaseHeight: 14
  property int thumbRadius: Settings.rounding.md
  property int grabExtraWidth: 4
  property int grabExtraHeight: 2
  property int maxStretch: 12
  property real stretchVelocityScale: 9
  property color trackColor: Colors.card
  property color fillColor: Colors.blue
  property color thumbColor: Colors.foreground
  property color thumbActiveColor: Colors.blue
  property color thumbPressedBorder: Colors.foreground
  property int trackRadius: Settings.rounding.sm
  property real wheelStep: 0.05
  property real wheelFineStep: 0.01

  signal moved(real fraction)

  readonly property bool dragging: sliderMa.pressed
  property real lastMouseX: 0
  property real lastTime: 0
  property real smoothVel: 0
  property real displayedStretch: 0
  property real grabT: dragging ? 1 : 0
  property real momentumVel: 0

  readonly property real stretchMag: Math.abs(displayedStretch)
  readonly property real effectiveW: thumbBaseWidth + grabT * grabExtraWidth + stretchMag
  readonly property real effectiveH: thumbBaseHeight + grabT * grabExtraHeight
  readonly property real centerX: root.width * Math.max(0, Math.min(1, root.fraction))
  readonly property real thumbXRaw: centerX - effectiveW / 2 + (dragging ? (displayedStretch >= 0 ? 1 : -1) * stretchMag * 0.5 : 0)
  readonly property real thumbX: Math.max(0, Math.min(root.width - effectiveW, thumbXRaw))

  property real tickScale: 1
  property real _prevFrac: fraction
  property var detents: [0, 0.5, 1]

  function _checkDetents(newF, oldF) {
    for (let i = 0; i < detents.length; i++) {
      let t = detents[i]
      let crossed = (oldF < t && newF >= t) || (oldF > t && newF <= t)
      if (!crossed && (t === 0 || t === 1)) {
        let nearOld = Math.abs(oldF - t) < 0.012
        let nearNew = Math.abs(newF - t) < 0.012
        if (!nearOld && nearNew && Math.abs(newF - oldF) > 0.004) crossed = true
      }
      if (crossed) { tickAnim.restart(); return }
    }
  }

  onFractionChanged: {
    let prev = _prevFrac
    let cur = fraction
    if (Math.abs(cur - prev) > 0.001) _checkDetents(cur, prev)
    _prevFrac = cur
  }

  SequentialAnimation {
    id: tickAnim
    NumberAnimation { target: root; property: "tickScale"; to: 1.06; duration: 85; easing.type: Easing.OutCubic }
    NumberAnimation { target: root; property: "tickScale"; to: 1; duration: 150; easing.type: Easing.OutCubic }
  }

  Behavior on grabT { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
  Behavior on displayedStretch { NumberAnimation { duration: root.dragging ? 90 : 180; easing.type: Easing.OutCubic } }

  function clampFraction(v) { return Math.max(0, Math.min(1, v)) }

  function resetVelocity(x) {
    lastMouseX = x
    lastTime = Date.now()
    smoothVel = 0
  }

  function updateVelocity(newX) {
    let now = Date.now()
    let dt = now - lastTime
    if (dt < 4) dt = 4
    if (dt > 80) dt = 16
    let dx = newX - lastMouseX
    let inst = dx / dt
    smoothVel = smoothVel * 0.45 + inst * 0.55
    let target = Math.max(-maxStretch, Math.min(maxStretch, smoothVel * stretchVelocityScale))
    if (Math.abs(target) < 1.0) target = target * 0.5
    displayedStretch = target
    lastMouseX = newX
    lastTime = now
  }

  Timer {
    id: momentumTimer
    interval: 16
    repeat: true
    onTriggered: {
      root.momentumVel *= 0.80
      if (Math.abs(root.momentumVel) < 0.02) {
        root.momentumVel = 0
        stop()
        return
      }
      let deltaFrac = root.momentumVel * 16 / Math.max(1, root.width) * 0.9
      if (Math.abs(deltaFrac) < 0.0008) {
        root.momentumVel = 0
        stop()
        return
      }
      let next = root.clampFraction(root.fraction + deltaFrac)
      if (next === 0 || next === 1) {
        root.momentumVel = 0
        stop()
      }
      if (Math.abs(next - root.fraction) > 0.0001) root.moved(next)
      else {
        root.momentumVel = 0
        stop()
      }
    }
  }

  Rectangle {
    id: trackBg
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: root.trackHeight
    radius: root.trackRadius
    color: root.trackColor
  }

  Rectangle {
    id: trackFill
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    width: Math.round(parent.width * root.clampFraction(root.fraction))
    height: root.trackHeight
    radius: root.trackRadius
    color: root.fillColor
    opacity: root.ready ? 1 : 0.4
    Behavior on width { enabled: !root.dragging; NumberAnimation { duration: 40; easing.type: Easing.Linear } }
  }

  Rectangle {
    id: thumb
    width: root.effectiveW
    height: root.effectiveH
    radius: root.thumbRadius
    color: sliderMa.containsMouse || sliderMa.pressed ? root.thumbActiveColor : root.thumbColor
    border.color: sliderMa.pressed ? root.thumbPressedBorder : Colors.transparent
    border.width: 1
    anchors.verticalCenter: parent.verticalCenter
    x: root.thumbX
    scale: root.tickScale
    transformOrigin: Item.Center
    opacity: root.ready ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: 90 } }
    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: "transparent"
      border.color: Colors.black
      border.width: 1
      opacity: 0.15
      z: -1
    }
  }

  MouseArea {
    id: sliderMa
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    enabled: root.ready
    function updateFromMouse(mouse) {
      let f = mouse.x / root.width
      root.moved(root.clampFraction(f))
    }
    onPressed: mouse => {
      momentumTimer.stop()
      root.momentumVel = 0
      root.resetVelocity(mouse.x)
      updateFromMouse(mouse)
    }
    onPositionChanged: mouse => {
      if (pressed) {
        updateFromMouse(mouse)
        updateVelocity(mouse.x)
      }
    }
    onReleased: {
      let relVel = root.smoothVel
      root.displayedStretch = 0
      if (Math.abs(relVel) > 0.40) {
        let scaled = relVel * 0.11
        scaled = Math.max(-1.4, Math.min(1.4, scaled))
        let est = Math.abs(scaled * 80 / Math.max(1, root.width))
        if (est > 0.045) scaled *= 0.045 / est
        if (Math.abs(scaled) > 0.06) {
          root.momentumVel = scaled
          momentumTimer.start()
        } else {
          root.smoothVel = 0
        }
      } else {
        root.smoothVel = 0
      }
    }
    onCanceled: {
      root.displayedStretch = 0
      root.smoothVel = 0
      momentumTimer.stop()
      root.momentumVel = 0
    }
    onWheel: wheel => {
      let step = (wheel.modifiers & Qt.AltModifier) ? root.wheelFineStep : root.wheelStep
      if (wheel.angleDelta.y > 0) root.moved(root.clampFraction(root.fraction + step))
      else if (wheel.angleDelta.y < 0) root.moved(root.clampFraction(root.fraction - step))
    }
  }
}
