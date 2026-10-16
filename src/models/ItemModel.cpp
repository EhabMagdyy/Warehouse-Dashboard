#include "ItemModel.h"

#include <QHash>
#include <utility>
#include <QSqlQuery>
#include <QVariantMap>

ItemModel::ItemModel(const QSqlDatabase &db, QObject *parent)
    : QAbstractListModel(parent), m_db(db)
{
}

int ItemModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_rows.size());
}

QVariant ItemModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= int(m_rows.size()))
        return {};
    const Row &r = m_rows.at(index.row());
    switch (role) {
    case IdRole: return r.id;
    case NameRole: return r.name;
    case QuantityRole: return r.quantity;
    case UnitRole: return r.unit;
    case MinQuantityRole: return r.minQuantity;
    case NotesRole: return r.notes;
    case LowStockRole: return r.minQuantity > 0 && r.quantity <= r.minQuantity;
    case CreatedAtRole: return r.createdAt;
    case ValuesRole: return r.values;
    default: return {};
    }
}

QHash<int, QByteArray> ItemModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {NameRole, "name"},
        {QuantityRole, "quantity"},
        {UnitRole, "unit"},
        {MinQuantityRole, "minQuantity"},
        {NotesRole, "notes"},
        {LowStockRole, "lowStock"},
        {CreatedAtRole, "createdAt"},
        {ValuesRole, "values"},
    };
}

void ItemModel::reload(int stockId)
{
    beginResetModel();
    m_rows.clear();

    // custom columns of this stock
    QVariantList columns;
    QVector<int> columnIds;
    QSqlQuery cq(m_db);
    cq.prepare(QStringLiteral(
        "SELECT id, name FROM custom_columns WHERE stock_id = ? ORDER BY position, id"));
    cq.addBindValue(stockId);
    if (cq.exec()) {
        while (cq.next()) {
            columnIds.append(cq.value(0).toInt());
            columns.append(QVariantMap{{QStringLiteral("id"),   cq.value(0).toInt()},
                                       {QStringLiteral("name"), cq.value(1).toString()}});
        }
    }

    // values: (item, column) -> value; a missing row means 0
    QHash<qint64, int> values;
    if (!columnIds.isEmpty()) {
        QSqlQuery vq(m_db);
        vq.prepare(QStringLiteral(
            "SELECT v.item_id, v.column_id, v.value FROM item_values v"
            " JOIN items i ON i.id = v.item_id WHERE i.stock_id = ?"));
        vq.addBindValue(stockId);
        if (vq.exec()) {
            while (vq.next())
                values.insert((qint64(vq.value(0).toInt()) << 32) | quint32(vq.value(1).toInt()),
                              vq.value(2).toInt());
        }
    }

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "SELECT id, name, quantity, unit, min_quantity, notes, created_at"
        " FROM items WHERE stock_id = ? ORDER BY name"));
    q.addBindValue(stockId);
    if (q.exec()) {
        while (q.next()) {
            const int itemId = q.value(0).toInt();
            QVariantList rowValues;
            for (int columnId : std::as_const(columnIds))
                rowValues.append(values.value((qint64(itemId) << 32) | quint32(columnId), 0));
            m_rows.append({itemId, q.value(1).toString(),
                           q.value(2).toInt(), q.value(3).toString(),
                           q.value(4).toInt(), q.value(5).toString(),
                           q.value(6).toString(), rowValues});
        }
    }
    m_columns = columns;
    endResetModel();
    emit columnsChanged();
    emit countChanged();
}
