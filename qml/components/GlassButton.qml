import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root

    property string text: ""
    property string iconName: ""        // optional SVG icon name from /assets/icons/
    property bool primary: false
    property bool danger: false
    property bool outlined: false
    property int fontSize: Theme.fontSizeBody

    signal clicked()

    implicitWidth: Math.max(Theme.dp(110), contentRow.implicitWidth + Theme.dp(40))
    implicitHeight: Theme.dp(44)
    opacity: enabled ? 1.0 : 0.38

    readonly property color baseColor:
        root.danger   ? Theme.danger  :
        root.primary  ? Theme.primary :
                        Theme.accent

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: root.outlined
               ? "transparent"
               : root.primary
                 ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, hover.hovered ? 1.0 : 0.92)
                 : root.danger
                   ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, hover.hovered ? 0.22 : 0.14)
                   : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, hover.hovered ? 0.22 : 0.14)
        border.width: root.outlined || root.danger ? 1.5 : 0
        border.color: root.baseColor
        scale: tap.pressed ? 0.95 : 1.0

        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // shimmer line on primary buttons
    Rectangle {
        visible: root.primary && !root.outlined
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.dp(12)
        anchors.rightMargin: Theme.dp(12)
        height: 1
        radius: 1
        color: Qt.rgba(1, 1, 1, 0.28)
    }

    // content row: optional icon + label
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.dp(7)

        Icon {
            visible: root.iconName.length > 0
            name: root.iconName
            size: Theme.dp(16)
            anchors.verticalCenter: parent.verticalCenter
            color: root.outlined
                   ? root.baseColor
                   : root.primary
                     ? "#0B1120"
                     : root.danger
                       ? Theme.danger
                       : Theme.textPrimary
        }

        Label {
            id: label
            visible: root.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: root.fontSize
            font.bold: true
            font.family: Theme.fontFamily
            font.letterSpacing: 1.1
            color: root.outlined
                   ? root.baseColor
                   : root.primary
                     ? "#0B1120"
                     : root.danger
                       ? Theme.danger
                       : Theme.textPrimary
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
