import "../.."
import QtQuick

/*
 * Frequency-band bar visualizer, ported from audiocn's bar-visualizer.
 * The mic gives a single scalar level, so it is shaped into a mirrored
 * band profile, then run through the reference ballistics: instant attack,
 * smooth release toward the resting floor, an idle wave while quiet, and
 * a loading sweep instead of reading the mic for thinking states.
 */
Item {
  id: root

  property bool active: false
  property real level: 0
  // Runs a sweep instead of reading the mic, for thinking states.
  property bool loading: false
  property color barColor: Colors.foreground

  property int barCount: 24
  readonly property real barGap: 3
  readonly property real barMaxWidth: 6
  // Resting bar size, 0..1.
  readonly property real minLevel: 0.08

  readonly property real barWidth: Math.max(1, Math.min(barMaxWidth, (width - (barCount - 1) * barGap) / barCount))
  readonly property real startX: Math.max(0, (width - (barCount * barWidth + (barCount - 1) * barGap)) / 2)

  property real clockMs: 0
  // Animated level per bar, 0..1 before the resting floor.
  property var levels: []

  onActiveChanged: root.reset()
  onLoadingChanged: if (root.loading) root.reset()
  Component.onCompleted: root.reset()

  FrameAnimation {
    running: root.active || root.loading
    onTriggered: root.step(Math.min(frameTime, 0.1) * 1000)
  }

  function reset(): void {
    root.clockMs = 0
    root.levels = []
  }

  function clamp01(v: real): real {
    return Math.max(0, Math.min(1, v))
  }

  // White noise per bar, per tick. Release smoothing turns each tick
  // change into a flicker, so one scalar level reads as a band spectrum.
  function rand(index: int, tick: int): real {
    const v = Math.sin(index * 12.9898 + tick * 78.233) * 43758.5453
    return v - Math.floor(v)
  }

  // Idle wave, matching the reference idleLevel.
  function idleExtra(seconds: real, index: int): real {
    return 0.16 * (0.5 + 0.5 * Math.sin(seconds * 4 - index * 0.55))
  }

  // Loading sweep: a Gaussian packet that travels the row and wraps,
  // matching the reference sweepLevel.
  function sweepLevel(seconds: real, index: int): real {
    const span = root.barCount + 6
    const position = ((seconds * root.barCount * 0.9) % span) - 3
    return 0.55 * Math.exp(-((index - position) ** 2) / 3)
  }

  // Mirrored band shape: lows in the centre, edges down to a third, each
  // band flickering slightly louder and softer around the scalar level.
  function bandTarget(index: int, seconds: real, quiet: bool): real {
    if (root.loading) return root.sweepLevel(seconds, index)
    if (quiet) return root.idleExtra(seconds, index)
    const half = Math.max(1, (root.barCount - 1) / 2)
    const fromCenter = Math.abs(index - half) / half
    const shape = 1 - 0.7 * fromCenter
    const tick = Math.floor(seconds * 24)
    const flicker = 0.7 + 0.5 * root.rand(index, tick)
    return root.clamp01(root.level * shape * flicker)
  }

  function step(dtMs: real): void {
    // A painter clock: never jumps further than 100ms after a stall.
    root.clockMs += Math.min(dtMs, 100)
    const seconds = root.clockMs / 1000
    const release = Math.pow(0.86, dtMs / 16.67)
    const quiet = root.level < 0.02

    // A fresh array each frame so the delegate bindings see the change
    // signal. The floor is a render concern, not stored state.
    const rows = new Array(root.barCount)
    for (let i = 0; i < root.barCount; i++) {
      const target = root.bandTarget(i, seconds, quiet)
      const previous = root.levels[i] || 0
      const next = target >= previous ? target : previous * release + target * (1 - release)
      rows[i] = root.clamp01(next)
    }
    root.levels = rows
  }

  Repeater {
    model: root.barCount

    delegate: Rectangle {
      required property int index

      x: root.startX + index * (root.barWidth + root.barGap)
      width: root.barWidth
      height: Math.max(root.minLevel, root.levels[index] || 0) * root.height
      y: Math.max(0, (root.height - height) / 2)
      radius: Settings.rounding.sm
      color: root.barColor
    }
  }
}
