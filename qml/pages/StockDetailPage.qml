import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "../components"
import "../theme"

Item {
    id: root

    required property int stockId
    required property string stockName

    Component.onCompleted: app.selectStock(root.stockId, root.stockName)

    property int    adjustItemId:      -1
    property string adjustItemName:    ""
    property int    adjustCurrentQty:  0
    property int    adjustSign:        1
    property int    pendingDeleteItemId: -1
    property int    editItemId:        -1
    property string historyItemName:   ""

    // compact action button used in table rows
    component SmallBtn: Rectangle {
        property string iconName: ""
        property color  tint:  Theme.primary
        signal clicked()
        width: Theme.dp(34); height: Theme.dp(34)
        radius: Theme.radiusSmall
        color: h.hovered
               ? Qt.rgba(tint.r, tint.g, tint.b, 0.28)
               : Qt.rgba(tint.r, tint.g, tint.b, 0.10)
        border.width: 1
        border.color: Qt.rgba(tint.r, tint.g, tint.b, h.hovered ? 0.50 : 0.20)
        Behavior on color       { ColorAnimation { duration: 110 } }
        Behavior on border.color { ColorAnimation { duration: 110 } }
        Icon { anchors.centerIn: parent; name: iconName; size: Theme.dp(15); color: tint }
        HoverHandler { id: h; cursorShape: Qt.PointingHandCursor }
        TapHandler   { onTapped: parent.clicked() }
    }

    // background
    Rectangle { anchors.fill: parent; color: Theme.background }
    Rectangle {
        width: parent.width * 0.40; height: width; radius: width / 2
        x: parent.width * 0.65; y: -height * 0.45
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
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

            // back btn
            GlassButton {
                text: qsTr("BACK")
                iconName: "arrow-left"
                outlined: true
                onClicked: root.StackView.view.pop()
            }

            // title
            Column {
                Layout.fillWidth: true
                spacing: 0
                Row {
                    width: parent.width
                    spacing: Theme.dp(10)
                    Label {
                        id: stockTitle
                        anchors.verticalCenter: parent.verticalCenter
                        text: app.selectedStockName
                        font.pixelSize: Theme.fontSizeHeader
                        font.bold: true
                        font.family: Theme.fontFamily
                        font.letterSpacing: 0.8
                        color: Theme.primary
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, parent.width - stockEditBtn.width - parent.spacing)
                    }
                    SmallBtn {
                        id: stockEditBtn
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "edit"
                        onClicked: editStockDialog.edit(root.stockId, app.selectedStockName,
                                                        app.stockDescription(root.stockId))
                    }
                }
                Label {
                    text: qsTr("%1 item(s) in inventory").arg(app.itemModel.count)
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    color: Theme.textSecondary
                }
            }

            // search
            GlassTextField {
                id: searchField
                placeholder: qsTr("Search items…")
                implicitWidth: Theme.dp(260)
                onTextChanged: app.itemFilterModel.setFilterString(text)
            }

            GlassButton { text: qsTr("ADD ITEM"); iconName: "plus"; primary: true; onClicked: addItemDialog.open() }
            GlassButton { iconName: "lock"; outlined: true; onClicked: app.lock() }
        }
    }

    // table
    Rectangle {
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.pageMargin
        anchors.topMargin: Theme.spacingMedium
        color: "transparent"
        radius: Theme.radiusLarge

        // table header
        Rectangle {
            id: tableHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.dp(48)
            radius: Theme.radiusSmall
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.28)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.dp(20)
                anchors.rightMargin: Theme.dp(20)
                spacing: Theme.dp(8)

                Label { text: qsTr("ITEM NAME"); Layout.preferredWidth: Theme.dp(260); Layout.fillWidth: false; color: Theme.primary; font.bold: true; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                Label { text: qsTr("QTY");       Layout.preferredWidth: Theme.dp(100);                         color: Theme.primary; font.bold: true; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                Label { text: qsTr("NOTES");     Layout.fillWidth: true;                                      color: Theme.primary; font.bold: true; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
                Label { text: qsTr("ACTIONS");   Layout.preferredWidth: Theme.dp(250);                        color: Theme.primary; font.bold: true; font.pixelSize: Theme.fontSizeSmall; font.family: Theme.fontFamily; font.letterSpacing: 1 }
            }
        }

        // table rows
        ListView {
            id: itemsList
            anchors.top: tableHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Theme.spacingXS
            clip: true
            model: app.itemFilterModel
            spacing: Theme.dp(4)

            delegate: Rectangle {
                width: ListView.view.width
                height: Theme.dp(62)
                radius: Theme.radiusSmall
                color: rowHover.hovered
                       ? Qt.rgba(0.12, 0.18, 0.30, 0.95)
                       : model.lowStock
                         ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.07)
                         : Qt.rgba(0.07, 0.10, 0.18, 0.85)
                border.width: 1
                border.color: model.lowStock
                              ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, rowHover.hovered ? 0.55 : 0.28)
                              : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, rowHover.hovered ? 0.30 : 0.10)

                Behavior on color       { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                // low-stock left indicator
                Rectangle {
                    visible: model.lowStock
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Theme.dp(8)
                    anchors.bottomMargin: Theme.dp(8)
                    width: Theme.dp(3)
                    radius: 2
                    color: Theme.danger
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.dp(20)
                    anchors.rightMargin: Theme.dp(16)
                    spacing: Theme.dp(8)

                    Column {
                        Layout.preferredWidth: Theme.dp(260)
                        Layout.fillWidth: false
                        spacing: Theme.dp(2)
                        Label {
                            width: parent.width
                            text: model.name
                            horizontalAlignment: Text.AlignLeft
                            color: Theme.textPrimary
                            font.bold: true
                            font.pixelSize: Theme.fontSizeBody
                            font.family: Theme.fontFamily
                            elide: Text.ElideRight
                        }
                        Row {
                            visible: model.lowStock
                            spacing: Theme.dp(4)
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "warning"
                                size: Theme.dp(13)
                                color: Theme.danger
                            }
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: qsTr("Low stock")
                                color: Theme.danger
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                        }
                    }

                    // qty badge
                    Rectangle {
                        Layout.preferredWidth: Theme.dp(100)
                        height: Theme.dp(30)
                        radius: Theme.radiusSmall
                        color: model.lowStock
                               ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15)
                               : Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.12)
                        border.width: 1
                        border.color: model.lowStock
                                      ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.40)
                                      : Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.35)
                        Label {
                            anchors.centerIn: parent
                            text: model.quantity
                            color: model.lowStock ? Theme.danger : Theme.success
                            font.bold: true
                            font.pixelSize: Theme.fontSizeBody
                            font.family: Theme.fontFamily
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: model.notes || "—"
                        horizontalAlignment: Text.AlignLeft
                        color: Theme.textFaint
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        elide: Text.ElideRight
                    }

                    // actions
                    Row {
                        Layout.preferredWidth: Theme.dp(250)
                        spacing: Theme.dp(5)

                        SmallBtn { iconName: "minus";   tint: Theme.danger;  onClicked: root.openAdjust(model.id, model.name, model.quantity, -1) }
                        Rectangle {
                            width: Theme.dp(44); height: Theme.dp(34)
                            radius: Theme.radiusSmall
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)
                            border.width: 1
                            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
                            Label {
                                anchors.centerIn: parent
                                text: model.quantity
                                color: Theme.primary
                                font.bold: true
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.fontFamily
                            }
                        }
                        SmallBtn { iconName: "plus";    tint: Theme.success; onClicked: root.openAdjust(model.id, model.name, model.quantity, +1) }
                        SmallBtn { iconName: "edit";    tint: Theme.primary; onClicked: root.openEditItem(model.id, model.name, model.notes) }
                        SmallBtn { iconName: "history"; tint: Theme.accent;  onClicked: { root.historyItemName = model.name; app.showHistory(model.id); historyDialog.open() } }
                        SmallBtn { iconName: "trash";   tint: Theme.danger;  onClicked: { root.pendingDeleteItemId = model.id; deleteItemDialog.open() } }
                    }
                }

                HoverHandler { id: rowHover }
            }

            // empty state
            Label {
                anchors.centerIn: parent
                visible: app.itemModel.count === 0
                text: qsTr("No items yet — press \"ADD ITEM\" to create the first one")
                color: Theme.textFaint
                font.pixelSize: Theme.fontSizeBody
                font.family: Theme.fontFamily
            }
        }
    }

    // quantity adjust dialog
    GlassDialog {
        id: adjustDialog
        title: (root.adjustSign > 0 ? qsTr("Increase quantity") : qsTr("Decrease quantity")) + " — " + root.adjustItemName
        acceptText: qsTr("Apply")
        acceptEnabled: reasonField.text.trim().length > 0
                       && (root.adjustSign > 0 || stepper.value <= root.adjustCurrentQty)
        onAboutToShow: { reasonField.text = "" }

        Column {
            width: parent.width
            spacing: Theme.spacingMedium

            Label {
                width: parent.width
                text: qsTr("Current quantity: %1").arg(root.adjustCurrentQty)
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeBody
                font.family: Theme.fontFamily
            }
            Stepper { id: stepper; width: parent.width; minimum: 1; value: 1 }
            Label {
                width: parent.width
                text: qsTr("Result: %1").arg(root.adjustCurrentQty + root.adjustSign * stepper.value)
                color: (root.adjustCurrentQty + root.adjustSign * stepper.value) >= 0 ? Theme.success : Theme.danger
                font.bold: true
                font.pixelSize: Theme.fontSizeBody
                font.family: Theme.fontFamily
            }
            GlassTextField {
                id: reasonField
                width: parent.width
                placeholder: qsTr("Reason / note (required)")
            }
        }

        onAccepted: app.adjustQuantity(root.adjustItemId, root.adjustSign * stepper.value, reasonField.text)
    }

    // add item dialog
    GlassDialog {
        id: addItemDialog
        title: qsTr("Add item to %1").arg(app.selectedStockName)
        acceptText: qsTr("Add")
        acceptEnabled: itemNameField.text.trim().length > 0
        onAboutToShow: { itemNameField.text = ""; initialQtyField.text = ""; notesField.text = "" }

        Column {
            width: parent.width
            spacing: Theme.spacingMedium

            GlassTextField {
                id: itemNameField
                width: parent.width
                placeholder: qsTr("Item name")
                maxLength: 40
            }

            GlassTextField {
                id: initialQtyField
                width: parent.width
                placeholder: qsTr("Initial quantity (leave blank for 0)")
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0; top: 999 }
                property int intValue: text.length > 0 ? parseInt(text) : 0
            }

            GlassTextField {
                id: notesField
                width: parent.width
                placeholder: qsTr("Notes (optional)")
                maxLength: 120
            }
        }

        onAccepted: app.addItem(
            itemNameField.text.trim(), "", 0,
            notesField.text.trim(),
            initialQtyField.intValue
        )
    }

    // edit item dialog (name + notes)
    GlassDialog {
        id: editItemDialog
        title: qsTr("Edit item")
        acceptText: qsTr("Save")
        acceptEnabled: editItemNameField.text.trim().length > 0

        Column {
            width: parent.width
            spacing: Theme.spacingMedium
            GlassTextField { id: editItemNameField;  width: parent.width; placeholder: qsTr("Item name");         maxLength: 40 }
            GlassTextField { id: editItemNotesField; width: parent.width; placeholder: qsTr("Notes (optional)");  maxLength: 120 }
        }

        onAccepted: app.updateItem(root.editItemId, editItemNameField.text.trim(), editItemNotesField.text.trim())
    }

    StockEditDialog { id: editStockDialog }

    GlassDialog {
        id: deleteItemDialog
        title: qsTr("Delete item?")
        acceptText: qsTr("Delete")
        showCancel: true
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBody
            text: qsTr("This will permanently delete the item and its full history.")
        }
        onAccepted: app.deleteItem(root.pendingDeleteItemId)
    }

    GlassDialog {
        id: historyDialog
        title: qsTr("History — %1").arg(root.historyItemName)
        showCancel: false
        acceptText: qsTr("Close")
        preferredWidth: Theme.dp(640)

        ListView {
            width: parent.width
            height: Math.min(Theme.dp(400), contentHeight + Theme.dp(10))
            clip: true
            model: app.historyModel
            spacing: Theme.dp(5)

            delegate: Rectangle {
                width: ListView.view.width
                height: Math.max(Theme.dp(60), contentRow.implicitHeight + Theme.dp(18))
                radius: Theme.radiusSmall
                color: Qt.rgba(0.07, 0.10, 0.18, 0.90)
                border.width: 1
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)

                // delta indicator bar
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: Theme.dp(8)
                    anchors.bottomMargin: Theme.dp(8)
                    width: Theme.dp(3)
                    radius: 2
                    color: model.delta > 0 ? Theme.success : Theme.danger
                }

                RowLayout {
                    id: contentRow
                    anchors.fill: parent
                    anchors.leftMargin: Theme.dp(18)
                    anchors.rightMargin: Theme.dp(14)
                    anchors.topMargin: Theme.dp(10)
                    anchors.bottomMargin: Theme.dp(10)
                    spacing: Theme.spacingMedium

                    Rectangle {
                        Layout.preferredWidth: Theme.dp(56)
                        Layout.preferredHeight: Theme.dp(36)
                        radius: Theme.radiusSmall
                        color: model.delta > 0
                               ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.15)
                               : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.15)
                        border.width: 1
                        border.color: model.delta > 0
                                      ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.40)
                                      : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.40)
                        Label {
                            anchors.centerIn: parent
                            text: (model.delta > 0 ? "+" : "") + model.delta
                            color: model.delta > 0 ? Theme.success : Theme.danger
                            font.bold: true
                            font.pixelSize: Theme.fontSizeBody
                            font.family: Theme.fontFamily
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Theme.dp(3)
                        Label {
                            width: parent.width
                            text: model.reason
                            horizontalAlignment: Text.AlignLeft
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeBody
                            font.family: Theme.fontFamily
                            wrapMode: Text.WordWrap
                        }
                        Label {
                            text: qsTr("Qty after: %1").arg(model.quantityAfter)
                            color: Theme.textFaint
                            font.pixelSize: Theme.fontSizeSmall
                            font.family: Theme.fontFamily
                        }
                    }
                    Label {
                        text: model.createdAt
                        color: Theme.textFaint
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: app.historyModel.count === 0
                text: qsTr("No history yet")
                color: Theme.textFaint
                font.family: Theme.fontFamily
            }
        }
    }

    function openEditItem(itemId, name, notes) {
        root.editItemId = itemId
        editItemNameField.text  = name
        editItemNotesField.text = notes
        editItemDialog.open()
    }

    function openAdjust(itemId, itemName, currentQty, sign) {
        root.adjustItemId     = itemId
        root.adjustItemName   = itemName
        root.adjustCurrentQty = currentQty
        root.adjustSign       = sign
        stepper.value         = 1
        adjustDialog.open()
    }
}
