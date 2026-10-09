import "../.."
import Quickshell.Widgets
import QtQuick

Item {
  id: root

  required property string modelData
  required property bool isCurrent

  property string fileName: {
    let p = modelData
    let i = p.lastIndexOf("/")
    return i >= 0 ? p.slice(i + 1) : p
  }

  // Size is driven by the picker (delegate width); thumb fills it.
  // Keep implicitWidth out of the chain — width is set externally by the
  // PathView delegate, and deriving it from thumb would close a binding loop.
  implicitHeight:
    thumb.height +
    label.implicitHeight +
    8

  height: implicitHeight

  // Entrance state, same as caelestia: delegate starts small/invisible and
  // the Behaviors below animate it to its resting values once bound.
  // scale/opacity are transforms — they never affect the Row's layout.
  opacity: 0
  z: root.isCurrent ? 1 : 0

  // Middle (isCurrent) is the one that gets set on Enter
  scale: 0.85

  Component.onCompleted: {
    scale = Qt.binding(() => root.isCurrent ? 1.07 : 0.90)
    opacity = Qt.binding(() => root.isCurrent ? 1 : 0.78)
  }

  Behavior on scale {
    NumberAnimation {
      duration: 180
      easing.type: Easing.OutCubic
    }
  }

  Behavior on opacity {
    NumberAnimation {
      duration: 160
      easing.type: Easing.OutCubic
    }
  }

  ClippingRectangle {
    id: thumb

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    width: root.width
    height: root.width / 16 * 9

    radius: Settings.rounding.md

    color: Colors.surface
    contentUnderBorder: true

    border.color:
      root.isCurrent
        ? Colors.border
        : "transparent"

    border.width:
      root.isCurrent ? 2 : 0

    Text {
      anchors.centerIn: parent

      text: "image"

      color: Colors.white
      opacity: 0.25

      font.family: Typography.icons.family
      font.pixelSize: 28

      visible:
        thumbImage.status !== Image.Ready
    }

    Image {
      id: thumbImage

      anchors.fill: parent

      source:
        root.modelData &&
        root.modelData.length > 1
          ? "file://" + root.modelData
          : ""

      fillMode: Image.PreserveAspectCrop
      sourceSize.width: 400
      sourceSize.height: 225

      asynchronous: true
      cache: true
      smooth: true
      mipmap: false
      autoTransform: false
      retainWhileLoading: true

      // Caelestia-style fade-in: thumb stays hidden until the image is
      // actually decoded, then crossfades over the placeholder icon.
      opacity: status === Image.Ready ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: 220
          easing.type: Easing.OutCubic
        }
      }

      onStatusChanged: {
        if (status === Image.Error) {
          console.log(
            "WallpaperItem failed:",
            root.modelData,
            "->",
            source
          )
        }
      }
    }
  }

  Label {
    id: label

    anchors.top: thumb.bottom
    anchors.topMargin: 4

    anchors.horizontalCenter: parent.horizontalCenter

    width: thumb.width - 8

    horizontalAlignment: Text.AlignHCenter

    elide: Text.ElideMiddle
    maximumLineCount: 1

    text: root.fileName

    color:
      root.isCurrent
        ? Colors.foreground
        : Colors.white

    size: Typography.sizeSM

    opacity:
      root.isCurrent
        ? 1
        : 0.8
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  signal clicked()
}
