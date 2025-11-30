import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQml 2.15
import QtCore
import QtQuick.Window 2.15
import Qt.labs.platform 1.1 as Platform

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents

import org.kde.private.desktopcontainment.folder as Folder

PlasmoidItem {
    id: root

    Plasmoid.title: i18n("Folder Arc")
    Plasmoid.icon: "folder-download"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property int maxItems: Plasmoid.configuration.maxItems || 10
    property int totalItems: dirModel.count || 0
    property int remainingItems: Math.max(0, totalItems - maxItems)
    
    property int actualItemCount: 0
    
    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
        }
    }
Folder.FolderModel {
    id: dirModel
    previews: true

    // Setare corecta a folderului
    url: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/Downloads"

    onListingCompleted: {
        Qt.callLater(function() {
            root.totalItems = dirModel.count || 0
        })
    }
}

    Connections {
        target: Plasmoid.configuration
        function onFolderPathChanged() {
            dirModel.updateUrl()
        }
        function onMaxItemsChanged() {
        }
    }

    function openFile(url) {
        Qt.openUrlExternally(url)
    }

    function openFolderInFiles() {
        var path = dirModel.url.replace("file://", "")
        executable.connectSource("nautilus \"" + path.replace(/"/g, '\\"') + "\"")
    }

    // Buton compact pentru panel
    compactRepresentation: Item {
        id: compactRepresentationItem
        
        MouseArea {
            id: compactMouseArea
            anchors.fill: parent
            hoverEnabled: false
            acceptedButtons: Qt.LeftButton
            
            property bool wasExpanded: false
            
            onPressed: wasExpanded = root.expanded
            
            onClicked: {
                root.expanded = !wasExpanded
            }
        }

        Kirigami.Icon {
            anchors.fill: parent
            source: root.expanded ? "/usr/share/extras/folder-arc-open.png" : Plasmoid.icon
            active: false
        }

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: Plasmoid.title
            subText: i18np("One item", "%1 items", dirModel.count)
        }
    }

    Window {
        id: overlayWindow
        visible: root.expanded
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.Tool
        color: "transparent"
        modality: Qt.NonModal
        
        x: 0
        y: 0
        width: Qt.application.screens[0].virtualSize.width
        height: Qt.application.screens[0].virtualSize.height
        
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                root.expanded = false
            }
            z: -1000  // În spatele popup-ului
        }
    }

    fullRepresentation: Window {
        id: popupDialog
        
        property bool shouldBeVisible: root.expanded
        visible: shouldBeVisible
        
        Connections {
            target: root
            function onExpandedChanged() {
                if (!root.expanded) {
                    var maxDelay = (root.maxItems - 1) * 10 + 300 // delay + animation duration
                    closeWindowTimer.interval = maxDelay
                    closeWindowTimer.start()
                } else {
                    closeWindowTimer.stop()
                    popupDialog.shouldBeVisible = true
                }
            }
        }
        
        Timer {
            id: closeWindowTimer
            running: false
            onTriggered: {
                popupDialog.shouldBeVisible = false
            }
        }
        
        flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.Tool
        color: "transparent"
        modality: Qt.NonModal
        
        property Item visualParent: root.compactRepresentationItem || root
        
        function updatePosition() {
            if (!visualParent) return
            
            var globalPos = visualParent.mapToGlobal(0, 0)
            var screen = Qt.application.screens[0]
            
            if (Plasmoid.location === PlasmaCore.Types.BottomEdge) {
                popupDialog.x = globalPos.x + (visualParent.width / 2) - (popupContent.width / 2)
                popupDialog.y = globalPos.y - popupContent.height - Kirigami.Units.smallSpacing
            } else if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
                popupDialog.x = globalPos.x + (visualParent.width / 2) - (popupContent.width / 2)
                popupDialog.y = globalPos.y + visualParent.height + Kirigami.Units.smallSpacing
            } else {
                popupDialog.x = globalPos.x
                popupDialog.y = globalPos.y
            }
        }

        Item {
            id: popupContent
            focus: true
            
            property real baseWidth: Kirigami.Units.gridUnit * 20
            property real maxIndent: (root.maxItems + 0) * 1 + (Plasmoid.configuration.offset !== undefined ? Plasmoid.configuration.offset : -100) // max indentation for bottom item
            width: baseWidth + maxIndent
            height: Math.min(Kirigami.Units.gridUnit * 100, columnLayout.implicitHeight)
            
            Component.onCompleted: {
                popupDialog.width = width
                popupDialog.height = height
            }

            Keys.onEscapePressed: {
                root.expanded = false
            }
            
            onWidthChanged: {
                popupDialog.width = width
                popupDialog.updatePosition()
            }
            
            onHeightChanged: {
                popupDialog.height = height
                popupDialog.updatePosition()
            }

            ColumnLayout {
                id: columnLayout
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                    
                    property real indentAmount: 0
                    property real rotationStep: Plasmoid.configuration.rotationStep || 2
                    property real rotationAmount: root.maxItems * rotationStep
                    
                    PlasmaComponents.ItemDelegate {
                        id: showMoreItem
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: parent.indentAmount
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        rotation: parent.rotationAmount
                        
                        visible: {
                            var count = root.actualItemCount > 0 ? root.actualItemCount : (dirModel.count || 0)
                            var shouldShow = count > root.maxItems
                            return true  // TODO: inlocuie cu 'return shouldShow' dupa testingg
                        }

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        layoutDirection: Qt.LeftToRight

                        Item {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            
                            PlasmaComponents.Label {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: {
                                    var count = root.actualItemCount > 0 ? root.actualItemCount : (dirModel.count || 0)
                                    var remaining = Math.max(0, count - root.maxItems)
                                    return i18np("Show %1 more item in Files", "Show %1 more items in Files", remaining)
                                }
                                elide: Text.ElideRight
                                
                                background: Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: -8
                                    anchors.rightMargin: -8
                                    anchors.topMargin: -8
                                    anchors.bottomMargin: -8
                                    color: Kirigami.Theme.backgroundColor
                                    opacity: 0.2
                                    radius: 50
                                }
                            }
                        }

                        Item {
                            Layout.preferredWidth: Plasmoid.configuration.iconSize || 65
                            Layout.preferredHeight: Plasmoid.configuration.iconSize || 65
                            Layout.alignment: Qt.AlignRight

                            Kirigami.Icon {
                                anchors.fill: parent
                                source: "document-open"
                                smooth: true
                            }
                        }
                    }

                    onClicked: {
                        root.openFolderInFiles()
                        root.expanded = false
                    }

                        background: Rectangle {
                            color: "transparent"
                            radius: 4
                        }
                    }
                }

                Kirigami.Separator {
                    Layout.fillWidth: true
                    visible: remainingItems > 0 && dirModel.count > 0
                }

                Repeater {
                    id: visibleItems
                    model: dirModel
                    
                    onCountChanged: {
                        root.actualItemCount = count
                        root.totalItems = count
                    }
                    
                    Component.onCompleted: {
                        root.actualItemCount = count
                        root.totalItems = count
                    }

                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        visible: index < root.maxItems
                        
                        property real indentStep: Plasmoid.configuration.indentStep || 10
                        property real indentAmount: index * indentStep
                        property real rotationStep: Plasmoid.configuration.rotationStep || 2
                        property real rotationAmount: (root.maxItems - 1 - index) * rotationStep
                        
                        id: itemDelegate
                        
                        opacity: 0
                        property real startOffset: 30
                        property real currentOffset: startOffset
                        property bool shouldAnimate: false
                        
                        Behavior on opacity {
                            enabled: shouldAnimate
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Behavior on currentOffset {
                            enabled: shouldAnimate
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                        
                        Timer {
                            id: animationTimer
                            running: false
                            onTriggered: {
                                itemDelegate.shouldAnimate = true
                                itemDelegate.opacity = 1
                                itemDelegate.currentOffset = 0
                            }
                        }
                        
                        Timer {
                            id: closeAnimationTimer
                            running: false
                            onTriggered: {
                                itemDelegate.shouldAnimate = false
                                itemDelegate.currentOffset = 0
                                itemDelegate.opacity = 1
                                
                                startCloseAnimationTimer.start()
                            }
                        }
                        
                        Timer {
                            id: startCloseAnimationTimer
                            interval: 1
                            running: false
                            onTriggered: {
                                itemDelegate.shouldAnimate = true
                                itemDelegate.opacity = 0
                                itemDelegate.currentOffset = startOffset
                            }
                        }
                        
                        Connections {
                            target: root
                            function onExpandedChanged() {
                                if (root.expanded) {
                                    itemDelegate.opacity = 0
                                    itemDelegate.currentOffset = startOffset
                                    itemDelegate.shouldAnimate = false
                                    
                                    var delay = Math.max(0, (root.maxItems - 1 - index) * 10)
                                    
                                    animationTimer.interval = delay
                                    animationTimer.start()
                                } else {
                                    if (itemDelegate.opacity > 0) {
                                        itemDelegate.shouldAnimate = false
                                        itemDelegate.opacity = 1
                                        itemDelegate.currentOffset = 0
                                        
                                        var delay = Math.max(0, index * 10)
                                        
                                        closeAnimationTimer.interval = delay
                                        closeAnimationTimer.start()
                                    } else {
                                        itemDelegate.shouldAnimate = false
                                        animationTimer.stop()
                                        closeAnimationTimer.stop()
                                        startCloseAnimationTimer.stop()
                                    }
                                }
                            }
                        }
                        
                        Component.onCompleted: {
                            if (root.expanded && visible) {
                                itemDelegate.opacity = 0
                                itemDelegate.currentOffset = startOffset
                                
                                var delay = Math.max(0, (root.maxItems - 1 - index) * 10)
                                animationTimer.interval = delay
                                animationTimer.start()
                            }
                        }
                        
                        anchors.topMargin: currentOffset
                        
                        // Debug: red rect to check indentation
                        // Rectangle {
                        //     anchors.right: parent.right
                        //     width: indentAmount
                        //     height: parent.height
                        //     color: "red"
                        //     opacity: 0.5
                        //     z: 1
                        // }
                        
                        // Debug: debug text goes here
                        // Text {
                        //     anchors.right: parent.right
                        //     anchors.rightMargin: 5
                        //     anchors.top: parent.top
                        //     anchors.topMargin: 5
                        //     text: "idx:" + index + " indent:" + indentAmount + " max:" + root.maxItems
                        //     color: "white"
                        //     font.pixelSize: 10
                        //     z: 10
                        // }
                        
                        PlasmaComponents.ItemDelegate {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.rightMargin: indentAmount
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            rotation: rotationAmount
                            z: 0
                            
                            contentItem: RowLayout {
                                spacing: Kirigami.Units.smallSpacing
                                layoutDirection: Qt.LeftToRight

                            Item {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                
                                PlasmaComponents.Label {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    horizontalAlignment: Text.AlignRight
                                    text: model.display || ""
                                    elide: Text.ElideMiddle
                                    
                                    background: Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.leftMargin: -8
                                        anchors.rightMargin: -8
                                        anchors.topMargin: -8
                                        anchors.bottomMargin: -8
                                        color: Kirigami.Theme.backgroundColor
                                        opacity: 0.2
                                        radius: 50
                                    }
                                }
                            }

                            Item {
                                Layout.preferredWidth: Plasmoid.configuration.iconSize || 65
                                Layout.preferredHeight: Plasmoid.configuration.iconSize || 65
                                Layout.alignment: Qt.AlignRight

                                Kirigami.Icon {
                                    anchors.fill: parent
                                    source: model.decoration || (model.isDir ? "folder" : "text-plain")
                                    smooth: true
                                }
                            }
                        }

                            onClicked: {
                                var fileUrl = model.linkDestinationUrl || (dirModel.url + "/" + (model.display || ""))
                                root.openFile(fileUrl)
                                root.expanded = false
                            }

                            background: Rectangle {
                                color: "transparent"
                                radius: 4
                            }
                        }
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                z: -1
                propagateComposedEvents: false
                onWheel: {
                }
                onClicked: {
                    root.expanded = false
                }
            }
        }
        
        onVisibleChanged: {
            if (visible) {
                updatePosition()
                Qt.callLater(function() {
                    popupContent.forceActiveFocus()
                })
            }
        }
        
        onActiveChanged: {
            if (!active && visible) {
                root.expanded = false
            }
        }
        
        Connections {
            target: Qt.application
            function onAboutToQuit() {
                // n0thing
            }
        }
        
    }
}
