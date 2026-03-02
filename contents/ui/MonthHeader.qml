import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami

RowLayout {
    id: headerRoot

    property string monthName: ""

    spacing: Kirigami.Units.smallSpacing

    PlasmaComponents.Label {
        text: headerRoot.monthName
        font.pixelSize: Kirigami.Units.gridUnit * 1.2
        font.weight: Font.Bold
        color: Kirigami.Theme.textColor
        Layout.fillWidth: true
    }
}
