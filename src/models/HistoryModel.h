#pragma once

#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QVector>

class HistoryModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        ItemNameRole,
        DeltaRole,
        ReasonRole,
        QuantityAfterRole,
        CreatedAtRole,
    };

    explicit HistoryModel(const QSqlDatabase &db, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return int(m_rows.size()); }
    void reload(int itemId);

signals:
    void countChanged();

private:
    struct Row {
        int id;
        QString itemName;
        int delta;
        QString reason;
        int quantityAfter;
        QString createdAt;
    };
    QSqlDatabase m_db;
    QVector<Row> m_rows;
};
