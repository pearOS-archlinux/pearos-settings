/*
    SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Window 2.15
// Deliberately imported after QtQuick to avoid missing restoreMode property in Binding. Fix in Qt 6.
import QtQml 2.15

import org.kde.plasma.plasmoid 2.0
import org.kde.kquickcontrolsaddons 2.0 // For KCMShell
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.private.appmenu 1.0 as AppMenuPrivate
import org.kde.kirigami 2.5 as Kirigami
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.taskmanager 0.1 as TaskManager

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool view: Plasmoid.configuration.compactView

    onViewChanged: {
        Plasmoid.view = view;
    }

    Plasmoid.constraintHints: Plasmoid.CanFillArea
    preferredRepresentation: Plasmoid.configuration.compactView ? compactRepresentation : fullRepresentation

    // Only exists because the default CompactRepresentation doesn't expose a
    // way to mark its icon as disabled.
    // TODO remove once it gains that feature.
    compactRepresentation: PlasmaComponents3.ToolButton {
        readonly property int fakeIndex: 0
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.minimumWidth: implicitWidth
        Layout.maximumWidth: implicitWidth
        enabled: appMenuModel.menuAvailable || shouldShowBasicMenu
        checkable: (appMenuModel.menuAvailable || shouldShowBasicMenu) && Plasmoid.currentIndex === fakeIndex
        checked: checkable
        icon.name: "application-menu"

        display: PlasmaComponents3.AbstractButton.IconOnly
        text: Plasmoid.title
        Accessible.description: toolTipSubText

        onClicked: Plasmoid.trigger(this, 0);
    }

    fullRepresentation: GridLayout {
        id: buttonGrid

        Plasmoid.status: {
            if (appMenuModel.menuAvailable && Plasmoid.currentIndex > -1 && buttonRepeater.count > 0) {
                return PlasmaCore.Types.NeedsAttentionStatus;
            } else {
                return buttonRepeater.count > 0 || basicMenuRepeater.count > 0 || Plasmoid.configuration.compactView ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus;
            }
        }

        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight

        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: 0
        columnSpacing: 0

        Binding {
            target: plasmoid
            property: "buttonGrid"
            value: buttonGrid
            restoreMode: Binding.RestoreNone
        }

        Connections {
            target: Plasmoid
            function onRequestActivateIndex(index: int) {
                const button = buttonRepeater.itemAt(index);
                if (button) {
                    button.activated();
                }
            }
        }

        Connections {
            target: Plasmoid
            function onActivated() {
                const button = buttonRepeater.itemAt(0);
                if (button) {
                    button.activated();
                }
            }
        }

        PlasmaComponents3.ToolButton {
            id: noMenuPlaceholder
            visible: buttonRepeater.count === 0 && basicMenuRepeater.count === 0
            text: Plasmoid.title
            Layout.fillWidth: root.vertical
            Layout.fillHeight: !root.vertical
        }

        Repeater {
            id: buttonRepeater
            model: appMenuModel.visible ? appMenuModel : null

            MenuDelegate {
                readonly property int buttonIndex: index

                Layout.fillWidth: root.vertical
                Layout.fillHeight: !root.vertical
                text: activeMenu
                Kirigami.MnemonicData.active: altState.pressed

                down: pressed || Plasmoid.currentIndex === index
                visible: text !== "" && model.activeActions.visible

                menuIsOpen: Plasmoid.currentIndex !== -1
                onActivated: Plasmoid.trigger(this, index)

                // So we can show mnemonic underlines only while Alt is pressed
                KeyboardIndicator.KeyState {
                    id: altState
                    key: Qt.Key_Alt
                }
            }
        }
        
        // Basic menu - DOAR când nu există meniul real - TREBUIE să fie în interiorul fullRepresentation
        Repeater {
            id: basicMenuRepeater
            model: shouldShowBasicMenu ? basicMenuModel : null

            MenuDelegate {
                readonly property int buttonIndex: index
                readonly property bool isFileMenu: menuName === "File"
                readonly property bool isEditMenu: menuName === "Edit"
                readonly property bool isViewMenu: menuName === "View"
                readonly property bool isGoMenu: menuName === "Go"
                readonly property bool isWindowMenu: menuName === "Window"
                readonly property bool isHelpMenu: menuName === "Help"
                id: menuButton

                Layout.fillWidth: root.vertical
                Layout.fillHeight: !root.vertical
                text: menuName
                Kirigami.MnemonicData.active: altState.pressed

                down: pressed
                visible: text !== ""

                menuIsOpen: (isFileMenu && fileMenu.status === PlasmaExtras.Menu.Open) || 
                           (isEditMenu && editMenu.status === PlasmaExtras.Menu.Open) ||
                           (isViewMenu && viewMenu.status === PlasmaExtras.Menu.Open) ||
                           (isGoMenu && goMenu.status === PlasmaExtras.Menu.Open) ||
                           (isWindowMenu && windowMenu.status === PlasmaExtras.Menu.Open) ||
                           (isHelpMenu && helpMenu.status === PlasmaExtras.Menu.Open)
                
                onActivated: {
                    if (isFileMenu) {
                        fileMenu.openRelative()
                    } else if (isEditMenu) {
                        editMenu.openRelative()
                    } else if (isViewMenu) {
                        viewMenu.openRelative()
                    } else if (isGoMenu) {
                        goMenu.openRelative()
                    } else if (isWindowMenu) {
                        windowMenu.openRelative()
                    } else if (isHelpMenu) {
                        helpMenu.openRelative()
                    }
                }

                KeyboardIndicator.KeyState {
                    id: altState
                    key: Qt.Key_Alt
                }
                
                PlasmaExtras.Menu {
                    id: fileMenu
                    visualParent: menuButton
                    placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
                    
                    PlasmaExtras.MenuItem {
                        text: "New Finder Window"
                        icon: "window-new"
                        onClicked: {
                            root.openNautilus()
                            fileMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "New Folder"
                        icon: "folder-new"
                        onClicked: {
                            root.createNewFolder()
                            fileMenu.close()
                        }
                    }
                }
                
                PlasmaExtras.Menu {
                    id: editMenu
                    visualParent: menuButton
                    placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
                    
                    PlasmaExtras.MenuItem {
                        text: "Undo\t⌘Z"
                        onClicked: {
                            root.undo()
                            editMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Redo\t⇧⌘Z"
                        onClicked: {
                            root.redo()
                            editMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Cut\t⌘X"
                        icon: "edit-cut"
                        onClicked: {
                            root.cut()
                            editMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Copy\t⌘C"
                        icon: "edit-copy"
                        onClicked: {
                            root.copy()
                            editMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Paste\t⌘V"
                        icon: "edit-paste"
                        onClicked: {
                            root.paste()
                            editMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Select All\t⌘A"
                        onClicked: {
                            root.selectAll()
                            editMenu.close()
                        }
                    }
                }
                
                PlasmaExtras.Menu {
                    id: viewMenu
                    visualParent: menuButton
                    placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
                    
                    PlasmaExtras.MenuItem {
                        text: "Show Toolbar"
                        icon: "view-visible"
                        checkable: true
                        checked: true
                        onClicked: {
                            viewMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Show Sidebar"
                        icon: "sidebar-show-symbolic"
                        checkable: true
                        checked: true
                        onClicked: {
                            viewMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Show Hidden Files"
                        icon: "show-hidden-symbolic"
                        checkable: true
                        onClicked: {
                            viewMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Zoom In\t⌘+"
                        icon: "zoom-in"
                        onClicked: {
                            root.sendKeyShortcut("super+equal")
                            viewMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Zoom Out\t⌘-"
                        icon: "zoom-out"
                        onClicked: {
                            root.sendKeyShortcut("super+minus")
                            viewMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Actual Size\t⌘0"
                        icon: "zoom-fit-best"
                        onClicked: {
                            root.sendKeyShortcut("super+0")
                            viewMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Refresh\t⌘R"
                        icon: "view-refresh"
                        onClicked: {
                            root.sendKeyShortcut("super+r")
                            viewMenu.close()
                        }
                    }
                }
                
                PlasmaExtras.Menu {
                    id: goMenu
                    visualParent: menuButton
                    placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
                    
                    onStatusChanged: {
                        if (status === PlasmaExtras.Menu.Open) {
                            root.loadRecentFolders()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Back\t⌘["
                        onClicked: {
                            root.goBack()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Forward\t⌘]"
                        onClicked: {
                            root.goForward()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Recents\t⇧⌘F"
                        onClicked: {
                            root.openRecents()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Documents\t⇧⌘O"
                        onClicked: {
                            root.openDocuments()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Desktop\t⇧⌘D"
                        onClicked: {
                            root.openDesktop()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Downloads\t⌥⌘L"
                        onClicked: {
                            root.openDownloads()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Home\t⇧⌘H"
                        onClicked: {
                            root.openHome()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Computer\t⇧⌘C"
                        onClicked: {
                            root.openComputer()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Applications\t⇧⌘A"
                        onClicked: {
                            root.openApplications()
                            goMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        id: recentFoldersMenuItem
                        text: "Recent Folders"
                        
                        property PlasmaExtras.Menu recentFoldersSubmenu: PlasmaExtras.Menu {
                            id: goMenuRecentFoldersSubmenu
                            visualParent: recentFoldersMenuItem.action
                            
                            property var menuItems: []
                            
                            function refreshItems() {
                                menuItems.forEach(function(item) {
                                    removeMenuItem(item)
                                    item.destroy()
                                })
                                menuItems = []
                                
                                for (var i = 0; i < recentFoldersModel.count; i++) {
                                    var item = recentFoldersModel.get(i)
                                    var menuItem = Qt.createQmlObject(
                                        'import org.kde.plasma.extras 2.0 as PlasmaExtras; PlasmaExtras.MenuItem { text: "' + 
                                        item.name.replace(/"/g, '\\"') + '"; property string path: "' + 
                                        item.path.replace(/"/g, '\\"') + '"; onClicked: { root.openRecentFolder(path); goMenuRecentFoldersSubmenu.close(); goMenu.close(); } }',
                                        goMenuRecentFoldersSubmenu
                                    )
                                    addMenuItem(menuItem)
                                    menuItems.push(menuItem)
                                }
                            }
                            
                            onStatusChanged: {
                                if (status === PlasmaExtras.Menu.Open) {
                                    root.loadRecentFolders()
                                }
                            }
                            
                            Component.onCompleted: {
                                recentFoldersModel.onCountChanged.connect(function() {
                                    refreshItems()
                                })
                            }
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Go to Folder…\t⇧⌘G"
                        onClicked: {
                            root.openGoToFolder()
                            goMenu.close()
                        }
                    }
                }
                
                PlasmaExtras.Menu {
                    id: windowMenu
                    visualParent: menuButton
                    placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
                    
                    PlasmaExtras.MenuItem {
                        text: "Minimize\t⌘M"
                        icon: "window-minimize"
                        enabled: tasksModel.activeTask !== null && (tasksModel.data(tasksModel.activeTask, TaskManager.AbstractTasksModel.IsMinimizable) || false)
                        onClicked: {
                            if (tasksModel.activeTask !== null) {
                                tasksModel.requestToggleMinimized(tasksModel.activeTask)
                            }
                            windowMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Zoom\t⌥⌘Z"
                        icon: "window-maximize"
                        enabled: tasksModel.activeTask !== null && (tasksModel.data(tasksModel.activeTask, TaskManager.AbstractTasksModel.IsMaximizable) || false)
                        checkable: true
                        checked: tasksModel.activeTask !== null && (tasksModel.data(tasksModel.activeTask, TaskManager.AbstractTasksModel.IsMaximized) || false)
                        onClicked: {
                            if (tasksModel.activeTask !== null) {
                                tasksModel.requestToggleMaximized(tasksModel.activeTask)
                            }
                            windowMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Close Window\t⌘W"
                        icon: "window-close"
                        enabled: tasksModel.activeTask !== null && (tasksModel.data(tasksModel.activeTask, TaskManager.AbstractTasksModel.IsClosable) || false)
                        onClicked: {
                            if (tasksModel.activeTask !== null) {
                                tasksModel.requestClose(tasksModel.activeTask)
                            }
                            windowMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        separator: true
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Bring All to Front"
                        icon: "view-restore"
                        onClicked: {
                            for (var i = 0; i < tasksModel.count; i++) {
                                var taskIndex = tasksModel.index(i, 0)
                                if (taskIndex !== null && tasksModel.data(taskIndex, TaskManager.AbstractTasksModel.IsWindow)) {
                                    tasksModel.requestActivate(taskIndex)
                                }
                            }
                            windowMenu.close()
                        }
                    }
                }
                
                PlasmaExtras.Menu {
                    id: helpMenu
                    visualParent: menuButton
                    placement: PlasmaExtras.Menu.BottomPosedLeftAlignedPopup
                    
                    PlasmaExtras.MenuItem {
                        text: "Donate"
                        icon: Qt.resolvedUrl("icons/heart-outline.svg")
                        onClicked: {
                            root.openUrl("https://pearos.xyz/donate")
                            helpMenu.close()
                        }
                    }
                    
                    PlasmaExtras.MenuItem {
                        text: "Join pearOS Discord"
                        icon: "irc-join-channel"
                        onClicked: {
                            root.openUrl("https://discord.gg/7jfh8MPDMR")
                            helpMenu.close()
                        }
                    }
                }
            }
        }
        
        Item {
            Layout.preferredWidth: 0
            Layout.preferredHeight: 0
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    AppMenuPrivate.AppMenuModel {
        id: appMenuModel
        containmentStatus: Plasmoid.containment.status
        screenGeometry: root.screenGeometry
        onRequestActivateIndex: Plasmoid.requestActivateIndex(index)
        Component.onCompleted: {
            Plasmoid.model = appMenuModel;
        }
    }
    
    // Proprietate pentru basic menu - DOAR când nu există meniul real
    readonly property bool shouldShowBasicMenu: !appMenuModel.menuAvailable && !appMenuModel.visible
    
    // TaskManager pentru gestionarea ferestrelor (folosit de Window menu)
    TaskManager.TasksModel {
        id: tasksModel
        screenGeometry: root.screenGeometry
    }
    
    // Executare comenzi shell
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
        }
    }
    
    function executeCommand(cmd) {
        executable.connectSource(cmd)
    }
    
    function openNautilus() {
        executeCommand("nautilus --new-window")
    }
    
    function createNewFolder() {
        executeCommand("cd ~/Desktop && name='New Folder' && counter=1 && while [ -d \"$name\" ]; do name=\"New Folder $counter\"; counter=$((counter+1)); done && mkdir -p \"$name\"")
    }
    
    function sendKeyShortcut(keys) {
        executeCommand("xdotool key " + keys)
    }
    
    function undo() {
        sendKeyShortcut("ctrl+z")
    }
    
    function redo() {
        sendKeyShortcut("ctrl+shift+z")
    }
    
    function cut() {
        sendKeyShortcut("ctrl+x")
    }
    
    function copy() {
        sendKeyShortcut("ctrl+c")
    }
    
    function paste() {
        sendKeyShortcut("ctrl+v")
    }
    
    function selectAll() {
        sendKeyShortcut("ctrl+a")
    }
    
    function goBack() {
        sendKeyShortcut("XF86Back")
    }
    
    function goForward() {
        sendKeyShortcut("XF86Forward")
    }
    
    function openRecents() {
        executeCommand("nautilus --new-window \"$(xdg-user-dir RECENT)\"")
    }
    
    function openDocuments() {
        executeCommand("nautilus --new-window \"$(xdg-user-dir DOCUMENTS)\"")
    }
    
    function openDesktop() {
        executeCommand("nautilus --new-window \"$(xdg-user-dir DESKTOP)\"")
    }
    
    function openDownloads() {
        executeCommand("nautilus --new-window \"$(xdg-user-dir DOWNLOAD)\"")
    }
    
    function openHome() {
        executeCommand("nautilus --new-window \"$HOME\"")
    }
    
    function openComputer() {
        executeCommand("nautilus --new-window computer://")
    }
    
    function openApplications() {
        executeCommand("nautilus --new-window applications://")
    }
    
    function openFolderPath(path) {
        if (path && path.trim() !== "") {
            var normalizedPath = path.trim()
            if (normalizedPath.startsWith("~")) {
                normalizedPath = normalizedPath.replace("~", "$HOME")
            }
            executeCommand("bash -c 'nautilus \"" + normalizedPath.replace(/"/g, '\\"') + "\"'")
        }
    }
    
    function openRecentFolder(path) {
        openFolderPath(path)
    }
    
    function openUrl(url) {
        Qt.openUrlExternally(url)
    }
    
    property var goToFolderDialogInstance: null
    
    function openGoToFolder() {
        if (goToFolderDialogInstance) {
            goToFolderDialogInstance.destroy()
        }
        goToFolderDialogInstance = goToFolderDialogComponent.createObject(root)
        if (goToFolderDialogInstance) {
            goToFolderDialogInstance.show()
        }
    }
    
    ListModel {
        id: recentFoldersModel
    }
    
    Plasma5Support.DataSource {
        id: recentFoldersReader
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            if (data["exit code"] === 0 && data["stdout"]) {
                var output = data["stdout"].toString().trim()
                if (output) {
                    var lines = output.split('\n')
                    recentFoldersModel.clear()
                    var count = 0
                    var maxFiles = 10
                    for (var i = 0; i < lines.length && count < maxFiles; i++) {
                        var line = lines[i].trim()
                        if (line) {
                            var parts = line.split('|')
                            if (parts.length >= 2) {
                                recentFoldersModel.append({
                                    name: parts[0],
                                    path: parts[1]
                                })
                                count++
                            }
                        }
                    }
                }
            }
        }
    }
    
    function loadRecentFolders() {
        var cmd = "python3 -c \"import xml.etree.ElementTree as ET, urllib.parse, os; tree = ET.parse(os.path.expanduser('~/.local/share/recently-used.xbel')); [print(os.path.basename(urllib.parse.unquote(b.get('href', '').replace('file://', ''))) + '|' + urllib.parse.unquote(b.get('href', '').replace('file://', ''))) for b in list(tree.findall('.//bookmark'))[:10] if b.get('href', '').startswith('file://') and os.path.exists(urllib.parse.unquote(b.get('href', '').replace('file://', '')))]\" 2>/dev/null"
        recentFoldersReader.connectSource(cmd)
    }
    
    ListModel {
        id: basicMenuModel
        ListElement { menuName: "File" }
        ListElement { menuName: "Edit" }
        ListElement { menuName: "View" }
        ListElement { menuName: "Go" }
        ListElement { menuName: "Window" }
        ListElement { menuName: "Help" }
    }

    Component {
        id: goToFolderDialogComponent
        
        Window {
            id: dialog
            flags: Qt.Dialog | Qt.WindowStaysOnTopHint
            title: i18n("Go to Folder")
            width: 500
            height: 150
            modality: Qt.WindowModal
            
            color: Kirigami.Theme.backgroundColor
            
            Component.onCompleted: {
                var screen = Qt.application.screens[0]
                dialog.x = (screen.width - dialog.width) / 2
                dialog.y = (screen.height - dialog.height) / 2
            }
            
            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.backgroundColor
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing
                
                    QQC2.Label {
                        text: i18n("Enter folder path:")
                        Layout.fillWidth: true
                    }
                    
                    QQC2.TextField {
                        id: folderPathInput
                        Layout.fillWidth: true
                        placeholderText: i18n("e.g., /home/user/Documents or ~/Documents")
                        focus: true
                        
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                root.openFolderPath(folderPathInput.text)
                                dialog.close()
                            } else if (event.key === Qt.Key_Escape) {
                                dialog.close()
                            }
                        }
                    }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: Kirigami.Units.smallSpacing
                        
                        QQC2.Button {
                            text: i18n("Cancel")
                            onClicked: dialog.close()
                        }
                        
                        QQC2.Button {
                            text: i18n("OK")
                            onClicked: {
                                root.openFolderPath(folderPathInput.text)
                                dialog.close()
                            }
                        }
                    }
                }
            }
            
            onClosing: {
                dialog.destroy()
            }
        }
    }
}
