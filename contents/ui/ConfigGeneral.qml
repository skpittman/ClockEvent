import QtQuick
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {

    property alias cfg_refreshIntervalMinutes: refreshSpinBox.value
    property int cfg_refreshIntervalMinutesDefault
    property string cfg_calendarSources
    property string cfg_calendarSourcesDefault
    property bool cfg_use24HourClock
    property bool cfg_use24HourClockDefault
    property int cfg_daysAhead
    property int cfg_daysAheadDefault
    property bool cfg_showTimezone
    property bool cfg_showTimezoneDefault
    property double cfg_windowOpacity
    property double cfg_windowOpacityDefault

    Kirigami.FormLayout {

        QQC2.SpinBox {
            id: refreshSpinBox
            Kirigami.FormData.label: i18n("Refresh interval (minutes):")
            from: 5
            to: 120
            value: 15
            stepSize: 5
        }
    }
}
