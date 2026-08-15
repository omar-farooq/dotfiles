pragma Singleton

// Which popout is open -- and there is only ever one.
//
// Each popout hangs off its own pill and knows nothing about the others, so two
// pills clicked in turn left two panels on screen at once. That is survivable
// with two of them and not with five: a bar that accumulates panels until you
// go back and click each pill a second time is a bar you have to tidy up after.
//
// Doing it here rather than inside Popout is the point. `current` *is* the open
// popout and every Popout's visibility is a binding onto it, so opening one
// closes the last by construction -- there is no sequence of clicks that leaves
// two visible, and no state to keep in sync when one is added.
//
// One at a time is global rather than per monitor: opening the calendar on the
// second screen closes the mixer on the first. Deliberate, if debatable. A
// popout is the detail behind a pill you just clicked, so the useful invariant
// is "the thing on screen is the thing I last asked for", and that is a
// property of the session rather than of a monitor.

import Quickshell

Singleton {
    id: root

    // The popout on screen, or null when none is. Go through the functions
    // below rather than assigning it: they are the whole API, and they keep a
    // caller that means *this* panel from writing code that means whichever
    // panel happens to be open at the time.
    property var current: null

    // What a pill's click does. Clicking the pill whose popout is open shuts
    // it; clicking any other swaps to that one.
    function toggle(popout) {
        root.current = root.current === popout ? null : popout;
    }

    // For a popout closing itself -- picking a row that ends the interaction,
    // say. Guarded so a stale caller cannot close a panel it does not own.
    function close(popout) {
        if (root.current === popout)
            root.current = null;
    }
}
