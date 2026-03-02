import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

MouseArea {
    id: eventRoot

    property string summary: ""
    property real startTime: 0
    property real endTime: 0
    property bool allDay: false
    property string uid: ""
    property bool showDateBadge: true
    property bool use24HourClock: false
    property color calendarColor: "#1d99f3"
    property bool placeholder: uid === "__today_placeholder__"

    signal eventClicked(string uid, real startTime)

    implicitHeight: rowLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
    cursorShape: placeholder ? Qt.ArrowCursor : Qt.PointingHandCursor

    onClicked: if (!placeholder) eventRoot.eventClicked(eventRoot.uid, eventRoot.startTime)

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: Kirigami.Units.mediumSpacing

        // Date badge (left side)
        Item {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            Layout.fillHeight: true
            visible: eventRoot.showDateBadge

            property bool isToday: {
                var d = new Date(eventRoot.startTime)
                var now = new Date()
                return d.getFullYear() === now.getFullYear()
                    && d.getMonth() === now.getMonth()
                    && d.getDate() === now.getDate()
            }

            // Today highlight pill
            Rectangle {
                anchors.centerIn: parent
                width: Kirigami.Units.gridUnit * 2.6
                height: Kirigami.Units.gridUnit * 3.2
                radius: Kirigami.Units.cornerRadius * 2
                color: parent.isToday ? Kirigami.Theme.highlightColor : "transparent"
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (!eventRoot.showDateBadge) return ""
                        var d = new Date(eventRoot.startTime)
                        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                        return days[d.getDay()]
                    }
                    font.pixelSize: Kirigami.Units.gridUnit * 0.75
                    color: parent.parent.isToday ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.disabledTextColor
                }

                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (!eventRoot.showDateBadge) return ""
                        var d = new Date(eventRoot.startTime)
                        return d.getDate().toString()
                    }
                    font.pixelSize: Kirigami.Units.gridUnit * 1.2
                    font.weight: Font.Bold
                    color: parent.parent.isToday ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                }
            }
        }

        // Spacer when badge is hidden (keep alignment)
        Item {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            visible: !eventRoot.showDateBadge
        }

        // Event block (right side)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: eventContent.implicitHeight + Kirigami.Units.mediumSpacing * 2
            radius: Kirigami.Units.cornerRadius * 2
            color: eventRoot.placeholder
                   ? Qt.rgba(Kirigami.Theme.textColor.r,
                             Kirigami.Theme.textColor.g,
                             Kirigami.Theme.textColor.b, 0.08)
                   : Qt.rgba(eventRoot.calendarColor.r,
                             eventRoot.calendarColor.g,
                             eventRoot.calendarColor.b, 0.35)

            ColumnLayout {
                id: eventContent
                anchors.fill: parent
                anchors.margins: Kirigami.Units.mediumSpacing
                spacing: Kirigami.Units.smallSpacing / 2

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: eventRoot.summary
                    font.weight: Font.Bold
                    font.pixelSize: Kirigami.Units.gridUnit * 0.85
                    color: eventRoot.placeholder ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: {
                        if (eventRoot.placeholder) return " "
                        if (eventRoot.allDay) return i18n("All day")
                        var s = new Date(eventRoot.startTime)
                        var e = new Date(eventRoot.endTime)
                        return formatTime(s) + " \u2013 " + formatTime(e)
                    }
                    font.pixelSize: Kirigami.Units.gridUnit * 0.75
                    color: Kirigami.Theme.disabledTextColor
                    elide: Text.ElideRight
                }
            }
        }
    }

    function formatTime(date) {
        if (eventRoot.use24HourClock) {
            return Qt.formatTime(date, "H:mm")
        } else {
            return Qt.formatTime(date, "h:mm AP")
        }
    }
}
