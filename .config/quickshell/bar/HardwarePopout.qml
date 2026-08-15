// The hardware panel under the system drawer.
//
// The drawer answers "is anything busy" in three numbers. This answers the
// question that follows -- *what* is busy -- which the pill has never had room
// for: twenty cores individually, and how much of the memory and the disk is
// actually gone rather than what fraction it works out to.
//
// Per core is the point of it. A single CPU percentage hides the difference
// between a machine with every core at 40% and a machine with one core pegged
// and nineteen idle, and those are entirely different situations: the first is
// a load, the second is something stuck.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"
import "root:/services"

Popout {
    id: root

    readonly property int contentWidth: 300

    // Two columns of cores, with a gutter between them.
    readonly property int columnGap: 14
    readonly property int columnWidth: (root.contentWidth - root.columnGap) / 2

    // Nearly full memory or disk is drawn as a warning rather than as a level:
    // both are things you have to go and fix, and a bar that is merely longer
    // than yesterday's does not say so.
    //
    // Cores deliberately do not get this. A core at 100% is a core doing its
    // job -- every compile would light four of them orange, and a warning that
    // appears whenever the machine is working is one you stop reading. Busy
    // cores are already unmistakable next to idle ones from bar length alone.
    readonly property int high: 90

    function tint(percent) {
        return percent >= root.high ? Theme.warning : Theme.surfaceStrong;
    }

    // Bytes as GiB. The figures here are all tens of gigabytes, so one decimal
    // place is the useful precision -- "11.2 GiB" moves visibly as memory
    // fills, "11 GiB" sits still for an hour and "11.23 GiB" is noise.
    function gib(bytes) {
        return (bytes / (1024 * 1024 * 1024)).toFixed(1);
    }

    Column {
        spacing: 8

        // -------------------------------------------------------------
        // CPU: the same number the drawer shows, its recent history, and
        // then the cores it is an average of.
        // -------------------------------------------------------------

        Item {
            width: root.contentWidth
            height: 20

            PanelText {
                anchors.left: parent.left
                height: parent.height
                text: "CPU"
                font.weight: Font.DemiBold
            }

            PanelText {
                anchors.right: parent.right
                height: parent.height
                text: `${Sys.cpu}%`
                opacity: 0.7
            }
        }

        // The full history, unlike the drawer's abridged run -- there is room
        // for all forty samples here, which is two minutes of past.
        Sparkline {
            width: root.contentWidth
            height: 38
            count: Sys.historyLength
            barWidth: 6
            barSpacing: 1.5
            values: Sys.cpuHistory
            color: Theme.surfaceStrong
            opacity: 0.9
        }

        // Column-major, so the core numbers read downwards like a list instead
        // of zig-zagging across the panel. `rows` is derived rather than fixed
        // at ten: this machine has twenty cores, the next one might not.
        Grid {
            columns: 2
            rows: Math.ceil(Sys.cores.length / 2)
            flow: Grid.TopToBottom
            columnSpacing: root.columnGap
            rowSpacing: 2

            // The core count, not the array of readings: Sys replaces that
            // array every sample, and a Repeater modelled on it would rebuild
            // twenty rows of delegates every three seconds -- throwing away the
            // meters' animations along with them. The count only changes if the
            // machine grows a core.
            Repeater {
                model: Sys.cores.length

                Item {
                    id: core

                    required property int index

                    readonly property int percent: Number(Sys.cores[core.index] || 0)

                    width: root.columnWidth
                    height: 18

                    PanelText {
                        id: coreLabel

                        anchors.left: parent.left
                        width: 16
                        height: parent.height
                        text: core.index
                        font.pixelSize: Theme.fontSize - 3
                        opacity: 0.4
                    }

                    Meter {
                        anchors.left: coreLabel.right
                        anchors.right: corePercent.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        height: 5
                        value: core.percent / 100
                    }

                    PanelText {
                        id: corePercent

                        anchors.right: parent.right
                        width: 32
                        height: parent.height
                        horizontalAlignment: Text.AlignRight
                        text: `${core.percent}%`
                        font.pixelSize: Theme.fontSize - 2
                        opacity: 0.65
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // Memory and disk. Both get the figure as well as the fraction:
        // "34%" of an unstated total is not something you can act on, and
        // how many gigabytes are left is the thing you actually wanted.
        // -------------------------------------------------------------

        Heading {
            width: root.contentWidth
            text: "Memory"
        }

        Usage {
            percent: Sys.memory
            used: Sys.memoryUsed
            total: Sys.memoryTotal
        }

        Heading {
            width: root.contentWidth
            text: "Disk"
        }

        Usage {
            percent: Sys.disk
            used: Sys.diskUsed
            total: Sys.diskTotal

            // Root only, and said so -- the machine has other filesystems
            // mounted and this number is not about them.
            note: "/"
        }
    }

    // A bar with its figures under it. Local to this panel: it is the shape
    // memory and disk happen to share, not a pattern anything else has asked
    // for yet.
    component Usage: Item {
        id: usage

        property int percent: 0
        property real used: 0
        property real total: 0
        property string note: ""

        width: root.contentWidth
        height: 34

        Meter {
            id: bar

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 6
            value: usage.percent / 100
            fillColor: root.tint(usage.percent)
        }

        PanelText {
            anchors.top: bar.bottom
            anchors.left: parent.left
            height: parent.height - bar.height
            text: usage.total > 0 ? `${root.gib(usage.used)} of ${root.gib(usage.total)} GiB${usage.note ? ` on ${usage.note}` : ""}` : ""
            font.pixelSize: Theme.fontSize - 2
            opacity: 0.6
        }

        PanelText {
            anchors.top: bar.bottom
            anchors.right: parent.right
            height: parent.height - bar.height
            text: `${usage.percent}%`
            font.pixelSize: Theme.fontSize - 2
            opacity: 0.7
        }
    }
}
