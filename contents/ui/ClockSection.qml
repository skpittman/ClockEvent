import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

ColumnLayout {
    id: clockRoot

    property bool use24HourClock: false
    property bool showTimezone: false

    spacing: 0

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

    // Time display with optional vertical timezone
    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: timeLabel.implicitWidth + (tzColumn.visible ? tzColumn.width + 1 : 0)
        implicitHeight: timeLabel.implicitHeight

        PlasmaComponents.Label {
            id: timeLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
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

        // Vertical timezone letters beside AM/PM, spread to fill clock height
        Column {
            id: tzColumn
            visible: clockRoot.showTimezone && !clockRoot.use24HourClock
            anchors.left: timeLabel.right
            anchors.leftMargin: 1
            anchors.top: timeLabel.top
            anchors.bottom: timeLabel.bottom
            width: Kirigami.Units.gridUnit * 0.8

            property string tzText: {
                var s = clockRoot.currentTime.toString()
                // Try short abbreviation in parens: "(EST)"
                var match = s.match(/\(([A-Z]{2,5})\)/)
                if (match) return match[1]
                // Try long name in parens: "(Eastern Standard Time)" -> initials "EST"
                match = s.match(/\(([^)]+)\)/)
                if (match) {
                    var words = match[1].split(/\s+/)
                    var abbr = ""
                    for (var i = 0; i < words.length; i++)
                        abbr += words[i].charAt(0).toUpperCase()
                    return abbr
                }
                // Fallback: just "GMT"
                return "GMT"
            }
            property real letterSize: Kirigami.Units.gridUnit * 0.7

            Repeater {
                model: tzColumn.tzText.length
                PlasmaComponents.Label {
                    required property int index
                    width: tzColumn.width
                    text: tzColumn.tzText.charAt(index)
                    font.pixelSize: tzColumn.letterSize
                    font.weight: Font.Normal
                    color: Kirigami.Theme.disabledTextColor
                    horizontalAlignment: Text.AlignHCenter
                    // Spread evenly across the full height
                    y: tzColumn.height > 0
                       ? index * (tzColumn.height - tzColumn.letterSize) / Math.max(1, tzColumn.tzText.length - 1)
                       : 0
                }
            }
        }
    }

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -Kirigami.Units.smallSpacing
        text: Qt.formatDate(clockRoot.currentTime, "ddd MMM d")
        font.pixelSize: Kirigami.Units.gridUnit * 1.5
        color: Kirigami.Theme.disabledTextColor
    }
}
