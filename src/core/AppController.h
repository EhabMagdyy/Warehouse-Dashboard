#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QString>

#include "../models/StockModel.h"
#include "../models/ItemModel.h"
#include "../models/ItemFilterModel.h"
#include "../models/HistoryModel.h"

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool passwordSet READ passwordSet NOTIFY passwordSetChanged)
    Q_PROPERTY(int selectedStockId READ selectedStockId NOTIFY selectedStockChanged)
    Q_PROPERTY(QString selectedStockName READ selectedStockName NOTIFY selectedStockChanged)
    Q_PROPERTY(int maxStocks READ maxStocks CONSTANT)
    Q_PROPERTY(int maxCustomColumns READ maxCustomColumns CONSTANT)
    Q_PROPERTY(int maxColumnNameLength READ maxColumnNameLength CONSTANT)
    Q_PROPERTY(int maxColumnValue READ maxColumnValue CONSTANT)
    Q_PROPERTY(StockModel* stockModel READ stockModel CONSTANT)
    Q_PROPERTY(ItemModel* itemModel READ itemModel CONSTANT)
    Q_PROPERTY(ItemFilterModel* itemFilterModel READ itemFilterModel CONSTANT)
    Q_PROPERTY(HistoryModel* historyModel READ historyModel CONSTANT)

public:
    explicit AppController(const QSqlDatabase &db, QObject *parent = nullptr);
    ~AppController() override;

    static constexpr int kMaxStocks = 16;
    int maxStocks() const { return kMaxStocks; }

    static constexpr int kMaxCustomColumns = 3;      // per stock
    static constexpr int kMaxColumnNameLength = 7;
    static constexpr int kMaxColumnValue = 999;      // 3 digits
    int maxCustomColumns() const { return kMaxCustomColumns; }
    int maxColumnNameLength() const { return kMaxColumnNameLength; }
    int maxColumnValue() const { return kMaxColumnValue; }

    bool passwordSet() const;
    int selectedStockId() const { return m_selectedStockId; }
    QString selectedStockName() const { return m_selectedStockName; }
    StockModel *stockModel() const { return m_stockModel; }
    ItemModel *itemModel() const { return m_itemModel; }
    ItemFilterModel *itemFilterModel() const { return m_itemFilterModel; }
    HistoryModel *historyModel() const { return m_historyModel; }

    Q_INVOKABLE bool setupPassword(const QString &password, const QString &magicWord);   // first run only
    Q_INVOKABLE bool changePassword(const QString &magicWord, const QString &newPassword);
    Q_INVOKABLE bool login(const QString &password);
    Q_INVOKABLE void lock();

    Q_INVOKABLE bool addStock(const QString &name, const QString &description);
    Q_INVOKABLE bool updateStock(int stockId, const QString &name, const QString &description);
    Q_INVOKABLE QString stockDescription(int stockId) const;
    Q_INVOKABLE bool deleteStock(int stockId);
    Q_INVOKABLE void selectStock(int stockId, const QString &name);

    Q_INVOKABLE bool addItem(const QString &name, const QString &unit,
                             int minQuantity, const QString &notes,
                             int initialQuantity = 0);
    Q_INVOKABLE bool updateItem(int itemId, const QString &name, const QString &notes);
    Q_INVOKABLE bool deleteItem(int itemId);
    Q_INVOKABLE bool adjustQuantity(int itemId, int delta, const QString &reason);
    Q_INVOKABLE bool addColumn(const QString &name);   // custom column on the selected stock
    Q_INVOKABLE bool adjustColumnValue(int itemId, int columnId, int delta, const QString &reason);
    Q_INVOKABLE void showHistory(int itemId);

signals:
    void passwordSetChanged();
    void loginSucceeded();
    void locked();
    void selectedStockChanged();
    void operationFailed(const QString &message);

private:
    QSqlDatabase m_db;
    StockModel *m_stockModel = nullptr;
    ItemModel *m_itemModel = nullptr;
    ItemFilterModel *m_itemFilterModel = nullptr;
    HistoryModel *m_historyModel = nullptr;
    int m_selectedStockId = -1;
    QString m_selectedStockName;
    int m_historyItemId = -1;
};
