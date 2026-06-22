
import Quickshell
import QtQuick

Text {
  text: Qt.formatDateTime(clock.date, "hh:mm")
  color: '#c8d3f5'
  font {
    family: "SF Pro Text"
    pixelSize: 13
    weight: 600
  }

  SystemClock { 
    id: clock
    precision: SystemClock.Minutes
  }
}
