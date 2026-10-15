#include "HistoryModel.h"

#include <QSqlQuery>

HistoryModel::HistoryModel(const QSqlDatabase &db, QObject *parent)
    : QAbstractListModel(parent), m_db(db)
{
}

int HistoryModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_rows.size());
}

QVariant HistoryModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= int(m_rows.size()))
        return {};
    const Row &r = m_rows.at(index.row());
    switch (role) {
    case IdRole: return r.id;
    case ItemNameRole: return r.itemName;
    case DeltaRole: return r.delta;
    case ReasonRole: return r.reason;
    case QuantityAfterRole: return r.quantityAfter;
    case CreatedAtRole: return r.createdAt;
    default: return {};
    }
}

QHash<int, QByteArray> HistoryModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {ItemNameRole, "itemName"},
        {DeltaRole, "delta"},
        {ReasonRole, "reason"},
        {QuantityAfterRole, "quantityAfter"},
        {CreatedAtRole, "createdAt"},
    };
}

void HistoryModel::reload(int itemId)
{
    beginResetModel();
    m_rows.clear();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "SELECT t.id, i.name, t.delta, t.reason, t.quantity_after, t.created_at"
        " FROM transactions t JOIN items i ON i.id = t.item_id"
        " WHERE t.item_id = ? ORDER BY t.id DESC LIMIT 1000"));
    q.addBindValue(itemId);
    if (q.exec()) {
        while (q.next()) {
            m_rows.append({q.value(0).toInt(), q.value(1).toString(),
                           q.value(2).toInt(), q.value(3).toString(),
                           q.value(4).toInt(), q.value(5).toString()});
        }
    }
    endResetModel();
    emit countChanged();
}
