// A run of recent samples, as little vertical bars.
//
// Bars rather than a line: at fourteen pixels tall a polyline is one aliased
// diagonal per step and reads as fuzz, while a rectangle stays a rectangle. Qt
// would draw either, so this is a legibility choice at this size, not a
// technical one.
//
// Nothing here scrolls or animates. A new sample replaces the array and the
// whole run redraws, which at forty rectangles is far cheaper than any scheme
// for sliding the old ones along would be.

import QtQuick
import "root:/theme"

Item {
    id: root

    // Oldest first, newest last -- the order services/Sys.qml records them in.
    // Shorter than `count` is fine: the run grows in from the right as samples
    // arrive, rather than padding the past with zeroes it never measured.
    property var values: []

    property int count: 16
    property real maximum: 100

    property color color: Theme.text
    property real barWidth: 2
    property real barSpacing: 1

    implicitWidth: root.count * root.barWidth + (root.count - 1) * root.barSpacing
    implicitHeight: 14

    readonly property var window: root.values.slice(-root.count)

    // Right-aligned and bottom-aligned: the newest sample sits against the
    // right edge, so the line stays put as history fills in behind it.
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height
        spacing: root.barSpacing

        // Modelled on the *count* rather than on the array. Every new sample
        // replaces `values` with a fresh array, and a Repeater handed that
        // would destroy and rebuild every bar three seconds apart forever;
        // handed a length that only changes while history is still filling, it
        // rebuilds nothing and just re-evaluates the heights.
        Repeater {
            model: root.window.length

            // Each column is drawn twice: a full-height ghost, and the sample
            // on top of it. The ghost is what makes a low reading legible --
            // an idle CPU is a run of one-pixel marks, which on its own looks
            // like a dotted rule or a rendering fault rather than like 3%.
            // Against a column you can see the empty space it did not fill.
            Item {
                id: column

                required property int index

                readonly property real fraction: Math.max(0, Math.min(1, Number(root.window[column.index]) / root.maximum))

                width: root.barWidth
                height: root.height

                Rectangle {
                    anchors.fill: parent
                    color: root.color
                    opacity: 0.16
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width

                    // Never zero-height: a sample that measured 0% is still a
                    // sample, and a gap in the run would read as missing data.
                    height: Math.max(1, column.fraction * parent.height)

                    color: root.color
                    opacity: 0.95
                }
            }
        }
    }
}
