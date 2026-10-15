import QtQuick
import QtQuick.Controls
import "../theme"

// Edit a stock's name + description.
// Usage: dlg.edit(id, name, description);  onSaved: (name) => ...
GlassDialog {
    id: dlg

    property int stockId: -1
    signal saved(string name)

    title: qsTr("Edit Stock")
    acceptText: qsTr("Save")
    acceptEnabled: editNameField.text.trim().length > 0

    function edit(id, name, description) {
        dlg.stockId = id
        editNameField.text = name
        editDescField.text = description
        dlg.open()
    }

    Column {
        width: parent.width
        spacing: Theme.spacingMedium
        GlassTextField { id: editNameField; width: parent.width; placeholder: qsTr("Stock name");            maxLength: 20 }
        GlassTextField { id: editDescField; width: parent.width; placeholder: qsTr("Description (optional)"); maxLength: 40 }
    }

    onAccepted: {
        const n = editNameField.text.trim()
        if (app.updateStock(dlg.stockId, n, editDescField.text.trim()))
            dlg.saved(n)
    }
}
