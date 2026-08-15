// A horizontal slider.
//
// Not QtQuick.Controls' Slider: that arrives with a style whose handle, groove
// and hover states would all have to be overridden away, and what is left after
// that is the twenty lines below.
//
// It does not write its own `value`. The owner sets the real thing -- a
// PipeWire volume, say -- and the new value arrives back through the binding,
// so there is never a moment where the handle and the thing it controls
// disagree about where it is.

import QtQuick
import "root:/theme"

Item {
    id: root

    // 0..1.
    property real value: 0

    property color fillColor: Theme.surfaceStrong
    property int trackHeight: 6

    // Wheel step, matching the volume pill's.
    property real step: 0.02

    signal moved(real value)

    implicitHeight: 18
    implicitWidth: 120

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.14)

        Rectangle {
            width: root.clamp(root.value) * parent.width
            height: parent.height
            radius: parent.radius
            color: root.fillColor
        }
    }

    // The handle is drawn outside the track so it can be taller than it, which
    // is what makes a 6px groove aimable.
    Rectangle {
        x: root.clamp(root.value) * root.width - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: height / 2
        color: Theme.text
        opacity: mouse.containsMouse || mouse.pressed ? 1.0 : 0.85

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation
            }
        }
    }

    // MouseArea rather than DragHandler: pointer handlers receive nothing on
    // these layer-shell surfaces. See Pill.
    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        // Pressing anywhere on the track jumps there and starts dragging from
        // that point, rather than requiring the handle to be hit first.
        onPressed: event => root.moved(root.clamp(event.x / root.width))
        onPositionChanged: event => {
            if (mouse.pressed)
                root.moved(root.clamp(event.x / root.width));
        }

        onWheel: event => root.moved(root.clamp(root.value + (event.angleDelta.y > 0 ? root.step : -root.step)))
    }
}
