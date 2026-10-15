#pragma once

#include <QSqlDatabase>
#include <QString>

class DatabaseManager
{
public:
    bool open();
    QSqlDatabase database() const { return m_db; }
    QString dbPath() const { return m_dbPath; }

private:
    bool createSchema();

    QSqlDatabase m_db;
    QString m_dbPath;
};
