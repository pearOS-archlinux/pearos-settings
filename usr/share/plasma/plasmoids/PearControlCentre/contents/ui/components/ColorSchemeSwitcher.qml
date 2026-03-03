import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.0

import org.kde.plasma.plasmoid
//import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami 

import "../lib" as Lib
import "../js/colorType.js" as ColorType

Lib.CardButton {
    id: colorSchemeSwitcher

    visible: root.showColorSwitcher
    Layout.fillHeight: true
    Layout.fillWidth: true
    title: i18n("Dark Theme")
    
    property string stateFile: "/usr/share/extras/system-settings/themeswitcher/state"
    property string scriptPath: "/usr/share/extras/system-settings/themeswitcher/kde-theme-switch.sh"
    property bool isDarkMode: false

    property alias sourceColor: icon.sourceColor
    
    Lib.Icon {
        id: icon
        anchors.fill: parent
        fullSizeIcon: colorSchemeSwitcher.fullSizeIcon
        source: Qt.resolvedUrl("../icons/feather/dark-mode.svg")
        selected: colorSchemeSwitcher.isDarkMode
        customIcon: true
    }

    Component.onCompleted: {
        readState()
    }

    function readState() {
        stateReader.exec("cat " + stateFile)
    }

    onClicked: {
        scriptExec.exec(scriptPath)
        // Read state after a short delay to allow script to update file
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: readState()
    }

    Plasma5Support.DataSource {
        id: stateReader
        engine: "executable"
        connectedSources: []
        onNewData: {
            if (data["exit code"] == 0) {
                var state = data.stdout.trim()
                colorSchemeSwitcher.isDarkMode = (state === "dark")
            }
            disconnectSource(sourceName)
        }
        
        function exec(cmd) {
            connectSource(cmd)
        }
    }

    Plasma5Support.DataSource {
        id: scriptExec
        engine: "executable"
        connectedSources: []
        onNewData: {
            disconnectSource(sourceName)
        }
        
        function exec(cmd) {
            connectSource(cmd)
        }
    }
}
