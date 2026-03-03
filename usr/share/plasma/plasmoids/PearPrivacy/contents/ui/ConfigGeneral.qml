import QtQuick 2.15
import QtQuick.Controls 2.15

import org.kde.kirigami 2.3 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configGeneral

    property alias cfg_checkInterval: checkInterval.value
    property alias cfg_showCameraIndicator: showCameraIndicator.checked
    property alias cfg_showMicrophoneIndicator: showMicrophoneIndicator.checked
    property alias cfg_showScreenRecordingIndicator: showScreenRecordingIndicator.checked
    property alias cfg_iconSize: iconSize.value
    property alias cfg_ringLightThickness: ringLightThickness.value

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Detection Settings")
        }

        SpinBox {
            id: checkInterval
            Kirigami.FormData.label: i18n("Check interval (seconds):")
            from: 1
            to: 10
            value: Plasmoid.configuration.checkInterval
            stepSize: 1
            editable: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Indicators")
        }

        CheckBox {
            id: showCameraIndicator
            Kirigami.FormData.label: i18n("Show camera indicator:")
            checked: Plasmoid.configuration.showCameraIndicator
        }

        CheckBox {
            id: showMicrophoneIndicator
            Kirigami.FormData.label: i18n("Show microphone indicator:")
            checked: Plasmoid.configuration.showMicrophoneIndicator
        }

        CheckBox {
            id: showScreenRecordingIndicator
            Kirigami.FormData.label: i18n("Show screen recording indicator:")
            checked: Plasmoid.configuration.showScreenRecordingIndicator
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Appearance")
        }

        SpinBox {
            id: iconSize
            Kirigami.FormData.label: i18n("Icon size:")
            from: 50
            to: 200
            value: Plasmoid.configuration.iconSize
            stepSize: 1
            editable: true
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Ring Light")
        }

        SpinBox {
            id: ringLightThickness
            Kirigami.FormData.label: i18n("Border thickness:")
            from: 2
            to: 20
            value: Plasmoid.configuration.ringLightThickness
            stepSize: 1
            editable: true
        }
    }
}

