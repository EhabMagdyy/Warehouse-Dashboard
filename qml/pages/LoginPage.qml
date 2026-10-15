import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../components"
import "../theme"

Item {
    id: root

    // "reset" = change password using the magic word (only reachable from the login screen)
    property bool resetMode: false
    readonly property bool setupMode: !app.passwordSet
    property bool messageIsError: true

    function focusFirst() {
        (resetMode ? resetMagicField : passwordField).forceFocus()
    }

    // Enter: go to the next visible field, submit from the last one
    function advance(field) {
        const list = [resetMagicField, passwordField, confirmField, magicField, magicConfirmField]
                     .filter(f => f.visible)
        const i = list.indexOf(field)
        if (i >= 0 && i < list.length - 1) list[i + 1].forceFocus()
        else root.attempt()
    }

    Component.onCompleted: Qt.callLater(root.focusFirst)

    function clearFields() {
        resetMagicField.text = ""
        passwordField.text   = ""
        confirmField.text    = ""
        magicField.text      = ""
        magicConfirmField.text = ""
    }

    // Clear sensitive fields every time the app locks
    Connections {
        target: app
        function onLocked() {
            root.clearFields()
            root.resetMode = false
            errorLabel.text = ""
            Qt.callLater(root.focusFirst)
        }
    }

    // dark background with radial glow
    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    // ambient blobs — blurred circles (pure Qt6, no Qt5Compat)
    Rectangle {
        width: parent.width * 0.55; height: width; radius: width / 2
        x: parent.width * 0.55; y: -height * 0.40
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }
    }
    Rectangle {
        width: parent.width * 0.50; height: width; radius: width / 2
        x: -width * 0.35; y: parent.height * 0.55
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }
    }

    // login card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(Theme.dp(460), parent.width * 0.90)
        height: cardCol.implicitHeight + Theme.dp(64)
        radius: Theme.radiusLarge
        color: Qt.rgba(0.07, 0.10, 0.18, 0.92)
        border.width: 1
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28)

        // top gold accent bar
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.55
            height: Theme.dp(3)
            radius: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.primary }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Column {
            id: cardCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Theme.dp(40)
            width: parent.width - Theme.dp(56)
            spacing: Theme.dp(22)

            // logo
            Column {
                width: parent.width
                spacing: Theme.dp(14)

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.dp(84); height: width

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.dp(22)
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                        border.width: 1.5
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.45)
                    }
                    Icon {
                        anchors.centerIn: parent
                        name: "warehouse"
                        size: Theme.dp(38)
                        color: Theme.primary
                    }
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Warehouse Dashboard")
                    font.pixelSize: Theme.fontSizeTitle
                    font.bold: true
                    font.family: Theme.fontFamily
                    font.letterSpacing: Theme.dp(2)
                    color: Theme.primary
                }
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.setupMode
                          ? qsTr("First access — create your master password and magic word")
                          : root.resetMode
                            ? qsTr("Enter your magic word to set a new password")
                            : qsTr("Enter your password to continue")
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    color: Theme.textSecondary
                    wrapMode: Text.WordWrap
                }
            }

            // divider
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) }

            // fields
            Column {
                width: parent.width
                spacing: Theme.dp(12)

                GlassTextField {
                    id: resetMagicField
                    width: parent.width
                    password: true
                    maxLength: 20
                    visible: root.resetMode
                    placeholder: qsTr("Magic word")
                    onAccepted: root.advance(resetMagicField)
                }
                GlassTextField {
                    id: passwordField
                    width: parent.width
                    password: true
                    maxLength: 12
                    placeholder: root.setupMode ? qsTr("New password (6-12 chars)")
                                : root.resetMode ? qsTr("New password (6-12 chars)")
                                : qsTr("Password")
                    onAccepted: root.advance(passwordField)
                }
                GlassTextField {
                    id: confirmField
                    width: parent.width
                    password: true
                    maxLength: 12
                    placeholder: qsTr("Confirm password")
                    visible: root.setupMode || root.resetMode
                    onAccepted: root.advance(confirmField)
                }
                GlassTextField {
                    id: magicField
                    width: parent.width
                    password: true
                    maxLength: 20
                    placeholder: qsTr("Magic word (needed to change password later)")
                    visible: root.setupMode
                    onAccepted: root.advance(magicField)
                }
                GlassTextField {
                    id: magicConfirmField
                    width: parent.width
                    password: true
                    maxLength: 20
                    placeholder: qsTr("Confirm magic word")
                    visible: root.setupMode
                    onAccepted: root.advance(magicConfirmField)
                }
            }

            // error label
            Label {
                id: errorLabel
                width: parent.width
                wrapMode: Text.WordWrap
                visible: text.length > 0
                color: root.messageIsError ? Theme.danger : Theme.success
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                horizontalAlignment: Text.AlignHCenter

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -Theme.dp(10)
                    radius: Theme.radiusSmall
                    color: root.messageIsError
                           ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.10)
                           : Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.10)
                    visible: errorLabel.text.length > 0
                    z: -1
                }
            }

            // button
            GlassButton {
                width: parent.width
                primary: true
                text: root.setupMode ? qsTr("CREATE & ENTER")
                      : root.resetMode ? qsTr("CHANGE PASSWORD")
                      : qsTr("AUTHENTICATE")
                onClicked: root.attempt()
            }

            // switch between login and change-password
            Label {
                width: parent.width
                visible: !root.setupMode
                horizontalAlignment: Text.AlignHCenter
                text: root.resetMode ? qsTr("Back to login") : qsTr("Change password")
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                font.underline: linkHover.hovered
                color: linkHover.hovered ? Theme.primary : Theme.textSecondary
                HoverHandler { id: linkHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        root.clearFields()
                        errorLabel.text = ""
                        root.resetMode = !root.resetMode
                        Qt.callLater(root.focusFirst)
                    }
                }
            }

            Item { height: Theme.dp(4) } // bottom padding spacer
        }
    }

    // version tag
    Label {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.dp(20)
        text: qsTr("Warehouse Management System")
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
        color: Theme.textFaint
        font.letterSpacing: 0.5
    }

    function fail(message) {
        errorLabel.text = message
        card.border.color = Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.55)
        shakeTimer.restart()
    }

    Timer {
        id: shakeTimer
        interval: 500
        onTriggered: card.border.color = Qt.binding(
            function() { return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28) }
        )
    }

    function checkNewPassword() {
        const len = passwordField.text.length
        if (len < 6)  { fail(qsTr("Password must be at least 6 characters")); return false }
        if (len > 12) { fail(qsTr("Password must be at most 12 characters")); return false }
        if (passwordField.text !== confirmField.text) {
            fail(qsTr("Passwords do not match")); return false
        }
        return true
    }

    function attempt() {
        errorLabel.text = ""
        root.messageIsError = true

        if (root.setupMode) {
            if (!checkNewPassword()) return
            const magic = magicField.text.trim()
            if (magic.length < 4) {
                fail(qsTr("Magic word must be at least 4 characters")); return
            }
            if (magic !== magicConfirmField.text.trim()) {
                fail(qsTr("Magic words do not match")); return
            }
            if (magic === passwordField.text) {
                fail(qsTr("Magic word must be different from the password")); return
            }
            if (app.setupPassword(passwordField.text, magic))
                root.clearFields()
        } else if (root.resetMode) {
            if (resetMagicField.text.trim().length === 0) {
                fail(qsTr("Enter your magic word")); return
            }
            if (!checkNewPassword()) return
            if (passwordField.text === resetMagicField.text.trim()) {
                fail(qsTr("Password must be different from the magic word")); return
            }
            if (app.changePassword(resetMagicField.text, passwordField.text)) {
                root.clearFields()
                root.resetMode = false
                root.messageIsError = false
                errorLabel.text = qsTr("Password changed")
            } else {
                fail("")   // reason shown by the toast; just flash the card
                resetMagicField.text = ""
            }
        } else {
            if (!app.login(passwordField.text)) {
                fail(qsTr("Wrong password"))
                passwordField.text = ""
            }
        }
    }
}
