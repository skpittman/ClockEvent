import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import "fetcher.js" as Fetcher

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    compactRepresentation: null

    implicitWidth: Kirigami.Units.gridUnit * 18
    implicitHeight: Kirigami.Units.gridUnit * 24

    // Event data model
    ListModel {
        id: eventModel
    }



    // Month names for section headers
    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    // Refresh events from all configured calendars
    function refreshEvents() {
        var sourcesJson = Plasmoid.configuration.calendarSources || "[]"
        var daysAhead = Plasmoid.configuration.daysAhead || 30

        Fetcher.fetchAllCalendars(sourcesJson, daysAhead, function(events) {
            eventModel.clear()

            // Check if today has any events
            var now = new Date()
            var todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
            var todayEnd = new Date(todayStart.getTime() + 86400000)
            var todaySection = monthNames[now.getMonth()] + " " + now.getFullYear()
            var hasTodayEvent = false
            for (var i = 0; i < events.length; i++) {
                var t = events[i].startTime.getTime()
                if (t >= todayStart.getTime() && t < todayEnd.getTime()) {
                    hasTodayEvent = true
                    break
                }
            }

            // Insert a placeholder for today if no events exist
            if (!hasTodayEvent) {
                eventModel.append({
                    summary: "Nothing scheduled",
                    startTime: todayStart.getTime(),
                    endTime: todayEnd.getTime(),
                    allDay: true,
                    uid: "__today_placeholder__",
                    description: "",
                    location: "",
                    calendarLabel: "",
                    calendarColor: "transparent",
                    monthSection: todaySection
                })
            }

            for (var i = 0; i < events.length; i++) {
                var ev = events[i]
                var startDate = ev.startTime
                var monthSection = monthNames[startDate.getMonth()] + " " + startDate.getFullYear()
                eventModel.append({
                    summary: ev.summary,
                    startTime: startDate.getTime(),
                    endTime: ev.endTime.getTime(),
                    allDay: ev.allDay,
                    uid: ev.uid,
                    description: ev.description,
                    location: ev.location,
                    calendarLabel: ev.calendarLabel,
                    calendarColor: ev.calendarColor || "#1d99f3",
                    monthSection: monthSection
                })
            }
        })
    }

    // Refresh on startup
    Component.onCompleted: refreshEvents()

    // Refresh when calendar sources change
    Connections {
        target: Plasmoid.configuration
        function onCalendarSourcesChanged() { root.refreshEvents() }
        function onDaysAheadChanged() { root.refreshEvents() }
    }

    // Periodic refresh timer
    Timer {
        interval: (Plasmoid.configuration.refreshIntervalMinutes || 15) * 60000
        running: true
        repeat: true
        onTriggered: root.refreshEvents()
    }

    // Open event in Google Calendar
    function openEvent(uid, startTime) {
        var d = new Date(startTime)
        var yyyy = d.getFullYear()
        var mm = (d.getMonth() + 1).toString().padStart(2, '0')
        var dd = d.getDate().toString().padStart(2, '0')
        var url = "https://calendar.google.com/calendar/r/day/" + yyyy + "/" + mm + "/" + dd
        Qt.openUrlExternally(url)
    }

    // Open new event page
    function openNewEvent() {
        Qt.openUrlExternally("https://calendar.google.com/calendar/r/eventedit")
    }

    fullRepresentation: Item {
        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            ClockSection {
                id: clockSection
                Layout.fillWidth: true
                use24HourClock: Plasmoid.configuration.use24HourClock
                showTimezone: Plasmoid.configuration.showTimezone
            }

            // Toolbar row
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: eventList.currentSection
                    font.pixelSize: Kirigami.Units.gridUnit * 1.2
                    font.weight: Font.Bold
                    color: Kirigami.Theme.textColor
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.ToolButton {
                    icon.name: "list-add"
                    icon.width: Kirigami.Units.iconSizes.small
                    icon.height: Kirigami.Units.iconSizes.small
                    onClicked: root.openNewEvent()
                    PlasmaComponents.ToolTip { text: i18n("Add event") }
                }

                PlasmaComponents.ToolButton {
                    icon.name: "configure"
                    icon.width: Kirigami.Units.iconSizes.small
                    icon.height: Kirigami.Units.iconSizes.small
                    onClicked: Plasmoid.internalAction("configure").trigger()
                    PlasmaComponents.ToolTip { text: i18n("Configure") }
                }
            }

            EventList {
                id: eventList
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceModel: eventModel
                use24HourClock: Plasmoid.configuration.use24HourClock
                onEventClicked: function(uid, startTime) {
                    root.openEvent(uid, startTime)
                }
            }
        }
    }
}
