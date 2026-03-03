import QtQml 2.15
import QtQuick 2.15
import QtQuick.Layouts 1.15
//import QtGraphicalEffects 1.0

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
Item {
    id: compactRep
    
    RowLayout {
        anchors.fill: parent
        
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isOpen = !root.isOpen
                }
            }
            
            Image {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) * 0.6
                height: width
                source: Qt.resolvedUrl("../assets/control.png")
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }
    }
}
