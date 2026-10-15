import QtQuick
import QtQuick.Effects
import "../theme"

// Usage:
//   Icon { name: "trash";  size: Theme.dp(20); color: Theme.danger }
//   Icon { name: "lock";   size: Theme.dp(18) }          // defaults to white
Item {
    id: root

    property string name: ""
    property real   size: Theme.dp(20)
    property color  color: "white"
    property real   opacity_: 1.0   // renamed to avoid clash with Item.opacity

    implicitWidth:  size
    implicitHeight: size
    opacity: opacity_

    Image {
        id: img
        anchors.fill: parent
        source: root.name.length > 0 ? "qrc:/icons/assets/icons/" + root.name + ".svg" : ""
        sourceSize.width:  root.size * 2   // 2x for HiDPI sharpness
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
        visible: false          // hidden; shown through ColorOverlay below
    }

    // Tint the white SVG strokes to the requested color
    MultiEffect {
        anchors.fill: img
        source: img
        colorization: 1.0
        colorizationColor: root.color
        visible: root.name.length > 0
    }
}
