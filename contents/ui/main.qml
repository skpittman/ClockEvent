import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    compactRepresentation: null

    implicitWidth: Kirigami.Units.gridUnit * 18
    implicitHeight: Kirigami.Units.gridUnit * 24

    fullRepresentation: Rectangle {
        color: Kirigami.Theme.backgroundColor
        radius: Kirigami.Units.cornerRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            ClockSection {
                Layout.fillWidth: true
                use24HourClock: Plasmoid.configuration.use24HourClock
            }

            // Event list will go here in Phase 3
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                PlasmaComponents.Label {
                    anchors.centerIn: parent
                    text: i18n("No events configured")
                    opacity: 0.5
                }
            }
        }
    }
}
