import "../.."
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets

ColumnLayout {
  id: root
  spacing: 4

  property bool editingDir: false
  property real editProgress: editingDir ? 1 : 0
  Behavior on editProgress { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

  function commitDir(): void {
    let t = dirField.text.trim()
    if (t !== "") Settings.wallpaper.directory = t
    else dirField.text = Settings.wallpaper.directory
    editingDir = false
  }

  function cancelDir(): void {
    dirField.text = Settings.wallpaper.directory
    editingDir = false
  }

  function startEdit(): void {
    dirField.text = Settings.wallpaper.directory
    dirField.cursorPosition = dirField.text.length
    editingDir = true
    dirField.forceActiveFocus()
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Label {
        text: "Library"
        color: Colors.foreground
        weight: Font.DemiBold
        Layout.fillWidth: true
      }

      Label {
        text: Wallpapers.all.length + " images"
        color: Colors.white
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 0

      Rectangle {
        id: dirBox
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Settings.rounding.md
        color: root.editingDir || fieldMa.containsMouse ? Colors.surface : Colors.transparent
        border.color: {
          if (Wallpapers.directoryState !== "ok" && !root.editingDir) return Colors.red
          return root.editingDir ? Colors.blue : Colors.border
        }
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        TextInput {
          id: dirField
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          clip: true
          enabled: root.editingDir
          selectByMouse: true
          text: Settings.wallpaper.directory
          verticalAlignment: TextInput.AlignVCenter
          color: Colors.foreground
          selectionColor: Colors.blue
          selectedTextColor: Colors.black
          font.family: Typography.sans.family
          font.pixelSize: Typography.sizeSM
          font.weight: Typography.sans.weight
          onAccepted: root.commitDir()
          Keys.onEscapePressed: event => {
            root.cancelDir()
            event.accepted = true
          }
        }

        MouseArea {
          id: fieldMa
          anchors.fill: parent
          enabled: !root.editingDir
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.startEdit()
        }
      }

      Item {
        id: buttonsWrap
        Layout.preferredWidth: 80 * root.editProgress
        Layout.preferredHeight: 32
        clip: true
        visible: root.editingDir || root.editProgress > 0.01

        Row {
          spacing: 8
          height: 32
          anchors.verticalCenter: parent.verticalCenter
          x: parent.width - 72 + (1 - root.editProgress) * 28

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
              onClicked: root.cancelDir()
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
              onClicked: root.commitDir()
            }
          }
        }
      }
    }

    // Inline validation — specific message per directoryState (POSIX sh)
    Label {
      visible: Wallpapers.directoryState !== "ok" && !root.editingDir
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      color: Colors.red
      size: Typography.sizeXS
      text: {
        switch (Wallpapers.directoryState) {
          case "empty": return "Directory not set — please set a valid path"
          case "missing": return "Directory not found — please check path"
          case "notADir": return "Path is not a directory"
          case "noPerm": return "No permission to read that folder"
          default: return ""
        }
      }
    }
  }

  SettingsRow {
    title: "Current"
    subtitle: Wallpapers.current ? Wallpapers.fileName(Wallpapers.current) : "-"
    Layout.fillWidth: true
  }

  // -- Wipe direction control ------------------------------------------------
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 6
    Layout.topMargin: 6

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Label {
        text: "Wipe direction"
        color: Colors.foreground
        weight: Font.DemiBold
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Label {
        text: Settings.wallpaper.wipeDeg + "°"
        color: Colors.foreground
        useMono: true
        horizontalAlignment: Text.AlignRight
      }
    }

    Label {
      text: "Choose from which direction the new wallpaper will appear."
      color: Colors.white
      Layout.fillWidth: true
      wrapMode: Text.WordWrap
      elide: Text.ElideRight
    }

    ClippingRectangle {
      id: previewBox
      Layout.fillWidth: true
      Layout.preferredHeight: 172
      color: Colors.surface
      border.color: previewMa.containsMouse || previewMa.pressed ? Colors.blue : Colors.border
      border.width: 1
      radius: Settings.rounding.md
      contentUnderBorder: true

      readonly property int deg: Settings.wallpaper.wipeDeg
      readonly property real rad: deg * Math.PI / 180
      readonly property real sn: Math.sin(rad)
      readonly property real cs: Math.cos(rad)
      readonly property real handleOrbit: Math.min(width, height) * 0.34
      readonly property real diag: Math.sqrt(width * width + height * height)

      Behavior on border.color { ColorAnimation { duration: 150 } }

      // Old wallpaper layer - full bleed
      Image {
        id: oldImg
        anchors.fill: parent
        source: Wallpapers.current ? "file://" + Wallpapers.current : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        mipmap: false
        autoTransform: false
        visible: status === Image.Ready
        opacity: 0.95
      }

      Rectangle {
        anchors.fill: parent
        color: Colors.card
        visible: oldImg.status !== Image.Ready
        Text {
          anchors.centerIn: parent
          text: "image"
          color: Colors.white
          opacity: 0.28
          font.family: Typography.icons.family
          font.pixelSize: 28
        }
      }

      Rectangle {
        anchors.fill: parent
        color: Colors.black
        opacity: 0.10
        visible: oldImg.status === Image.Ready
      }

      // New wallpaper layer - masked to half-plane (from wipe direction)
      Item {
        id: newLayer
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: wipePreviewMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.01
        }

        Image {
          id: newImg
          anchors.fill: parent
          source: {
            if (Wallpapers.all.length > 1) {
              for (let i = 0; i < Wallpapers.all.length; i++) {
                if (Wallpapers.all[i] !== Wallpapers.current) return "file://" + Wallpapers.all[i]
              }
            }
            return Wallpapers.current ? "file://" + Wallpapers.current : ""
          }
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: true
          smooth: true
          mipmap: false
          autoTransform: false
          visible: status === Image.Ready
        }

        Rectangle {
          anchors.fill: parent
          color: Colors.surface
          visible: newImg.status !== Image.Ready
          Text {
            anchors.centerIn: parent
            text: "image"
            color: Colors.blue
            opacity: 0.35
            font.family: Typography.icons.family
            font.pixelSize: 28
          }
        }

        // Blue tint to distinguish new side from current
        Rectangle {
          anchors.fill: parent
          color: Colors.blue
          opacity: newImg.status === Image.Ready ? 0.16 : 0.10
        }
      }

      // Invisible mask defining the new half-plane (rhs = 0, through center)
      Item {
        id: wipePreviewMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        readonly property real rad: previewBox.rad
        readonly property real sn: previewBox.sn
        readonly property real cs: previewBox.cs
        readonly property real r: Math.sqrt(width * width + height * height) / 2
        readonly property real cover: r * 3
        readonly property real p0x: width / 2
        readonly property real p0y: height / 2

        Rectangle {
          width: wipePreviewMask.cover
          height: wipePreviewMask.cover
          rotation: -previewBox.deg
          transformOrigin: Item.TopLeft
          x: wipePreviewMask.p0x - (wipePreviewMask.cover / 2) * wipePreviewMask.sn
          y: wipePreviewMask.p0y - (wipePreviewMask.cover / 2) * wipePreviewMask.cs
          color: "white"
        }
      }

      // Diagonal wipe boundary line
      Rectangle {
        id: diagLine
        width: previewBox.diag * 1.28
        height: 2
        color: Colors.blue
        anchors.centerIn: parent
        rotation: 90 - previewBox.deg
        Behavior on rotation {
          enabled: !previewMa.pressed
          NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
      }

      // Direction arrow centered, pointing in wipe direction
      Item {
        id: directionArrow
        width: 22
        height: 22
        anchors.centerIn: parent
        // offset slightly toward new side so arrow sits in new half
        // w = (cs, -sn)
        x: parent.width / 2 + previewBox.cs * 18 - width / 2
        y: parent.height / 2 - previewBox.sn * 18 - height / 2
        Behavior on x { enabled: !previewMa.pressed; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !previewMa.pressed; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
          anchors.centerIn: parent
          width: 22
          height: 22
          radius: Settings.rounding.sm
          color: Colors.background
          border.color: Colors.blue
          border.width: 1
          opacity: 0.96
          Text {
            anchors.centerIn: parent
            text: "arrow-right"
            color: Colors.blue
            font.family: Typography.icons.family
            font.pixelSize: 14
            rotation: 180 - previewBox.deg
            Behavior on rotation { enabled: !previewMa.pressed; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
          }
        }
      }

      // Handle on the diagonal line
      Rectangle {
        id: handle
        width: 14
        height: 14
        radius: Settings.rounding.sm
        color: previewMa.pressed ? Colors.blue : Colors.foreground
        border.color: previewMa.pressed ? Colors.foreground : Colors.blue
        border.width: 1
        x: previewBox.width / 2 + previewBox.sn * previewBox.handleOrbit - width / 2
        y: previewBox.height / 2 + previewBox.cs * previewBox.handleOrbit - height / 2
        Behavior on x { enabled: !previewMa.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !previewMa.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Rectangle {
          anchors.centerIn: parent
          width: 4
          height: 4
          radius: Settings.rounding.xs
          color: previewMa.pressed ? Colors.foreground : Colors.blue
          Behavior on color { ColorAnimation { duration: 120 } }
        }
      }

      // Side labels positioned offset along wipe normal with thick black stroke for legibility
      Item {
        id: oldLabelWrap
        width: oldLabelFront.implicitWidth + 4
        height: oldLabelFront.implicitHeight + 4
        x: previewBox.width / 2 - previewBox.cs * 52 - width / 2
        y: previewBox.height / 2 + previewBox.sn * 52 - height / 2
        Behavior on x { enabled: !previewMa.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !previewMa.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        // 8-way black stroke (~2px)
        Repeater {
          model: [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]
          delegate: Label {
            required property var modelData
            text: "CURRENT"
            color: Colors.black
            size: Typography.sizeXS
            weight: Font.Bold
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: modelData[0] * 1.1
            anchors.verticalCenterOffset: modelData[1] * 1.1
            opacity: 0.95
          }
        }
        Label {
          id: oldLabelFront
          text: "CURRENT"
          color: Colors.foreground
          size: Typography.sizeXS
          weight: Font.Bold
          opacity: 0.88
          anchors.centerIn: parent
        }
      }

      Item {
        id: newLabelWrap
        width: newLabelFront.implicitWidth + 4
        height: newLabelFront.implicitHeight + 4
        x: previewBox.width / 2 + previewBox.cs * 62 - width / 2
        y: previewBox.height / 2 - previewBox.sn * 62 - height / 2
        Behavior on x { enabled: !previewMa.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !previewMa.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Repeater {
          model: [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]
          delegate: Label {
            required property var modelData
            text: "NEW"
            color: Colors.black
            size: Typography.sizeXS
            weight: Font.Bold
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: modelData[0] * 1.1
            anchors.verticalCenterOffset: modelData[1] * 1.1
            opacity: 0.95
          }
        }
        Label {
          id: newLabelFront
          text: "NEW"
          color: Colors.blue
          size: Typography.sizeXS
          weight: Font.Bold
          opacity: 1
          anchors.centerIn: parent
        }
      }

      // Subtle preview wipe animation when angle settles
      // A thin highlight that sweeps once when deg changes while not dragging
      Rectangle {
        id: sweepHighlight
        width: previewBox.diag * 1.1
        height: previewBox.height
        color: Colors.blue
        opacity: 0
        rotation: 90 - previewBox.deg
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 0
      }

      SequentialAnimation {
        id: sweepAnim
        PropertyAction { target: sweepHighlight; property: "opacity"; value: 0 }
        NumberAnimation { target: sweepHighlight; property: "opacity"; to: 0.0; duration: 0 }
        // quick flash
        NumberAnimation { target: sweepHighlight; property: "opacity"; to: 0.08; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: sweepHighlight; property: "opacity"; to: 0.0; duration: 320; easing.type: Easing.OutCubic }
      }

      Connections {
        target: previewBox
        function onDegChanged() {
          if (!previewMa.pressed) sweepAnim.restart()
        }
      }

      MouseArea {
        id: previewMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        property real snapThreshold: 7
        readonly property var presets: [0, 45, 90, 135, 180, 225, 270, 315]

        function normDeg(d) {
          let n = d % 360
          return n < 0 ? n + 360 : n
        }

        function angleForPos(mx, my) {
          let cx = previewBox.width / 2
          let cy = previewBox.height / 2
          let dx = mx - cx
          let dy = my - cy
          if (dx === 0 && dy === 0) return previewBox.deg
          let handleAngle = Math.atan2(-dy, dx) * 180 / Math.PI
          if (handleAngle < 0) handleAngle += 360
          let raw = (handleAngle + 90) % 360
          return raw
        }

        function snappedDeg(raw) {
          let best = raw
          let bestDist = 360
          for (let i = 0; i < presets.length; i++) {
            let p = presets[i]
            let diff = Math.abs(raw - p)
            diff = Math.min(diff, 360 - diff)
            if (diff < bestDist) {
              bestDist = diff
              best = p
            }
          }
          if (bestDist < snapThreshold) return best
          return Math.round(raw) % 360
        }

        function updateFromPos(mx, my) {
          let raw = angleForPos(mx, my)
          let target = snappedDeg(raw)
          if (target === 360) target = 0
          Settings.wallpaper.wipeDeg = target
        }

        onPressed: mouse => updateFromPos(mouse.x, mouse.y)
        onPositionChanged: mouse => { if (pressed) updateFromPos(mouse.x, mouse.y) }
        onWheel: wheel => {
          let step = (wheel.modifiers & Qt.AltModifier) ? 1 : 5
          let cur = Settings.wallpaper.wipeDeg
          if (wheel.angleDelta.y > 0) Settings.wallpaper.wipeDeg = (cur + step) % 360
          else if (wheel.angleDelta.y < 0) Settings.wallpaper.wipeDeg = (cur - step + 360) % 360
        }
      }
    }


  }
}
