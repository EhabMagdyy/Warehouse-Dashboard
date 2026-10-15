import QtQuick
import QtQuick.Controls
import "../theme"

// Custom window bar. Use as the ApplicationWindow header:
//
//   ApplicationWindow {
//       flags: Qt.Window | Qt.FramelessWindowHint
//       header: TitleBar {}
//   }
//
// Drag the bar to move the window, double-click to maximize / restore.
Rectangle {
    id: bar

    // The hosting window, resolved from the scene (avoids `window: window` self-binding)
    readonly property var win: Window.window

    property string title: win ? win.title : ""
    property string iconName: "warehouse"

    readonly property bool isWindowed: win && win.visibility === Window.Windowed
    readonly property bool isFullScreen: win && win.visibility === Window.FullScreen

    function toggleMaximized() {
        if (!win) return
        win.visibility = isWindowed ? Window.Maximized : (isFullScreen ? Window.Maximized : Window.Windowed)
    }

    implicitHeight: Theme.dp(40)

    // Same idea as the glass panels: solid, slightly lighter ends fading into the page colour
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: Theme.surface }
        GradientStop { position: 0.5; color: Qt.rgba(0.04, 0.07, 0.13, 0.95) }
        GradientStop { position: 1.0; color: Theme.surface }
    }

    // gold hairline along the bottom, same as the page headers
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30)
    }

    // --- drag / double-click area (sits under the buttons) ---
    Item {
        anchors.fill: parent

        DragHandler {
            target: null
            enabled: !bar.isFullScreen
            onActiveChanged: if (active && bar.win) bar.win.startSystemMove()
        }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            onDoubleTapped: bar.toggleMaximized()
        }
    }

    // --- title ---
    Row {
        anchors.centerIn: parent
        spacing: Theme.dp(10)

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: bar.iconName
            size: Theme.dp(18)
            color: Theme.primary
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.title.toUpperCase()
            color: Theme.primary
            font.pixelSize: Theme.fontSizeSmall + 1
            font.bold: true
            font.family: Theme.fontFamily
            font.letterSpacing: 2
        }
    }

    // --- window buttons ---
    component WinButton: Item {
        id: btn
        property string iconName: ""
        property bool danger: false
        signal clicked()

        width: Theme.dp(52)
        height: bar.height - 1      // keep the hairline visible

        Rectangle {
            anchors.fill: parent
            color: btn.danger
                   ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b,
                             tap.pressed ? 1.0 : (hover.hovered ? 0.85 : 0))
                   : Qt.rgba(1, 1, 1, tap.pressed ? 0.14 : (hover.hovered ? 0.07 : 0))
            Behavior on color { ColorAnimation { duration: 110 } }
        }
        Icon {
            anchors.centerIn: parent
            name: btn.iconName
            size: Theme.dp(16)
            color: (btn.danger && hover.hovered) ? "white"
                   : hover.hovered ? Theme.textPrimary : Theme.textSecondary
            Behavior on color { ColorAnimation { duration: 110 } }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: tap; onTapped: btn.clicked() }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top

        WinButton {
            iconName: "minus"
            onClicked: if (bar.win) bar.win.showMinimized()
        }
        WinButton {
            iconName: bar.isWindowed ? "window-maximize" : "window-restore"
            onClicked: bar.toggleMaximized()
        }
        WinButton {
            iconName: "close"
            danger: true
            onClicked: if (bar.win) bar.win.close()
        }
    }
}
