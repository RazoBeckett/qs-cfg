import ".."
import Quickshell
import QtQuick

Text {
  text: Qt.formatDateTime(clock.date, "hh:mm")
  color: Colors.foreground
  font: Config.font

  SystemClock { 
    id: clock
    precision: SystemClock.Minutes
  }
}
