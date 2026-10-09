import "../.."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
  id: root

  property bool open: false

  function toggle(): void {
    open ? close() : show()
  }

  function show(): void {
    open = true
  }

  function close(): void {
    open = false
  }

  GlobalShortcut {
    appid: "quickshell"
    name: "wallpaper-picker-toggle"
    description: "Toggle wallpaper picker"

    onPressed: root.toggle()
  }

  IpcHandler {
    target: "wallpaperPicker"

    function toggle(): void {
      root.toggle()
    }

    function open(): void {
      root.show()
    }

    function close(): void {
      root.close()
    }

    function isOpen(): string {
      return root.open ? "1" : "0"
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win

      required property var modelData

      screen: modelData

      visible: root.open || animProgress > 0

      color: "transparent"

      anchors.top: true
      anchors.bottom: true
      anchors.left: true
      anchors.right: true

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.exclusionMode: ExclusionMode.Ignore

      WlrLayershell.keyboardFocus:
        (root.open || win.animProgress > 0)
          ? WlrKeyboardFocus.Exclusive
          : WlrKeyboardFocus.None

      exclusionMode: ExclusionMode.Ignore

      property real animProgress: 0
      property bool shouldShow: root.open

      // 3-up, bigger for readability — fits 1080p+ and clamps on smaller screens
      readonly property int pickerItemW: 400
      readonly property int pickerGap: 12
      readonly property int pickerVisibleCount: 3

      readonly property int pickerRowW:
        pickerVisibleCount * pickerItemW +
        (pickerVisibleCount - 1) * pickerGap

      property string debouncedText: ""
      readonly property var filteredModel: Wallpapers.query(debouncedText) || []

      onFilteredModelChanged: {
        Qt.callLater(() => {
          let m = filteredModel
          if (!m || m.length === 0)
            return
          let cur = Wallpapers.current
          let idx = m.indexOf(cur)
          carousel.currentIndex = idx >= 0 ? idx : 0
        })
      }

      onShouldShowChanged: {
        animProgress = shouldShow ? 1 : 0
      }

      // Scale in and out are mirrored — same curve reversed for exit/Enter.
      Behavior on animProgress {
        NumberAnimation {
          duration: 280
          easing.type: Easing.InOutCubic
        }
      }

      Rectangle {
        id: dim
        anchors.fill: parent
        color: "#000000"
        opacity: win.animProgress * 0.32
        visible: opacity > 0.01
        // no Behavior — dim is pure derivative of animProgress (single progress)
        TapHandler {
          acceptedButtons: Qt.LeftButton
          onTapped: root.close()
        }
      }

      function commitCurrent(): void {
        if (
          carousel.currentIndex < 0 ||
          carousel.currentIndex >= win.filteredModel.length
        )
          return
        Wallpapers.setWallpaper(win.filteredModel[carousel.currentIndex])
        root.close()
      }

      Column {
        id: contentCol

        anchors.centerIn: parent

        /*
         * Keep the whole picker centered and compact.
         * Opacity/scale are derived from animProgress — single progress
         * drives the whole exit so the reverse mirrors the entrance without
         * the chase stutter (see Quickshell Motion guide).
         */
        width: Math.min(
          win.pickerRowW,
          parent.width - 32
        )

        spacing: 8

        opacity: win.animProgress
        scale: 0.96 + win.animProgress * 0.04

        visible: win.animProgress > 0.01

        /*
         * Search
         */
        Rectangle {
          id: searchWrap

          width: parent.width
          height: 44

          radius: Settings.rounding.md

          color: "transparent"

          TextInput {
            id: searchField

            anchors.fill: parent

            anchors.leftMargin: 12
            anchors.rightMargin: 12

            horizontalAlignment: TextInput.AlignHCenter
            verticalAlignment: TextInput.AlignVCenter

            color: Colors.foreground

            selectionColor: Colors.blue
            selectedTextColor: Colors.background

            font.family: Typography.sans.family
            font.pixelSize: Typography.sizeMD
            font.weight: Typography.sans.weight

            property string placeholderText:
              "Search by filename"

            Text {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter

              horizontalAlignment: Text.AlignHCenter

              text: searchField.placeholderText

              color: Colors.white

              opacity:
                searchField.text.length === 0
                  ? (
                      searchField.activeFocus
                        ? 0.28
                        : 0.45
                    )
                  : 0

              font.family: searchField.font.family
              font.pixelSize: searchField.font.pixelSize
              font.weight: searchField.font.weight

              visible: opacity > 0

              Behavior on opacity {
                NumberAnimation {
                  duration: 110
                }
              }
            }

            Timer {
              id: searchDebounce
              interval: 100
              onTriggered: win.debouncedText = searchField.text
            }
            onTextChanged: { if (searchDebounce) searchDebounce.restart() }

            Keys.onPressed: event => {
              if (
                (event.modifiers & Qt.ControlModifier) &&
                event.key === Qt.Key_H
              ) {
                win.selectPrevious()
                event.accepted = true

              } else if (
                (event.modifiers & Qt.ControlModifier) &&
                event.key === Qt.Key_L
              ) {
                win.selectNext()
                event.accepted = true

              } else if (event.key === Qt.Key_Left) {
                win.selectPrevious()
                event.accepted = true

              } else if (event.key === Qt.Key_Right) {
                win.selectNext()
                event.accepted = true

              } else if (event.key === Qt.Key_Escape) {
                root.close()
                event.accepted = true

              } else if (
                event.key === Qt.Key_Return ||
                event.key === Qt.Key_Enter
              ) {
                if (
                  carousel.currentIndex >= 0 &&
                  carousel.currentIndex < win.filteredModel.length
                ) {
                  Wallpapers.setWallpaper(
                    win.filteredModel[carousel.currentIndex]
                  )
                }
                root.close()
                event.accepted = true
              }
            }
          }
        }

        Item {
          id: carouselHost

          width: parent.width

          height: 280

          clip: true

          Column {
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 4
            visible: Wallpapers.all.length === 0 || !win.filteredModel || win.filteredModel.length === 0

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              width: parent.width
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              visible: Wallpapers.all.length === 0
              text: {
                switch (Wallpapers.directoryState) {
                  case "empty": return "Wallpaper directory not set — please set a path in Settings"
                  case "missing": return "Wallpaper directory not found — please check Settings\n" + Settings.wallpaper.directory
                  case "notADir": return "Path is not a directory — please pick a folder\n" + Settings.wallpaper.directory
                  case "noPerm": return "No permission to read that folder\n" + Settings.wallpaper.directory
                  default: return Wallpapers.all.length === 0 ? "No wallpapers found in this folder\n" + Settings.wallpaper.directory : ""
                }
              }
              color: Wallpapers.directoryState === "ok" ? Colors.white : Colors.red
              opacity: 0.85
              font.family: Typography.sans.family
              font.pixelSize: Typography.sizeSM
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              visible: Wallpapers.all.length !== 0 && (!win.filteredModel || win.filteredModel.length === 0)
              text: "No match"
              color: Colors.white
              opacity: 0.6
              font.family: Typography.sans.family
              font.pixelSize: Typography.sizeSM
              horizontalAlignment: Text.AlignHCenter
            }
          }

        /*
         * Wallpaper previews — PathView carousel, like caelestia's launcher.
         *
         * Delegates slide along the path; only delegates created at the path
         * edge play the entrance pop, so existing previews glide instead of
         * re-popping on every navigation.
         *
         * Path length = 3 * (item + gap) with the current item snapped to the
         * middle, so visible spacing between previews is exactly pickerGap.
         */
        PathView {
          id: carousel

          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter

          width:
            win.pickerVisibleCount * win.pickerItemW +
            (win.pickerVisibleCount - 1) * win.pickerGap
          height: 260

          visible: win.filteredModel ? win.filteredModel.length > 0 : false

          model: win.filteredModel

          pathItemCount: win.pickerVisibleCount
          cacheItemCount: 4

          highlightRangeMode: PathView.StrictlyEnforceRange
          preferredHighlightBegin: 0.5
          preferredHighlightEnd: 0.5
          snapMode: PathView.SnapToItem
          highlightMoveDuration: 220

          interactive: true
          flickDeceleration: 2000

          path: Path {
            startY: carousel.height / 2

            PathAttribute { name: "z"; value: 0 }

            PathLine {
              x: carousel.width / 2
              relativeY: 0
            }

            PathAttribute { name: "z"; value: 1 }

            PathLine {
              x: carousel.width
              relativeY: 0
            }

            PathAttribute { name: "z"; value: 0 }
          }

          delegate: WallpaperItem {
            id: del

            width: win.pickerItemW

            isCurrent: PathView.isCurrentItem
            z: del.PathView.z ?? 0

            /*
             * Entrance state (caelestia-style): new delegates start small
             * and invisible, then the Behaviors in WallpaperItem animate
             * them to their resting values. Scale/opacity are transforms —
             * the path layout is never disturbed.
             */
            scale: 0.5
            opacity: 0

            Component.onCompleted: {
              scale = Qt.binding(() =>
                PathView.onPath
                  ? (PathView.isCurrentItem ? 1.07 : 0.90)
                  : 0
              )
              opacity = Qt.binding(() => PathView.onPath ? 1 : 0)
            }

            onClicked: {
              if (PathView.isCurrentItem)
                win.commitCurrent()
              else
                carousel.currentIndex = del.index
            }
          }
        }
      }
      }

      function selectPrevious(): void {
        if (!filteredModel || filteredModel.length === 0)
          return
        carousel.decrementCurrentIndex()
      }

      function selectNext(): void {
        if (!filteredModel || filteredModel.length === 0)
          return
        carousel.incrementCurrentIndex()
      }

      onVisibleChanged: {
        if (!root.open)
          return

        searchField.text = ""
        debouncedText = ""
        if (searchDebounce) searchDebounce.stop()

        let start = Wallpapers.current
        let all = Wallpapers.all
        let idx = all.indexOf(start)

        if (idx >= 0) {
          carousel.currentIndex = idx
        } else if (all.length > 0) {
          carousel.currentIndex = 0
        } else {
          carousel.currentIndex = -1
        }

        Qt.callLater(() => {
          searchField.forceActiveFocus()
        })
      }

      /*
       * Global keyboard handling while the picker is open.
       *
       * This does not sit above the thumbnails, so it cannot
       * intercept mouse clicks.
       */
      Shortcut {
        sequence: "Escape"
        onActivated: root.close()
      }

      Shortcut {
        sequence: "Ctrl+H"
        onActivated: win.selectPrevious()
      }

      Shortcut {
        sequence: "Ctrl+L"
        onActivated: win.selectNext()
      }

      HyprlandFocusGrab {
        active: root.open || win.animProgress > 0

        windows: [win]

        onCleared: root.close()
      }
    }
  }
}
