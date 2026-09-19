pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/*
 * Dictation state machine. Records 16 kHz mono raw PCM with pw-record,
 * uploads to Deepgram on stop, and types the transcript with wtype.
 * Owns no visuals; DictationOsd reads `state`, `peak`, and `lastAction`.
 */
Singleton {
  id: root

  // idle | recording | transcribing | done | error
  property string state: "idle"
  // pasted | copied, set when the transcript leaves the shell
  property string lastAction: "pasted"
  readonly property real peak: peakMonitor.peak
  readonly property string audioPath: Quickshell.cachePath("dictate.raw")

  // mip_opt_out keeps audio out of training, retained only to process.
  readonly property string listenUrl: {
    const params = [
      "model=" + encodeURIComponent(Settings.ai.model),
      "encoding=linear16",
      "sample_rate=16000",
      "channels=1",
      "smart_format=" + Settings.ai.smartFormat,
      "punctuate=" + Settings.ai.punctuate,
      "language=" + encodeURIComponent(Settings.ai.language),
      "mip_opt_out=true"
    ]
    return "https://api.deepgram.com/v1/listen?" + params.join("&")
  }

  function notify(summary: string, body: string): void {
    Quickshell.execDetached(["notify-send", "-a", "KettShell", summary, body])
  }

  function begin(): void {
    if (root.state !== "idle") return
    if (Settings.ai.deepgramKey.trim() === "") {
      notify("Dictation", "Add a Deepgram API key in Settings > AI")
      return
    }
    root.state = "recording"
    recorder.running = true
    limitTimer.restart()
  }

  function stop(): void {
    if (root.state !== "recording") return
    limitTimer.stop()
    root.state = "transcribing"
    // SIGTERM. Raw PCM has no header, so a stop at any moment is safe.
    recorder.running = false
  }

  function cancel(): void {
    if (root.state === "idle") return
    limitTimer.stop()
    resetTimer.stop()
    root.state = "idle"
    recorder.running = false
    upload.running = false
    Quickshell.execDetached(["rm", "-f", root.audioPath])
  }

  function toggle(): void {
    if (root.state === "idle") begin()
    else if (root.state === "recording") stop()
    else cancel()
  }

  function transcriptFrom(response: string): string {
    try {
      const json = JSON.parse(response)
      const channels = json && json.results && json.results.channels
      const alt = channels && channels[0] && channels[0].alternatives && channels[0].alternatives[0]
      return alt && alt.transcript ? alt.transcript.trim() : ""
    } catch (error) {
      return ""
    }
  }

  function finish(): void {
    const text = transcriptFrom(upload.response)
    if (text === "") {
      root.state = "error"
      resetTimer.interval = 2000
      resetTimer.restart()
      return
    }
    typer.text = text
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
        // The recorder died on its own: no mic or a busy device.
        root.state = "error"
        resetTimer.interval = 2000
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
      if (root.state !== "transcribing") return
      if (exitCode === 0) {
        root.lastAction = "pasted"
        if (Settings.ai.autoCopy) Quickshell.execDetached(["wl-copy", "--", typer.text])
      } else {
        // Some XWayland clients reject the virtual keyboard. Never lose the text.
        root.lastAction = "copied"
        Quickshell.execDetached(["wl-copy", "--", typer.text])
        root.notify("Dictation", "Could not type into the focused window. Transcript copied to clipboard.")
      }
      root.state = "done"
      resetTimer.interval = 1400
      resetTimer.restart()
    }
  }

  PwNodePeakMonitor {
    id: peakMonitor
    node: Pipewire.defaultAudioSource
    enabled: root.state === "recording" && Pipewire.defaultAudioSource
  }

  // Deepgram bills per minute. Never let a recording run away.
  Timer {
    id: limitTimer
    interval: 60000
    onTriggered: root.stop()
  }

  Timer {
    id: resetTimer
    onTriggered: root.state = "idle"
  }
}
