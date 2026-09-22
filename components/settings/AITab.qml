import "../.."
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: root
  spacing: 4

  property bool editingKey: false
  property real keyProgress: editingKey ? 1 : 0
  property bool showKey: false
  readonly property bool editingLang: langField.activeFocus

  Behavior on keyProgress { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  // History file for the graphs, same path the service writes.
  FileView {
    id: historyFile
    path: Quickshell.dataPath("transcripts.jsonl")
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
  }

  readonly property var entries: {
    if (!historyFile.loaded) return []
    const t = historyFile.text()
    if (t.length === 0) return []
    const out = []
    const lines = t.split("\n")
    for (let i = 0; i < lines.length; i++) {
      const ln = lines[i].trim()
      if (ln.length === 0) continue
      try { out.push(JSON.parse(ln)) } catch (e) {}
    }
    return out
  }

  function localKey(d) { return d.getFullYear() + "-" + String(d.getMonth()+1).padStart(2,"0") + "-" + String(d.getDate()).padStart(2,"0") }

  readonly property var dayCounts: {
    const m = {}
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i]
      if (!e.ts || e.status !== "success") continue
      const dt = new Date(e.ts)
      const k = localKey(dt)
      m[k] = (m[k] || 0) + 1
    }
    return m
  }

  readonly property int streakLen: {
    let n = 0
    const d = new Date()
    d.setHours(0, 0, 0, 0)
    for (let i = 0; i < 120; i++) {
      const k = localKey(d)
      if (dayCounts[k] > 0) { n++; d.setDate(d.getDate() - 1) } else if (n === 0) { d.setDate(d.getDate() - 1); continue } else break
    }
    return n
  }

  readonly property int longestStreak: {
    const keys = Object.keys(dayCounts).sort()
    let best = 0; let cur = 0; let prev = null
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i]
      if (prev) {
        const a = new Date(prev); const b = new Date(k)
        const diff = Math.round((b - a) / 86400000)
        cur = diff === 1 ? cur + 1 : 1
      } else cur = 1
      if (cur > best) best = cur; prev = k
    }
    return best
  }

  readonly property int totalWords: {
    let n = 0
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i]
      if (e.status !== "success") continue
      n += e.wordCount || 0
    }
    return n
  }

  readonly property int wpm: {
    let words = 0; let ms = 0
    for (let i = 0; i < entries.length; i++) {
      const e = entries[i]
      if (e.status !== "success" || !e.audioDurationMs) continue
      words += e.wordCount || 0; ms += e.audioDurationMs
    }
    return ms > 0 ? Math.round(words / (ms / 60000)) : 0
  }

  function commitKey(): void {
    Settings.ai.deepgramKey = keyField.text.trim()
    editingKey = false
  }

  function cancelKey(): void {
    keyField.text = Settings.ai.deepgramKey
    editingKey = false
  }

  function startEditKey(): void {
    keyField.text = Settings.ai.deepgramKey
    keyField.cursorPosition = keyField.text.length
    editingKey = true
    keyField.forceActiveFocus()
  }

  // Graphs at the top. Small gauge on the left, calendar flexes on the right.
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Label {
        text: (root.streakLen > 0 ? root.streakLen + " day streak" : "No streak yet")
        color: Colors.foreground
        weight: Font.Bold
        size: Typography.sizeSM
        Layout.fillWidth: true
      }

      Label {
        text: root.longestStreak > 0 ? "Longest streak | " + root.longestStreak + " days" : ""
        color: Colors.white
        size: Typography.sizeXS
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 12

      ColumnLayout {
        Layout.preferredWidth: 148
        Layout.alignment: Qt.AlignTop
        spacing: 10

        TotalWords {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          count: root.totalWords
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Colors.border; opacity: 0.6 }

        WpmGauge {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          wpm: root.wpm
        }
      }

      ContributionGrid {
        Layout.fillWidth: true
        Layout.preferredHeight: 112
        Layout.alignment: Qt.AlignTop
        counts: root.dayCounts
      }
    }
  }

  Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Colors.border; Layout.topMargin: 6; Layout.bottomMargin: 2 }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6

    Label {
      text: "Deepgram API key"
      color: Colors.foreground
      weight: Font.DemiBold
      Layout.fillWidth: true
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Settings.rounding.md
        color: root.editingKey || keyMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: root.editingKey ? Colors.blue : Colors.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        MouseArea {
          id: keyMa
          anchors.fill: parent
          enabled: !root.editingKey
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.startEditKey()
        }

        TextInput {
          id: keyField
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 34
          clip: true
          enabled: root.editingKey
          selectByMouse: true
          echoMode: root.showKey ? TextInput.Normal : TextInput.Password
          text: Settings.ai.deepgramKey
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.foreground
          selectionColor: Colors.blue
          selectedTextColor: Colors.black
          font.family: Typography.mono.family
          font.pixelSize: Typography.sizeSM
          font.weight: Typography.mono.weight
          onAccepted: root.commitKey()
          Keys.onEscapePressed: event => {
            root.cancelKey()
            event.accepted = true
          }
        }

        Text {
          anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
          text: root.showKey ? "eye-slash" : "eye"
          color: eyeMa.containsMouse ? Colors.foreground : Colors.white
          font.family: Typography.icons.family
          font.pixelSize: 16
          Behavior on color { ColorAnimation { duration: 150 } }

          MouseArea {
            id: eyeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showKey = !root.showKey
          }
        }
      }

      Item {
        Layout.preferredWidth: 80 * root.keyProgress
        Layout.preferredHeight: 32
        clip: true
        visible: root.editingKey || root.keyProgress > 0.01

        Row {
          spacing: 8
          height: 32
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - 72 + (1 - root.keyProgress) * 28

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: cancelMa.containsMouse ? Colors.red : Colors.transparent
            border.color: cancelMa.containsMouse ? Colors.red : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "x"
              color: cancelMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: cancelMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.cancelKey()
            }
          }

          Rectangle {
            width: 32
            height: 32
            radius: Settings.rounding.sm
            color: saveMa.containsMouse ? Colors.green : Colors.transparent
            border.color: saveMa.containsMouse ? Colors.green : Colors.border
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
              anchors.centerIn: parent
              text: "check"
              color: saveMa.containsMouse ? Colors.black : Colors.white
              font.family: Typography.icons.family
              font.pixelSize: 16
              Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
              id: saveMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.commitKey()
            }
          }
        }
      }
    }

    Label {
      text: "Stored as plain text in kettshell.json."
      color: Colors.white
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      elide: Text.ElideRight
    }
  }

  SettingsRow {
    title: "Model"
    subtitle: "Deepgram transcription model"
    Layout.fillWidth: true
    Layout.topMargin: 8

    Row {
      spacing: 6
      Layout.alignment: Qt.AlignVCenter

      Repeater {
        model: ["nova-3", "nova-2", "enhanced", "base"]

        delegate: Rectangle {
          id: chip
          required property string modelData
          readonly property bool active: Settings.ai.model === modelData

          width: chipLabel.implicitWidth + 16
          height: 26
          radius: Settings.rounding.sm
          color: active ? Colors.blue : (chipMa.containsMouse ? Colors.card : Colors.transparent)
          border.color: active ? Colors.blue : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }
          Behavior on border.color { ColorAnimation { duration: 150 } }

          Label {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.modelData
            color: chip.active ? Colors.black : Colors.white
            size: Typography.sizeXS
            weight: Font.DemiBold
          }

          MouseArea {
            id: chipMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Settings.ai.model = chip.modelData
          }
        }
      }
    }
  }

  SettingsRow {
    title: "Language"
    subtitle: "BCP-47 code like en or en-US; multi for auto-detect"
    Layout.fillWidth: true

    Rectangle {
      Layout.preferredWidth: 100
      Layout.preferredHeight: 32
      Layout.alignment: Qt.AlignVCenter
      radius: Settings.rounding.md
      color: langField.activeFocus || langMa.containsMouse ? Colors.surface : Colors.transparent
      border.color: langField.activeFocus ? Colors.blue : Colors.border
      border.width: 1
      Behavior on color { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      MouseArea {
        id: langMa
        anchors.fill: parent
        enabled: !langField.activeFocus
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: langField.forceActiveFocus()
      }

      TextInput {
        id: langField
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        clip: true
        selectByMouse: true
        text: Settings.ai.language
        verticalAlignment: TextInput.AlignVCenter
        color: Colors.foreground
        selectionColor: Colors.blue
        selectedTextColor: Colors.black
        font.family: Typography.sans.family
        font.pixelSize: Typography.sizeSM
        font.weight: Typography.sans.weight
        onAccepted: {
          const t = text.trim()
          if (t !== "") Settings.ai.language = t
          else text = Settings.ai.language
          focus = false
        }
        Keys.onEscapePressed: event => {
          text = Settings.ai.language
          focus = false
          event.accepted = true
        }
        onActiveFocusChanged: if (!activeFocus) text = Settings.ai.language
      }
    }
  }

  SettingsRow {
    title: "Smart formatting"
    subtitle: "Deepgram cleans up numbers, dates, and paragraphs"
    Layout.fillWidth: true

    RowToggle {
      checked: Settings.ai.smartFormat
      onToggled: c => Settings.ai.smartFormat = c
    }
  }

  SettingsRow {
    title: "Punctuation"
    subtitle: "Add punctuation to the transcript"
    Layout.fillWidth: true

    RowToggle {
      checked: Settings.ai.punctuate
      onToggled: c => Settings.ai.punctuate = c
    }
  }

  SettingsRow {
    title: "Copy to clipboard"
    subtitle: "Also keep the transcript on the clipboard after typing"
    Layout.fillWidth: true

    RowToggle {
      checked: Settings.ai.autoCopy
      onToggled: c => Settings.ai.autoCopy = c
    }
  }

  SettingsRow {
    title: "History retention"
    subtitle: "Days to keep transcripts. 0 keeps forever. Stored as JSONL."
    Layout.fillWidth: true

    RowLayout {
      Layout.alignment: Qt.AlignVCenter
      spacing: 8

      Label {
        text: Settings.ai.retentionDays === 0 ? "forever" : Settings.ai.retentionDays + " days"
        color: Colors.foreground
        useMono: true
        size: Typography.sizeXS
        Layout.preferredWidth: 64
        horizontalAlignment: Text.AlignRight
      }

      Slider {
        Layout.preferredWidth: 140
        Layout.preferredHeight: 32
        Layout.alignment: Qt.AlignVCenter
        fraction: Math.min(1, Settings.ai.retentionDays / 60)
        ready: true
        onMoved: f => Settings.ai.retentionDays = Math.round(f * 60)
      }
    }
  }

  component ContributionGrid: Item {
    id: grid
    property var counts: ({})
    function localKey(d) { return d.getFullYear() + "-" + String(d.getMonth()+1).padStart(2,"0") + "-" + String(d.getDate()).padStart(2,"0") }
    readonly property int weeks: 16
    readonly property int cell: 11
    readonly property int gap: 3
    // Fixed square grid like the reference, not stretched. Width 221 keeps cells square.
    implicitWidth: weeks * cell + (weeks - 1) * gap
    implicitHeight: 14 + 7 * cell + 6 * gap

    function levelFor(k) {
      const n = counts[k] || 0
      if (n === 0) return 0
      if (n === 1) return 1
      if (n <= 3) return 2
      if (n <= 6) return 3
      return 4
    }

    // Oklch lerp between palette tokens, perceptually uniform like the reference.
    function srgbToLinear(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
    function linearToSrgb(c) { return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055 }
    function toOklch(col) {
      const r = srgbToLinear(col.r), g = srgbToLinear(col.g), b = srgbToLinear(col.b)
      const l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
      const m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
      const s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
      const l_ = Math.cbrt(l), m_ = Math.cbrt(m), s_ = Math.cbrt(s)
      const L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
      const a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
      const b2 = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
      const C = Math.sqrt(a * a + b2 * b2)
      let h = Math.atan2(b2, a) * 180 / Math.PI
      if (h < 0) h += 360
      return { L: L, C: C, h: h }
    }
    function fromOklch(oc) {
      const a = oc.C * Math.cos(oc.h * Math.PI / 180)
      const b2 = oc.C * Math.sin(oc.h * Math.PI / 180)
      const l_ = oc.L + 0.3963377774 * a + 0.2158037573 * b2
      const m_ = oc.L - 0.1055613458 * a - 0.0638541728 * b2
      const s_ = oc.L - 0.0894841775 * a - 1.2914855480 * b2
      const l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_
      let r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
      let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
      let b3 = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
      r = Math.min(1, Math.max(0, linearToSrgb(r))); g = Math.min(1, Math.max(0, linearToSrgb(g))); b3 = Math.min(1, Math.max(0, linearToSrgb(b3)))
      return Qt.rgba(r, g, b3, 1)
    }
    function oklchMix(a, b, t) {
      const ca = toOklch(a), cb = toOklch(b)
      let dh = cb.h - ca.h
      if (dh > 180) dh -= 360; else if (dh < -180) dh += 360
      return fromOklch({ L: ca.L + (cb.L - ca.L) * t, C: ca.C + (cb.C - ca.C) * t, h: ca.h + dh * t })
    }
    function colorFor(l) {
      if (l === 0) return Colors.surface
      // 4 steps from surface to green in Oklch, matches reference intensity ramp.
      const t = l / 4
      return oklchMix(Colors.surface, Colors.green, 0.22 + 0.78 * t)
    }

    // Three month labels: current month and the two before it, centered to the square grid.
    RowLayout {
      width: grid.weeks * grid.cell + (grid.weeks - 1) * grid.gap
      anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
      spacing: 0
      Repeater {
        model: grid.weeks
        delegate: Label {
          required property int index
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          color: Colors.white
          size: Typography.sizeXS
          text: {
            const now = new Date(); now.setHours(0,0,0,0)
            const thresh = 2
            const d = new Date(now); d.setDate(d.getDate() - (grid.weeks - 1 - index) * 7)
            const curY = now.getFullYear(), curM = now.getMonth()
            const y = d.getFullYear(), m = d.getMonth()
            const diff = (curY - y) * 12 + (curM - m)
            if (diff < 0 || diff > thresh) return ""
            if (d.getDate() > 7) return ""
            const prevIdx = index - 1
            if (prevIdx >= 0) {
              const pd = new Date(now); pd.setDate(pd.getDate() - (grid.weeks - 1 - prevIdx) * 7)
              if (pd.getMonth() === m && pd.getFullYear() === y && pd.getDate() <= 7) return ""
            }
            return Qt.formatDate(d, "MMM")
          }
        }
      }
    }

    GridLayout {
      width: grid.weeks * grid.cell + (grid.weeks - 1) * grid.gap
      anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 14 }
      columns: grid.weeks
      rows: 7
      columnSpacing: grid.gap
      rowSpacing: grid.gap

      Repeater {
        model: grid.weeks * 7
        delegate: Rectangle {
          required property int index
          readonly property int col: Math.floor(index / 7)
          readonly property int row: index % 7
          readonly property var d: {
            const base = new Date(); base.setHours(0,0,0,0)
            const offset = (grid.weeks - 1 - col) * 7 + (6 - row)
            const todayDow = base.getDay()
            const shift = 6 - todayDow
            const dt = new Date(base); dt.setDate(base.getDate() - offset + shift)
            return dt
          }
          readonly property string key: grid.localKey(d)
          readonly property int lvl: grid.levelFor(key)
          Layout.preferredWidth: grid.cell
          Layout.preferredHeight: grid.cell
          radius: Settings.rounding.sm
          color: grid.colorFor(lvl)
          border.width: lvl === 0 ? 1 : 0
          border.color: Colors.border

          MouseArea {
            id: cellMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
          }

          Rectangle {
            visible: cellMa.containsMouse
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 6
            color: Colors.card
            border.color: Colors.border
            border.width: 1
            radius: Settings.rounding.sm
            width: tipLabel.implicitWidth + 14
            height: tipLabel.implicitHeight + 8
            z: 10

            Label {
              id: tipLabel
              anchors.centerIn: parent
              color: Colors.foreground
              size: Typography.sizeXS
              text: {
                const n = grid.counts[key] || 0
                const ds = Qt.formatDate(d, "MMM d, yyyy")
                return n === 0 ? "No dictates on " + ds : n + (n === 1 ? " dictate on " : " dictates on ") + ds
              }
            }
          }
        }
      }
    }
  }

  component TotalWords: Item {
    id: total
    property int count: 0

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 2

      Label {
        text: total.count.toLocaleString()
        color: Colors.foreground
        weight: Font.Bold
        size: Typography.sizeLG
        Layout.alignment: Qt.AlignHCenter
      }

      Label {
        text: "Total words dictated"
        color: Colors.white
        size: Typography.sizeXS
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }

  component WpmGauge: Item {
    id: gauge
    property int wpm: 0

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 2

      Label { text: String(gauge.wpm); color: Colors.foreground; weight: Font.Bold; size: Typography.sizeLG; Layout.alignment: Qt.AlignHCenter }
      Label { text: "Words per minute"; color: Colors.white; size: Typography.sizeXS; Layout.alignment: Qt.AlignHCenter }
    }
  }

  component RowToggle: Rectangle {
    id: rowToggle
    property alias checked: toggle.checked
    signal toggled(bool checked)

    Layout.preferredWidth: 44
    Layout.preferredHeight: 24
    Layout.alignment: Qt.AlignVCenter
    color: Colors.transparent
    border.color: Colors.border
    border.width: 1
    radius: Settings.rounding.md

    Toggle {
      id: toggle
      anchors.fill: parent
      onToggled: c => rowToggle.toggled(c)
    }
  }
}
