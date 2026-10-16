#include "DatabaseManager.h"

#include <QDebug>
#include <QDir>
#include <QList>
#include <QPair>
#include <QStringList>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

bool DatabaseManager::open()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    m_dbPath = dir + "/warehouse.db";

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(m_dbPath);
    if (!m_db.open()) {
        qWarning() << "Database open failed:" << m_db.lastError().text();
        return false;
    }

    QSqlQuery q(m_db);
    q.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
    q.exec(QStringLiteral("PRAGMA foreign_keys=ON"));

    return createSchema();
}

bool DatabaseManager::createSchema()
{
    const QStringList statements = {
        QStringLiteral(R"(
            CREATE TABLE IF NOT EXISTS users(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                salt BLOB NOT NULL,
                hash BLOB NOT NULL,
                iterations INTEGER NOT NULL,
                magic_salt BLOB,
                magic_hash BLOB,
                magic_iterations INTEGER,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
            ))"),
        QStringLiteral(R"(
            CREATE TABLE IF NOT EXISTS stocks(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                description TEXT DEFAULT '',
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
            ))"),
        QStringLiteral(R"(
            CREATE TABLE IF NOT EXISTS items(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                stock_id INTEGER NOT NULL REFERENCES stocks(id) ON DELETE CASCADE,
                name TEXT NOT NULL,
                quantity INTEGER NOT NULL DEFAULT 0,
                unit TEXT DEFAULT '',
                min_quantity INTEGER NOT NULL DEFAULT 0,
                notes TEXT DEFAULT '',
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
            ))"),
        QStringLiteral(R"(
            CREATE TABLE IF NOT EXISTS transactions(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                item_id INTEGER NOT NULL REFERENCES items(id),
                delta INTEGER NOT NULL,
                reason TEXT NOT NULL,
                quantity_after INTEGER NOT NULL,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
            ))"),
        // user-defined numeric columns (max 3 per stock), shown after QTY
        QStringLiteral(R"(
            CREATE TABLE IF NOT EXISTS custom_columns(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                stock_id INTEGER NOT NULL REFERENCES stocks(id) ON DELETE CASCADE,
                name TEXT NOT NULL,
                position INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))
            ))"),
        QStringLiteral(R"(
            CREATE TABLE IF NOT EXISTS item_values(
                item_id INTEGER NOT NULL REFERENCES items(id) ON DELETE CASCADE,
                column_id INTEGER NOT NULL REFERENCES custom_columns(id) ON DELETE CASCADE,
                value INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY(item_id, column_id)
            ))"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_items_stock ON items(stock_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_cols_stock ON custom_columns(stock_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_tx_item ON transactions(item_id)"),
    };

    for (const QString &sql : statements) {
        QSqlQuery q(m_db);
        if (!q.exec(sql)) {
            qWarning() << "Schema error:" << q.lastError().text() << sql;
            return false;
        }
    }

    // Migrations: add columns that older databases don't have yet.
    auto addColumnIfMissing = [this](const QString &table, const QString &column, const QString &type) {
        QSqlQuery info(m_db);
        if (info.exec(QStringLiteral("PRAGMA table_info(%1)").arg(table))) {
            while (info.next()) {
                if (info.value(1).toString() == column)
                    return true;
            }
        }
        QSqlQuery alter(m_db);
        if (!alter.exec(QStringLiteral("ALTER TABLE %1 ADD COLUMN %2 %3").arg(table, column, type))) {
            qWarning() << "Migration error:" << alter.lastError().text();
            return false;
        }
        return true;
    };

    // magic word (users)
    if (!addColumnIfMissing(QStringLiteral("users"), QStringLiteral("magic_salt"),       QStringLiteral("BLOB"))
        || !addColumnIfMissing(QStringLiteral("users"), QStringLiteral("magic_hash"),       QStringLiteral("BLOB"))
        || !addColumnIfMissing(QStringLiteral("users"), QStringLiteral("magic_iterations"), QStringLiteral("INTEGER")))
        return false;

    // which column a history entry belongs to (NULL = QTY)
    if (!addColumnIfMissing(QStringLiteral("transactions"), QStringLiteral("column_id"), QStringLiteral("INTEGER")))
        return false;
    return true;
}
