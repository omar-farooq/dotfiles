// Clock. Click toggles to the date, as waybar's format-alt did.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"

Pill {
    id: root

    property bool showDate: false

    accent: Theme.surfaceStrong

    onClicked: root.showDate = !root.showDate

    // Minute precision. The bar shows no seconds, so waking once a second to
    // redraw an identical string is wasted work.
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    BarText {
        text: Qt.formatDateTime(clock.date, root.showDate ? "yyyy-MM-dd" : "HH:mm ddd")
    }
}
