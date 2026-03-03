import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.platform as QtLabs
import org.kde.kcmutils
import org.kde.plasma.plasmoid
import org.kde.ksvg 1.0 as KSvg
import org.kde.kirigami 2 as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.private.sessions 2.0 as Sessions
import org.kde.taskmanager 0.1 as TaskManager
import org.kde.plasma.plasma5support as Plasma5Support

AbstractButton {
    id: menuButton

    readonly property string appStoreCommand: Plasmoid.configuration.appStoreCommand
        ?? Plasmoid.configuration.appStoreCommandDefault
    readonly property string aboutThisPCCommand: Plasmoid.configuration.aboutThisPCCommand
        ?? Plasmoid.configuration.aboutThisPCCommandDefault
    readonly property bool aboutThisPCUseCommand: Plasmoid.configuration.aboutThisPCUseCommand
        ?? Plasmoid.configuration.aboutThisPCUseCommandDefault
    readonly property string systemSettingsCommand: Plasmoid.configuration.systemSettingsCommand
        ?? Plasmoid.configuration.systemSettingsCommandDefault
    readonly property bool systemSettingsUseCommand: Plasmoid.configuration.systemSettingsUseCommand
        ?? Plasmoid.configuration.systemSettingsUseCommandDefault

    readonly property var customCommandsConfig: Plasmoid.configuration.commands
    readonly property bool customCommandsInSeparateMenu: Plasmoid.configuration.customCommandsInSeparateMenu
        ?? Plasmoid.configuration.customCommandsInSeparateMenuDefault
    readonly property string customCommandsMenuTitle: Plasmoid.configuration.customCommandsMenuTitle ?? ""

    property var customCommands: []

    enum State {
        Rest,
        Hover,
        Down
    }
    property int menuState: {
        if (down) {
            return MainMenuButton.State.Down;
        } else if (hovered && !menu.isOpened) {
            return MainMenuButton.State.Hover;
        }
        return MainMenuButton.State.Rest;
    }

    Connections {
        target: Plasmoid
        function onActivated() {
            Plasmoid.configuration.shortcutOpensPlasmoid
                ? menuButton.clicked()
                : forceQuit.show()
        }
    }

    Sessions.SessionManagement {
        id: sm
    }

    TaskManager.TasksModel {
        id: tasksModel
    }

    KCoreAddons.KUser {
        id: kUser
    }

    ListModel {
        id: recentItemsModel
    }

    TaskManager.TasksModel {
        id: recentTasksModel
        sortMode: TaskManager.TasksModel.SortLastActivated
        groupMode: TaskManager.TasksModel.GroupApplications
    }

    function updateRecentItems() {
        // Use currently running applications as recent items
        recentItemsModel.clear()
        const seenApps = new Set()
        const maxItems = 10
        let count = 0
        
        for (let i = 0; i < recentTasksModel.count && count < maxItems; i++) {
            const modelIndex = recentTasksModel.makeModelIndex(i)
            const appName = recentTasksModel.data(modelIndex, TaskManager.AbstractTasksModel.AppName)
            const appIcon = recentTasksModel.data(modelIndex, TaskManager.AbstractTasksModel.DecorationRole)
            const appPid = recentTasksModel.data(modelIndex, TaskManager.AbstractTasksModel.AppPid)
            
            if (appName && !seenApps.has(appName)) {
                seenApps.add(appName)
                // Try to get the desktop file name
                const desktopFile = recentTasksModel.data(modelIndex, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon)
                recentItemsModel.append({
                    name: appName,
                    icon: appIcon || "application-x-executable",
                    command: desktopFile ? "kioclient5 exec " + desktopFile : null,
                    desktopFile: desktopFile
                })
                count++
            }
        }
    }

    Connections {
        target: recentTasksModel
        function onCountChanged() {
            updateRecentItems()
        }
    }

    Component.onCompleted: {
        updateRecentItems()
    }

    function formatMacShortcut(shortcutString) {
        if (!shortcutString) return ""
        return shortcutString
            .replace(/Meta/g, "⌘")
            .replace(/Ctrl/g, "^")
            .replace(/Alt/g, "⌥")
            .replace(/Delete/g, "⌫")
    }

    onCustomCommandsConfigChanged: {
        let commands = [];
        for (const command of Plasmoid.configuration.commands ?? []) {
            const data = JSON.parse(command)
            commands.push(data)
        }
        customCommands = commands
    }
    onCustomCommandsChanged: {
        customMenuEntries.clear()
        for (const command of customCommands) {
            customMenuEntries.append(command);
        }
    }

    onClicked: {
        menu.isOpened ? menu.close() : menu.open(root)
    }

    Layout.preferredHeight: root.height
    Layout.preferredWidth: Plasmoid.configuration.useRectangleButtonShape
        ? Layout.preferredHeight * 1.5
        : Layout.preferredHeight

    contentItem: Item {
        width: parent.width
        height: parent.height
        Kirigami.Icon {
            id: menuIcon
            anchors.centerIn: parent
            source: root.icon
            height: {
                if (Plasmoid.configuration.useFixedIconSize) {
                    if (Plasmoid.configuration.resizeIconToRoot) {
                        return Plasmoid.configuration.fixedIconSize > root.height
                            ? root.height
                            : Plasmoid.configuration.fixedIconSize
                    }
                    return Plasmoid.configuration.fixedIconSize
                }
                return parent.height * (Plasmoid.configuration.iconSizePercent / 100)
            }
            width: height
        }
    }

    down: menu.isOpened

    background: KSvg.FrameSvgItem {
        id: rest
        height: parent.height
        width: parent.width
        imagePath: "widgets/menubaritem"
        prefix: switch (menuButton.menuState) {
            case MainMenuButton.State.Down: return "pressed";
            case MainMenuButton.State.Hover: return "hover";
            case MainMenuButton.State.Rest: return "normal";
        }
    }

    QtLabs.Menu {
        id: menu
        property bool isOpened: false
        readonly property int customCommandsEntryStartIndex: 2
        
        // Invisible item to force minimum width
        QtLabs.MenuItem {
            visible: false
            text: "                                                                        " // Spaces to force width
        }
        
        QtLabs.MenuItem {
            id: aboutThisPCMenuItem
            text: i18n("About This Pear")
            icon.name: "computer"
            onTriggered: menuButton.aboutThisPCUseCommand
                ? executable.exec(menuButton.aboutThisPCCommand)
                : KCMLauncher.openInfoCenter("")
        }

        QtLabs.MenuSeparator {}
        ListModel {
            id: customMenuEntries
            Component.onCompleted: {
                for (const command of customCommands) {
                    customMenuEntries.append(command);
                }
            }
        }
        QtLabs.Menu {
            id: customCommandsSubMenu
            enabled: menuButton.customCommandsInSeparateMenu && customMenuEntries.length > 0
            visible: menuButton.customCommandsInSeparateMenu
            title: menuButton.customCommandsMenuTitle?.length > 0 ? menuButton.customCommandsMenuTitle : i18n("Commands")
            Instantiator {
                model: menuButton.customCommandsInSeparateMenu ? customMenuEntries : []
                active: menuButton.customCommandsInSeparateMenu
                delegate: QtLabs.MenuItem {
                    text: model.text
                    icon.name: "application-x-executable"
                    onTriggered: {
                        executable.exec(model.command)
                    }
                }

                onObjectAdded: (index, object) => customCommandsSubMenu.insertItem(
                    customCommandsSubMenu.customCommandsEntryStartIndex,
                    object
                )
                onObjectRemoved: (index, object) => customCommandsSubMenu.removeItem(object)
            }
        }
        Instantiator {
            model: menuButton.customCommandsInSeparateMenu ? [] : customMenuEntries
            active: !menuButton.customCommandsInSeparateMenu
            delegate: QtLabs.MenuItem {
                text: model.text
                icon.name: "application-x-executable"
                onTriggered: {
                    logic.openExec(model.command)
                }
            }

            onObjectAdded: (index, object) => menu.insertItem(menu.customCommandsEntryStartIndex, object)
            onObjectRemoved: (index, object) => menu.removeItem(object)
        }

        QtLabs.MenuSeparator {}

        QtLabs.MenuItem {
            id: systemSettingsMenuItem
            text: i18n("System Settings...                                    ")
            icon.name: "preferences-system"
            onTriggered: {
                menuButton.systemSettingsUseCommand
                    ? executable.exec(menuButton.systemSettingsCommand)
                    : KCMLauncher.openSystemSettings("")
            }
        }

        QtLabs.MenuItem {
            id: appStoreMenuItem
            text: i18n("App Store...")
            icon.name: "applications-other"
            onTriggered: executable.exec(menuButton.appStoreCommand)
        }

        QtLabs.MenuSeparator {}

        QtLabs.Menu {
            id: recentItemsMenu
            title: i18n("Recent Items")
            icon.name: "clock"
            enabled: recentItemsModel.count > 0
            visible: recentItemsModel.count > 0
            Instantiator {
                model: recentItemsModel
                delegate: QtLabs.MenuItem {
                    text: model.name || ""
                    icon.name: model.icon || "application-x-executable"
                    onTriggered: {
                        if (model.command) {
                            executable.exec(model.command)
                        } else if (model.desktopFile) {
                            executable.exec("kioclient5 exec " + model.desktopFile)
                        }
                    }
                }
                onObjectAdded: (index, object) => recentItemsMenu.insertItem(index, object)
                onObjectRemoved: (index, object) => recentItemsMenu.removeItem(object)
            }
        }

        QtLabs.MenuSeparator {}

        QtLabs.MenuItem {
            text: {
                const baseText = i18n("Force Quit...")
                const shortcut = Plasmoid.configuration.shortcutOpensPlasmoid ? null : plasmoid.globalShortcut
                return shortcut ? baseText + "\t" + menuButton.formatMacShortcut(shortcut.toString()) : baseText
            }
            icon.name: "application-exit"
            onTriggered: {
                root.forceQuit.show()
            }
            shortcut: Plasmoid.configuration.shortcutOpensPlasmoid ? null : plasmoid.globalShortcut
        }

        QtLabs.MenuSeparator {}

        QtLabs.MenuItem {
            visible: sm.canSuspend
            text: i18n("Sleep")
            icon.name: "system-suspend"
            onTriggered: sm.suspend()
        }
        QtLabs.MenuItem {
            text: i18n("Restart...")
            icon.name: "system-reboot"
            onTriggered: sm.requestReboot();
        }
        QtLabs.MenuItem {
            text: i18n("Shut Down...")
            icon.name: "system-shutdown"
            onTriggered: sm.requestShutdown();
        }

        QtLabs.MenuSeparator {}

        QtLabs.MenuItem {
            text: i18n("Lock Screen") + "\t" + menuButton.formatMacShortcut("Meta+L")
            icon.name: "system-lock-screen"
            shortcut: "Meta+L"
            onTriggered: sm.lock()
        }
        QtLabs.MenuItem {
            text: {
                i18n("Log Out %1...", kUser.fullName) + "\t" + menuButton.formatMacShortcut("Ctrl+Alt+Delete")
            }
            icon.name: "system-log-out"
            shortcut: "Ctrl+Alt+Delete"
            onTriggered: sm.requestLogout()
        }
        onAboutToHide: menu.isOpened = false
        onAboutToShow: menu.isOpened = true
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source)
        }

        function exec(cmd) {
            executable.connectSource(cmd)
        }
    }

    Connections {
    target: Plasmoid
        function onConfigurationChanged() {
            menu.forceLayout()
        }
    }
}
