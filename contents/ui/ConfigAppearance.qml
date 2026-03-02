import QtQuick
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {

    property alias cfg_use24HourClock: use24HourCheckBox.checked
    property bool cfg_use24HourClockDefault
    property alias cfg_daysAhead: daysAheadSpinBox.value
    property int cfg_daysAheadDefault
    property alias cfg_showTimezone: showTimezoneCheckBox.checked
    property bool cfg_showTimezoneDefault
    property alias cfg_windowOpacity: opacitySlider.value
    property double cfg_windowOpacityDefault
    property string cfg_calendarSources
    property string cfg_calendarSourcesDefault
    property int cfg_refreshIntervalMinutes
    property int cfg_refreshIntervalMinutesDefault

    Kirigami.FormLayout {

        QQC2.CheckBox {
            id: use24HourCheckBox
            Kirigami.FormData.label: i18n("Clock format:")
            text: i18n("Use 24-hour clock")
        }

        QQC2.CheckBox {
            id: showTimezoneCheckBox
            text: i18n("Show time zone")
        }

        QQC2.SpinBox {
            id: daysAheadSpinBox
            Kirigami.FormData.label: i18n("Days ahead:")
            from: 1
            to: 365
            value: 30
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Window opacity:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: opacitySlider
                from: 0.2
                to: 1.0
                live: true
                value: cfg_windowOpacity
                Layout.fillWidth: true
            }

            QQC2.Label {
                text: Math.round(opacitySlider.value * 100) + "%"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
            }
        }
    }
}
