import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Window
import QtCore
import Qt5Compat.GraphicalEffects
import QtWebEngine

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.title: i18n("PearPrivacy")
    Plasmoid.icon: "camera-web"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    property bool cameraInUse: false
    property bool microphoneInUse: false
    property bool screenRecordingInUse: false
    property string cameraProcess: ""
    property string microphoneProcess: ""
    property string screenRecordingProcess: ""
    property string cameraPid: ""
    property string microphonePid: ""
    property string screenRecordingPid: ""
    property string cameraAppName: ""
    property string microphoneAppName: ""
    property string screenRecordingAppName: ""
    property string cameraAppIcon: ""
    property string microphoneAppIcon: ""
    property string screenRecordingAppIcon: ""
    property bool piriStatusReady: true
    property bool piriShowIcon: false

    Plasma5Support.DataSource {
        id: piriShowIconReader
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            root.piriShowIcon = (output === "true")
        }
    }

    Plasma5Support.DataSource {
        id: piriStatusReader
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            root.piriStatusReady = (output === "ready")
        }
    }

    Plasma5Support.DataSource {
        id: cameraChecker
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            var wasInUse = root.cameraInUse
            root.cameraInUse = (data["exit code"] === 0 && output.length > 0)
            
            if (root.cameraInUse) {
                root.cameraPid = output
                // Obține numele procesului
                getProcessName(output, "camera")
            } else {
                root.cameraPid = ""
                root.cameraProcess = ""
                root.cameraAppName = ""
                root.cameraAppIcon = ""
            }
            
            if (wasInUse !== root.cameraInUse) {
                updateStatus()
                // Auto start Ring Light dacă este activată opțiunea
                if (root.cameraInUse && Plasmoid.configuration.ringLightAutoStartOnCamera) {
                    Plasmoid.configuration.ringLightEnabled = true
                }
            }
        }
    }
    
    Plasma5Support.DataSource {
        id: processNameGetter
        engine: "executable"
        connectedSources: []
        property string type: ""
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            if (type === "camera") {
                root.cameraProcess = output
                getAppInfo(output, "camera")
            } else if (type === "microphone") {
                root.microphoneProcess = output
                getAppInfo(output, "microphone")
            } else if (type === "screenrecording") {
                root.screenRecordingProcess = output
                getAppInfo(output, "screenrecording")
            }
        }
    }
    
    Plasma5Support.DataSource {
        id: appInfoGetter
        engine: "executable"
        connectedSources: []
        property string pid: ""
        property var callback: null
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var processName = data["stdout"].toString().trim()
            if (callback) {
                callback(processName, "")
            }
        }
    }
    
    function getProcessName(pid, type) {
        var cmd = "ps -p " + pid + " -o comm= 2>/dev/null | head -1"
        processNameGetter.type = type
        processNameGetter.connectSource(cmd)
    }
    
    function getAppInfo(processName, type) {
        if (!processName || processName === "") {
            if (type === "camera") {
                root.cameraAppName = ""
                root.cameraAppIcon = ""
            } else {
                root.microphoneAppName = ""
                root.microphoneAppIcon = ""
            }
            return
        }
        
        // Obține numele aplicației din desktop file
        var nameCmd = "desktop-file-validate $(find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | xargs grep -l '^Exec=.*" + processName + "' 2>/dev/null | head -1) 2>/dev/null && grep -h '^Name=' $(find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | xargs grep -l '^Exec=.*" + processName + "' 2>/dev/null | head -1) 2>/dev/null | head -1 | cut -d'=' -f2 || echo '" + processName + "'"
        appNameGetter.type = type
        appNameGetter.processName = processName
        appNameGetter.connectSource(nameCmd)
    }
    
    Plasma5Support.DataSource {
        id: appNameGetter
        engine: "executable"
        connectedSources: []
        property string type: ""
        property string processName: ""
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var name = data["stdout"].toString().trim() || processName
            if (type === "camera") {
                root.cameraAppName = name
                getAppIcon(processName, "camera")
            } else if (type === "microphone") {
                root.microphoneAppName = name
                getAppIcon(processName, "microphone")
            } else if (type === "screenrecording") {
                root.screenRecordingAppName = name
                getAppIcon(processName, "screenrecording")
            }
        }
    }
    
    function getAppIcon(processName, type) {
        var cmd = "grep -h '^Icon=' $(find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | xargs grep -l '^Exec=.*" + processName + "' 2>/dev/null | head -1) 2>/dev/null | head -1 | cut -d'=' -f2 || echo '" + processName.toLowerCase() + "'"
        appIconGetter.type = type
        appIconGetter.connectSource(cmd)
    }
    
    Plasma5Support.DataSource {
        id: appIconGetter
        engine: "executable"
        connectedSources: []
        property string type: ""
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var icon = data["stdout"].toString().trim()
            if (type === "camera") {
                root.cameraAppIcon = icon || root.cameraProcess.toLowerCase()
            } else if (type === "microphone") {
                root.microphoneAppIcon = icon || root.microphoneProcess.toLowerCase()
            } else if (type === "screenrecording") {
                root.screenRecordingAppIcon = icon || root.screenRecordingProcess.toLowerCase()
            }
        }
    }

    Plasma5Support.DataSource {
        id: microphoneChecker
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            var wasInUse = root.microphoneInUse
            // Verifică dacă există output valid
            root.microphoneInUse = (data["exit code"] === 0 && output.length > 0)
            
            if (root.microphoneInUse) {
                // Pentru PulseAudio, obține PID-ul din altă comandă
                var pidCmd = "pactl list sources short 2>/dev/null | grep -v 'monitor' | grep -E 'RUNNING|IDLE' | head -1 | awk '{print $6}' || lsof /dev/snd/* 2>/dev/null | grep -E 'capture|pcm.*c' | awk 'NR>1 {print $2}' | head -1"
                microphonePidGetter.connectSource(pidCmd)
            } else {
                root.microphonePid = ""
                root.microphoneProcess = ""
                root.microphoneAppName = ""
                root.microphoneAppIcon = ""
            }
            
            if (wasInUse !== root.microphoneInUse) {
                updateStatus()
            }
        }
    }
    
    Plasma5Support.DataSource {
        id: microphonePidGetter
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var pid = data["stdout"].toString().trim()
            if (pid && pid !== "") {
                root.microphonePid = pid
                getProcessName(pid, "microphone")
            }
        }
    }

    function checkCamera() {
        if (!Plasmoid.configuration.showCameraIndicator) {
            root.cameraInUse = false
            return
        }
        // Verifică dacă există procese care folosesc dispozitive video și obține PID-ul
        var cmd = "lsof /dev/video* 2>/dev/null | awk 'NR>1 {print $2}' | head -1"
        cameraChecker.connectSource(cmd)
    }
    
    function getAppInfoFromPid(pid, callback) {
        if (!pid || pid === "") {
            callback("", "")
            return
        }
        // Obține numele procesului și încearcă să găsească iconița aplicației
        var cmd = "ps -p " + pid + " -o comm= 2>/dev/null | head -1"
        var infoCmd = "ps -p " + pid + " -o comm= 2>/dev/null | head -1 && desktop-file-validate $(find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null | xargs grep -l '^Exec=.*'$(ps -p " + pid + " -o comm= 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]')" + "' 2>/dev/null | head -1) 2>/dev/null | head -1 || echo ''"
        appInfoGetter.connectSource(cmd)
        appInfoGetter.pid = pid
        appInfoGetter.callback = callback
    }

    function checkMicrophone() {
        if (!Plasmoid.configuration.showMicrophoneIndicator) {
            root.microphoneInUse = false
            return
        }
        // Verifică dacă există procese care folosesc microfonul
        // Verifică atât PulseAudio cât și dispozitivele directe
        var cmd = "pactl list sources short 2>/dev/null | grep -v 'monitor' | grep -E 'RUNNING|IDLE' | head -1 || lsof /dev/snd/* 2>/dev/null | grep -E 'capture|pcm.*c' | head -1"
        microphoneChecker.connectSource(cmd)
    }
    
    Plasma5Support.DataSource {
        id: screenRecordingChecker
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            var wasInUse = root.screenRecordingInUse
            root.screenRecordingInUse = (data["exit code"] === 0 && output.length > 0)
            
            if (root.screenRecordingInUse) {
                // Obține PID-ul primului proces găsit din output-ul ps aux
                // Format ps aux: USER PID CPU MEM VSZ RSS TTY STAT START TIME COMMAND
                var lines = output.split('\n')
                if (lines.length > 0) {
                    var parts = lines[0].trim().split(/\s+/)
                    // PID-ul este al doilea câmp (index 1)
                    if (parts.length > 1) {
                        var pid = parts[1]
                        if (pid && pid !== "" && !isNaN(pid)) {
                            root.screenRecordingPid = pid
                            getProcessName(pid, "screenrecording")
                        } else {
                            // Dacă nu găsim PID, încercăm să obținem numele procesului direct
                            var processName = parts[parts.length - 1] || parts[parts.length - 2] || ""
                            if (processName) {
                                root.screenRecordingProcess = processName
                                getAppInfo(processName, "screenrecording")
                            }
                        }
                    }
                }
            } else {
                root.screenRecordingPid = ""
                root.screenRecordingProcess = ""
                root.screenRecordingAppName = ""
                root.screenRecordingAppIcon = ""
            }
            
            if (wasInUse !== root.screenRecordingInUse) {
                updateStatus()
            }
        }
    }
    
    Plasma5Support.DataSource {
        id: spectacleChecker
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            var wasInUse = root.screenRecordingInUse
            
            // Verifică dacă spectacle rulează ȘI dacă folosește efectiv interfețe de capture
            var spectacleRunning = (data["exit code"] === 0 && output.length > 0)
            
            if (spectacleRunning) {
                // Verifică dacă spectacle folosește efectiv interfețe de capture (nu doar rulează în background)
                var pid = output.split('\n')[0] || output
                if (pid && pid !== "" && !isNaN(pid)) {
                    // Verifică dacă spectacle folosește x11grab sau alte interfețe de capture
                    var hasCaptureCmd = "lsof -p " + pid + " 2>/dev/null | grep -E '(x11grab|X11|screen|display)' | head -1 || echo ''"
                    spectacleCaptureChecker.pid = pid
                    spectacleCaptureChecker.connectSource(hasCaptureCmd)
                } else {
                    // Dacă nu găsim PID, nu considerăm că este activ
                    if (!root.screenRecordingInUse) {
                        root.screenRecordingInUse = false
                    }
                }
            } else {
                // Dacă spectacle nu rulează, verifică procesele normale de screen recording
                // (nu resetăm screenRecordingInUse aici, lasă screenRecordingChecker să gestioneze)
            }
            
            if (wasInUse !== root.screenRecordingInUse) {
                updateStatus()
            }
        }
    }
    
    Plasma5Support.DataSource {
        id: spectacleCaptureChecker
        engine: "executable"
        connectedSources: []
        property string pid: ""
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"].toString().trim()
            var wasInUse = root.screenRecordingInUse
            
            // Dacă spectacle folosește efectiv interfețe de capture, considerăm că screen recording este activ
            var hasCapture = (data["exit code"] === 0 && output.length > 0)
            
            if (hasCapture && pid !== "") {
                root.screenRecordingInUse = true
                root.screenRecordingPid = pid
                root.screenRecordingProcess = "spectacle"
                getProcessName(pid, "screenrecording")
            } else {
                // Dacă spectacle nu folosește interfețe de capture, nu considerăm că este în modul de screen recording
                // (nu resetăm screenRecordingInUse aici, lasă screenRecordingChecker să gestioneze)
            }
            
            if (wasInUse !== root.screenRecordingInUse) {
                updateStatus()
            }
        }
    }
    
    function checkPiriStatus() {
        piriStatusReader.connectSource("cat /usr/share/extras/piri/status 2>/dev/null || echo ''")
    }

    function checkPiriShowIcon() {
        piriShowIconReader.connectSource("cat /usr/share/extras/piri/show_icon 2>/dev/null || echo 'false'")
    }

    Plasma5Support.DataSource {
        id: piriLaunchCommand
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
        }
    }

    function launchPiriCommand() {
        piriLaunchCommand.connectSource("sh -c 'piri-voice'")
    }

    function checkScreenRecording() {
        if (!Plasmoid.configuration.showScreenRecordingIndicator) {
            root.screenRecordingInUse = false
            return
        }
        // Verifică separat dacă spectacle rulează (chiar dacă nu este în modul de înregistrare)
        spectacleChecker.connectSource("pgrep -x spectacle 2>/dev/null")
        
        // Verifică procese cunoscute pentru screen recording
        // Verifică: ffmpeg cu x11grab/gdigrab, obs, kazam, simplescreenrecorder, vokoscreen, peek, gifine, byzanz
        // Și verifică PipeWire pentru surse de capture
        var cmd = "ps aux | grep -E '(ffmpeg.*x11grab|ffmpeg.*gdigrab|ffmpeg.*screen|obs|kazam|simplescreenrecorder|vokoscreen|peek|gifine|byzanz|gnome-screenshot.*--interactive|flameshot|wf-recorder|grim|slurp)' | grep -v grep | head -1 || (pw-cli list-sources 2>/dev/null | grep -E 'screen|monitor' | head -1)"
        screenRecordingChecker.connectSource(cmd)
    }
    
    function showAppDialog(type, visualParent) {
        // Dacă panoul este deja deschis, îl închidem
        if (appInfoDialog.visible && appInfoDialog.currentType === type) {
            appInfoDialog.visible = false
            return
        }
        
        // Dacă tipul este "all", afișăm toate dispozitivele active
        if (type === "all") {
            appInfoDialog.showAllDevices = true
            appInfoDialog.currentType = "all"
            appInfoDialog.visualParent = visualParent
            appInfoDialog.visible = true
            return
        }
        
        // Pentru tipuri specifice, afișăm doar acel dispozitiv
        appInfoDialog.showAllDevices = false
        var appName = type === "camera" ? root.cameraAppName : (type === "microphone" ? root.microphoneAppName : root.screenRecordingAppName)
        var appIcon = type === "camera" ? root.cameraAppIcon : (type === "microphone" ? root.microphoneAppIcon : root.screenRecordingAppIcon)
        var processName = type === "camera" ? root.cameraProcess : (type === "microphone" ? root.microphoneProcess : root.screenRecordingProcess)
        
        var hasAppName = appName && appName !== "" && appName !== processName
        
        if (!hasAppName) {
            // Dacă nu avem nume de aplicație, afișăm mesajul generic
            appInfoDialog.appName = ""
            if (type === "camera") {
                appInfoDialog.appIcon = "camera"
                appInfoDialog.deviceType = i18n("Camera")
            } else if (type === "microphone") {
                appInfoDialog.appIcon = "audio-input-microphone"
                appInfoDialog.deviceType = i18n("Microphone")
            } else {
                appInfoDialog.appIcon = "video-display"
                appInfoDialog.deviceType = i18n("Screen Recording")
            }
            appInfoDialog.showGenericMessage = true
        } else {
            appInfoDialog.appName = appName
            appInfoDialog.appIcon = appIcon || (processName ? processName.toLowerCase() : "application-x-executable")
            if (type === "camera") {
                appInfoDialog.deviceType = i18n("Camera")
            } else if (type === "microphone") {
                appInfoDialog.deviceType = i18n("Microphone")
            } else {
                appInfoDialog.deviceType = i18n("Screen Recording")
            }
            appInfoDialog.showGenericMessage = false
        }
        
        appInfoDialog.currentType = type
        appInfoDialog.visualParent = visualParent
        appInfoDialog.visible = true
    }

    function updateStatus() {
        if (cameraInUse || microphoneInUse || screenRecordingInUse) {
            Plasmoid.status = PlasmaCore.Types.ActiveStatus
        } else {
            Plasmoid.status = PlasmaCore.Types.PassiveStatus
        }
    }

    Timer {
        id: checkTimer
        interval: Plasmoid.configuration.checkInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            checkCamera()
            checkMicrophone()
            checkScreenRecording()
            checkPiriStatus()
            checkPiriShowIcon()
        }
    }

    Component.onCompleted: {
        checkCamera()
        checkMicrophone()
        checkScreenRecording()
        checkPiriStatus()
        checkPiriShowIcon()
        updateStatus()
    }

    Connections {
        target: Plasmoid.configuration
        function onCheckIntervalChanged() {
            checkTimer.interval = Plasmoid.configuration.checkInterval * 1000
        }
        function onShowCameraIndicatorChanged() {
            checkCamera()
        }
        function onShowMicrophoneIndicatorChanged() {
            checkMicrophone()
        }
        function onShowScreenRecordingIndicatorChanged() {
            checkScreenRecording()
        }
    }

    preferredRepresentation: fullRepresentation

    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)

    fullRepresentation: MouseArea {
        id: mouseArea

        anchors.fill: parent
        activeFocusOnTab: true
        hoverEnabled: true

        onClicked: Plasmoid.expanded = !Plasmoid.expanded

        RowLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            MouseArea {
                id: piriIconArea
                readonly property bool shouldBeVisible: root.piriShowIcon && !(Plasmoid.configuration.showCameraIndicator && root.cameraInUse) && !(Plasmoid.configuration.showMicrophoneIndicator && root.microphoneInUse) && !(Plasmoid.configuration.showScreenRecordingIndicator && root.screenRecordingInUse)
                visible: shouldBeVisible || opacity > 0
                Layout.preferredWidth: pillWidth
                Layout.preferredHeight: pillHeight
                Layout.minimumWidth: pillWidth
                Layout.minimumHeight: pillHeight
                readonly property real baseSize: isHorizontal ? mouseArea.height : mouseArea.width
                readonly property bool isHorizontal: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                readonly property real pillHeight: Math.max(16, baseSize * (Plasmoid.configuration.iconSize / 100))
                readonly property real pillWidth: pillHeight

                opacity: shouldBeVisible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                        onRunningChanged: {
                            if (!running && opacity === 0.0) {
                                piriIconArea.visible = false
                            }
                        }
                    }
                }

                onClicked: {
                    if (root.piriShowIcon) {
                        root.launchPiriCommand()
                    } else {
                        Plasmoid.expanded = !Plasmoid.expanded
                    }
                }

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../assets/piri.png")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            MouseArea {
                id: cameraPillArea
                // Afișează doar dacă camera este activă ȘI nu există screen recording (prioritate mai mare)
                readonly property bool shouldBeVisible: Plasmoid.configuration.showCameraIndicator && root.cameraInUse && !(Plasmoid.configuration.showScreenRecordingIndicator && root.screenRecordingInUse)
                visible: shouldBeVisible || opacity > 0
                Layout.preferredWidth: pillWidth
                Layout.preferredHeight: pillHeight
                Layout.minimumWidth: pillWidth
                Layout.minimumHeight: pillHeight
                readonly property real baseSize: isHorizontal ? mouseArea.height : mouseArea.width
                readonly property bool isHorizontal: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                readonly property real pillHeight: Math.max(16, baseSize * (Plasmoid.configuration.iconSize / 100))
                readonly property real pillWidth: pillHeight * 1.5 // Pastilă alungită
                
                opacity: shouldBeVisible ? 1.0 : 0.0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                        onRunningChanged: {
                            if (!running && opacity === 0.0) {
                                cameraPillArea.visible = false
                            }
                        }
                    }
                }
                
                onClicked: root.showAppDialog("all", cameraPillArea)
                
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "#4CAF50" // Verde
                    
                    Kirigami.Icon {
                        source: "camera"
                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.5, parent.height * 0.6)
                        height: width
                        color: "white"
                    }
                }
            }

            MouseArea {
                id: microphonePillArea
                // Afișează doar dacă microfonul este activ ȘI nu există screen recording sau camera (prioritate mai mare)
                readonly property bool shouldBeVisible: Plasmoid.configuration.showMicrophoneIndicator && root.microphoneInUse && !(Plasmoid.configuration.showScreenRecordingIndicator && root.screenRecordingInUse) && !(Plasmoid.configuration.showCameraIndicator && root.cameraInUse)
                visible: shouldBeVisible || opacity > 0
                Layout.preferredWidth: pillWidth
                Layout.preferredHeight: pillHeight
                Layout.minimumWidth: pillWidth
                Layout.minimumHeight: pillHeight
                readonly property real baseSize: isHorizontal ? mouseArea.height : mouseArea.width
                readonly property bool isHorizontal: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                readonly property real pillHeight: Math.max(16, baseSize * (Plasmoid.configuration.iconSize / 100))
                readonly property real pillWidth: pillHeight * 1.5 // Pastilă alungită
                
                opacity: shouldBeVisible ? 1.0 : 0.0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                        onRunningChanged: {
                            if (!running && opacity === 0.0) {
                                microphonePillArea.visible = false
                            }
                        }
                    }
                }
                
                onClicked: root.showAppDialog("all", microphonePillArea)
                
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "#FF9800" // Portocaliu
                    
                    Kirigami.Icon {
                        source: "audio-input-microphone"
                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.5, parent.height * 0.6)
                        height: width
                        color: "white"
                    }
                }
            }

            MouseArea {
                id: screenRecordingPillArea
                // Screen recording are prioritate maximă, deci se afișează întotdeauna când este activ
                readonly property bool shouldBeVisible: Plasmoid.configuration.showScreenRecordingIndicator && root.screenRecordingInUse
                visible: shouldBeVisible || opacity > 0
                Layout.preferredWidth: pillWidth
                Layout.preferredHeight: pillHeight
                Layout.minimumWidth: pillWidth
                Layout.minimumHeight: pillHeight
                readonly property real baseSize: isHorizontal ? mouseArea.height : mouseArea.width
                readonly property bool isHorizontal: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                readonly property real pillHeight: Math.max(16, baseSize * (Plasmoid.configuration.iconSize / 100))
                readonly property real pillWidth: pillHeight * 1.5 // Pastilă alungită
                
                opacity: shouldBeVisible ? 1.0 : 0.0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.InOutQuad
                        onRunningChanged: {
                            if (!running && opacity === 0.0) {
                                screenRecordingPillArea.visible = false
                            }
                        }
                    }
                }
                
                onClicked: root.showAppDialog("all", screenRecordingPillArea)
                
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: "#F44336" // Roșu
                    
                    Kirigami.Icon {
                        source: "video-display"
                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.5, parent.height * 0.6)
                        height: width
                        color: "white"
                    }
                }
            }
        }

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: Plasmoid.title
            subText: {
                var parts = []
                if (root.cameraInUse) {
                    parts.push(i18n("Camera in use") + (root.cameraAppName ? ": " + root.cameraAppName : (root.cameraProcess ? ": " + root.cameraProcess : "")))
                }
                if (root.microphoneInUse) {
                    parts.push(i18n("Microphone in use") + (root.microphoneAppName ? ": " + root.microphoneAppName : (root.microphoneProcess ? ": " + root.microphoneProcess : "")))
                }
                if (root.screenRecordingInUse) {
                    parts.push(i18n("Screen recording in use") + (root.screenRecordingAppName ? ": " + root.screenRecordingAppName : (root.screenRecordingProcess ? ": " + root.screenRecordingProcess : "")))
                }
                if (parts.length === 0) {
                    return i18n("Camera, microphone and screen recording are not in use")
                }
                return parts.join("\n")
            }
        }
    }
    
    PlasmaCore.Dialog {
        id: appInfoDialog
        
        visible: false
        location: Plasmoid.location
        type: PlasmaCore.Dialog.Popup
        flags: Qt.FramelessWindowHint | Qt.Popup
        backgroundHints: PlasmaCore.Types.StandardBackground
        hideOnWindowDeactivate: true
        
        property string appName: ""
        property string appIcon: ""
        property string deviceType: ""
        property bool showGenericMessage: false
        property bool showAllDevices: false
        property string currentType: ""
        
        onVisibleChanged: {
            if (visible) {
                appInfoDialog.requestActivate()
            } else {
                currentType = ""
            }
        }
        
        mainItem: Item {
            width: 350
            readonly property int activeDevicesCount: (root.screenRecordingInUse && Plasmoid.configuration.showScreenRecordingIndicator ? 1 : 0) + 
                                                      (root.cameraInUse && Plasmoid.configuration.showCameraIndicator ? 1 : 0) + 
                                                      (root.microphoneInUse && Plasmoid.configuration.showMicrophoneIndicator ? 1 : 0)
            height: Plasmoid.configuration.ringLightEnabled ? 550 : (appInfoDialog.showAllDevices ? Math.max(150, 100 + activeDevicesCount * 60) : 150)
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.mediumSpacing
                
                // Afișează toate dispozitivele active sau unul singur
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    visible: !appInfoDialog.showAllDevices
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing
                        
                        Kirigami.Icon {
                            source: appInfoDialog.appIcon || "application-x-executable"
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            
                            QQC2.Label {
                                text: appInfoDialog.showGenericMessage 
                                    ? i18n("Your %1 is being used", appInfoDialog.deviceType)
                                    : i18n("%1 is using %2", appInfoDialog.appName, appInfoDialog.deviceType)
                                font.bold: true
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
                
                // Afișează toate dispozitivele active
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.mediumSpacing
                    visible: appInfoDialog.showAllDevices
                    
                    QQC2.Label {
                        text: i18n("Devices in use:")
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    // Screen Recording (prioritate maximă)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing
                        visible: root.screenRecordingInUse && Plasmoid.configuration.showScreenRecordingIndicator
                        
                        Kirigami.Icon {
                            source: root.screenRecordingAppIcon || "video-display"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            QQC2.Label {
                                text: root.screenRecordingAppName && root.screenRecordingAppName !== "" && root.screenRecordingAppName !== root.screenRecordingProcess
                                    ? i18n("%1 is recording your screen", root.screenRecordingAppName)
                                    : i18n("Your screen is being recorded")
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                    
                    // Camera
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing
                        visible: root.cameraInUse && Plasmoid.configuration.showCameraIndicator
                        
                        Kirigami.Icon {
                            source: root.cameraAppIcon || "camera"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            QQC2.Label {
                                text: root.cameraAppName && root.cameraAppName !== "" && root.cameraAppName !== root.cameraProcess
                                    ? i18n("%1 is using your camera", root.cameraAppName)
                                    : i18n("Your camera is being used")
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                    
                    // Microphone
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing
                        visible: root.microphoneInUse && Plasmoid.configuration.showMicrophoneIndicator
                        
                        Kirigami.Icon {
                            source: root.microphoneAppIcon || "audio-input-microphone"
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            
                            QQC2.Label {
                                text: root.microphoneAppName && root.microphoneAppName !== "" && root.microphoneAppName !== root.microphoneProcess
                                    ? i18n("%1 is using your microphone", root.microphoneAppName)
                                    : i18n("Your microphone is being used")
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
                
                Kirigami.Separator {
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    QQC2.Label {
                        text: i18n("Ring Light:")
                        Layout.fillWidth: true
                    }
                    
                    QQC2.Switch {
                        id: ringLightSwitch
                        checked: Plasmoid.configuration.ringLightEnabled
                        onToggled: {
                            Plasmoid.configuration.ringLightEnabled = checked
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    QQC2.Label {
                        text: i18n("Auto start on Camera Use:")
                        Layout.fillWidth: true
                    }
                    
                    QQC2.Switch {
                        id: autoStartSwitch
                        checked: Plasmoid.configuration.ringLightAutoStartOnCamera
                        onToggled: {
                            Plasmoid.configuration.ringLightAutoStartOnCamera = checked
                        }
                    }
                }
                
                // Slider-uri pentru Ring Light (vizibile doar când este activat)
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: Plasmoid.configuration.ringLightEnabled
                    spacing: Kirigami.Units.smallSpacing
                    
                    Kirigami.Separator {
                        Layout.fillWidth: true
                    }
                    
                    // Slider pentru raza cercului (vizibil doar când e pe Circle)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        visible: Plasmoid.configuration.ringLightShape
                        
                        QQC2.Label {
                            text: i18n("Radius: %1px", ringLightRadiusSlider.value)
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            
                            QQC2.Slider {
                                id: ringLightRadiusSlider
                                Layout.fillWidth: true
                                from: 50
                                to: Math.max(2000, Plasmoid.configuration.ringLightRadius + 500)
                                value: Plasmoid.configuration.ringLightRadius
                                stepSize: 10
                                onValueChanged: {
                                    if (value > ringLightRadiusSlider.to) {
                                        ringLightRadiusSlider.to = value + 500
                                    }
                                    Plasmoid.configuration.ringLightRadius = value
                                }
                            }
                            
                            QQC2.SpinBox {
                                from: 50
                                to: 10000
                                value: Plasmoid.configuration.ringLightRadius
                                stepSize: 10
                                editable: true
                                onValueChanged: {
                                    if (value > ringLightRadiusSlider.to) {
                                        ringLightRadiusSlider.to = value + 500
                                    }
                                    Plasmoid.configuration.ringLightRadius = value
                                    ringLightRadiusSlider.value = value
                                }
                            }
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        visible: !Plasmoid.configuration.ringLightShape
                        
                        QQC2.Label {
                            text: i18n("Width: %1px", ringLightWidthSlider.value)
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            
                            QQC2.Slider {
                                id: ringLightWidthSlider
                                Layout.fillWidth: true
                                from: 100
                                to: Math.max(10000, Plasmoid.configuration.ringLightWidth + 1000)
                                value: Plasmoid.configuration.ringLightWidth
                                stepSize: 10
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightWidth = value
                                }
                            }
                            
                            QQC2.SpinBox {
                                from: 1
                                to: 999999
                                value: ringLightWidthSlider.value
                                stepSize: 10
                                editable: true
                                onValueChanged: {
                                    if (value > ringLightWidthSlider.to) {
                                        ringLightWidthSlider.to = value + 1000
                                    }
                                    Plasmoid.configuration.ringLightWidth = value
                                    ringLightWidthSlider.value = value
                                }
                            }
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        visible: !Plasmoid.configuration.ringLightShape
                        
                        QQC2.Label {
                            text: i18n("Height: %1px", ringLightHeightSlider.value)
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            
                            QQC2.Slider {
                                id: ringLightHeightSlider
                                Layout.fillWidth: true
                                from: 100
                                to: Math.max(10000, Plasmoid.configuration.ringLightHeight + 1000)
                                value: Plasmoid.configuration.ringLightHeight
                                stepSize: 10
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightHeight = value
                                }
                            }
                            
                            QQC2.SpinBox {
                                from: 1
                                to: 999999
                                value: ringLightHeightSlider.value
                                stepSize: 10
                                editable: true
                                onValueChanged: {
                                    if (value > ringLightHeightSlider.to) {
                                        ringLightHeightSlider.to = value + 1000
                                    }
                                    Plasmoid.configuration.ringLightHeight = value
                                    ringLightHeightSlider.value = value
                                }
                            }
                        }
                    }
                    
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    QQC2.Label {
                        text: i18n("Shape:")
                        Layout.fillWidth: true
                    }
                    
                    QQC2.Switch {
                        id: ringLightShapeSwitch
                        checked: Plasmoid.configuration.ringLightShape
                        text: checked ? i18n("Circle") : i18n("Screen")
                        onToggled: {
                            Plasmoid.configuration.ringLightShape = checked
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    QQC2.Label {
                        text: i18n("Color Mode:")
                        Layout.fillWidth: true
                    }
                    
                    QQC2.Switch {
                        id: ringLightColorModeSwitch
                        checked: Plasmoid.configuration.ringLightUseWhite
                        text: checked ? i18n("White") : i18n("Color")
                        onToggled: {
                            Plasmoid.configuration.ringLightUseWhite = checked
                        }
                    }
                }
                    
                    // Slider pentru temperatura (Cool/Warm) - vizibil doar când e pe White
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: Plasmoid.configuration.ringLightUseWhite
                        spacing: Kirigami.Units.smallSpacing
                        
                        QQC2.Label {
                            text: i18n("Temperature: %1", ringLightTemperatureSlider.value < 50 ? i18n("Cool") : i18n("Warm"))
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            
                            QQC2.Slider {
                                id: ringLightTemperatureSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: Plasmoid.configuration.ringLightTemperature
                                stepSize: 1
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightTemperature = value
                                }
                            }
                            
                            QQC2.SpinBox {
                                from: 0
                                to: 100
                                value: ringLightTemperatureSlider.value
                                stepSize: 1
                                editable: true
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightTemperature = value
                                    ringLightTemperatureSlider.value = value
                                }
                            }
                        }
                    }
                    
                    // Slider pentru hue - vizibil doar când e pe Color
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !Plasmoid.configuration.ringLightUseWhite
                        spacing: Kirigami.Units.smallSpacing
                        
                        QQC2.Label {
                            text: i18n("Hue: %1°", ringLightHueSlider.value)
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            
                            QQC2.Slider {
                                id: ringLightHueSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 360
                                value: Plasmoid.configuration.ringLightHue
                                stepSize: 1
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightHue = value
                                }
                            }
                            
                            QQC2.SpinBox {
                                from: 0
                                to: 360
                                value: ringLightHueSlider.value
                                stepSize: 1
                                editable: true
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightHue = value
                                    ringLightHueSlider.value = value
                                }
                            }
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        
                        QQC2.Label {
                            text: i18n("Thickness: %1px", ringLightThicknessSlider.value)
                            Layout.fillWidth: true
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            
                            QQC2.Slider {
                                id: ringLightThicknessSlider
                                Layout.fillWidth: true
                                from: 2
                                to: 500
                                value: Plasmoid.configuration.ringLightThickness
                                stepSize: 1
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightThickness = value
                                }
                            }
                            
                            QQC2.SpinBox {
                                from: 2
                                to: 500
                                value: ringLightThicknessSlider.value
                                stepSize: 1
                                editable: true
                                onValueChanged: {
                                    Plasmoid.configuration.ringLightThickness = value
                                    ringLightThicknessSlider.value = value
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    Window {
        id: ringLightWindow
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowTransparentForInput | Qt.BypassWindowManagerHint | Qt.WindowDoesNotAcceptFocus | Qt.Tool
        color: "transparent"
        visible: Plasmoid.configuration.ringLightEnabled
        
        property int borderThickness: Plasmoid.configuration.ringLightThickness
        property int cornerRadius: 20
        
        function calculateBorderColor() {
            if (Plasmoid.configuration.ringLightUseWhite) {
                // Modul White: calculează temperatura de culoare (cool = albastru, warm = portocaliu/roșu)
                var temp = Plasmoid.configuration.ringLightTemperature / 100.0
                // Cool (0) = albastru, Warm (100) = portocaliu/roșu
                var r = 255
                var g = 255 - (temp * 100) // Scade verde pentru warm
                var b = 255 - (temp * 150) // Scade albastru pentru warm
                return Qt.rgba(r / 255, g / 255, b / 255, 1.0)
            } else {
                // Modul Color: folosește hue pentru a crea o culoare
                var hue = Plasmoid.configuration.ringLightHue / 360.0
                return Qt.hsla(hue, 1.0, 0.5, 1.0)
            }
        }
        
        property color borderColor: calculateBorderColor()
        
        Component.onCompleted: {
            updateGeometry()
        }
        
        Connections {
            target: Plasmoid.configuration
            function onRingLightThicknessChanged() {
                ringLightWindow.borderThickness = Plasmoid.configuration.ringLightThickness
            }
            function onRingLightWidthChanged() {
                // Oprim și pornim Ring Light automat pentru a se centra corect
                if (Plasmoid.configuration.ringLightEnabled) {
                    Plasmoid.configuration.ringLightEnabled = false
                    Qt.callLater(function() {
                        Plasmoid.configuration.ringLightEnabled = true
                    })
                }
            }
            function onRingLightHeightChanged() {
                // Oprim și pornim Ring Light automat pentru a se centra corect
                if (Plasmoid.configuration.ringLightEnabled) {
                    Plasmoid.configuration.ringLightEnabled = false
                    Qt.callLater(function() {
                        Plasmoid.configuration.ringLightEnabled = true
                    })
                }
            }
            function onRingLightUseWhiteChanged() {
                ringLightWindow.borderColor = ringLightWindow.calculateBorderColor()
            }
            function onRingLightTemperatureChanged() {
                if (Plasmoid.configuration.ringLightUseWhite) {
                    ringLightWindow.borderColor = ringLightWindow.calculateBorderColor()
                }
            }
            function onRingLightHueChanged() {
                if (!Plasmoid.configuration.ringLightUseWhite) {
                    ringLightWindow.borderColor = ringLightWindow.calculateBorderColor()
                }
            }
            function onRingLightShapeChanged() {
                // Oprim și pornim Ring Light automat pentru a se centra corect
                if (Plasmoid.configuration.ringLightEnabled) {
                    Plasmoid.configuration.ringLightEnabled = false
                    Qt.callLater(function() {
                        Plasmoid.configuration.ringLightEnabled = true
                    })
                }
            }
            function onRingLightRadiusChanged() {
                // Oprim și pornim Ring Light automat pentru a se centra corect
                if (Plasmoid.configuration.ringLightEnabled) {
                    Plasmoid.configuration.ringLightEnabled = false
                    Qt.callLater(function() {
                        Plasmoid.configuration.ringLightEnabled = true
                    })
                }
            }
        }
        
        function updateGeometry() {
            // Folosim Screen pentru a obține dimensiunile complete ale ecranului
            var screen = Qt.application.screens && Qt.application.screens.length > 0 ? Qt.application.screens[0] : null
            var centerX = 0
            var centerY = 0
            
            // Calculăm centrul perfect al ecranului
            if (screen && screen.virtualGeometry) {
                var vg = screen.virtualGeometry
                centerX = vg.x + vg.width / 2
                centerY = vg.y + vg.height / 2
            } else if (screen && screen.geometry) {
                var geom = screen.geometry
                centerX = geom.x + geom.width / 2
                centerY = geom.y + geom.height / 2
            } else {
                // Fallback folosind Screen global
                centerX = Screen.width / 2
                centerY = Screen.height / 2
            }
            
            if (Plasmoid.configuration.ringLightShape) {
                // Modul Circle: fereastra trebuie să fie suficient de mare pentru cerc
                var radius = Plasmoid.configuration.ringLightRadius || 400
                var diameter = radius * 2 + ringLightWindow.borderThickness * 2
                
                // Calculăm poziția centrată perfect pe ecran
                var finalX = centerX - diameter / 2
                var finalY = centerY - diameter / 2
                
                // Setăm dimensiunile înainte de poziție pentru a evita probleme de layout
                ringLightWindow.width = diameter
                ringLightWindow.height = diameter
                
                // Setăm poziția centrată perfect + offset
                ringLightWindow.x = Math.round(finalX)
                ringLightWindow.y = Math.round(finalY)
            } else {
                // Modul Screen: bordurile pe ecran
                var newWidth = Plasmoid.configuration.ringLightWidth || 1920
                var newHeight = Plasmoid.configuration.ringLightHeight || 1080
                
                // Calculăm poziția centrată perfect pe ecran
                // Pentru a centra forma simetric:
                // - X: centru - width/2 (se extinde egal stânga și dreapta)
                // - Y: centru - height/2 (se extinde egal sus și jos)
                var finalX = centerX - newWidth / 2
                var finalY = centerY - newHeight / 2
                
                // IMPORTANT: Setăm poziția ÎNAINTE de dimensiuni pentru a evita extinderea într-o singură direcție
                // Apoi setăm dimensiunile pentru a extinde forma simetric
                ringLightWindow.x = Math.round(finalX)
                ringLightWindow.y = Math.round(finalY)
                
                // Setăm dimensiunile după poziție pentru a extinde forma simetric
                ringLightWindow.width = newWidth
                ringLightWindow.height = newHeight
            }
        }
        
        onVisibleChanged: {
            if (visible) {
                updateGeometry()
            }
        }
        
        onScreenChanged: {
            if (visible) {
                updateGeometry()
            }
        }
        
        // Recalculăm poziția și redesenează forma când se schimbă dimensiunile
        // Folosim updateGeometry() complet pentru a reașeza forma în mijloc, similar cu când se pornește Ring Light
        onWidthChanged: {
            if (visible) {
                // Recalculăm totul pentru a reașeza forma complet în mijloc
                updateGeometry()
            }
        }
        
        onHeightChanged: {
            if (visible) {
                // Recalculăm totul pentru a reașeza forma complet în mijloc
                updateGeometry()
            }
        }
        
        Item {
            anchors.fill: parent
            
            // Modul Circle: afișăm un cerc
            Rectangle {
                anchors.centerIn: parent
                width: (Plasmoid.configuration.ringLightRadius || 400) * 2
                height: (Plasmoid.configuration.ringLightRadius || 400) * 2
                radius: width / 2
                color: "transparent"
                border.width: ringLightWindow.borderThickness
                border.color: ringLightWindow.borderColor
                visible: Plasmoid.configuration.ringLightShape
            }
            
            // Modul Screen: bordurile pe ecran cu colțuri rotunjite
            Item {
                anchors.fill: parent
                visible: !Plasmoid.configuration.ringLightShape
                
                // Bordură cu colțuri rotunjite exterioare
                // Notă: QML Rectangle nu suportă colțuri rotunjite interioare perfecte
                // Colțurile exterioare sunt rotunjite, iar grosimea bordurii este respectată
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: ringLightWindow.borderThickness
                    border.color: ringLightWindow.borderColor
                    radius: ringLightWindow.cornerRadius
                }
            }
        }
    }

    PlasmaCore.Dialog {
        id: piriDialog
        visible: !root.piriStatusReady
        location: Plasmoid.location
        type: PlasmaCore.Dialog.AppletPopup
        flags: Qt.FramelessWindowHint | Qt.Popup | Qt.WindowDoesNotAcceptFocus | Qt.WindowTransparentForInput
        backgroundHints: PlasmaCore.Types.NoBackground
        hideOnWindowDeactivate: false
        visualParent: root

        mainItem: WebEngineView {
            width: 200
            height: 200
            url: Qt.resolvedUrl("../assets/index.html").toString()
            backgroundColor: "transparent"
        }
    }
}



