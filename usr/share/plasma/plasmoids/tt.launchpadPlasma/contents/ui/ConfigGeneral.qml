/*
    SPDX-FileCopyrightText: 2014 Eike Hein <hein@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.draganddrop 2.0 as DragDrop
import org.kde.kirigami 2.5 as Kirigami
import org.kde.iconthemes as KIconThemes
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols 2.0 as KQuickControls

KCM.SimpleKCM {
    id: configGeneral

    property bool isDash: (Plasmoid.pluginName === "org.kde.plasma.kickerdash")

    property string cfg_icon: Plasmoid.configuration.icon
    property bool cfg_useCustomButtonImage: Plasmoid.configuration.useCustomButtonImage
    property string cfg_customButtonImage: Plasmoid.configuration.customButtonImage

    property alias cfg_appNameFormat: appNameFormat.currentIndex
    property alias cfg_limitDepth: limitDepth.checked
    property alias cfg_alphaSort: alphaSort.checked
    property alias cfg_showIconsRootLevel: showIconsRootLevel.checked

    property alias cfg_recentOrdering: recentOrdering.currentIndex
    property alias cfg_showRecentApps: showRecentApps.checked
    property alias cfg_showRecentDocs: showRecentDocs.checked

    property alias cfg_useExtraRunners: useExtraRunners.checked
    property alias cfg_alignResultsToBottom: alignResultsToBottom.checked

    property alias cfg_appsIconSize: appsIconSize.currentIndex
    property alias cfg_systemIconSize: systemIconSize.currentIndex
    property alias cfg_showSystemIcons: showSystemIcons.currentIndex

    property alias cfg_gridColumns: gridColumns.value
    property alias cfg_gridRows: gridRows.value
    property alias cfg_useCustomGridSize: useCustomGridSize.checked
    property alias cfg_backgroundOpacity: backgroundOpacity.value
    property alias cfg_useCustomBackgroundColor: useCustomBackgroundColor.checked
    property string cfg_customBackgroundColor: Plasmoid.configuration.customBackgroundColor

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        Button {
            id: iconButton

            Kirigami.FormData.label: i18n("Icon:")

            implicitWidth: previewFrame.width + Kirigami.Units.smallSpacing * 2
            implicitHeight: previewFrame.height + Kirigami.Units.smallSpacing * 2

            // Just to provide some visual feedback when dragging;
            // cannot have checked without checkable enabled
            checkable: true
            checked: dropArea.containsAcceptableDrag

            onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

            DragDrop.DropArea {
                id: dropArea

                property bool containsAcceptableDrag: false

                anchors.fill: parent

                onDragEnter: {
                    // Cannot use string operations (e.g. indexOf()) on "url" basic type.
                    var urlString = event.mimeData.url.toString();

                    // This list is also hardcoded in KIconDialog.
                    var extensions = [".png", ".xpm", ".svg", ".svgz"];
                    containsAcceptableDrag = urlString.indexOf("file:///") === 0 && extensions.some(function (extension) {
                        return urlString.indexOf(extension) === urlString.length - extension.length; // "endsWith"
                    });

                    if (!containsAcceptableDrag) {
                        event.ignore();
                    }
                }
                onDragLeave: containsAcceptableDrag = false

                onDrop: {
                    if (containsAcceptableDrag) {
                        // Strip file:// prefix, we already verified in onDragEnter that we have only local URLs.
                        iconDialog.setCustomButtonImage(event.mimeData.url.toString().substr("file://".length));
                    }
                    containsAcceptableDrag = false;
                }
            }

            KIconThemes.IconDialog {
                id: iconDialog

                function setCustomButtonImage(image) {
                    configGeneral.cfg_customButtonImage = image || configGeneral.cfg_icon || "start-here-kde-symbolic"
                    configGeneral.cfg_useCustomButtonImage = true;
                }

                onIconNameChanged: setCustomButtonImage(iconName);
            }

            KSvg.FrameSvgItem {
                id: previewFrame
                anchors.centerIn: parent
                imagePath: Plasmoid.location === PlasmaCore.Types.Vertical || Plasmoid.location === PlasmaCore.Types.Horizontal
                        ? "widgets/panel-background" : "widgets/background"
                width: Kirigami.Units.iconSizes.large + fixedMargins.left + fixedMargins.right
                height: Kirigami.Units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    source: configGeneral.cfg_useCustomButtonImage ? configGeneral.cfg_customButtonImage : configGeneral.cfg_icon
                }
            }

            Menu {
                id: iconMenu

                // Appear below the button
                y: +parent.height

                onClosed: iconButton.checked = false;

                MenuItem {
                    text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                    icon.name: "document-open-folder"
                    onClicked: iconDialog.open()
                }
                MenuItem {
                    text: i18nc("@item:inmenu Reset icon to default", "Clear Icon")
                    icon.name: "edit-clear"
                    onClicked: {
                        configGeneral.cfg_icon = "start-here-kde-symbolic"
                        configGeneral.cfg_useCustomButtonImage = false
                    }
                }
            }
        }


        Item {
            Kirigami.FormData.isSection: true
        }

        ComboBox {
            id: appNameFormat

            Kirigami.FormData.label: i18n("Show applications as:")

            model: [i18n("Name only"), i18n("Description only"), i18n("Name (Description)"), i18n("Description (Name)")]
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        CheckBox {
            id: alphaSort
            visible: false
            Kirigami.FormData.label: i18n("Behavior:")

            text: i18n("Sort applications alphabetically")
        }

        CheckBox {
            id: limitDepth
            visible: false
            text: i18n("Flatten sub-menus to a single level")
        }

        CheckBox {
            id: showIconsRootLevel
            visible: false
            text: i18n("Show icons on the root level of the menu")
        }

        CheckBox {
            id: showRecentApps
            visible: false
            Kirigami.FormData.label: i18n("Show categories:")

            text: recentOrdering.currentIndex == 0
                    ? i18n("Recent applications")
                    : i18n("Often used applications")
        }

        CheckBox {
            id: showRecentDocs
            visible: false
            text: recentOrdering.currentIndex == 0
                    ? i18n("Recent files")
                    : i18n("Often used files")
        }

        ComboBox {
            id: recentOrdering
            visible: false
            Kirigami.FormData.label: i18n("Sort items in categories by:")
            model: [i18nc("@item:inlistbox Sort items in categories by [Recently used | Often used]", "Recently used"), i18nc("@item:inlistbox Sort items in categories by [Recently used | Ofetn used]", "Often used")]
        }

        CheckBox {
            id: useExtraRunners
            visible: false
            Kirigami.FormData.label: i18n("Search:")
            text: i18n("Expand search to bookmarks, files and emails")
        }

        CheckBox {
            id: alignResultsToBottom
            visible: false
            text: i18n("Align search results to bottom")
        }

        ComboBox {
            id: appsIconSize
            Kirigami.FormData.label: i18n("Apps icon size:")            
            model: [i18n("Small"),i18n("Medium"),i18n("Large"), i18n("Huge"),i18n("HUGE"),i18n("Enormous")]
        }

        ComboBox {
            id: systemIconSize
            Kirigami.FormData.label: i18n("System icons size:")
            model: [i18n("Small"),i18n("Medium"),i18n("Large"), i18n("Huge"),i18n("Enormous")]
        }

        ComboBox {
            id: showSystemIcons
            Kirigami.FormData.label: i18n("System Actions:")
            model: [i18n("Hide"), i18n("Show")]
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Grid Layout Settings")
        }

        CheckBox {
            id: useCustomGridSize
            Kirigami.FormData.label: i18n("Grid Layout:")
            text: i18n("Use custom grid size")
        }

        SpinBox {
            id: gridColumns
            enabled: useCustomGridSize.checked
            Kirigami.FormData.label: i18n("Columns:")
            from: 1
            to: 20
            value: 6
            stepSize: 1
        }

        SpinBox {
            id: gridRows
            enabled: useCustomGridSize.checked
            Kirigami.FormData.label: i18n("Rows:")
            from: 1
            to: 20
            value: 4
            stepSize: 1
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Appearance")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background transparency:")
            Layout.fillWidth: true
            
            Slider {
                id: backgroundOpacity
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: 0.4
                stepSize: 0.01
                
                ToolTip {
                    parent: backgroundOpacity.handle
                    visible: backgroundOpacity.pressed
                    text: Math.round(backgroundOpacity.value * 100) + "%"
                }
            }
            
            Label {
                text: Math.round(backgroundOpacity.value * 100) + "%"
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            }
        }

        CheckBox {
            id: useCustomBackgroundColor
            Kirigami.FormData.label: i18n("Background color:")
            text: i18n("Use custom background color")
        }

        RowLayout {
            Layout.fillWidth: true
            visible: useCustomBackgroundColor.checked
            
            Label {
                text: i18n("Custom Color:")
            }
            KQuickControls.ColorButton {
                id: backgroundColorPicker
                dialogTitle: i18n("Background Color")
                showAlphaChannel: true
                onAccepted: {
                    configGeneral.cfg_customBackgroundColor = color
                }
                Component.onCompleted: {
                    color = configGeneral.cfg_customBackgroundColor
                }
            }
        }
    }
}
