#pragma once

#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QVector>

class ItemModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        QuantityRole,
        UnitRole,
        MinQuantityRole,
        NotesRole,
        LowStockRole,
        CreatedAtRole,
    };

    explicit ItemModel(const QSqlDatabase &db, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return int(m_rows.size()); }
    void reload(int stockId);

signals:
    void countChanged();

private:
    struct Row {
        int id;
        QString name;
        int quantity;
        QString unit;
        int minQuantity;
        QString notes;
        QString createdAt;
    };
    QSqlDatabase m_db;
    QVector<Row> m_rows;
};
