import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.11
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: configRoot

    QtObject {
        id: initialValue
        property var value
    }

    signal configurationChanged

    property alias cfg_fontSize: sizeFontSpinBox.value
    property alias cfg_dayInitial: initialValue.value
    property alias cfg_latinAlphabet: latinAlphabet.checked

    ColumnLayout {
        spacing: units.smallSpacing * 2


        RowLayout{
            Label {
                text: i18n("Maintain formatting with Latin alphabet:")
            }
            CheckBox {
                id: latinAlphabet
            }
        }
        RowLayout{
            Label {
                text: i18n("Font Size")
            }
            SpinBox {
                id: sizeFontSpinBox
                from: 0
                to: 300
            }
        }
            ColumnLayout {
        spacing: units.smallSpacing * 2

        Label {
            text: i18n("Day initial:")
        }
        ComboBox {
            textRole: "text"
            valueRole: "value"
			id: initial
			model: [
                {text: i18n("Sunday"), value: 0},
                {text: i18n("Monday"), value: 1},
                {text: i18n("Tuesday"), value: 2},
                {text: i18n("Wednesday"), value: 3},
                {text: i18n("Thursday"), value: 4},
                {text: i18n("Friday"), value: 5},
                {text: i18n("Saturday"), value: 6},
            ]
            onActivated: initialValue.value = currentValue
            Component.onCompleted: currentIndex = indexOfValue(initialValue.value)
		}

   }
   }
}
