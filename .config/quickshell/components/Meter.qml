// A read-only bar: how full one thing is.
//
// Not Slider with its input switched off -- the press-to-jump, the wheel step
// and the handle's hover state are most of that file, and what would be left
// after disabling them is the track below.

import QtQuick
import "root:/theme"

Rectangle {
    id: root

    // 0..1.
    property real value: 0

    property color fillColor: Theme.surfaceStrong

    implicitWidth: 120
    implicitHeight: 6

    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.14)

    readonly property real fraction: Math.max(0, Math.min(1, root.value))

    Rectangle {
        // A non-zero reading never renders as nothing: below about 2% the fill
        // is sub-pixel, so twenty idle cores would be twenty empty rules and
        // the panel would look broken rather than quiet. The floor is one
        // round cap's worth, which reads as "on, barely".
        width: root.fraction <= 0 ? 0 : Math.max(root.height, root.fraction * parent.width)
        height: parent.height
        radius: parent.radius
        color: root.fillColor

        // Sampled values arrive in steps; easing between them stops a grid of
        // these from flickering like a fault every time the poll comes round.
        Behavior on width {
            NumberAnimation {
                duration: Theme.animation
            }
        }
    }
}
