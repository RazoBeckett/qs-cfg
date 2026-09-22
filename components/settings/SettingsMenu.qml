import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

/*
 * Settings card: sidebar tabs on the left, page content on the right.
 * Width breakpoints: 900 and up keeps the full sidebar, below that
 * collapses it to icons with tooltips.
 * Open plays a staggered intro (card, then sidebar, then content); close
 * collapses content and sidebar first, then the card.
 */
Item {
  id: root

  property bool open: false
  property int currentTab: 0

  property real introBase: 0.0
  property real introSidebar: 0.0
  property real introContent: 0.0
  readonly property bool busy: openSequence.running || closeSequence.running
  property string commitHash: "development"
  property bool commitResolved: false
  readonly property string commitDisplay: "KettShell @" + commitHash

  // 2 is wide, 1 is medium. Medium starts at 640 and keeps the
  // icon-only sidebar usable at the minimum window size.
  readonly property int mode: width >= 900 ? 2 : 1

  signal closeFinished

  Process {
    id: gitCommitProc
    command: ["git", "-C", Quickshell.shellDir, "rev-parse", "--short", "HEAD"]
    workingDirectory: Quickshell.shellDir
    running: root.open && !root.commitResolved
    stdout: StdioCollector {
      onStreamFinished: {
        let t = (text || "").trim()
        root.commitHash = t.length > 0 ? t : "development"
        root.commitResolved = true
      }
    }
  }

  function playOpen(): void {
    closeSequence.stop()
    introBase = 0.0
    introSidebar = 0.0
    introContent = 0.0
    openSequence.restart()
  }

  function playClose(): void {
    if (closeSequence.running) return
    if (!root.open && root.introBase <= 0.0) return
    openSequence.stop()
    closeSequence.restart()
  }

  function resetIntro(): void {
    openSequence.stop()
    closeSequence.stop()
    introBase = 0.0
    introSidebar = 0.0
    introContent = 0.0
  }

  function nextTab(): void {
    currentTab = (currentTab + 1) % tabsModel.length
  }

  function prevTab(): void {
    currentTab = (currentTab - 1 + tabsModel.length) % tabsModel.length
  }

  onOpenChanged: {
    if (open) {
      forceActiveFocus()
      playOpen()
    }
  }

  onCurrentTabChanged: settingsFlick.contentY = 0

  readonly property var tabsModel: [
    { name: "UI", icon: "sliders-horizontal" },
    { name: "Wallpaper", icon: "image" },
    { name: "Fonts", icon: "text-aa" },
    { name: "AI", icon: "robot" },
    { name: "About", icon: "info" }
  ]

  Shortcut {
    sequence: "Escape"
    enabled: !wallpaperTab.editingDir && !fontsTab.editingFont && !fontsTab.editingMono && !aiTab.editingKey && !aiTab.editingLang
    onActivated: root.playClose()
  }

  Keys.onTabPressed: event => {
    root.nextTab()
    event.accepted = true
  }

  Keys.onBacktabPressed: event => {
    root.prevTab()
    event.accepted = true
  }

  ParallelAnimation {
    id: openSequence
    running: false
    NumberAnimation {
      target: root
      property: "introBase"
      from: 0.0
      to: 1.0
      duration: 220
      easing.type: Easing.OutCubic
    }
    SequentialAnimation {
      PauseAnimation { duration: 40 }
      NumberAnimation {
        target: root
        property: "introSidebar"
        from: 0.0
        to: 1.0
        duration: 380
        easing.type: Easing.OutBack
        easing.overshoot: 1.05
      }
    }
    SequentialAnimation {
      PauseAnimation { duration: 80 }
      NumberAnimation {
        target: root
        property: "introContent"
        from: 0.0
        to: 1.0
        duration: 320
        easing.type: Easing.OutBack
        easing.overshoot: 1.02
      }
    }
  }

  SequentialAnimation {
    id: closeSequence
    running: false
    ParallelAnimation {
      NumberAnimation {
        target: root
        property: "introContent"
        to: 0.0
        duration: 120
        easing.type: Easing.InExpo
      }
      NumberAnimation {
        target: root
        property: "introSidebar"
        to: 0.0
        duration: 120
        easing.type: Easing.InExpo
      }
    }
    NumberAnimation {
      target: root
      property: "introBase"
      to: 0.0
      duration: 160
      easing.type: Easing.InQuart
    }
    ScriptAction {
      script: root.closeFinished()
    }
  }

  Item {
    anchors.fill: parent
    opacity: root.introBase
    scale: 0.95 + 0.05 * root.introBase
    transformOrigin: Item.Center

    ClippingRectangle {
      anchors.fill: parent
      color: Colors.background
      border.color: Colors.border
      border.width: 1
      radius: Settings.rounding.lg
      contentUnderBorder: true

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
          Layout.preferredWidth: root.mode === 2 ? 224 : 72
          Layout.fillHeight: true
          opacity: root.introSidebar
          transform: Translate { x: -30 * (1.0 - root.introSidebar) }

          Rectangle {
            anchors.fill: parent
            color: Colors.surface
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            RowLayout {
              Layout.fillWidth: true
              Layout.bottomMargin: 10
              spacing: 10

              Item {
                visible: root.mode === 1
                Layout.fillWidth: true
              }

              Text {
                text: "gear"
                color: Colors.blue
                font.family: Typography.icons.family
                font.pixelSize: 20
              }

              Label {
                visible: root.mode === 2
                text: "Settings"
                color: Colors.foreground
                weight: Font.Bold
                Layout.fillWidth: true
              }

              Item {
                visible: root.mode === 1
                Layout.fillWidth: true
              }
            }

            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: tabsRepeater.count * 48 - 4

              Rectangle {
                id: activeHighlight
                width: parent.width
                height: 44
                y: tabsRepeater.itemAt(root.currentTab) ? tabsRepeater.itemAt(root.currentTab).y : 0
                color: Colors.blue
                radius: Settings.rounding.md
                Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
              }

              ColumnLayout {
                anchors.fill: parent
                spacing: 4

                Repeater {
                  id: tabsRepeater
                  model: root.tabsModel

                  delegate: Item {
                    id: tabBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44

                    readonly property bool active: root.currentTab === index

                    Rectangle {
                      anchors.fill: parent
                      color: tabMa.containsMouse && !active ? Colors.card : Colors.transparent
                      radius: Settings.rounding.md
                      Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: root.mode === 2 ? 14 + (active ? 4 : 0) : 0
                      anchors.rightMargin: root.mode === 2 ? 14 : 0
                      spacing: 10
                      Behavior on anchors.leftMargin { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                      Item {
                        visible: root.mode === 1
                        Layout.fillWidth: true
                      }

                      Text {
                        text: modelData.icon
                        color: active ? Colors.black : Colors.white
                        font.family: Typography.icons.family
                        font.pixelSize: 18
                        Behavior on color { ColorAnimation { duration: 150 } }
                      }

                      Label {
                        visible: root.mode === 2
                        text: modelData.name
                        color: active ? Colors.black : Colors.white
                        weight: Font.DemiBold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation { duration: 150 } }
                      }

                      Item {
                        visible: root.mode === 1
                        Layout.fillWidth: true
                      }
                    }

                    MouseArea {
                      id: tabMa
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.currentTab = index
                    }

                    PopupWindow {
                      id: tabTip
                      visible: tabMa.containsMouse && root.mode === 1 && !active
                      grabFocus: false
                      color: Colors.transparent
                      implicitWidth: tipBg.width
                      implicitHeight: tipBg.height

                      anchor {
                        item: tabBtn
                        adjustment: PopupAdjustment.Slide
                        edges: Edges.Top | Edges.Left
                        gravity: Edges.Bottom | Edges.Right
                        rect.x: tabBtn.width + 8
                        rect.y: Math.round((tabBtn.height - tabTip.implicitHeight) / 2)
                        rect.width: 1
                        rect.height: 1
                      }

                      Rectangle {
                        id: tipBg
                        width: tipLabel.implicitWidth + 16
                        height: tipLabel.implicitHeight + 8
                        color: Colors.black
                        border.color: Colors.border
                        border.width: 1
                        radius: Settings.rounding.sm
                        clip: true

                        Label {
                          id: tipLabel
                          anchors.centerIn: parent
                          text: modelData.name
                          color: Colors.foreground
                          size: Typography.sizeXS
                        }
                      }
                    }
                  }
                }
              }
            }

            Item { Layout.fillHeight: true }

            Label {
              visible: root.mode === 2
              text: root.commitDisplay
              color: Colors.white
              size: Typography.sizeXS
              opacity: 0.65
              elide: Text.ElideRight
              Layout.fillWidth: true
              Layout.topMargin: 8
            }
          }

          Rectangle {
            width: 1
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: Colors.border
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
          opacity: root.introContent
          scale: 0.95 + 0.05 * root.introContent
          transformOrigin: Item.Center
          transform: Translate { y: 20 * (1.0 - root.introContent) }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Label {
              text: root.tabsModel[root.currentTab].name
              color: Colors.foreground
              weight: Font.Bold
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 1
              color: Colors.border
            }

            Flickable {
              id: settingsFlick
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              contentWidth: settingsFlick.width
              contentHeight: flickContent.implicitHeight
              boundsBehavior: Flickable.StopAtBounds

              ColumnLayout {
                id: flickContent
                width: Math.min(settingsFlick.width, 700)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                UiTab { visible: root.currentTab === 0; Layout.fillWidth: true }
                WallpaperTab { id: wallpaperTab; visible: root.currentTab === 1; Layout.fillWidth: true }
                FontsTab { id: fontsTab; visible: root.currentTab === 2; Layout.fillWidth: true; commitDisplay: root.commitDisplay }
                AITab { id: aiTab; visible: root.currentTab === 3; Layout.fillWidth: true }
                AboutTab { visible: root.currentTab === 4; Layout.fillWidth: true }

                Item { Layout.fillHeight: true; Layout.preferredHeight: 0 }
              }
            }
          }
        }
      }
    }
  }
}
