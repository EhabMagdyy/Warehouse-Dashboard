#pragma once

#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QVector>

class StockModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        ItemCountRole,
        CreatedAtRole,
    };

    explicit StockModel(const QSqlDatabase &db, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return int(m_rows.size()); }
    void reload();

signals:
    void countChanged();

private:
    struct Row {
        int id;
        QString name;
        QString description;
        QString createdAt;
        int itemCount;
    };
    QSqlDatabase m_db;
    QVector<Row> m_rows;
};
