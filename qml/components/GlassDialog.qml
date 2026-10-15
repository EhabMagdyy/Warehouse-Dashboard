import QtQuick
import QtQuick.Controls
import "../theme"

Popup {
    id: dlg

    property string title: ""
    property string acceptText: qsTr("OK")
    property string cancelText: qsTr("Cancel")
    property bool showCancel: true
    property bool acceptEnabled: true
    property real preferredWidth: Theme.dp(500)

    default property alias content: body.data

    signal accepted()
    signal rejected()

    // Enter = accept. With several fields, Enter moves to the next one and
    // accepts from the last. Escape closes (Popup default).
    property var _fields: []

    function submit() {
        if (!dlg.opened || !dlg.acceptEnabled) return
        dlg.accepted()
        dlg.close()
    }
    function _collect(item, out) {
        for (let i = 0; i < item.children.length; ++i) {
            const c = item.children[i]
            if (c.forceFocus !== undefined) out.push(c)
            else _collect(c, out)
        }
    }
    function _advance(field) {
        const list = dlg._fields.filter(f => f.visible)
        const i = list.indexOf(field)
        if (i >= 0 && i < list.length - 1) list[i + 1].forceFocus()
        else dlg.submit()
    }
    Component.onCompleted: {
        const found = []
        dlg._collect(body, found)
        dlg._fields = found
        found.forEach(f => f.accepted.connect(() => dlg._advance(f)))
    }
    onOpened: {
        const first = dlg._fields.find(f => f.visible)
        if (first) first.forceFocus()
        else dlg.contentItem.forceActiveFocus()
    }

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    dim: true
    padding: 0
    focus: true

    width: Math.min(preferredWidth, Overlay.overlay ? Overlay.overlay.width * 0.92 : preferredWidth)



    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale";   from: 0.93; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale";   from: 1.0; to: 0.96; duration: 150; easing.type: Easing.InCubic }
        }
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0.04, 0.07, 0.13, 0.78)
    }

    background: Item {}

    contentItem: Rectangle {
        radius: Theme.radiusLarge
        color: Theme.surface
        focus: true
        Keys.onReturnPressed: dlg.submit()
        Keys.onEnterPressed:  dlg.submit()
        border.width: 1
        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28)
        implicitWidth: dlg.width
        implicitHeight: innerCol.implicitHeight + Theme.dp(48)

        // gold top bar
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.dp(4)
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.4; color: Theme.primary }
                GradientStop { position: 0.6; color: Theme.primary }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Column {
            id: innerCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.dp(28)
            spacing: Theme.dp(20)

            // title row
            Row {
                width: parent.width
                spacing: Theme.dp(12)
                Rectangle {
                    width: Theme.dp(4); height: titleLabel.implicitHeight
                    anchors.verticalCenter: undefined
                    y: 0
                    color: Theme.primary
                    radius: 2
                }
                Label {
                    id: titleLabel
                    width: parent.width - Theme.dp(16)
                    text: dlg.title
                    font.pixelSize: Theme.fontSizeHeader
                    font.bold: true
                    font.family: Theme.fontFamily
                    color: Theme.textPrimary
                    wrapMode: Text.WordWrap
                }
            }

            // body content
            Column {
                id: body
                width: parent.width
                spacing: Theme.dp(12)
            }

            // button row
            Item {
                width: parent.width
                height: btnRow.height

                Row {
                    id: btnRow
                    anchors.right: parent.right
                    spacing: Theme.dp(10)

                    GlassButton {
                        text: dlg.cancelText
                        outlined: true
                        visible: dlg.showCancel
                        onClicked: { dlg.rejected(); dlg.close() }
                    }
                    GlassButton {
                        text: dlg.acceptText
                        primary: true
                        enabled: dlg.acceptEnabled
                        onClicked: { dlg.accepted(); dlg.close() }
                    }
                }
            }
        }
    }
}
