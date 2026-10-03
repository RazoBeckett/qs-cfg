import "../.."
import QtQuick

/*
 * Frequency-band bar visualizer, ported from audiocn's bar-visualizer.
 * The mic gives a single scalar level, so it is shaped into a mirrored
 * band profile, then run through the reference ballistics: instant attack,
 * smooth release toward the resting floor, and an idle wave while quiet.
 */
Item {
  id: root

  property bool active: false
  property real level: 0
  // What quiet bars do: static, pulse, or a traveling wave.
  property string idle: "wave"
  // Runs a sweep instead of reading the mic, for thinking states.
  property bool loading: false
  property color barColor: Colors.foreground

  property int barCount: 24
  readonly property real barGap: 3
  readonly property real barMaxWidth: 6
  // Resting bar size, 0..1.
  readonly property real minLevel: 0.08

  readonly property real barWidth: Math.max(1, Math.min(barMaxWidth, (width - (barCount - 1) * barGap) / barCount))
  readonly property real totalWidth: barCount * barWidth + (barCount - 1) * barGap
  readonly property real startX: Math.max(0, (width - totalWidth) / 2)

  // Per release frame, the share of the old bar left after 16.67ms.
  readonly property real releasePerFrame: 0.86
  property real clockMs: 0
  property var levels: []

  function reset(): void {
    root.clockMs = 0
    const base = new Array(root.barCount).fill(root.minLevel)
    root.levels = base
    // Drain from the floor instead of holding stale levels across takes.
    root.current = base.slice()
  }

  property var current: new Array(root.barCount).fill(0)
  onActiveChanged: root.reset()
  onLoadingChanged: if (root.loading) root.reset()
  Component.onCompleted: root.reset()

  FrameAnimation {
    running: root.active || root.loading
    onTriggered: root.step(Math.min(frameTime, 0.1) * 1000)
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

  // Idle level for one bar, matching the reference idleLevel.
  function idleExtra(seconds: real, index: int): real {
    if (root.idle === "pulse") return 0.1 * (0.5 + 0.5 * Math.sin(seconds * Math.PI * 1.6))
    if (root.idle === "wave") return 0.16 * (0.5 + 0.5 * Math.sin(seconds * 4 - index * 0.55))
    return 0
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
    const release = Math.pow(root.releasePerFrame, dtMs / 16.67)
    const quiet = root.level < 0.02

    const nextLevels = root.current.slice()
    const shown = new Array(root.barCount)
    for (let i = 0; i < root.barCount; i++) {
      const target = root.bandTarget(i, seconds, quiet)
      const previous = nextLevels[i] || 0
      const next = target >= previous ? target : previous * release + target * (1 - release)
      nextLevels[i] = next
      shown[i] = root.clamp01(Math.max(root.minLevel, next))
    }
    root.current = nextLevels
    root.levels = shown
  }

  Repeater {
    model: root.barCount

    delegate: Rectangle {
      required property int index

      x: root.startX + index * (root.barWidth + root.barGap)
      width: root.barWidth
      height: Math.max(2, (root.levels[index] || root.minLevel) * root.height)
      y: Math.max(0, (root.height - height) / 2)
      radius: width / 2
      color: root.barColor
    }
  }
}
