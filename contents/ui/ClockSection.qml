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

    // 9px padding on each side to match event list margins
    property real clockPadding: 18
    property real availableWidth: clockRoot.width - clockPadding

    // Measure natural text width at a reference size, then scale font to fill available width
    property real refFontSize: Kirigami.Units.gridUnit * 2.5

    TextMetrics {
        id: timeRefMetrics
        font.pixelSize: clockRoot.refFontSize
        text: clockRoot.use24HourClock
            ? Qt.formatTime(clockRoot.currentTime, "H:mm")
            : Qt.formatTime(clockRoot.currentTime, "h:mm AP")
    }

    // Font size that makes time text fill the available width
    property real timeFontSize: timeRefMetrics.advanceWidth > 0
        ? Math.max(refFontSize, refFontSize * availableWidth / timeRefMetrics.advanceWidth)
        : refFontSize

    // Date font: independently sized to fill the same available width
    property real dateRefFontSize: Kirigami.Units.gridUnit * 1.5

    TextMetrics {
        id: dateRefMetrics
        font.pixelSize: clockRoot.dateRefFontSize
        text: Qt.formatDate(clockRoot.currentTime, "ddd MMM d")
    }

    property real dateFontSize: dateRefMetrics.advanceWidth > 0
        ? Math.max(dateRefFontSize, dateRefFontSize * availableWidth / dateRefMetrics.advanceWidth)
        : dateRefFontSize

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

    // Time display: "9:53" + "AM" as separate labels so we can anchor tz letters to AM/PM
    Item {
        Layout.fillWidth: true
        implicitHeight: timeLabel.implicitHeight

        PlasmaComponents.Label {
            id: timeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -(ampmLabel.visible ? (ampmLabel.implicitWidth + (tzColumn.visible ? tzColumn.width + 1 : 0)) / 2 : 0)
            text: clockRoot.use24HourClock
                ? Qt.formatTime(clockRoot.currentTime, "H:mm")
                : Qt.formatTime(clockRoot.currentTime, "h:mm ")
            font.pixelSize: clockRoot.timeFontSize
            color: Kirigami.Theme.textColor
        }

        // AM/PM as its own label — only visible in 12h mode
        PlasmaComponents.Label {
            id: ampmLabel
            visible: !clockRoot.use24HourClock
            anchors.left: timeLabel.right
            anchors.baseline: timeLabel.baseline
            text: Qt.formatTime(clockRoot.currentTime, "AP")
            font.pixelSize: clockRoot.timeFontSize
            color: Kirigami.Theme.textColor
        }

        TextMetrics {
            id: ampmMetrics
            font.pixelSize: clockRoot.timeFontSize
            text: "AM"
        }

        // Timezone letters stacked vertically beside AM/PM
        Column {
            id: tzColumn
            visible: clockRoot.showTimezone && !clockRoot.use24HourClock && tzResolver.tzText.length > 0

            property real glyphHeight: ampmMetrics.tightBoundingRect.height
            property real glyphTop: (ampmLabel.height - glyphHeight) / 2
            property real letterHeight: glyphHeight / tzResolver.tzText.length

            anchors.left: ampmLabel.right
            anchors.leftMargin: 1
            y: ampmLabel.y + glyphTop

            Repeater {
                model: tzColumn.visible ? tzResolver.tzText.length : 0
                Text {
                    width: implicitWidth
                    height: tzColumn.letterHeight
                    text: tzResolver.tzText.charAt(index)
                    font.pixelSize: tzColumn.letterHeight * 1.1
                    font.weight: Font.Bold
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.disabledTextColor
                }
            }
        }

        // Timezone abbreviation resolver
        QtObject {
            id: tzResolver
            property string tzText: {
                var s = clockRoot.currentTime.toString()
                var match = s.match(/\(([A-Z]{2,5})\)/)
                if (match) return match[1]
                match = s.match(/\(([^)]+)\)/)
                if (match) {
                    var words = match[1].split(/\s+/)
                    var abbr = ""
                    for (var i = 0; i < words.length; i++)
                        abbr += words[i].charAt(0).toUpperCase()
                    if (abbr.length >= 2) return abbr
                }
                var offset = -clockRoot.currentTime.getTimezoneOffset()
                var offsetMap = {
                    "-600": "HST", "-540": "AKST", "-480": "PST", "-420": "MST",
                    "-360": "CST", "-300": "EST", "-240": "AST",
                    "-540d": "AKDT", "-420d": "PDT", "-360d": "MDT",
                    "-300d": "CDT", "-240d": "EDT",
                    "0": "GMT", "60": "CET", "120": "EET", "180": "MSK",
                    "330": "IST", "480": "CST", "540": "JST", "600": "AEST"
                }
                var jan = new Date(clockRoot.currentTime.getFullYear(), 0, 1)
                var isDST = clockRoot.currentTime.getTimezoneOffset() < jan.getTimezoneOffset()
                var key = isDST ? (offset.toString() + "d") : offset.toString()
                if (offsetMap[key]) return offsetMap[key]
                if (offsetMap[offset.toString()]) return offsetMap[offset.toString()]
                var h = Math.floor(Math.abs(offset) / 60)
                return "UTC" + (offset >= 0 ? "+" : "-") + h
            }
        }
    }

    PlasmaComponents.Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -Kirigami.Units.smallSpacing
        text: Qt.formatDate(clockRoot.currentTime, "ddd MMM d")
        font.pixelSize: clockRoot.dateFontSize
        color: Kirigami.Theme.textColor
    }
}
