import QtQuick
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

ListView {
    id: listRoot

    property alias sourceModel: listRoot.model

    property bool use24HourClock: false

    signal eventClicked(string uid, real startTime)

    clip: true
    spacing: Kirigami.Units.smallSpacing

    // Scrollbar hidden for now — infrastructure kept for later
    QQC2.ScrollBar.vertical: QQC2.ScrollBar { width: 0; policy: QQC2.ScrollBar.AlwaysOff }

    // Section by month/year string
    section.property: "monthSection"
    section.delegate: MonthHeader {
        width: listRoot.width
        monthName: section
    }

    delegate: EventRow {
        width: listRoot.width
        summary: model.summary
        startTime: model.startTime
        endTime: model.endTime
        allDay: model.allDay
        uid: model.uid
        use24HourClock: listRoot.use24HourClock
        calendarColor: model.calendarColor
        showDateBadge: {
            // Show badge only for the first event on a given date
            if (model.index === 0) return true
            var prev = listRoot.model.get(model.index - 1)
            if (!prev) return true
            var thisDate = new Date(model.startTime)
            var prevDate = new Date(prev.startTime)
            return thisDate.getFullYear() !== prevDate.getFullYear()
                || thisDate.getMonth() !== prevDate.getMonth()
                || thisDate.getDate() !== prevDate.getDate()
        }
        onEventClicked: function(uid, startTime) {
            listRoot.eventClicked(uid, startTime)
        }
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        visible: listRoot.count === 0
        text: i18n("No events configured")
        opacity: 0.5
    }
}
