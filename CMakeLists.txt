cmake_minimum_required(VERSION 3.21)
project(WarehouseDashboard VERSION 0.1 LANGUAGES CXX)
if(WIN32)
    enable_language(RC)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Sql)

qt_standard_project_setup()

set_source_files_properties(
    qml/theme/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

set(APP_SOURCES main.cpp)
if(WIN32)
    list(APPEND APP_SOURCES appicon.rc)   # embeds the .exe icon
endif()

qt_add_executable(appWarehouseDashboard
    ${APP_SOURCES}
    src/core/DatabaseManager.h
    src/core/DatabaseManager.cpp
    src/core/AppController.h
    src/core/AppController.cpp
    src/models/StockModel.h
    src/models/StockModel.cpp
    src/models/ItemModel.h
    src/models/ItemModel.cpp
    src/models/ItemFilterModel.h
    src/models/ItemFilterModel.cpp
    src/models/HistoryModel.h
    src/models/HistoryModel.cpp
)

qt_add_qml_module(appWarehouseDashboard
    URI WarehouseDashboard
    VERSION 1.0
    QML_FILES
        Main.qml
        qml/theme/Theme.qml
        qml/components/GlassPanel.qml
        qml/components/GlassButton.qml
        qml/components/GlassTextField.qml
        qml/components/GlassDialog.qml
        qml/components/Stepper.qml
        qml/components/StockEditDialog.qml
        qml/components/Icon.qml
        qml/components/TitleBar.qml
        qml/pages/LoginPage.qml
        qml/pages/StockListPage.qml
        qml/pages/StockDetailPage.qml
)

qt_add_resources(appWarehouseDashboard "icons"
    PREFIX "/icons"
    FILES
        assets/icons/app.png
        assets/icons/warehouse.svg
        assets/icons/package.svg
        assets/icons/trash.svg
        assets/icons/lock.svg
        assets/icons/history.svg
        assets/icons/eye.svg
        assets/icons/eye-off.svg
        assets/icons/arrow-left.svg
        assets/icons/warning.svg
        assets/icons/plus.svg
        assets/icons/minus.svg
        assets/icons/search.svg
        assets/icons/edit.svg
        assets/icons/close.svg
        assets/icons/window-maximize.svg
        assets/icons/window-restore.svg
)

target_include_directories(appWarehouseDashboard PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/models
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
)

target_link_libraries(appWarehouseDashboard PRIVATE Qt6::Quick Qt6::Sql Qt6::Core)

if(WIN32)
    set_target_properties(appWarehouseDashboard PROPERTIES WIN32_EXECUTABLE TRUE)
endif()
