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
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_items_stock ON items(stock_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_tx_item ON transactions(item_id)"),
    };

    for (const QString &sql : statements) {
        QSqlQuery q(m_db);
        if (!q.exec(sql)) {
            qWarning() << "Schema error:" << q.lastError().text() << sql;
            return false;
        }
    }

    // Migration: databases created before the magic word existed lack these columns.
    QSqlQuery info(m_db);
    QStringList columns;
    if (info.exec(QStringLiteral("PRAGMA table_info(users)"))) {
        while (info.next())
            columns << info.value(1).toString();
    }
    const QList<QPair<QString, QString>> migrations = {
        { QStringLiteral("magic_salt"),       QStringLiteral("BLOB") },
        { QStringLiteral("magic_hash"),       QStringLiteral("BLOB") },
        { QStringLiteral("magic_iterations"), QStringLiteral("INTEGER") },
    };
    for (const auto &m : migrations) {
        if (columns.contains(m.first))
            continue;
        QSqlQuery alter(m_db);
        if (!alter.exec(QStringLiteral("ALTER TABLE users ADD COLUMN %1 %2").arg(m.first, m.second))) {
            qWarning() << "Migration error:" << alter.lastError().text();
            return false;
        }
    }
    return true;
}
