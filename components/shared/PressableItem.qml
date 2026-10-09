import QtQuick

Item {
  id: root
  property bool pressed: false
  property bool dimOnPress: true

  transformOrigin: Item.Center
  scale: pressed ? 0.96 : 1
  opacity: dimOnPress && pressed ? 0.92 : 1

  Behavior on scale { SpringAnimation { spring: 3.5; damping: 0.22 } }
  Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
}
