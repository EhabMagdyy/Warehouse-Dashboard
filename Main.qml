import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Effects
import "qml/theme"
import "qml/components"
import "qml/pages"

ApplicationWindow {
    id: window
    visible: true
    visibility: Window.FullScreen
    // size used when restored out of maximized / fullscreen
    width: Math.round(Screen.width * 0.8)
    height: Math.round(Screen.height * 0.8)
    minimumWidth: 900
    minimumHeight: 600
    flags: Qt.Window | Qt.FramelessWindowHint
    title: qsTr("Warehouse Dashboard")

    color: Theme.background

    header: TitleBar {}

    // Only two states are allowed: full screen, or minimized (hidden in the taskbar).
    // If the window manager ever restores it into a normal / maximized window, snap back.
    onVisibilityChanged: {
        if (window.visibility === Window.Windowed || window.visibility === Window.Maximized)
            window.visibility = Window.FullScreen
    }

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: LoginPage {}

        pushEnter:  Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic } }
        pushExit:   Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 160; easing.type: Easing.InCubic } }
        popEnter:   Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic } }
        popExit:    Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 160; easing.type: Easing.InCubic } }
    }

    Component {
        id: stockListComponent
        StockListPage {
            onStockClicked: (id, name) => stack.push(stockDetailComponent, { stockId: id, stockName: name })
        }
    }
    Component { id: stockDetailComponent; StockDetailPage {} }

    Connections {
        target: app
        function onLoginSucceeded() {
            if (stack.depth === 1) stack.push(stockListComponent)
        }
        function onLocked() {
            while (stack.depth > 1) stack.pop()
        }
        function onOperationFailed(message) {
            toastText.text = message
            toast.opacity = 1.0
            toastTimer.restart()
        }
    }

    // toast notification
    Rectangle {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.dp(40)
        width: toastText.implicitWidth + Theme.dp(80)
        height: Theme.dp(52)
        radius: height / 2
        color: Theme.dangerSoft
        border.width: 1
        border.color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.55)
        opacity: 0
        visible: opacity > 0.01
        z: 100

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Row {
            anchors.centerIn: parent
            spacing: Theme.dp(10)
            Icon { anchors.verticalCenter: parent.verticalCenter; name: "warning"; size: Theme.dp(18); color: Theme.danger }
            Label {
                id: toastText
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeBody
                font.family: Theme.fontFamily
                font.bold: true
            }
        }
        Timer {
            id: toastTimer
            interval: 3500
            onTriggered: toast.opacity = 0
        }
    }
}
