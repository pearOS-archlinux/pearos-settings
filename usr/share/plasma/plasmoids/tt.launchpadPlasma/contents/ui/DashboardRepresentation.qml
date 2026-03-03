/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import Qt5Compat.GraphicalEffects
// Deliberately imported after QtQuick to avoid missing restoreMode property in Binding. Fix in Qt 6.
import QtQml 2.15

import org.kde.kquickcontrolsaddons 2.0
import org.kde.kwindowsystem 1.0
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.private.shell 2.0
import org.kde.kirigami 2.20 as Kirigami
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.private.kicker 0.1 as Kicker

import QtQuick.Controls
import QtQuick
import Qt5Compat.GraphicalEffects


import "code/tools.js" as Tools


Kicker.DashboardWindow {
    id: root

    property bool smallScreen: ((Math.floor(width / Kirigami.Units.iconSizes.huge) <= 22) || (Math.floor(height / Kirigami.Units.iconSizes.huge) <= 14))

    property int iconSize:{ switch(Plasmoid.configuration.appsIconSize){
        case 0: return Kirigami.Units.iconSizes.smallMedium;
        case 1: return Kirigami.Units.iconSizes.medium;
        case 2: return Kirigami.Units.iconSizes.large;
        case 3: return Kirigami.Units.iconSizes.huge;
        case 4: return Kirigami.Units.iconSizes.large *  2;
        case 5: return Kirigami.Units.iconSizes.enormous;
        default: return 64
        }
    }

    property int systemIconSize:{ switch(Plasmoid.configuration.systemIconSize){
        case 0: return Kirigami.Units.iconSizes.smallMedium;
        case 1: return Kirigami.Units.iconSizes.medium;
        case 2: return Kirigami.Units.iconSizes.large;
        case 3: return Kirigami.Units.iconSizes.huge;
        case 4: return Kirigami.Units.iconSizes.enormous;
        default: return 64
        }
    }

    property int cellSize: iconSize + (2 * Kirigami.Units.iconSizes.sizeForLabels)
                           + (2 * Kirigami.Units.largeSpacing)
                           + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                           highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property int columns: Plasmoid.configuration.useCustomGridSize ? 
                         Plasmoid.configuration.gridColumns : 
                         Math.floor(((smallScreen ? 85 : 80)/100) * Math.ceil(width / cellSize))
    
    property int maxRows: Plasmoid.configuration.useCustomGridSize ? 
                         Plasmoid.configuration.gridRows : 
                         Math.floor(height / cellSize)

    property int actualRows: Plasmoid.configuration.useCustomGridSize ? 
                            Math.min(Plasmoid.configuration.gridRows, Math.floor(height*0.7 / cellSize)) :
                            Math.floor(height*0.7 / cellSize)

    property int actualColumns: Plasmoid.configuration.useCustomGridSize ? 
                               Math.min(Plasmoid.configuration.gridColumns, Math.floor(width*0.7 / cellSize)) :
                               Math.floor(width*0.7 / cellSize)

    property int neededRows: {
        if (allAppsGrid.model && allAppsGrid.model.count > 0) {
            return Math.ceil(allAppsGrid.model.count / actualColumns);
        }
        return actualRows;
    }
    
    property int finalRows: Math.max(1, Math.min(actualRows, neededRows))
    
    property bool searching: searchField.text !== ""

    //keyEventProxy: searchField
    backgroundColor:  "transparent"


    onKeyEscapePressed: {
        if (searching) {
            searchField.clear();
        } else {
            root.toggle();
        }
    }

    onVisibleChanged: {
        if(visible){
            animatorMainColumn.start()
        }else{
            rootItem.opacity = 0
        }
        reset();
    }

    onSearchingChanged: {
        if (!searching) {
            //mainView.currentIndex = 1
            mainView.pop()
            reset();
        } else {
            mainView.push(runnerComponent)
            //mainView.currentIndex = 0
        }
    }

    function colorWithAlpha(color: color, alpha: real): color {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }



    function reset() {
        allAppsGrid.model = rootModel.modelForRow(2)

        allAppsGrid.currentIndex = -1
        systemFavoritesGrid.currentIndex = -1;

        allAppsGrid.forceLayout()

        searchField.clear();
        searchField.focus = true

    }

    mainItem: MouseArea {
        id: rootItem

        anchors.fill: parent

        acceptedButtons: Qt.LeftButton | Qt.RightButton

        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Rectangle{
            anchors.fill: parent
            color: Plasmoid.configuration.useCustomBackgroundColor ? 
                   Plasmoid.configuration.customBackgroundColor : 
                   Kirigami.Theme.backgroundColor
            opacity: Plasmoid.configuration.backgroundOpacity
        }


        Connections {
            target: kicker

            function onReset() {
                if (!root.searching) {
                    //filterList.applyFilter();
                    //funnelModel.reset();
                }
            }

            function onDragSourceChanged() {
                if (!kicker.dragSource) {
                    // FIXME TODO HACK: Reset all views post-DND to work around
                    // mouse grab bug despite QQuickWindow::mouseGrabberItem==0x0.
                    // Needs a more involved hunt through Qt Quick sources later since
                    // it's not happening with near-identical code in the menu repr.
                    rootModel.refresh();
                }
            }
        }

        Connections {
            target: Plasmoid
            function onUserConfiguringChanged() {
                if (Plasmoid.userConfiguring) {
                    root.hide()
                }
            }
        }

        PlasmaExtras.Menu {
            id: contextMenu

            PlasmaExtras.MenuItem {
                action: Plasmoid.internalAction("configure")
            }
        }

        Kirigami.Heading {
            id: dummyHeading

            visible: false

            width: 0

            level: 1
        }

        TextMetrics {
            id: headingMetrics

            font: dummyHeading.font
        }

        Kicker.FunnelModel {
            id: funnelModel

            onSourceModelChanged: {
                if (mainColumn.visible) {
                    mainGrid.currentIndex = -1;
                    mainGrid.forceLayout();
                }
            }
        }

        Kicker.ContainmentInterface {
            id: containmentInterface
        }

        TextField{
            id: searchField
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Kirigami.Units.largeSpacing * 8
            //focus: true
            width: Kirigami.Units.gridUnit * 13
            topPadding: Kirigami.Units.largeSpacing
            bottomPadding: Kirigami.Units.largeSpacing
            placeholderText: i18nc("@info:placeholder as in, 'start typing to initiate a search'", "Search")
            horizontalAlignment: TextInput.AlignHCenter
            wrapMode: Text.NoWrap
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 0.5

            onTextChanged: {
                runnerModel.query = searchField.text;
            }

            function clear() {
                text = "";
            }

            background: Rectangle {
                color: colorWithAlpha(Kirigami.Theme.backgroundColor,0.7)
                radius: 100
                border.width: 1
                border.color: colorWithAlpha(Kirigami.Theme.textColor,0.05)
            }

            function appendText(newText) {
                if (!root.visible) {
                    return;
                }
                focus = true;
                text = text + newText;
            }

            function backspace() {
                if (!root.visible) {
                    return;
                }
                focus = true;
                text = text.slice(0, -1);
            }

            function updateSelection() {
                if (!searchField.selectedText) {
                    return;
                }

                var delta = text.lastIndexOf(searchField.text, text.length - 2);
                searchHeading.select(searchField.selectionStart + delta, searchField.selectionEnd + delta);
            }
            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                    event.accepted = true;
                                    if(root.searching){
                                        mainView.currentItem.tryActivate(0,0)
                                        mainView.currentItem.forceActiveFocus()
                                    }
                                    else{
                                        allAppsGrid.tryActivate(0,0)
                                        allAppsGrid.forceActiveFocus()
                                    }
                                }
                            }
        }


        OpacityAnimator{ id: animatorMainColumn ;from: 0; to: 1 ; target: rootItem;}

        StackView {
            id: mainView
            width: (root.actualColumns * root.cellSize) + Kirigami.Units.largeSpacing
            height: (root.finalRows * root.cellSize) + Kirigami.Units.largeSpacing * 2
            anchors{
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: (searchField.height + searchField.anchors.topMargin) / 2 - 
                                     (Plasmoid.configuration.showSystemIcons === 1 ? 
                                      (systemFavoritesGrid.height + systemFavoritesGrid.anchors.bottomMargin) / 2 : 0)
            }

            initialItem:           Column {
                id: allAppsColumn
                clip: true
                spacing: Kirigami.Units.largeSpacing
                anchors.centerIn: parent

                ItemGridView {
                    id: allAppsGrid
                    width: root.actualColumns * root.cellSize
                    height: root.finalRows * root.cellSize
                    cellWidth: root.cellSize
                    cellHeight: root.cellSize
                    iconSize: root.iconSize
                    dropEnabled: false
                    verticalScrollBarPolicy: (model && model.count > finalRows * actualColumns) ? 
                                           PlasmaComponents.ScrollBar.AsNeeded : 
                                           PlasmaComponents.ScrollBar.AlwaysOff
                    horizontalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
                    clip: true

                    onKeyNavUp: {
                        allAppsGrid.focus = false
                        searchField.focus = true
                    }
                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Tab) {
                                            event.accepted = true;
                                            allAppsGrid.focus = false
                                            if (Plasmoid.configuration.showSystemIcons === 1) {
                                                systemFavoritesGrid.tryActivate(0,0)
                                                systemFavoritesGrid.forceActiveFocus()
                                            } else {
                                                searchField.focus = true
                                            }
                                        }
                                    }
                }
            }

            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }
            popEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to:1
                    duration: 200
                }
            }
            popExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to:0
                    duration: 200
                }
            }

        }

        Component {
            id: runnerComponent

            ItemGridView {
                id: runnerGrid
                anchors.centerIn: parent
                width: mainView.width
                clip: true
                height: mainView.height
                grabFocus: true
                cellWidth: root.cellSize
                cellHeight: root.cellSize
                iconSize: root.iconSize
                model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : undefined
                onKeyNavUp: {
                    runnerGrid.focus = false
                    searchField.focus = true
                }
                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Tab) {
                                        event.accepted = true;
                                        runnerGrid.focus = false
                                        if (Plasmoid.configuration.showSystemIcons === 1) {
                                            systemFavoritesGrid.tryActivate(0,0)
                                            systemFavoritesGrid.forceActiveFocus()
                                        } else {
                                            searchField.focus = true
                                        }
                                    }
                                }
            }

        }

        Rectangle{
            anchors.centerIn: systemFavoritesGrid
            height: systemFavoritesGrid.height + Kirigami.Units.largeSpacing
            width: systemFavoritesGrid.width + Kirigami.Units.largeSpacing
            color: Kirigami.Theme.backgroundColor
            radius: 10
            opacity: 0.6
            z:1
            visible: Plasmoid.configuration.showSystemIcons === 1
        }

        ItemGridView {
            id: systemFavoritesGrid
            visible: Plasmoid.configuration.showSystemIcons === 1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Kirigami.Units.largeSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true
            width: systemFavoritesGrid.model ? Math.min(Math.floor((root.width*0.85)/cellWidth)*cellWidth, systemFavoritesGrid.model.count*cellWidth) : 0
            height: cellHeight
            cellWidth: iconSize + Kirigami.Units.largeSpacing * 2
            cellHeight: cellWidth
            iconSize: root.systemIconSize
            z:2
            showLabels: false
            model: systemFavorites
            dragEnabled: false
            dropEnabled: false
            verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Tab) {
                                    event.accepted = true;
                                    systemFavoritesGrid.focus = false
                                    searchField.focus = true
                                }
                            }
            onKeyNavUp: {
                systemFavoritesGrid.focus = false
                if(root.searching){
                    mainView.currentItem.tryActivate(0,0)
                    mainView.currentItem.forceActiveFocus()
                }
                else{
                    allAppsGrid.tryActivate(0,0)
                    allAppsGrid.forceActiveFocus()
                }
            }
        }

        onPressed: mouse => {
                       if (mouse.button === Qt.RightButton) {
                           contextMenu.open(mouse.x, mouse.y);
                       }
                   }

        onClicked: mouse => {
                       if (mouse.button === Qt.LeftButton) {
                           root.toggle();
                       }
                   }
        Keys.onPressed: (event)=> {
                            if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                                searchField.focus = true;
                                return
                            }
                            if (event.key === Qt.Key_Escape) {
                                event.accepted = true;
                                if (root.searching) {
                                    reset();
                                } else {
                                    root.visible = false;
                                }
                                return;
                            }
                            if (searchField.focus) {
                                return;
                            }
                            if (event.key === Qt.Key_Backspace) {
                                event.accepted = true;
                                searchField.backspace();
                            }  else if (event.text !== "") {
                                event.accepted = true;
                                searchField.appendText(event.text);
                            }
                            //searchField.focus = true
                        }
    }

    Component.onCompleted: {
        rootModel.refresh();
        searchField.forceActiveFocus()
    }
}
