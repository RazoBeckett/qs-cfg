import Quickshell
import QtQuick

Text {
  text: Qt.formatDateTime(clock.date, "hh:mm")
  color: '#c8d3f5'
  font: Config.font

  SystemClock { 
    id: clock
    precision: SystemClock.Minutes
  }
}
