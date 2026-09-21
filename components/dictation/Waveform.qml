import "../.."
import QtQuick

/*
 * Symmetric voice waveform driven only by the processed microphone level.
 * Samples flow from right to left and clear immediately during silence.
 * Bar color walks a magenta -> blue -> cyan gradient across the row.
 */
Item {
  id: root

  property bool active: false
  property real level: 0

  readonly property int maxBars: 32
  readonly property real barStep: 5
  readonly property real barWidth: 3
  readonly property real minHeight: 3
  readonly property int visibleBars: Math.max(4, Math.min(maxBars, Math.floor(width / barStep)))

  property real smoothedLevel: 0
  property real sampleElapsed: 0
  property var barHeights: []
  property var barColors: []

  function clearBars(): void {
    root.smoothedLevel = 0
    root.sampleElapsed = 0
    root.barHeights = new Array(root.visibleBars).fill(root.minHeight)
  }

  onActiveChanged: root.clearBars()
  onVisibleBarsChanged: root.clearBars()

  FrameAnimation {
    running: root.active && (root.level > 0 || root.smoothedLevel > 0)
    onTriggered: root.advance(Math.min(frameTime, 0.05))
  }

  function advance(dt: real): void {
    const target = Math.max(0, Math.min(1, root.level))
    if (target === 0) {
      root.clearBars()
      return
    }

    root.smoothedLevel += (target - root.smoothedLevel) * Math.min(1, dt * 18)
    root.sampleElapsed += dt
    if (root.sampleElapsed < 0.05) return
    root.sampleElapsed = 0

    const heights = root.barHeights.slice()
    while (heights.length < root.visibleBars) heights.push(root.minHeight)
    heights.shift()
    heights.push(root.minHeight + (root.height - root.minHeight) * root.smoothedLevel)
    root.barHeights = heights
  }

  function lerpColor(a: color, b: color, t: real): color {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
  }

  Component.onCompleted: {
    const colors = new Array(root.maxBars)
    for (let i = 0; i < root.maxBars; i++) {
      const t = i / (root.maxBars - 1)
      colors[i] = t < 0.5
        ? lerpColor(Colors.magenta, Colors.blue, t * 2)
        : lerpColor(Colors.blue, Colors.cyan, (t - 0.5) * 2)
    }
    root.barColors = colors
  }

  Item {
    anchors.fill: parent

    Repeater {
      model: root.visibleBars

      delegate: Rectangle {
        required property int index

        width: root.barWidth
        height: root.barHeights[index] || root.minHeight
        x: root.barStep * index + (root.barStep - width) / 2
        y: (root.height - height) / 2
        radius: width / 2
        color: root.barColors[index] || Colors.cyan
      }
    }
  }
}
