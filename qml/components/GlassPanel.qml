import QtQuick
import QtQuick.Effects
import "../theme"

Rectangle {
    id: panel

    implicitHeight: container.height + padding * 2

    default property alias contentData: container.data
    property real padding: Theme.dp(20)
    property color fillColor: Theme.glassFill
    property real fillOpacity: Theme.glassFillOpacity
    property bool glowEnabled: false

    radius: Theme.radiusLarge
    color: Qt.rgba(fillColor.r, fillColor.g, fillColor.b, fillOpacity)
    border.width: 1
    border.color: Qt.rgba(Theme.glassBorder.r, Theme.glassBorder.g,
                          Theme.glassBorder.b, Theme.glassBorderOpacity)

    // subtle top-edge highlight
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        height: 1
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
    }

    // glow strip (optional)
    Rectangle {
        visible: panel.glowEnabled
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Theme.dp(3)
        radius: panel.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Theme.primary }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Item {
        id: container
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: panel.padding
        height: childrenRect.height
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.8
        shadowVerticalOffset: Theme.dp(8)
        shadowHorizontalOffset: 0
    }
}
