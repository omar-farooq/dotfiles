// The mixer under the volume pill.
//
// This is what the pill's click used to launch pavucontrol for. Everything here
// is a thing the pill itself cannot express: which output the sound is going
// to, what else exists to send it to, and which applications are making noise
// at what level. The pill stays the summary -- one icon, one number.
//
// pavucontrol is not gone, only demoted: middle-clicking the pill still opens
// it, for the routing and per-device work this deliberately does not cover.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "root:/theme"
import "root:/components"
import "root:/services"

Popout {
    id: root

    readonly property int contentWidth: 300

    // Rows are pill-height so a label, an icon and a percentage sit on one line
    // without any of them having to be nudged vertically.
    readonly property int rowHeight: Theme.pillHeight

    Column {
        spacing: 8

        // -------------------------------------------------------------
        // The default output: the same number the pill shows, with the
        // slider the pill has no room for.
        // -------------------------------------------------------------

        Item {
            width: root.contentWidth
            height: root.rowHeight

            IconButton {
                id: masterMute

                anchors.left: parent.left
                icon: Icons.forVolume(Audio.volume, Audio.muted)
                color: Audio.muted ? Theme.danger : Theme.text

                onClicked: Audio.toggleMute(Audio.sink)
            }

            PanelText {
                anchors.left: masterMute.right
                anchors.leftMargin: 10
                anchors.right: masterLevel.left
                anchors.rightMargin: 8
                height: parent.height
                text: Audio.label(Audio.sink)
                elide: Text.ElideRight
                font.weight: Font.DemiBold
            }

            PanelText {
                id: masterLevel

                anchors.right: parent.right
                height: parent.height
                text: Audio.muted ? "muted" : `${Audio.volume}%`
                opacity: 0.7
            }
        }

        Slider {
            width: root.contentWidth
            value: Audio.audio ? Audio.audio.volume : 0
            opacity: Audio.muted ? 0.4 : 1.0

            onMoved: value => Audio.setVolume(Audio.sink, value)
        }

        // -------------------------------------------------------------
        // Where the sound goes. A tick beside the one in use, the same way
        // the wallpaper effect picker marks the effect in force.
        // -------------------------------------------------------------

        Heading {
            width: root.contentWidth
            text: "Output"
        }

        // Flush rows, no spacing: the hover highlight is a full-height pill, so
        // a gap between rows would show as a break in what is one list.
        Column {
            width: root.contentWidth
            spacing: 0

            Repeater {
                model: Audio.sinks

                Item {
                    id: device

                    required property var modelData

                    readonly property bool current: Audio.sink && Audio.sink.id === device.modelData.id

                    width: root.contentWidth
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: -6
                        anchors.rightMargin: -6
                        radius: height / 2
                        color: Theme.surface
                        opacity: hover.containsMouse ? 0.35 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.animation
                            }
                        }
                    }

                    BarIcon {
                        id: tick

                        anchors.left: parent.left
                        text: Icons.check
                        opacity: device.current ? 1.0 : 0.0
                    }

                    PanelText {
                        anchors.left: tick.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        height: parent.height
                        text: Audio.label(device.modelData)
                        elide: Text.ElideRight
                        opacity: device.current ? 1.0 : 0.65
                    }

                    MouseArea {
                        id: hover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Audio.setSink(device.modelData)
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // What is making the noise.
        // -------------------------------------------------------------

        Heading {
            width: root.contentWidth
            text: "Playing"
        }

        Column {
            width: root.contentWidth
            spacing: 8

            PanelText {
                height: root.rowHeight
                text: "Nothing playing"
                opacity: 0.4
                visible: Audio.streams.length === 0
            }

            Repeater {
                model: Audio.streams

                Item {
                    id: stream

                    required property var modelData

                    readonly property var streamAudio: stream.modelData.audio
                    readonly property bool streamMuted: stream.streamAudio ? stream.streamAudio.muted : false
                    readonly property real streamVolume: stream.streamAudio ? stream.streamAudio.volume : 0

                    width: root.contentWidth
                    height: root.rowHeight + 18

                    IconButton {
                        id: streamMute

                        anchors.left: parent.left
                        anchors.top: parent.top
                        icon: Icons.forVolume(stream.streamVolume * 100, stream.streamMuted)
                        color: stream.streamMuted ? Theme.danger : Theme.text

                        onClicked: Audio.toggleMute(stream.modelData)
                    }

                    PanelText {
                        anchors.left: streamMute.right
                        anchors.leftMargin: 10
                        anchors.right: streamLevel.left
                        anchors.rightMargin: 8
                        anchors.top: parent.top
                        height: root.rowHeight
                        // The tab or track title, not the application: two
                        // Firefox windows are both "Firefox" and there would be
                        // no telling which slider was which.
                        text: Audio.streamLabel(stream.modelData)
                        elide: Text.ElideRight
                    }

                    PanelText {
                        id: streamLevel

                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: root.rowHeight
                        text: stream.streamMuted ? "muted" : `${Math.round(stream.streamVolume * 100)}%`
                        opacity: 0.7
                    }

                    Slider {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        value: stream.streamVolume
                        opacity: stream.streamMuted ? 0.4 : 1.0
                        fillColor: Theme.surface

                        onMoved: value => Audio.setVolume(stream.modelData, value)
                    }
                }
            }
        }
    }
}
