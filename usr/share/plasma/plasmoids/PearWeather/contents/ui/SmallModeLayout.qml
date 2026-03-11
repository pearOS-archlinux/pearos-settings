import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: smallLayout

    required property var weatherRoot

    property var currentWeather: weatherRoot.currentWeather
    property string location: weatherRoot.location

    function getWeatherIcon(item) { return weatherRoot.getWeatherIcon(item) }
    
    Timer {
        id: autoReturnTimer
        interval: 5000
        repeat: false
        onTriggered: swipeView.currentIndex = 0
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        clip: true

        // PAGE 1: Current Weather
        Item {
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 4
                width: parent.width

                // 1. Numele orașului – mai mic, nu bold
                Text {
                    text: currentWeather ? (currentWeather.location || location) : (location || "")
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.pixelSize: Math.max(11, Math.min(15, smallLayout.height * 0.08))
                    font.bold: false
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // 2. Grade – font normal, mai mari
                Text {
                    text: currentWeather ? (Math.round(currentWeather.temp) + "°") : "--"
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.pixelSize: Math.max(28, Math.min(44, smallLayout.height * 0.22))
                    font.bold: false
                    Layout.fillWidth: true
                }

                // Spațiu mai mare între grade și icon
                Item { Layout.preferredHeight: 10 }

                // 3. Imagine vreme, mică
                Kirigami.Icon {
                    source: getWeatherIcon(currentWeather)
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    Layout.alignment: Qt.AlignLeft
                    isMask: false
                    smooth: true
                }

                // 4. Status (Mostly Sunny, Mainly Clear etc) – bold
                Text {
                    text: currentWeather ? i18n(currentWeather.condition) : ""
                    color: Kirigami.Theme.textColor
                    font.family: weatherRoot.activeFont.family
                    font.pixelSize: Math.max(12, Math.min(16, smallLayout.height * 0.08))
                    font.bold: true
                    opacity: 0.9
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // 5. H și L fără iconuri verde/roșu
                RowLayout {
                    spacing: 12
                    Layout.alignment: Qt.AlignLeft
                    Text {
                        text: "H: " + (currentWeather ? currentWeather.temp_max + "°" : "--")
                        color: Kirigami.Theme.textColor
                        font.family: weatherRoot.activeFont.family
                        font.pixelSize: Math.max(11, smallLayout.height * 0.07)
                        font.bold: false
                    }
                    Text {
                        text: "L: " + (currentWeather ? currentWeather.temp_min + "°" : "--")
                        color: Kirigami.Theme.textColor
                        font.family: weatherRoot.activeFont.family
                        font.pixelSize: Math.max(11, smallLayout.height * 0.07)
                        font.bold: false
                    }
                }
            }

            // Navigation Button – ascuns la cererea utilizatorului
            Rectangle {
                visible: false
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                width: 24
                height: 24
                radius: width / 2
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1)
                
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "media-playback-start"
                    color: Kirigami.Theme.textColor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        swipeView.currentIndex = 1
                        autoReturnTimer.restart()
                    }
                }
            }
        }

        // PAGE 2: Daily Forecast using new reusable component
        Item {
            DailyForecastView {
                anchors.fill: parent
                anchors.margins: 10
                weatherRoot: smallLayout.weatherRoot
                
                // Layout params for 1x2 grid (2 vertical tiles)
                cellWidth: width
                cellHeight: height / 2
                
                // Appearance for Small Mode
                showUnits: false
                showBackground: true
                itemSpacing: 4  // Match wide mode's card spacing
                edgeMargins: 0
                flushEdges: true
                isHorizontalLayout: true
                isHourly: false // Explicitly set to daily mode for small view
                // Model inherited from DailyForecastView (weatherRoot.forecastDaily)
            }
            
            // Hover detection for auto-return
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton // Let clicks pass through to GridView
                onEntered: autoReturnTimer.stop()
                onExited: autoReturnTimer.restart()
            }
        }
    }
    

}
