#include "StockModel.h"

#include <QSqlQuery>

StockModel::StockModel(const QSqlDatabase &db, QObject *parent)
    : QAbstractListModel(parent), m_db(db)
{
}

int StockModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_rows.size());
}

QVariant StockModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= int(m_rows.size()))
        return {};
    const Row &r = m_rows.at(index.row());
    switch (role) {
    case IdRole: return r.id;
    case NameRole: return r.name;
    case DescriptionRole: return r.description;
    case ItemCountRole: return r.itemCount;
    case CreatedAtRole: return r.createdAt;
    default: return {};
    }
}

QHash<int, QByteArray> StockModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {NameRole, "name"},
        {DescriptionRole, "description"},
        {ItemCountRole, "itemCount"},
        {CreatedAtRole, "createdAt"},
    };
}

void StockModel::reload()
{
    beginResetModel();
    m_rows.clear();
    QSqlQuery q(m_db);
    if (q.exec(QStringLiteral(
            "SELECT s.id, s.name, s.description, s.created_at,"
            " (SELECT COUNT(*) FROM items i WHERE i.stock_id = s.id)"
            " FROM stocks s ORDER BY s.name"))) {
        while (q.next()) {
            m_rows.append({q.value(0).toInt(), q.value(1).toString(),
                           q.value(2).toString(), q.value(3).toString(),
                           q.value(4).toInt()});
        }
    }
    endResetModel();
    emit countChanged();
}
