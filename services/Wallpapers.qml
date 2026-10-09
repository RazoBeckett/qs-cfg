pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  readonly property string expandedWallDir: {
    let p = Settings.wallpaper.directory

    if (!p || p.trim().length === 0)
      return ""

    let home = Quickshell.env("HOME") || ""

    p = p.replace(/^~/, home)
    p = p.replace(/\$HOME/g, home)
    p = p.replace(/\$\{HOME\}/g, home)

    if (!p.endsWith("/"))
      p += "/"

    return p
  }

  // Specific state for the wallpaper directory. Used to drive error messages
  // instead of a silent hardcoded fallback. Values: "empty" | "missing" | "notADir" | "noPerm" | "ok"
  // Start optimistic ("ok"/"empty") to avoid flashing red before the sh check completes.
  property string directoryState: expandedWallDir === "" ? "empty" : "ok"
  readonly property bool directoryExists: directoryState === "ok"

  // POSIX sh validation — no bashisms. Reports why the path is broken.
  // expandedWallDir always ends with "/", so strip it before testing
  // otherwise a file like "/a/b.jpg/" tests as "missing" not "notADir".
  Process {
    id: dirCheckProc
    command: [
      "sh", "-c",
      'p="$1"; p=${p%/}; if [ -z "$p" ]; then echo empty; elif [ ! -e "$p" ]; then echo missing; elif [ ! -d "$p" ]; then echo notADir; elif [ ! -r "$p" ] || [ ! -x "$p" ]; then echo noPerm; else echo ok; fi',
      "sh",
      root.expandedWallDir
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        let s = (text || "").trim()
        if (s === "empty" || s === "missing" || s === "notADir" || s === "noPerm" || s === "ok") root.directoryState = s
        else root.directoryState = "missing"
      }
    }
  }

  property list<string> all: []
  property var allLower: []

  readonly property string current: Settings.wallpaper.current

  function fileName(path: string): string {
    let i = path.lastIndexOf("/")

    return i >= 0
      ? path.slice(i + 1)
      : path
  }

  // Fuzzy score expects already lowercased pattern/text. Higher is better, 0 = no match.
  function fuzzyScore(pattern: string, text: string): real {
    if (!pattern || pattern.length === 0) return 1
    let pLen = pattern.length
    let tLen = text.length
    if (pLen > tLen) return 0
    let idx = text.indexOf(pattern)
    if (idx !== -1) {
      return 100 - idx
    }
    let score = 0
    let prev = -1
    let consecutive = 0
    for (let i = 0; i < pLen; i++) {
      let ch = pattern[i]
      let found = text.indexOf(ch, prev + 1)
      if (found === -1) return 0
      if (prev !== -1 && found === prev + 1) {
        consecutive++
        score += 8 + consecutive * 2
      } else {
        consecutive = 0
        let gap = found - prev - 1
        score -= gap * 1.5
        if (found === 0 || text[found - 1] === "_" || text[found - 1] === "-" || text[found - 1] === " " || text[found - 1] === "." || text[found - 1] === "/") {
          score += 6
        }
      }
      if (i === 0 && found === 0) score += 10
      prev = found
    }
    return score > 0 ? score : 0.5
  }

  function query(filter: string): list<string> {
    if (!filter || filter.trim() === "")
      return all
    let q = filter.trim().toLowerCase()
    let scored = []
    for (let i = 0; i < all.length; i++) {
      let s = fuzzyScore(q, allLower[i])
      if (s > 0) scored.push([all[i], s])
    }
    scored.sort((a, b) => b[1] - a[1])
    let out = []
    for (let i = 0; i < scored.length; i++) out.push(scored[i][0])
    return out
  }

  function setWallpaper(path: string): void {
    if (!path)
      return

    Settings.wallpaper.current = path
  }

  function refresh(): void {
    listProc.running = true
  }

  /*
   * Default to the first wallpaper when none is selected yet.
   */
  onAllChanged: {
    let lower = []
    for (let i = 0; i < all.length; i++) lower.push(fileName(all[i]).toLowerCase())
    allLower = lower
    if (
      !Settings.wallpaper.current &&
      root.all.length > 0
    ) {
      Settings.wallpaper.current = root.all[0]
    }
  }

  /*
   * Find wallpapers.
   */
  Process {
    id: listProc

    // Directory comes in as $1 so sh never re-parses its content.
    command: [
      "sh",
      "-c",
      "dir=\"$1\"; " +
        "[ -d \"$dir\" ] || exit 0; " +
        "find \"$dir\" -type f " +
        "\\( " +
        "-iname \"*.jpg\" -o " +
        "-iname \"*.jpeg\" -o " +
        "-iname \"*.png\" -o " +
        "-iname \"*.webp\" -o " +
        "-iname \"*.bmp\" -o " +
        "-iname \"*.gif\" " +
        "\\) 2>/dev/null | sort",
      "list-wallpapers",
      root.expandedWallDir
    ]

    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        let t = (text || "").trim()

        if (t === "") {
          root.all = []
          return
        }

        let lines = t
          .split("\n")
          .filter(
            s => s.trim().length > 0
          )

        root.all = lines
      }
    }
  }

  Component.onCompleted: {
    if (root.expandedWallDir === "") root.directoryState = "empty"
    else dirCheckProc.running = true
  }

  /*
   * Re-check and re-list when the wallpaper directory changes.
   */
  onExpandedWallDirChanged: {
    if (root.expandedWallDir === "") {
      root.directoryState = "empty"
    } else {
      dirCheckProc.running = true
    }
    Qt.callLater(() => {
      listProc.running = true
    })
  }

  /*
   * IPC
   */
  IpcHandler {
    target: "wallpaper"

    function list(): string {
      return root.all.join("\n")
    }

    function get(): string {
      return root.current
    }

    function set(path: string): void {
      root.setWallpaper(path)
    }

    function refresh(): void {
      root.refresh()
    }
  }
}
