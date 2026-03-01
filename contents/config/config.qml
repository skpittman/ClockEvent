import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Calendars")
        icon: "view-calendar"
        source: "ConfigCalendars.qml"
    }
    ConfigCategory {
        name: i18n("Appearance")
        icon: "preferences-desktop-color"
        source: "ConfigAppearance.qml"
    }
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "ConfigGeneral.qml"
    }
}
