import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property var today: new Date()
    property int displayMonth: today.getMonth()
    property int displayYear: today.getFullYear()
    property string monthLabel: Qt.formatDate(today, "MMMM").toUpperCase()
    property var calendarCells: []
    // Luni prima zi a săptămânii
    property var weekdayLabels: ["M", "T", "W", "T", "F", "S", "S"]

    // Citește tema globală: "dark" sau "light" (din fișierul de state themeswitcher).
    // Este actualizată la fiecare rebuild al calendarului.
    property string systemTheme: ""

    // Determină dacă tema este dark, pe baza fișierului de stare.
    // IMPORTANT: Nu mai folosim Qt.application.* (care e undefined în contextul plasmoidului),
    // ca să evităm TypeError. Dacă nu putem citi fișierul, implicit mergem pe "dark".
    property bool isDarkTheme: systemTheme === "dark"
                               ? true
                               : systemTheme === "light"
                                   ? false
                                   : true

    // Paletă derivată în funcție de tema detectată
    property color bgColor: isDarkTheme ? "#1a1a1a" : "#ffffff"
    property color borderColor: isDarkTheme ? "#333333" : "#c0c0c0"
    property color textColor: isDarkTheme ? "#dddddd" : "#202020"
    property color disabledTextColor: isDarkTheme ? "#808080" : "#a0a0a0"
    property color highlightColor: "#ff4e45"
    property color highlightedTextColor: "#ffffff"

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: updateAndBuildCalendar()
        Component.onCompleted: updateAndBuildCalendar()
    }

    function readSystemTheme() {
        console.log("PearCalendar: readSystemTheme() called")
        try {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///usr/share/extras/system-settings/themeswitcher/state", false)
            xhr.send()

            console.log("PearCalendar: theme xhr.status =", xhr.status)

            if (xhr.status === 0 || xhr.status === 200) {
                var raw = xhr.responseText
                console.log("PearCalendar: theme raw =", raw)
                if (raw) {
                    var txt = raw.trim()
                    console.log("PearCalendar: theme txt(trim) =", txt)
                    if (txt === "dark" || txt === "light") {
                        console.log("PearCalendar: returning theme", txt)
                        return txt
                    }
                }
            }
        } catch (e) {
            console.log("PearCalendar: error reading theme file", e)
        }
        console.log("PearCalendar: using palette-based theme detection")
        // dacă nu găsim nimic clar, lăsăm string gol și folosim paleta
        return ""
    }

    // Load events from /usr/share/extras/pearos-calendar/events.json
    // Accepted formats:
    //   ["2025-03-10", "2025-03-21"]
    //   [{ "date": "2025-03-10" }, ...]
    //   { "2025-03-10": { ... }, "2025-03-21": { ... } }
    //   { "events": [ { "date": "2025-03-10", ... }, ... ] }
    function loadEvents() {
        var map = {}
        try {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///usr/share/extras/pearos-calendar/events.json", false)
            xhr.send()

            console.log("PearCalendar: loadEvents() xhr.status =", xhr.status)

            if (xhr.status === 0 || xhr.status === 200) {
                console.log("PearCalendar: events raw =", xhr.responseText)
                var root = JSON.parse(xhr.responseText)
                if (!root)
                    return map

                var data = root
                if (root.events !== undefined) {
                    console.log("PearCalendar: using root.events array, length =", root.events.length)
                    data = root.events
                }

                if (data.length !== undefined) {
                    for (var i = 0; i < data.length; ++i) {
                        var entry = data[i]
                        var dateStr = ""
                        if (typeof entry === "string") {
                            dateStr = entry
                        } else if (entry && typeof entry.date === "string") {
                            dateStr = entry.date
                        }
                        if (dateStr && dateStr.length >= 10) {
                            dateStr = dateStr.substring(0, 10)
                            map[dateStr] = true
                            console.log("PearCalendar: added event date", dateStr)
                        }
                    }
                } else {
                    for (var key in data) {
                        if (!data.hasOwnProperty(key))
                            continue
                        var k = String(key)
                        if (k.length >= 10) {
                            k = k.substring(0, 10)
                            map[k] = true
                            console.log("PearCalendar: added event date (object key)", k)
                        }
                    }
                }
            }
        } catch (e) {
            console.log("PearCalendar: error loading events", e)
        }
        console.log("PearCalendar: events map keys =", Object.keys(map))
        return map
    }

    function pad2(n) {
        return n < 10 ? "0" + n : String(n)
    }

    function updateAndBuildCalendar() {
        systemTheme = readSystemTheme()
        today = new Date()
        displayMonth = today.getMonth()
        displayYear = today.getFullYear()
        monthLabel = Qt.formatDate(today, "MMMM").toUpperCase()

        var cells = []
        var eventsByDate = loadEvents()
        var firstOfMonth = new Date(displayYear, displayMonth, 1)
        // getDay(): 0 = Sunday, 1 = Monday, ... 6 = Saturday
        var jsStartDay = firstOfMonth.getDay()
        var startDay = (jsStartDay + 6) % 7  // 0 = Monday, ... 6 = Sunday
        var daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()

        for (var i = 0; i < startDay; ++i) {
            cells.push({ day: "", currentMonth: false, isToday: false })
        }

        for (var d = 1; d <= daysInMonth; ++d) {
            var isToday = d === today.getDate() &&
                displayMonth === today.getMonth() &&
                displayYear === today.getFullYear()

            var dateStr = String(displayYear) + "-" +
                          pad2(displayMonth + 1) + "-" +
                          pad2(d)
            var hasEvent = eventsByDate[dateStr] === true

            cells.push({
                day: String(d),
                currentMonth: true,
                isToday: isToday,
                hasEvent: hasEvent
            })
        }

        while (cells.length % 7 !== 0) {
            cells.push({ day: "", currentMonth: false, isToday: false })
        }
        calendarCells = cells
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 140
        Layout.minimumHeight: 150
        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
            id: background
            anchors.fill: parent
            radius: 20
            anchors.margins: 10
            color: bgColor
            opacity: 1
            border.width: 1
            border.color: borderColor

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    Qt.openUrlExternally("pear-calendar")
                }
                propagateComposedEvents: true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                // --- HEADER ---
                    Text {
                        text: monthLabel
                        font.family: "Sans Serif"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 1.5
                        color: highlightColor
                        Layout.fillWidth: true
                    }

                // --- GRID ---
                GridLayout {
                    columns: 7
                    columnSpacing: 0
                    rowSpacing: 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Weekday Labels
                    Repeater {
                        model: weekdayLabels
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 18
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: "Sans Serif"
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: disabledTextColor
                            }
                        }
                    }

                    // Days
                    Repeater {
                        model: calendarCells
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            property var cellData: modelData

                            // --- HIGHLIGHT RECTANGLE (astăzi) ---
                            Rectangle {
                                id: highlightRect
                                anchors.centerIn: parent
                                
                                width: 18
                                height: 18
                                radius: 20
                                
                                color: highlightColor
                                visible: cellData.isToday
                            }

                            // --- EVENT INDICATOR (cerc verde) ---
                            Rectangle {
                                id: eventIndicator
                                width: 6
                                height: 6
                                radius: 3
                                color: "#00cc66"
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                visible: cellData.hasEvent === true
                            }

                            // --- TEXT ---
                            Text {
                                anchors.centerIn: highlightRect 
                                text: cellData.day
                                font.family: "Sans Serif"
                            font.pixelSize: 10
                                font.weight: cellData.isToday ? Font.Bold : Font.Normal
                                color: cellData.isToday
                                       ? highlightedTextColor
                                       : textColor
                                opacity: cellData.day === "" ? 0 : 1
                            }
                        }
                    }
                }
            }
        }
    }
}
