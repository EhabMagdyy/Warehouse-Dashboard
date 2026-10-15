#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QIcon>
#include <QWindow>

#include "src/core/DatabaseManager.h"
#include "src/core/AppController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("WarehouseDashboard");
    QGuiApplication::setOrganizationName("AFA Nozom");
    // Wayland matches the window to its .desktop file (and so its icon) by this name
    QGuiApplication::setDesktopFileName(QStringLiteral("WarehouseDashboard"));

    const QIcon appIcon(QStringLiteral(":/icons/assets/icons/app.png"));
    if (appIcon.isNull())
        qWarning() << "App icon failed to load - re-run CMake so the resource is rebuilt";
    QGuiApplication::setWindowIcon(appIcon);

    DatabaseManager db;
    if (!db.open()) {
        qFatal("Failed to open database at %s", qPrintable(db.dbPath()));
    }
    qInfo() << "Database:" << db.dbPath();

    AppController controller(db.database());

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("app", &controller);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);
    engine.loadFromModule("WarehouseDashboard", "Main");

    // set it on the actual window too, not just the application default
    for (QWindow *w : app.allWindows())
        w->setIcon(appIcon);

    return app.exec();
}
