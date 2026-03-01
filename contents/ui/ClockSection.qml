import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    id: clockRoot

    property bool use24HourClock: false

    spacing: Kirigami.Units.smallSpacing

    property date currentTime: new Date()

    Timer {
        id: clockTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockRoot.currentTime = new Date()
    }

    // Sync timer to the start of the next minute
    Timer {
        id: syncTimer
        interval: {
            var now = new Date()
            return (60 - now.getSeconds()) * 1000
        }
        running: true
        repeat: false
        onTriggered: {
            clockRoot.currentTime = new Date()
            clockTimer.restart()
        }
    }

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignHCenter
        text: {
            if (clockRoot.use24HourClock) {
                return Qt.formatTime(clockRoot.currentTime, "H:mm")
            } else {
                return Qt.formatTime(clockRoot.currentTime, "h:mm AP")
            }
        }
        font.pixelSize: Kirigami.Units.gridUnit * 2.5
        font.weight: Font.Bold
        color: Kirigami.Theme.textColor
    }

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDate(clockRoot.currentTime, "ddd MMM d")
        font.pixelSize: Kirigami.Units.gridUnit * 1.0
        color: Kirigami.Theme.disabledTextColor
    }
}
