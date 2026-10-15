import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property int value: 1
    property int minimum: 1
    property int maximum: 999999

    signal valueModified(int newValue)

    implicitWidth: Theme.dp(220)
    implicitHeight: Theme.dp(48)

    function setValue(v) { root.value = Math.max(minimum, Math.min(maximum, v)) }

    RowLayout {
        anchors.fill: parent
        spacing: Theme.dp(8)

        // minus
        Rectangle {
            Layout.preferredWidth: Theme.dp(48)
            Layout.fillHeight: true
            radius: Theme.radiusMedium
            color: minusTap.pressed
                   ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.40)
                   : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.14)
            border.width: 1
            border.color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, minusHover.hovered ? 0.60 : 0.28)
            Behavior on color       { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Icon { anchors.centerIn: parent; name: "minus"; size: Theme.dp(16); color: Theme.danger }
            HoverHandler { id: minusHover; cursorShape: Qt.PointingHandCursor }
            TapHandler   { id: minusTap;  onTapped: { root.setValue(root.value - 1); root.valueModified(root.value) } }
        }

        // value display
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radiusMedium
            color: Qt.rgba(1, 1, 1, 0.04)
            border.width: 1
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)

            Label {
                anchors.centerIn: parent
                text: root.value
                color: Theme.primary
                font.pixelSize: Theme.fontSizeHeader
                font.bold: true
                font.family: Theme.fontFamily
            }
        }

        // plus
        Rectangle {
            Layout.preferredWidth: Theme.dp(48)
            Layout.fillHeight: true
            radius: Theme.radiusMedium
            color: plusTap.pressed
                   ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.40)
                   : Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.14)
            border.width: 1
            border.color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, plusHover.hovered ? 0.60 : 0.28)
            Behavior on color       { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Icon { anchors.centerIn: parent; name: "plus"; size: Theme.dp(16); color: Theme.success }
            HoverHandler { id: plusHover; cursorShape: Qt.PointingHandCursor }
            TapHandler   { id: plusTap;  onTapped: { root.setValue(root.value + 1); root.valueModified(root.value) } }
        }
    }
}
