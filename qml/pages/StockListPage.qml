import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../components"
import "../theme"

Item {
    id: root

    signal stockClicked(int stockId, string stockName)
    property int pendingDeleteId: -1

    // background
    Rectangle { anchors.fill: parent; color: Theme.background }

    Rectangle {
        width: parent.width * 0.45; height: width; radius: width / 2
        x: parent.width * 0.60; y: -height * 0.50
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }
    }

    // header bar
    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.dp(72)
        color: Qt.rgba(0.04, 0.07, 0.13, 0.95)
        border.width: 0

        // gold bottom line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30)
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.pageMargin
            anchors.rightMargin: Theme.pageMargin
            spacing: Theme.spacingMedium

            // logo + title
            Row {
                spacing: Theme.dp(12)
                Layout.fillWidth: true

                Rectangle {
                    width: Theme.dp(40); height: width
                    radius: Theme.dp(10)
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.40)
                    anchors.verticalCenter: parent.verticalCenter
                    Icon { anchors.centerIn: parent; name: "warehouse"; size: Theme.dp(22); color: Theme.primary }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Label {
                        text: app.stockModel.count === 0
                              ? qsTr("No stocks")
                              : qsTr("%1 active stock(s)").arg(app.stockModel.count)
                        font.pixelSize: Theme.fontSizeBody
                        font.bold: true
                        font.family: Theme.fontFamily
                        color: Theme.primary
                    }
                }
            }

            GlassButton {
                text: qsTr("LOCK")
                outlined: true
                iconName: "lock"
                onClicked: app.lock()
            }
        }
    }

    // stock grid
    ScrollView {
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.pageMargin
        contentWidth: availableWidth
        clip: true

        Flow {
            width: parent.width
            spacing: Theme.spacingMedium

            Repeater {
                model: app.stockModel

                Rectangle {
                    id: stockCard
                    width: Math.max(Theme.dp(300),
                                   (parent.width - (Math.floor(parent.width / Theme.dp(320)) - 1) * Theme.spacingMedium)
                                   / Math.max(1, Math.floor(parent.width / Theme.dp(320))))
                    height: Theme.dp(150)
                    radius: Theme.radiusLarge
                    color: cardHover.hovered
                           ? Qt.rgba(0.12, 0.18, 0.30, 0.95)
                           : Qt.rgba(0.07, 0.10, 0.18, 0.90)
                    border.width: 1
                    border.color: cardHover.hovered
                                  ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.55)
                                  : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)

                    Behavior on color       { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    // left gold stripe
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.topMargin: Theme.dp(16)
                        anchors.bottomMargin: Theme.dp(16)
                        width: Theme.dp(4)
                        radius: 2
                        color: Theme.primary
                        opacity: cardHover.hovered ? 1.0 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.dp(20)
                        anchors.leftMargin: Theme.dp(24)
                        spacing: Theme.spacingMedium

                        // icon
                        Rectangle {
                            Layout.preferredWidth: Theme.dp(56)
                            Layout.preferredHeight: Theme.dp(56)
                            radius: Theme.radiusMedium
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                            border.width: 1
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30)
                            Icon { anchors.centerIn: parent; name: "package"; size: Theme.dp(28); color: Theme.primary }
                        }

                        // info
                        Column {
                            Layout.fillWidth: true
                            spacing: Theme.dp(4)
                            Label {
                                width: parent.width
                                text: model.name
                                horizontalAlignment: Text.AlignLeft
                                font.pixelSize: Theme.fontSizeHeader
                                font.bold: true
                                font.family: Theme.fontFamily
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                            }
                            Label {
                                width: parent.width
                                text: model.description || qsTr("No description")
                                horizontalAlignment: Text.AlignLeft
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                            }
                            Row {
                                spacing: Theme.dp(8)
                                Rectangle {
                                    width: itemCountLabel.implicitWidth + Theme.dp(14)
                                    height: Theme.dp(22)
                                    radius: Theme.radiusRound
                                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                                    Label {
                                        id: itemCountLabel
                                        anchors.centerIn: parent
                                        text: qsTr("%1 items").arg(model.itemCount)
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.family: Theme.fontFamily
                                        color: Theme.accent
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        // edit btn
                        Rectangle {
                            Layout.preferredWidth: Theme.dp(36)
                            Layout.preferredHeight: Theme.dp(36)
                            radius: Theme.radiusSmall
                            color: editHover.hovered
                                   ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28)
                                   : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
                            border.width: 1
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.30)
                            visible: cardHover.hovered || editHover.hovered || delHover.hovered
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Icon { anchors.centerIn: parent; name: "edit"; size: Theme.dp(16); color: Theme.primary }
                            HoverHandler { id: editHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: editStockDialog.edit(model.id, model.name, model.description)
                            }
                        }

                        // delete btn
                        Rectangle {
                            Layout.preferredWidth: Theme.dp(36)
                            Layout.preferredHeight: Theme.dp(36)
                            radius: Theme.radiusSmall
                            color: delHover.hovered
                                   ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.22)
                                   : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.30)
                            visible: cardHover.hovered || delHover.hovered
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Icon { anchors.centerIn: parent; name: "trash"; size: Theme.dp(16); color: Theme.danger }
                            HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: { root.pendingDeleteId = model.id; deleteDialog.open() }
                            }
                        }
                    }

                    HoverHandler { id: cardHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        // the edit / delete buttons are children of the card: don't also open the stock
                        onTapped: if (!editHover.hovered && !delHover.hovered)
                                      root.stockClicked(model.id, model.name)
                    }
                }
            }

            // add-new tile (hidden once the stock limit is reached)
            Rectangle {
                visible: app.stockModel.count < app.maxStocks
                width: Math.max(Theme.dp(300),
                               (parent.width - (Math.floor(parent.width / Theme.dp(320)) - 1) * Theme.spacingMedium)
                               / Math.max(1, Math.floor(parent.width / Theme.dp(320))))
                height: Theme.dp(150)
                radius: Theme.radiusLarge
                color: addHover.hovered
                       ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
                       : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.04)
                border.width: 1.5
                border.color: addHover.hovered
                              ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.55)
                              : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.20)

                Behavior on color       { ColorAnimation { duration: 180 } }
                Behavior on border.color { ColorAnimation { duration: 180 } }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.dp(10)
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "plus"
                        size: Theme.dp(32)
                        color: Theme.primary
                        opacity_: addHover.hovered ? 1.0 : 0.55
                        Behavior on opacity_ { NumberAnimation { duration: 180 } }
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr("NEW STOCK")
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        font.family: Theme.fontFamily
                        font.letterSpacing: 1.5
                        color: Theme.primary
                        opacity: addHover.hovered ? 1.0 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }
                }

                HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: addDialog.open() }
            }
        }
    }

    // dialogs
    GlassDialog {
        id: addDialog
        title: qsTr("Add Stock")
        acceptText: qsTr("Create")
        acceptEnabled: nameField.text.trim().length > 0
        onAboutToShow: { nameField.text = ""; descField.text = "" }

        Column {
            width: parent.width
            spacing: Theme.spacingMedium
            GlassTextField { id: nameField; width: parent.width; placeholder: qsTr("Stock name");            maxLength: 20 }
            GlassTextField { id: descField; width: parent.width; placeholder: qsTr("Description (optional)"); maxLength: 40 }
        }

        onAccepted: app.addStock(nameField.text.trim(), descField.text.trim())
    }

    StockEditDialog { id: editStockDialog }

    GlassDialog {
        id: deleteDialog
        title: qsTr("Delete Stock?")
        acceptText: qsTr("Delete")
        showCancel: true
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBody
            text: qsTr("This will permanently delete the stock, all its items and their history. This action cannot be undone.")
        }
        onAccepted: app.deleteStock(root.pendingDeleteId)
    }
}
