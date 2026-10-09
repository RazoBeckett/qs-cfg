pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

/*
 * Dictation state machine. Records 16 kHz mono raw PCM, uploads to
 * Deepgram, and types the result. DictationOsd reads state, peak, and
 * lastAction. History is appended as JSONL.
 */
Singleton {
  id: root

  // idle | recording | transcribing | typing | done | error
  property string state: "idle"
  // pasted | copied
  property string lastAction: "pasted"
  readonly property real peak: peakMonitor.peak
  property real voiceLevel: 0
  property real noiseFloor: 0.005
  property bool speechStarted: false
  property int speechFrames: 0
  property double lastSpeechMs: 0
  readonly property real speechThreshold: Math.max(0.02, noiseFloor * 2.5 + 0.005)
  readonly property string audioPath: Quickshell.cachePath("dictate.raw")
  readonly property string historyPath: Quickshell.dataPath("transcripts.jsonl")

  // Timings for recording endpointing and the pill.
  readonly property int initialSilenceMs: 10000
  readonly property int trailingSilenceMs: 7000
  readonly property int errorMs: 2000
  readonly property int doneMs: 1400

  // Snapshot for the current utterance, filled at begin() so history and
  // the upload use the same values even if Settings change mid recording.
  property double startMs: 0
  property double uploadStartMs: 0
  property string snapModel: ""
  property string snapLanguage: ""
  property bool snapSmartFormat: true
  property bool snapPunctuate: true
  property string snapAppClass: ""
  property string snapAppTitle: ""
  property double snapConfidence: -1

  // Deepgram listen URL, snapshot aware so the request matches history.
  // mip_opt_out keeps audio out of training, retained only to process.
  readonly property string listenUrl: {
    const model = root.snapModel || Settings.ai.model
    const lang = root.snapLanguage || Settings.ai.language
    const smart = root.snapModel ? root.snapSmartFormat : Settings.ai.smartFormat
    const punct = root.snapModel ? root.snapPunctuate : Settings.ai.punctuate
    const params = [
      "model=" + encodeURIComponent(model),
      "encoding=linear16",
      "sample_rate=16000",
      "channels=1",
      "smart_format=" + smart,
      "punctuate=" + punct,
      "language=" + encodeURIComponent(lang),
      "mip_opt_out=true"
    ]
    return "https://api.deepgram.com/v1/listen?" + params.join("&")
  }

  function notify(summary: string, body: string): void {
    Quickshell.execDetached(["notify-send", "-a", "KettShell", summary, body])
  }

  function clearAudio(): void {
    Quickshell.execDetached(["rm", "-f", root.audioPath])
  }

  function captureContext(): void {
    const tl = Hyprland.activeToplevel
    if (!tl) {
      root.snapAppClass = ""
      root.snapAppTitle = ""
      return
    }
    const ipc = tl.lastIpcObject
    root.snapAppClass = ipc && ipc.class ? String(ipc.class).slice(0, 120) : ""
    root.snapAppTitle = tl.title ? String(tl.title).slice(0, 200) : ""
  }

  function begin(): void {
    if (root.state !== "idle") return
    if (Settings.ai.deepgramKey.trim() === "") {
      notify("Dictation", "Add a Deepgram API key in Settings > AI")
      return
    }
    root.startMs = Date.now()
    root.voiceLevel = 0
    root.noiseFloor = 0.005
    root.speechStarted = false
    root.speechFrames = 0
    root.lastSpeechMs = root.startMs
    root.snapModel = Settings.ai.model
    root.snapLanguage = Settings.ai.language
    root.snapSmartFormat = Settings.ai.smartFormat
    root.snapPunctuate = Settings.ai.punctuate
    root.snapConfidence = -1
    captureContext()
    root.state = "recording"
    recorder.running = true
  }

  function stop(): void {
    if (root.state !== "recording") return
    root.voiceLevel = 0
    root.uploadStartMs = Date.now()
    root.state = "transcribing"
    recorder.running = false
  }

  function cancel(): void {
    if (root.state === "idle") return
    resetTimer.stop()
    root.voiceLevel = 0
    root.state = "idle"
    recorder.running = false
    upload.running = false
    clearAudio()
  }

  function toggle(): void {
    if (root.state === "idle") begin()
    else if (root.state === "recording") stop()
    else cancel()
  }

  function monitorVoice(): void {
    const now = Date.now()
    const level = root.peak
    const threshold = root.speechThreshold

    if (level >= threshold) {
      root.speechFrames++
      if (root.speechFrames >= 3) {
        root.speechStarted = true
        root.lastSpeechMs = now
        root.voiceLevel = Math.min(1, (level - threshold) * 6)
      } else {
        root.voiceLevel = 0
      }
    } else {
      root.speechFrames = 0
      root.voiceLevel = 0
      root.noiseFloor = root.noiseFloor * 0.95 + level * 0.05
    }

    const silenceMs = root.speechStarted ? root.trailingSilenceMs : root.initialSilenceMs
    const silenceStartMs = root.speechStarted ? root.lastSpeechMs : root.startMs
    if (now - silenceStartMs >= silenceMs) root.stop()
  }

  function parseTranscript(response: string): var {
    try {
      const json = JSON.parse(response)
      const alt = json?.results?.channels?.[0]?.alternatives?.[0]
      const c = alt && typeof alt.confidence === "number" ? alt.confidence : -1
      const text = alt?.transcript ? String(alt.transcript).trim() : ""
      return { text: text, confidence: c }
    } catch (e) {
      return { text: "", confidence: -1 }
    }
  }

  function countWords(text: string): int {
    const t = text.trim()
    return t.length === 0 ? 0 : t.split(/\s+/).filter(function(w) { return w.length > 0 }).length
  }

  function buildEntry(text: string, status: string): var {
    const now = Date.now()
    const recMs = root.uploadStartMs > root.startMs ? Math.round(root.uploadStartMs - root.startMs) : 0
    const processingMs = root.uploadStartMs > 0 ? Math.max(0, Math.round(now - root.uploadStartMs)) : 0
    return {
      id: String(now) + "-" + Math.random().toString(36).slice(2, 8),
      ts: new Date(root.startMs).toISOString(),
      text: text,
      status: status,
      confidence: root.snapConfidence >= 0 ? root.snapConfidence : null,
      model: root.snapModel,
      language: root.snapLanguage,
      smartFormat: root.snapSmartFormat,
      punctuate: root.snapPunctuate,
      provider: "deepgram",
      audioDurationMs: recMs,
      processingMs: processingMs,
      wordCount: countWords(text),
      charCount: text.length,
      appClass: root.snapAppClass,
      appTitle: root.snapAppTitle,
      outputMethod: root.lastAction
    }
  }

  function appendHistory(text: string, status: string): void {
    const entry = buildEntry(text, status)
    const line = JSON.stringify(entry)
    const cur = historyFile.text()
    const next = cur.length === 0 ? line + "\n" : (cur.endsWith("\n") ? cur + line + "\n" : cur + "\n" + line + "\n")
    historyFile.setText(next)
    pruneHistory()
  }

  function pruneHistory(): void {
    const days = Settings.ai.retentionDays
    if (days === 0) return
    const cur = historyFile.text()
    if (cur.length === 0) return
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000
    const lines = cur.split("\n")
    let kept = []
    let dropped = false
    for (let i = 0; i < lines.length; i++) {
      const ln = lines[i].trim()
      if (ln.length === 0) continue
      try {
        const obj = JSON.parse(ln)
        const t = Date.parse(obj.ts)
        if (!isNaN(t) && t < cutoff) { dropped = true; continue }
      } catch (e) {}
      kept.push(lines[i])
    }
    if (dropped) historyFile.setText(kept.length === 0 ? "" : kept.join("\n") + "\n")
  }

  function finish(): void {
    const parsed = parseTranscript(upload.response)
    root.snapConfidence = parsed.confidence
    if (parsed.text === "") {
      appendHistory("", "empty")
      clearAudio()
      root.state = "error"
      resetTimer.interval = errorMs
      resetTimer.restart()
      return
    }
    appendHistory(parsed.text, "success")
    clearAudio()
    root.state = "typing"
    typer.text = parsed.text
    typer.running = true
  }

  Process {
    id: recorder
    command: ["pw-record", "--rate", "16000", "--channels", "1", "--format", "s16", "--container", "raw", root.audioPath]
    onExited: function(exitCode) {
      if (root.state === "transcribing") {
        upload.response = ""
        upload.running = true
      } else if (root.state === "recording") {
        root.state = "error"
        resetTimer.interval = errorMs
        resetTimer.restart()
      }
    }
  }

  Process {
    id: upload
    property string response: ""
    command: [
      "curl", "-sS", "-X", "POST", root.listenUrl,
      "-H", "Authorization: Token " + Settings.ai.deepgramKey,
      "-H", "Content-Type: audio/raw",
      "--data-binary", "@" + root.audioPath
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.state !== "transcribing") return
        upload.response = this.text
        root.finish()
      }
    }
  }

  Process {
    id: typer
    property string text: ""
    command: ["wtype", "-d", "1", "--", typer.text]
    onExited: function(exitCode) {
      if (root.state !== "typing") return
      if (exitCode === 0) {
        root.lastAction = "pasted"
        if (Settings.ai.autoCopy) Quickshell.execDetached(["wl-copy", "--", typer.text])
      } else {
        root.lastAction = "copied"
        Quickshell.execDetached(["wl-copy", "--", typer.text])
        notify("Dictation", "Could not type into the focused window. Transcript copied to clipboard.")
      }
      root.state = "done"
      resetTimer.interval = doneMs
      resetTimer.restart()
    }
  }

  PwNodePeakMonitor {
    id: peakMonitor
    node: Pipewire.defaultAudioSource
    enabled: root.state === "recording" && Pipewire.defaultAudioSource
  }

  FileView {
    id: historyFile
    path: root.historyPath
    printErrors: false
    atomicWrites: true
    onLoaded: pruneHistory()
  }

  Timer {
    interval: 50
    repeat: true
    running: root.state === "recording"
    onTriggered: root.monitorVoice()
  }

  Timer {
    id: resetTimer
    onTriggered: root.state = "idle"
  }
}
