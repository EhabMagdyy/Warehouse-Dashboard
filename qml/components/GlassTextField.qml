import QtQuick
import QtQuick.Controls
import "../theme"

Item {
    id: root

    property alias text: field.text
    property alias placeholder: field.placeholderText
    property alias validator: field.validator
    property alias inputMethodHints: field.inputMethodHints
    property alias maxLength: field.maximumLength
    property bool password: false
    property int fontSize: Theme.fontSizeBody

    signal editingFinished()
    signal accepted()

    function forceFocus() { field.forceActiveFocus() }

    implicitWidth: Theme.dp(340)
    implicitHeight: Theme.dp(52)

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusMedium
        color: Qt.rgba(1, 1, 1, field.activeFocus ? 0.07 : 0.04)
        border.width: 1.5
        border.color: field.activeFocus
                      ? Theme.primary
                      : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.20)
        Behavior on border.color { ColorAnimation { duration: 160 } }
        Behavior on color        { ColorAnimation { duration: 160 } }
    }

    TextField {
        id: field
        anchors.fill: parent
        anchors.leftMargin: Theme.dp(16)
        anchors.rightMargin: root.password ? eyeBtn.width + Theme.dp(4) : Theme.dp(16)
        font.pixelSize: root.fontSize
        font.family: Theme.fontFamily
        color: Theme.textPrimary
        placeholderTextColor: Theme.textFaint
        horizontalAlignment: TextInput.AlignLeft   // keep Arabic input left-aligned like English
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        background: Item {}
        onEditingFinished: root.editingFinished()
        // Enter / numpad Enter: handled here only, so it never also reaches the parent dialog
        Keys.onReturnPressed: (event) => { event.accepted = true; root.accepted() }
        Keys.onEnterPressed:  (event) => { event.accepted = true; root.accepted() }
        selectionColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
    }

    // password toggle
    Item {
        id: eyeBtn
        visible: root.password
        width: visible ? Theme.dp(44) : 0
        height: parent.height
        anchors.right: parent.right
        anchors.rightMargin: Theme.dp(4)

        Icon {
            anchors.centerIn: parent
            name: field.echoMode === TextInput.Password ? "eye" : "eye-off"
            size: Theme.dp(18)
            color: Theme.textSecondary
            opacity_: eyeHover.hovered ? 1.0 : 0.50
            Behavior on opacity_ { NumberAnimation { duration: 120 } }
        }

        HoverHandler { id: eyeHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: field.echoMode = (field.echoMode === TextInput.Password)
                       ? TextInput.Normal : TextInput.Password
        }
    }
}
