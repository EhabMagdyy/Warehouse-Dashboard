#pragma once

#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVector>

class ItemModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    // custom columns of the loaded stock: [{id, name}, ...] in display order
    Q_PROPERTY(QVariantList columns READ columns NOTIFY columnsChanged)

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
        ValuesRole,      // list<int>, one value per custom column (same order as `columns`)
    };

    explicit ItemModel(const QSqlDatabase &db, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return int(m_rows.size()); }
    QVariantList columns() const { return m_columns; }
    void reload(int stockId);

signals:
    void countChanged();
    void columnsChanged();

private:
    struct Row {
        int id;
        QString name;
        int quantity;
        QString unit;
        int minQuantity;
        QString notes;
        QString createdAt;
        QVariantList values;
    };
    QSqlDatabase m_db;
    QVector<Row> m_rows;
    QVariantList m_columns;
};
