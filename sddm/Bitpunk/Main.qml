import QtQuick 2.0
import QtQuick.Window 2.0
import SddmComponents 2.0

Rectangle {
    id: container
    width: Screen.width
    height: Screen.height

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
        function onLoginFailed() {
            password.text = ""
            errorMessage.text = textConstants.loginFailed
        }
    }

    // Background - near black for OLED
    Rectangle {
        anchors.fill: parent
        color: "#050505"
    }

    // Background image from config
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        visible: config.background !== undefined && config.background !== ""
    }

    // Subtle grid pattern overlay
    Canvas {
        anchors.fill: parent
        opacity: 0.03
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = "#0ABDC6"
            ctx.lineWidth = 0.5
            var gridSize = 40

            for (var x = 0; x < width; x += gridSize) {
                ctx.beginPath()
                ctx.moveTo(x, 0)
                ctx.lineTo(x, height)
                ctx.stroke()
            }
            for (var y = 0; y < height; y += gridSize) {
                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(width, y)
                ctx.stroke()
            }
        }
    }

    // Clock in top right
    Column {
        anchors {
            top: parent.top
            right: parent.right
            margins: 40
        }
        spacing: 4

        Text {
            id: timeLabel
            anchors.right: parent.right
            font.family: "JetBrains Mono"
            font.pixelSize: 56
            color: "#0ABDC6"

            function updateTime() {
                text = Qt.formatTime(new Date(), "HH:mm")
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: timeLabel.updateTime()
            }

            Component.onCompleted: updateTime()
        }

        Text {
            id: dateLabel
            anchors.right: parent.right
            font.family: "Inter"
            font.pixelSize: 16
            color: "#8A9BAD"
            text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
        }
    }

    // Main login panel - centered
    Rectangle {
        id: loginPanel
        anchors.centerIn: parent
        width: 380
        height: loginColumn.height + 60
        color: "#131A24"
        radius: 8
        border.color: "#08919A"
        border.width: 1

        // Subtle glow effect
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            radius: 10
            color: "transparent"
            border.color: "#0ABDC6"
            border.width: 1
            opacity: 0.3
        }

        Column {
            id: loginColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 30
            }
            spacing: 12

            // User icon placeholder
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 80
                height: 80
                radius: 40
                color: "#0A0E14"
                border.color: "#08919A"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: userName.text.length > 0 ? userName.text.charAt(0).toUpperCase() : "?"
                    font.pixelSize: 32
                    font.family: "Inter"
                    color: "#0ABDC6"
                }
            }

            // Username
            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Username"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#8A9BAD"
                }

                TextBox {
                    id: userName
                    width: parent.width
                    height: 40
                    text: userModel.lastUser
                    font.family: "Inter"
                    font.pixelSize: 14
                    color: "#0A0E14"
                    borderColor: "#08919A"
                    focusColor: "#0ABDC6"
                    hoverColor: "#131A24"
                    textColor: "#E0E8F0"

                    KeyNavigation.tab: password

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            password.focus = true
                            event.accepted = true
                        }
                    }
                }
            }

            // Password
            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: "Password"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#8A9BAD"
                }

                PasswordBox {
                    id: password
                    width: parent.width
                    height: 40
                    font.family: "Inter"
                    font.pixelSize: 14
                    color: "#0A0E14"
                    borderColor: "#08919A"
                    focusColor: "#0ABDC6"
                    hoverColor: "#131A24"
                    textColor: "#E0E8F0"
                    tooltipBG: "#131A24"
                    tooltipFG: "#E0E8F0"

                    KeyNavigation.backtab: userName
                    KeyNavigation.tab: loginButton

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(userName.text, password.text, session.index)
                            event.accepted = true
                        }
                    }
                }
            }

            // Error message
            Text {
                id: errorMessage
                width: parent.width
                height: 20
                font.family: "Inter"
                font.pixelSize: 12
                color: "#FF4A57"
                horizontalAlignment: Text.AlignHCenter
            }

            // Login button
            Button {
                id: loginButton
                width: parent.width
                height: 44
                text: "LOGIN"
                font.family: "Inter"
                font.pixelSize: 14
                color: "#0ABDC6"
                textColor: "#050505"
                borderColor: "#0ABDC6"
                activeColor: "#EA00D9"
                pressedColor: "#08919A"

                onClicked: sddm.login(userName.text, password.text, session.index)

                KeyNavigation.backtab: password
                KeyNavigation.tab: session
            }

            // Session selector
            Row {
                width: parent.width
                spacing: 8

                Text {
                    text: "Session:"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#8A9BAD"
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: session
                    width: parent.width - 60
                    height: 30
                    model: sessionModel
                    index: sessionModel.lastIndex
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#0A0E14"
                    textColor: "#E0E8F0"
                    borderColor: "#08919A"
                    focusColor: "#0ABDC6"
                    hoverColor: "#131A24"
                    arrowColor: "#0ABDC6"
                    menuColor: "#131A24"

                    KeyNavigation.backtab: loginButton
                }
            }
        }
    }

    // Bottom bar with power buttons
    Rectangle {
        id: bottomBar
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: 60
        color: "transparent"

        // Hostname left
        Text {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                margins: 40
            }
            text: sddm.hostName
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            color: "#8A9BAD"
            opacity: 0.6
        }

        // Power buttons right
        Row {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 40
            }
            spacing: 16

            ImageButton {
                id: rebootButton
                width: 32
                height: 32
                source: "reboot.svg"
                visible: sddm.canReboot
                onClicked: sddm.reboot()

                KeyNavigation.backtab: session
                KeyNavigation.tab: shutdownButton
            }

            ImageButton {
                id: shutdownButton
                width: 32
                height: 32
                source: "shutdown.svg"
                visible: sddm.canPowerOff
                onClicked: sddm.powerOff()

                KeyNavigation.backtab: rebootButton
                KeyNavigation.tab: userName
            }
        }
    }

    Component.onCompleted: {
        if (userName.text === "") {
            userName.focus = true
        } else {
            password.focus = true
        }
    }
}
