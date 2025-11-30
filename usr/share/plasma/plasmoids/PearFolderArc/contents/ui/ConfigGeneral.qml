/*
    SPDX-FileCopyrightText: 2024 Alexandru Balan

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configGeneral

    property alias cfg_folderPath: folderPathField.text
    property alias cfg_maxItems: maxItemsSpinBox.value
    property alias cfg_rotationStep: rotationStepSpinBox.value
    property alias cfg_offset: offsetSpinBox.value
    property alias cfg_iconSize: iconSizeSpinBox.value
    property alias cfg_indentStep: indentStepSpinBox.value

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        QQC2.TextField {
            id: folderPathField
            Kirigami.FormData.label: i18n("Folder path:")
            placeholderText: i18n("Leave empty for Downloads folder (e.g., ~/Downloads)")
        }

        QQC2.SpinBox {
            id: maxItemsSpinBox
            Kirigami.FormData.label: i18n("Maximum items:")
            from: 1
            to: 50
            stepSize: 1
            editable: true
        }

        QQC2.SpinBox {
            id: rotationStepSpinBox
            Kirigami.FormData.label: i18n("Rotation step (degrees):")
            from: 0
            to: 10
            stepSize: 1
            editable: true
        }

        QQC2.SpinBox {
            id: offsetSpinBox
            Kirigami.FormData.label: i18n("Offset:")
            from: -500
            to: 500
            stepSize: 1
            editable: true
        }

        QQC2.SpinBox {
            id: iconSizeSpinBox
            Kirigami.FormData.label: i18n("Icon size:")
            from: 20
            to: 200
            stepSize: 1
            editable: true
        }

        QQC2.SpinBox {
            id: indentStepSpinBox
            Kirigami.FormData.label: i18n("Indent step:")
            from: 0
            to: 50
            stepSize: 1
            editable: true
        }
    }
}

