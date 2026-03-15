import QtQuick
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {

    property string cfg_calendarSources: ""
    property string cfg_calendarSourcesDefault: ""
    property bool cfg_use24HourClock
    property bool cfg_use24HourClockDefault
    property int cfg_daysAhead
    property int cfg_daysAheadDefault
    property int cfg_refreshIntervalMinutes
    property int cfg_refreshIntervalMinutesDefault
    property bool cfg_showTimezone
    property bool cfg_showTimezoneDefault
    property double cfg_windowOpacity
    property double cfg_windowOpacityDefault

    // Default colors for new calendars (cycle through these)
    readonly property var defaultColors: [
        "#1d99f3", "#9b59b6", "#1abc9c", "#f39c12",
        "#e74c3c", "#2ecc71", "#3498db", "#e67e22"
    ]

    ListModel {
        id: sourcesModel
    }

    QtDialogs.ColorDialog {
        id: colorDialog
        property int editIndex: -1
        title: i18n("Choose Calendar Color")
        onAccepted: {
            if (editIndex >= 0) {
                sourcesModel.setProperty(editIndex, "color", selectedColor.toString())
                saveSources()
            }
        }
    }

    Component.onCompleted: loadSources()

    function loadSources() {
        sourcesModel.clear()
        try {
            var sources = JSON.parse(cfg_calendarSources)
            if (Array.isArray(sources)) {
                for (var i = 0; i < sources.length; i++) {
                    // Migrate old entries that lack a color
                    if (!sources[i].color) {
                        sources[i].color = defaultColors[i % defaultColors.length]
                    }
                    sourcesModel.append(sources[i])
                }
            }
        } catch (e) {}
    }

    function saveSources() {
        var arr = []
        for (var i = 0; i < sourcesModel.count; i++) {
            var item = sourcesModel.get(i)
            arr.push({ label: item.label, url: item.url, enabled: item.enabled, color: item.color })
        }
        cfg_calendarSources = JSON.stringify(arr)
    }

    Kirigami.FormLayout {

        ColumnLayout {
            Kirigami.FormData.label: i18n("Calendar Sources:")
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                id: sourceRepeater
                model: sourcesModel

                delegate: RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true

                    QQC2.CheckBox {
                        checked: model.enabled
                        onToggled: {
                            sourcesModel.setProperty(index, "enabled", checked)
                            saveSources()
                        }
                    }

                    // Color picker button
                    QQC2.ToolButton {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        contentItem: Rectangle {
                            radius: Kirigami.Units.cornerRadius
                            color: model.color || "#1d99f3"
                            border.color: Kirigami.Theme.textColor
                            border.width: 1
                        }
                        onClicked: {
                            colorDialog.editIndex = index
                            colorDialog.selectedColor = model.color || "#1d99f3"
                            colorDialog.open()
                        }
                        QQC2.ToolTip { text: i18n("Choose color") }
                    }

                    QQC2.TextField {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                        text: model.label
                        placeholderText: i18n("Label")
                        onEditingFinished: {
                            sourcesModel.setProperty(index, "label", text)
                            saveSources()
                        }
                    }

                    QQC2.TextField {
                        Layout.fillWidth: true
                        text: model.url
                        placeholderText: i18n("iCal URL (.ics)")
                        onEditingFinished: {
                            sourcesModel.setProperty(index, "url", text)
                            saveSources()
                        }
                    }

                    QQC2.ToolButton {
                        icon.name: "edit-delete"
                        onClicked: {
                            sourcesModel.remove(index)
                            saveSources()
                        }
                    }
                }
            }

            QQC2.Button {
                text: i18n("Add Calendar")
                icon.name: "list-add"
                onClicked: {
                    var nextColor = defaultColors[sourcesModel.count % defaultColors.length]
                    sourcesModel.append({ label: "", url: "", enabled: true, color: nextColor })
                    saveSources()
                }
            }
        }
    }
}
