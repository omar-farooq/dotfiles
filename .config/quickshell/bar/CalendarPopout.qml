// The month calendar under the clock.
//
// waybar could do this -- its clock module had a tooltip calendar -- but only
// as a tooltip: it appeared on hover, could not be clicked, and so could never
// page to another month. This one is a real panel, which is the whole reason
// for pulling it out of the pill.
//
// All the date arithmetic is plain JS Date maths rather than QtQuick.Controls'
// MonthGrid. MonthGrid would bring the Controls styling stack in to draw seven
// numbers per row, and the only thing it actually knows that this file doesn't
// is which days spill over from the neighbouring months -- which is the four
// lines of buildDays() below.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/components"

Popout {
    id: root

    // Today, for the highlight. Repointed whenever the panel opens, and on the
    // hour while it is open so that a panel left open over midnight moves the
    // highlight with it.
    property date today: new Date()

    // The month on display. Initially bound to today, deliberately broken by
    // the first page() -- once you have paged away, midnight arriving should
    // not yank the view back.
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    // A day cell. Wide enough for two digits with room around them, and short
    // enough that six rows do not make the panel taller than it is wide.
    readonly property int cellWidth: 36
    readonly property int cellHeight: 30

    readonly property int gridWidth: cellWidth * 7

    // Whichever day the locale starts its weeks on. Locale's day numbering is
    // JS Date's -- Sunday 0 through Saturday 6 -- so the two mix freely below.
    readonly property int firstDay: Qt.locale().firstDayOfWeek

    // Always six rows, even when the month fits in five. A grid that changes
    // height as you page makes the whole panel jump under the pointer.
    readonly property var days: root.buildDays(root.viewYear, root.viewMonth)

    onOpenChanged: if (root.open)
        root.showToday()

    // The six weeks starting from the first day of the week the 1st falls in.
    // Days from the neighbouring months are kept rather than blanked, because a
    // grid that ends mid-row reads as broken rather than as finished.
    function buildDays(year, month) {
        const lead = (new Date(year, month, 1).getDay() - root.firstDay + 7) % 7;
        const out = [];

        for (let i = 0; i < 42; i++) {
            // Day-of-month arithmetic rather than adding to a timestamp: Date
            // normalises out-of-range days for us, and doing it in local time
            // keeps a DST change from shifting a cell onto the wrong date.
            const d = new Date(year, month, 1 - lead + i);

            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month && d.getFullYear() === year,
                isToday: d.getDate() === root.today.getDate() && d.getMonth() === root.today.getMonth() && d.getFullYear() === root.today.getFullYear()
            });
        }

        return out;
    }

    function page(delta) {
        const m = root.viewMonth + delta;

        // Math.floor rather than a division: it carries backwards as well, so
        // paging left off January lands on December of the year before.
        root.viewYear = root.viewYear + Math.floor(m / 12);
        root.viewMonth = ((m % 12) + 12) % 12;
    }

    function showToday() {
        root.today = new Date();
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
    }

    // Centred variant of the shared panel text -- everything in a calendar is
    // centred in its own cell, and nothing else in a popout is.
    component CellText: PanelText {
        horizontalAlignment: Text.AlignHCenter
    }

    SystemClock {
        id: clock

        // Only ticks while the panel is open, and only on the hour: the one
        // thing it has to catch is the date changing underneath an open panel.
        enabled: root.open
        precision: SystemClock.Hours

        onDateChanged: root.today = clock.date
    }

    Column {
        spacing: 6

        // Month, year, and the two arrows. Clicking the name returns to today,
        // which is the one bit of navigation that would otherwise take as many
        // clicks as you had paged away.
        Item {
            width: root.gridWidth
            height: Theme.pillHeight

            IconButton {
                anchors.left: parent.left
                icon: Icons.chevronLeft
                onClicked: root.page(-1)
            }

            CellText {
                id: monthLabel

                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                font.weight: Font.DemiBold
                opacity: todayReset.containsMouse ? 1.0 : 0.9

                MouseArea {
                    id: todayReset

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.showToday()
                }
            }

            IconButton {
                anchors.right: parent.right
                icon: Icons.chevronRight
                onClicked: root.page(1)
            }
        }

        Row {
            Repeater {
                model: 7

                CellText {
                    required property int index

                    width: root.cellWidth
                    height: 20
                    text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.ShortFormat)
                    font.pixelSize: Theme.fontSize - 2
                    opacity: 0.5
                }
            }
        }

        Item {
            width: root.gridWidth
            height: root.cellHeight * 6

            Grid {
                columns: 7

                Repeater {
                    model: root.days

                    Item {
                        id: cell

                        required property var modelData

                        width: root.cellWidth
                        height: root.cellHeight

                        // Today's marker. A filled circle rather than a coloured
                        // number: against a wallpaper-derived palette a recolour
                        // can land close to the ordinary text colour, and a shape
                        // reads the same whatever pywal produced.
                        Rectangle {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            radius: height / 2
                            color: Theme.surfaceStrong
                            visible: cell.modelData.isToday
                        }

                        CellText {
                            anchors.fill: parent
                            text: cell.modelData.day
                            // The spill-over days are context, not content.
                            opacity: cell.modelData.inMonth ? 1.0 : 0.3
                            font.weight: cell.modelData.isToday ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }

            // Scrolling the grid pages months -- up for earlier, the direction
            // the rows themselves would move. This is a MouseArea because Qt's
            // WheelHandler receives nothing on these surfaces; see Pill.
            MouseArea {
                anchors.fill: parent

                onWheel: event => root.page(event.angleDelta.y > 0 ? -1 : 1)
            }
        }

        Rectangle {
            width: root.gridWidth
            height: 1
            color: Theme.panelBorder
        }

        // The long form of today's date. The pill can only ever show one of the
        // time and the date, so this is where the year lives.
        CellText {
            width: root.gridWidth
            text: Qt.formatDate(root.today, "dddd d MMMM yyyy")
            font.pixelSize: Theme.fontSize - 1
            opacity: 0.6
        }
    }
}
