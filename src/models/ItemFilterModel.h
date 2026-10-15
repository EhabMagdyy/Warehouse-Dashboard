#pragma once

#include <QSortFilterProxyModel>
#include <QtQml/qqmlregistration.h>

class ItemFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_NAMED_ELEMENT(ItemFilterModel)

public:
    explicit ItemFilterModel(QObject *parent = nullptr);

    Q_INVOKABLE void setFilterString(const QString &text);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;

private:
    QString m_text;
};
