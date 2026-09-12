import "../.."
import QtQuick

/*
 * Symmetric voice waveform: 32 bars centered on the horizontal axis, full
 * bar height is the amplitude. Motion follows the neon-visualizer recipe
 * (per-bar value noise + sine oscillator + one shared beat), scaled by the
 * live mic peak so the row swells when the user speaks. Bar color walks a
 * magenta -> blue -> cyan gradient across the row.
 */
Item {
  id: root

  property bool active: false
  property real level: 0

  readonly property int barCount: 32
  readonly property real minHeight: 3

  property real time: 0
  property real beatPhase: 0
  property real pulse: 1
  property real smoothedLevel: 0
  property var barHeights: []
  property var barColors: []

  onActiveChanged: if (active) root.smoothedLevel = 0

  FrameAnimation {
    running: root.active
    onTriggered: root.advance(Math.min(frameTime, 0.05))
  }

  function advance(dt: real): void {
    root.time += dt * 1.2
    root.beatPhase += dt * 9.0
    const beat = 0.5 + 0.45 * (Math.sin(root.beatPhase) + 1) // 0.5..1.4
    root.pulse = 0.65 + 0.35 * (beat - 0.5) / 0.9
    root.smoothedLevel += (Math.min(1, root.level * 1.6) - root.smoothedLevel) * Math.min(1, dt * 10)
    const mic = 0.25 + 0.75 * root.smoothedLevel
    const heights = new Array(root.barCount)
    for (let i = 0; i < root.barCount; i++) {
      const noise = noise2(i * 0.3, root.time)
      const osc = (Math.sin(root.time + i * 0.4) + 1) * 0.5
      let amp = (noise * 0.7 + osc * 0.3) * beat * mic // up to ~1.4
      amp = Math.pow(Math.min(amp / 1.4, 1), 1.35) // bias low, occasional peaks
      heights[i] = root.minHeight + (root.height - root.minHeight) * amp
    }
    root.barHeights = heights
  }

  // Value noise: deterministic and smooth across neighboring bars.
  function hash2(x: real, y: real): real {
    const s = Math.sin(x * 127.1 + y * 311.7) * 43758.5453
    return s - Math.floor(s)
  }

  function noise2(x: real, y: real): real {
    const xi = Math.floor(x)
    const yi = Math.floor(y)
    const xf = x - xi
    const yf = y - yi
    const u = xf * xf * (3 - 2 * xf)
    const v = yf * yf * (3 - 2 * yf)
    const a = hash2(xi, yi)
    const b = hash2(xi + 1, yi)
    const c = hash2(xi, yi + 1)
    const d = hash2(xi + 1, yi + 1)
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v
  }

  function lerpColor(a: color, b: color, t: real): color {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
  }

  Component.onCompleted: {
    const colors = new Array(root.barCount)
    for (let i = 0; i < root.barCount; i++) {
      const t = i / (root.barCount - 1)
      colors[i] = t < 0.5
        ? lerpColor(Colors.magenta, Colors.blue, t * 2)
        : lerpColor(Colors.blue, Colors.cyan, (t - 0.5) * 2)
    }
    root.barColors = colors
  }

  Item {
    anchors.fill: parent
    opacity: root.pulse

    Repeater {
      model: root.barCount

      delegate: Rectangle {
        required property int index
        readonly property real step: root.width / root.barCount

        width: Math.max(2, step * 0.6)
        height: root.barHeights[index] || root.minHeight
        x: step * index + (step - width) / 2
        y: (root.height - height) / 2
        radius: width / 2
        color: root.barColors[index] || Colors.cyan
      }
    }
  }
}
