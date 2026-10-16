#include "AppController.h"

#include "../models/StockModel.h"
#include "../models/ItemModel.h"
#include "../models/ItemFilterModel.h"
#include "../models/HistoryModel.h"

#include <QCryptographicHash>
#include <QPasswordDigestor>
#include <QRandomGenerator>
#include <QSqlError>
#include <QSqlQuery>

#include <cstring>

namespace {
    constexpr int kPbkdf2Iterations = 100000;
    constexpr int kSaltSize = 16;
    constexpr int kMinPasswordLength = 4;
    constexpr int kMinMagicWordLength = 4;

    QByteArray deriveHash(const QString &secret, const QByteArray &salt, int iterations, int size = 32)
    {
        return QPasswordDigestor::deriveKeyPbkdf2(
            QCryptographicHash::Sha256, secret.toUtf8(), salt, iterations, size);
    }

    bool hashesEqual(const QByteArray &a, const QByteArray &b)
    {
        return a.size() == b.size() && std::memcmp(a.constData(), b.constData(), size_t(a.size())) == 0;
    }

    QByteArray makeSalt()
    {
        QByteArray salt(kSaltSize, Qt::Uninitialized);
        for (int i = 0; i < salt.size(); ++i)
            salt[i] = char(QRandomGenerator::system()->generate() & 0xFF);
        return salt;
    }
}

AppController::AppController(const QSqlDatabase &db, QObject *parent)
    : QObject(parent), m_db(db)
{
    m_stockModel = new StockModel(m_db, this);
    m_itemModel = new ItemModel(m_db, this);
    m_itemFilterModel = new ItemFilterModel(this);
    m_historyModel = new HistoryModel(m_db, this);
    m_stockModel->reload();
}

AppController::~AppController() = default;

bool AppController::passwordSet() const
{
    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral("SELECT COUNT(*) FROM users")) || !q.next())
        return false;
    return q.value(0).toInt() > 0;
}

bool AppController::setupPassword(const QString &password, const QString &magicWord)
{
    if (passwordSet() || password.trimmed().size() < kMinPasswordLength)
        return false;

    const QString magic = magicWord.trimmed();
    if (magic.size() < kMinMagicWordLength) {
        emit operationFailed(tr("Magic word must be at least %1 characters").arg(kMinMagicWordLength));
        return false;
    }
    if (magic == password) {
        emit operationFailed(tr("Magic word must be different from the password"));
        return false;
    }

    const QByteArray salt = makeSalt();
    const QByteArray hash = deriveHash(password, salt, kPbkdf2Iterations);
    const QByteArray magicSalt = makeSalt();
    const QByteArray magicHash = deriveHash(magic, magicSalt, kPbkdf2Iterations);

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO users(salt, hash, iterations, magic_salt, magic_hash, magic_iterations) "
        "VALUES(?, ?, ?, ?, ?, ?)"));
    q.addBindValue(salt);
    q.addBindValue(hash);
    q.addBindValue(kPbkdf2Iterations);
    q.addBindValue(magicSalt);
    q.addBindValue(magicHash);
    q.addBindValue(kPbkdf2Iterations);
    if (!q.exec()) {
        emit operationFailed(tr("Could not save password"));
        return false;
    }

    emit passwordSetChanged();
    emit loginSucceeded();
    return true;
}

// Returns false on any failure; the reason is always raised via operationFailed.
bool AppController::changePassword(const QString &magicWord, const QString &newPassword)
{
    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral(
            "SELECT id, magic_salt, magic_hash, magic_iterations FROM users ORDER BY id LIMIT 1"))
        || !q.next())
        return false;

    const int userId = q.value(0).toInt();
    const QByteArray magicSalt = q.value(1).toByteArray();
    const QByteArray expected = q.value(2).toByteArray();
    const int magicIterations = q.value(3).toInt();

    if (expected.isEmpty() || magicIterations <= 0) {
        emit operationFailed(tr("No magic word is set for this account"));
        return false;
    }

    const QString magic = magicWord.trimmed();
    if (!hashesEqual(deriveHash(magic, magicSalt, magicIterations, expected.size()), expected)) {
        emit operationFailed(tr("Wrong magic word"));
        return false;
    }

    if (newPassword.trimmed().size() < kMinPasswordLength) {
        emit operationFailed(tr("New password is too short"));
        return false;
    }
    if (newPassword == magic) {
        emit operationFailed(tr("Password must be different from the magic word"));
        return false;
    }

    const QByteArray salt = makeSalt();
    const QByteArray hash = deriveHash(newPassword, salt, kPbkdf2Iterations);

    QSqlQuery u(m_db);
    u.prepare(QStringLiteral("UPDATE users SET salt = ?, hash = ?, iterations = ? WHERE id = ?"));
    u.addBindValue(salt);
    u.addBindValue(hash);
    u.addBindValue(kPbkdf2Iterations);
    u.addBindValue(userId);
    if (!u.exec()) {
        emit operationFailed(tr("Could not save password"));
        return false;
    }
    return true;
}

bool AppController::login(const QString &password)
{
    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral("SELECT salt, hash, iterations FROM users ORDER BY id LIMIT 1")) || !q.next())
        return false;

    const QByteArray salt = q.value(0).toByteArray();
    const QByteArray expected = q.value(1).toByteArray();
    const int iterations = q.value(2).toInt();
    const QByteArray derived = QPasswordDigestor::deriveKeyPbkdf2(
        QCryptographicHash::Sha256, password.toUtf8(), salt, iterations, expected.size());

    if (!hashesEqual(derived, expected))
        return false;

    emit loginSucceeded();
    return true;
}

void AppController::lock()
{
    emit locked();
}

bool AppController::addStock(const QString &name, const QString &description)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        emit operationFailed(tr("Stock name cannot be empty"));
        return false;
    }
    if (m_stockModel->count() >= kMaxStocks) {
        emit operationFailed(tr("Maximum of %1 stocks reached").arg(kMaxStocks));
        return false;
    }
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("INSERT INTO stocks(name, description) VALUES(?, ?)"));
    q.addBindValue(trimmed);
    q.addBindValue(description.trimmed());
    if (!q.exec()) {
        emit operationFailed(tr("A stock with this name already exists"));
        return false;
    }
    m_stockModel->reload();
    return true;
}

bool AppController::updateStock(int stockId, const QString &name, const QString &description)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        emit operationFailed(tr("Stock name cannot be empty"));
        return false;
    }
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE stocks SET name = ?, description = ? WHERE id = ?"));
    q.addBindValue(trimmed);
    q.addBindValue(description.trimmed());
    q.addBindValue(stockId);
    if (!q.exec()) {
        emit operationFailed(tr("A stock with this name already exists"));
        return false;
    }
    if (m_selectedStockId == stockId) {
        m_selectedStockName = trimmed;
        emit selectedStockChanged();
    }
    m_stockModel->reload();
    return true;
}

QString AppController::stockDescription(int stockId) const
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT description FROM stocks WHERE id = ?"));
    q.addBindValue(stockId);
    if (q.exec() && q.next())
        return q.value(0).toString();
    return {};
}

bool AppController::deleteStock(int stockId)
{
    m_db.transaction();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM transactions WHERE item_id IN (SELECT id FROM items WHERE stock_id = ?)"));
    q.addBindValue(stockId);
    const bool ok1 = q.exec();
    q.prepare(QStringLiteral("DELETE FROM item_values WHERE item_id IN (SELECT id FROM items WHERE stock_id = ?)"));
    q.addBindValue(stockId);
    q.exec();
    q.prepare(QStringLiteral("DELETE FROM items WHERE stock_id = ?"));
    q.addBindValue(stockId);
    const bool ok2 = q.exec();
    q.prepare(QStringLiteral("DELETE FROM custom_columns WHERE stock_id = ?"));
    q.addBindValue(stockId);
    q.exec();
    q.prepare(QStringLiteral("DELETE FROM stocks WHERE id = ?"));
    q.addBindValue(stockId);
    const bool ok3 = q.exec();
    if (ok1 && ok2 && ok3) {
        m_db.commit();
    } else {
        m_db.rollback();
        emit operationFailed(tr("Could not delete stock"));
        return false;
    }
    if (m_selectedStockId == stockId) {
        m_selectedStockId = -1;
        m_selectedStockName.clear();
        emit selectedStockChanged();
    }
    m_stockModel->reload();
    return true;
}

void AppController::selectStock(int stockId, const QString &name)
{
    m_selectedStockId = stockId;
    m_selectedStockName = name;
    m_itemModel->reload(stockId);
    m_itemFilterModel->setSourceModel(m_itemModel);
    m_historyItemId = -1;
    emit selectedStockChanged();
}

bool AppController::addItem(const QString &name, const QString &unit,
                            int minQuantity, const QString &notes,
                            int initialQuantity)
{
    if (m_selectedStockId < 0)
        return false;
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        emit operationFailed(tr("Item name cannot be empty"));
        return false;
    }
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO items(stock_id, name, unit, min_quantity, notes) VALUES(?, ?, ?, ?, ?)"));
    q.addBindValue(m_selectedStockId);
    q.addBindValue(trimmed);
    q.addBindValue(unit.trimmed());
    q.addBindValue(minQuantity);
    q.addBindValue(notes.trimmed());
    if (!q.exec()) {
        emit operationFailed(tr("Could not add item"));
        return false;
    }
    const int newItemId = q.lastInsertId().toInt();

    // Apply initial quantity if provided
    if (initialQuantity > 0) {
        QSqlQuery uq(m_db);
        uq.prepare(QStringLiteral("UPDATE items SET quantity = ? WHERE id = ?"));
        uq.addBindValue(initialQuantity);
        uq.addBindValue(newItemId);
        uq.exec();

        // Record in history
        QSqlQuery hq(m_db);
        hq.prepare(QStringLiteral(
            "INSERT INTO history(item_id, delta, quantity_after, reason) VALUES(?, ?, ?, ?)"));
        hq.addBindValue(newItemId);
        hq.addBindValue(initialQuantity);
        hq.addBindValue(initialQuantity);
        hq.addBindValue(tr("Initial stock"));
        hq.exec();
    }

    m_itemModel->reload(m_selectedStockId);
    m_stockModel->reload();   // item counts changed
    return true;
}

bool AppController::updateItem(int itemId, const QString &name, const QString &notes)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        emit operationFailed(tr("Item name cannot be empty"));
        return false;
    }
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE items SET name = ?, notes = ? WHERE id = ?"));
    q.addBindValue(trimmed);
    q.addBindValue(notes.trimmed());
    q.addBindValue(itemId);
    if (!q.exec()) {
        emit operationFailed(tr("Could not update item"));
        return false;
    }
    if (m_selectedStockId >= 0)
        m_itemModel->reload(m_selectedStockId);
    return true;
}

bool AppController::deleteItem(int itemId)
{
    m_db.transaction();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM transactions WHERE item_id = ?"));
    q.addBindValue(itemId);
    const bool ok1 = q.exec();
    q.prepare(QStringLiteral("DELETE FROM item_values WHERE item_id = ?"));
    q.addBindValue(itemId);
    q.exec();
    q.prepare(QStringLiteral("DELETE FROM items WHERE id = ?"));
    q.addBindValue(itemId);
    const bool ok2 = q.exec();
    if (ok1 && ok2) {
        m_db.commit();
    } else {
        m_db.rollback();
        emit operationFailed(tr("Could not delete item"));
        return false;
    }
    if (m_selectedStockId >= 0)
        m_itemModel->reload(m_selectedStockId);
    m_stockModel->reload();
    return true;
}

bool AppController::adjustQuantity(int itemId, int delta, const QString &reason)
{
    const QString trimmedReason = reason.trimmed();

    if (trimmedReason.isEmpty()) {
        emit operationFailed(tr("A reason is required"));
        return false;
    }
    if (trimmedReason.size() > 200) {
        emit operationFailed(tr("Reason can be at most 200 characters"));
        return false;
    }

    m_db.transaction();
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT quantity FROM items WHERE id = ?"));
    q.addBindValue(itemId);
    if (!q.exec() || !q.next()) {
        m_db.rollback();
        return false;
    }
    const int current = q.value(0).toInt();
    const int after = current + delta;
    if (after < 0) {
        m_db.rollback();
        emit operationFailed(tr("Not enough quantity (have %1)").arg(current));
        return false;
    }

    q.prepare(QStringLiteral("UPDATE items SET quantity = ? WHERE id = ?"));
    q.addBindValue(after);
    q.addBindValue(itemId);
    const bool ok1 = q.exec();

    q.prepare(QStringLiteral(
        "INSERT INTO transactions(item_id, delta, reason, quantity_after) VALUES(?, ?, ?, ?)"));
    q.addBindValue(itemId);
    q.addBindValue(delta);
    q.addBindValue(trimmedReason);
    q.addBindValue(after);
    const bool ok2 = q.exec();

    if (!ok1 || !ok2) {
        m_db.rollback();
        emit operationFailed(tr("Could not update quantity"));
        return false;
    }

    // Keep only the latest 100 history records for this item
    QSqlQuery prune(m_db);
    prune.prepare(QStringLiteral(
        "DELETE FROM transactions WHERE item_id = ? AND id NOT IN ("
        "  SELECT id FROM transactions WHERE item_id = ? ORDER BY id DESC LIMIT 100"
        ")"));
    prune.addBindValue(itemId);
    prune.addBindValue(itemId);
    prune.exec();   // ignore failure – not critical

    m_db.commit();

    if (m_selectedStockId >= 0)
        m_itemModel->reload(m_selectedStockId);
    if (m_historyItemId == itemId)
        m_historyModel->reload(itemId);
    return true;
}

bool AppController::addColumn(const QString &name)
{
    if (m_selectedStockId < 0)
        return false;

    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        emit operationFailed(tr("Column name cannot be empty"));
        return false;
    }
    if (trimmed.size() > kMaxColumnNameLength) {
        emit operationFailed(tr("Column name can be at most %1 characters").arg(kMaxColumnNameLength));
        return false;
    }
    const QString upper = trimmed.toUpper();
    if (upper == QLatin1String("QTY") || upper == QLatin1String("NOTES") || upper == QLatin1String("ACTIONS")) {
        emit operationFailed(tr("\"%1\" is already used by the table").arg(trimmed));
        return false;
    }

    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT name FROM custom_columns WHERE stock_id = ?"));
    q.addBindValue(m_selectedStockId);
    int count = 0;
    if (q.exec()) {
        while (q.next()) {
            ++count;
            if (q.value(0).toString().compare(trimmed, Qt::CaseInsensitive) == 0) {
                emit operationFailed(tr("A column named \"%1\" already exists").arg(trimmed));
                return false;
            }
        }
    }
    if (count >= kMaxCustomColumns) {
        emit operationFailed(tr("You can add at most %1 columns").arg(kMaxCustomColumns));
        return false;
    }

    QSqlQuery ins(m_db);
    ins.prepare(QStringLiteral("INSERT INTO custom_columns(stock_id, name, position) VALUES(?, ?, ?)"));
    ins.addBindValue(m_selectedStockId);
    ins.addBindValue(trimmed);
    ins.addBindValue(count);
    if (!ins.exec()) {
        emit operationFailed(tr("Could not add column"));
        return false;
    }
    m_itemModel->reload(m_selectedStockId);
    return true;
}

bool AppController::adjustColumnValue(int itemId, int columnId, int delta, const QString &reason)
{
    if (reason.trimmed().isEmpty()) {
        emit operationFailed(tr("A reason is required"));
        return false;
    }

    m_db.transaction();
    QSqlQuery q(m_db);

    // the column must belong to the same stock as the item
    q.prepare(QStringLiteral(
        "SELECT 1 FROM items i JOIN custom_columns c ON c.stock_id = i.stock_id"
        " WHERE i.id = ? AND c.id = ?"));
    q.addBindValue(itemId);
    q.addBindValue(columnId);
    if (!q.exec() || !q.next()) {
        m_db.rollback();
        return false;
    }

    q.prepare(QStringLiteral("SELECT value FROM item_values WHERE item_id = ? AND column_id = ?"));
    q.addBindValue(itemId);
    q.addBindValue(columnId);
    int current = 0;
    if (q.exec() && q.next())
        current = q.value(0).toInt();

    const int after = current + delta;
    if (after < 0) {
        m_db.rollback();
        emit operationFailed(tr("Not enough quantity (have %1)").arg(current));
        return false;
    }
    if (after > kMaxColumnValue) {
        m_db.rollback();
        emit operationFailed(tr("Maximum value is %1").arg(kMaxColumnValue));
        return false;
    }

    q.prepare(QStringLiteral(
        "INSERT INTO item_values(item_id, column_id, value) VALUES(?, ?, ?)"
        " ON CONFLICT(item_id, column_id) DO UPDATE SET value = excluded.value"));
    q.addBindValue(itemId);
    q.addBindValue(columnId);
    q.addBindValue(after);
    const bool ok1 = q.exec();
    q.prepare(QStringLiteral(
        "INSERT INTO transactions(item_id, delta, reason, quantity_after, column_id) VALUES(?, ?, ?, ?, ?)"));
    q.addBindValue(itemId);
    q.addBindValue(delta);
    q.addBindValue(reason.trimmed());
    q.addBindValue(after);
    q.addBindValue(columnId);
    const bool ok2 = q.exec();

    if (ok1 && ok2) {
        m_db.commit();
    } else {
        m_db.rollback();
        emit operationFailed(tr("Could not update value"));
        return false;
    }

    if (m_selectedStockId >= 0)
        m_itemModel->reload(m_selectedStockId);
    if (m_historyItemId == itemId)
        m_historyModel->reload(itemId);
    return true;
}

void AppController::showHistory(int itemId)
{
    m_historyItemId = itemId;
    m_historyModel->reload(itemId);
}
