/*
    Bitpunk Splash Screen for KDE Plasma 6
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami 2 as Kirigami

Rectangle {
    id: root
    color: "#050505"

    property int stage

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true
        }
    }

    // Subtle scan lines overlay
    Item {
        id: scanLines
        anchors.fill: parent
        opacity: 0.02

        Repeater {
            model: Math.ceil(parent.height / 2)
            Rectangle {
                width: parent.width
                height: 1
                y: index * 2
                color: "#0ABDC6"
            }
        }
    }

    // Main content container
    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        // Pulsing skull icon
        Item {
            id: skullContainer
            anchors.centerIn: parent
            width: Kirigami.Units.gridUnit * 8
            height: Kirigami.Units.gridUnit * 8

            property real pulsePhase: 0

            // Animate pulse phase
            NumberAnimation on pulsePhase {
                from: 0
                to: 1
                duration: 1500
                loops: Animation.Infinite
                running: content.opacity > 0.5
                easing.type: Easing.InOutSine
            }

            // Cyan skull
            Image {
                id: skullCyan
                anchors.centerIn: parent
                source: "images/skull.svg"
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            ColorOverlay {
                anchors.fill: skullCyan
                source: skullCyan
                color: "#0ABDC6"
                opacity: 1 - skullContainer.pulsePhase
                scale: 1 + (skullContainer.pulsePhase * 0.05)
                transformOrigin: Item.Center
            }

            // Magenta skull
            Image {
                id: skullMagenta
                anchors.centerIn: parent
                source: "images/skull.svg"
                sourceSize.width: parent.width
                sourceSize.height: parent.height
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            ColorOverlay {
                anchors.fill: skullMagenta
                source: skullMagenta
                color: "#EA00D9"
                opacity: skullContainer.pulsePhase
                scale: 1 + ((1 - skullContainer.pulsePhase) * 0.05)
                transformOrigin: Item.Center
            }
        }

        // Progress bar container
        Item {
            id: progressContainer
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Kirigami.Units.gridUnit * 4
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.35
            height: 3

            // Background track
            Rectangle {
                anchors.fill: parent
                color: "#1C2632"
                radius: 1
            }

            // Progress fill
            Rectangle {
                id: progressBar
                height: parent.height
                radius: 1
                width: (stage - 1) * (parent.width / 6)

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#0ABDC6" }
                    GradientStop { position: 1.0; color: "#EA00D9" }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // Progress pulse
            Rectangle {
                height: parent.height
                width: 15
                x: progressBar.width - 7
                radius: 1
                opacity: 0.5

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#0ABDC6" }
                    GradientStop { position: 1.0; color: "transparent" }
                }

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.7; duration: 600 }
                    NumberAnimation { to: 0.2; duration: 600 }
                }
            }
        }
    }

    // Fade in animation
    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
