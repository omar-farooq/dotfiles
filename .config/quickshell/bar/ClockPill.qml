// Clock. Click drops the month calendar out of the pill; right-click swaps the
// label between time and date, as waybar's format-alt did.
//
// The two used to be one gesture -- a left click was the only thing waybar gave
// a module, so it had to carry the date. Now the date has somewhere better to
// live, the swap keeps its place on the right button rather than being deleted:
// it is still the quickest way to read the date without a panel opening over
// whatever is underneath.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"

Pill {
    id: root

    property bool showDate: false

    accent: Theme.surfaceStrong

    onClicked: calendar.open = !calendar.open
    onRightClicked: root.showDate = !root.showDate

    // Minute precision. The bar shows no seconds, so waking once a second to
    // redraw an identical string is wasted work.
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    BarText {
        text: Qt.formatDateTime(clock.date, root.showDate ? "yyyy-MM-dd" : "HH:mm ddd")
    }

    // Hangs off this pill, so each monitor's bar gets its own -- and the one you
    // clicked is the one that opens. Not a visual child of the Row despite
    // sitting inside it: a window is a plain object as far as a Row is
    // concerned, so it takes no space in the pill.
    CalendarPopout {
        id: calendar

        anchorItem: root
    }
}
