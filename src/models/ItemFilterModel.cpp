#include "ItemFilterModel.h"

#include "ItemModel.h"

ItemFilterModel::ItemFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

void ItemFilterModel::setFilterString(const QString &text)
{
    m_text = text;
    invalidate();
}

bool ItemFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_text.trimmed().isEmpty())
        return true;
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    const QString needle = m_text.trimmed();
    return idx.data(ItemModel::NameRole).toString().contains(needle, Qt::CaseInsensitive)
        || idx.data(ItemModel::UnitRole).toString().contains(needle, Qt::CaseInsensitive)
        || idx.data(ItemModel::NotesRole).toString().contains(needle, Qt::CaseInsensitive);
}
