import QtQuick
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: eventListRoot

    property alias sourceModel: listView.model
    property bool use24HourClock: false
    property string currentSection: ""

    function updateSection() {
        if (listView.count === 0) { currentSection = ""; return }
        var idx = listView.indexAt(listView.contentX, listView.contentY + 1)
        if (idx < 0) return
        var item = listView.model.get(idx)
        if (item) currentSection = item.monthSection
    }
    Connections {
        target: listView
        function onContentYChanged() { eventListRoot.updateSection() }
        function onCountChanged() { eventListRoot.updateSection() }
    }
    Component.onCompleted: updateSection()

    signal eventClicked(string uid, real startTime)

    ListView {
        id: listView

        // Leave 4px extra on the right so total right gap = 9px (existing 5px + 4px)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 4

        clip: true
        spacing: Kirigami.Units.smallSpacing
        boundsBehavior: Flickable.StopAtBounds

        // Disable the built-in scrollbar; we use our own
        QQC2.ScrollBar.vertical: QQC2.ScrollBar { width: 0; policy: QQC2.ScrollBar.AlwaysOff }

        section.property: "monthSection"

        delegate: EventRow {
            width: listView.width
            summary: model.summary
            startTime: model.startTime
            endTime: model.endTime
            allDay: model.allDay
            uid: model.uid
            use24HourClock: eventListRoot.use24HourClock
            calendarColor: model.calendarColor
            showDateBadge: {
                if (model.index === 0) return true
                var prev = listView.model.get(model.index - 1)
                if (!prev) return true
                var thisDate = new Date(model.startTime)
                var prevDate = new Date(prev.startTime)
                return thisDate.getFullYear() !== prevDate.getFullYear()
                    || thisDate.getMonth() !== prevDate.getMonth()
                    || thisDate.getDate() !== prevDate.getDate()
            }
            onEventClicked: function(uid, startTime) {
                eventListRoot.eventClicked(uid, startTime)
            }
        }

        PlasmaComponents.Label {
            anchors.centerIn: parent
            visible: listView.count === 0
            text: i18n("No events configured")
            opacity: 0.5
        }
    }

    // Scrollbar centered in the right gap: 1px + 7px bar + 1px
    QQC2.ScrollBar {
        id: scrollBar
        anchors.top: listView.top
        anchors.bottom: listView.bottom
        // 1px gap from event box edge
        anchors.left: listView.right
        anchors.leftMargin: 2
        width: 6
        orientation: Qt.Vertical
        policy: listView.contentHeight > listView.height ? QQC2.ScrollBar.AlwaysOn : QQC2.ScrollBar.AlwaysOff

        background: Item {}
        contentItem: Rectangle {
            implicitWidth: 6
            radius: 3
            color: scrollBar.pressed ? Qt.rgba(1, 1, 1, 0.5)
                 : scrollBar.hovered ? Qt.rgba(1, 1, 1, 0.35)
                 : Qt.rgba(1, 1, 1, 0.2)
        }
        size: listView.visibleArea.heightRatio

        Binding on position {
            value: listView.visibleArea.yPosition
            when: !scrollBar.active
            restoreMode: Binding.RestoreNone
        }

        onPositionChanged: {
            if (active) {
                listView.contentY = position * listView.contentHeight
            }
        }
    }
}
