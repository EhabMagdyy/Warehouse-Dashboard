#include "ItemModel.h"

#include <QSqlQuery>

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
    };
}

void ItemModel::reload(int stockId)
{
    beginResetModel();
    m_rows.clear();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "SELECT id, name, quantity, unit, min_quantity, notes, created_at"
        " FROM items WHERE stock_id = ? ORDER BY name"));
    q.addBindValue(stockId);
    if (q.exec()) {
        while (q.next()) {
            m_rows.append({q.value(0).toInt(), q.value(1).toString(),
                           q.value(2).toInt(), q.value(3).toString(),
                           q.value(4).toInt(), q.value(5).toString(),
                           q.value(6).toString()});
        }
    }
    endResetModel();
    emit countChanged();
}
