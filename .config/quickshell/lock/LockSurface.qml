// What you actually see while the screen is locked.
//
// Kept separate from the WlSessionLock that hosts it for one practical reason:
// a session lock surface is the one piece of this config that cannot be poked
// at while it is running. Everything here is driven by plain properties, so a
// throwaway probe can render it full-screen in an ordinary PanelWindow -- real
// fonts, real palette, real wallpaper -- and it can be designed by looking at
// it rather than by locking the machine and hoping.
//
// The old hyprlock.conf this replaces was stock ML4W: its background was a
// pre-blurred PNG that hypr/scripts/wallpaper.sh had to generate on every
// wallpaper change, and its "avatar" was the same wallpaper cropped square,
// which put a circle of the wallpaper on top of the wallpaper. Both are gone.
//
// The lock screen deliberately does NOT show the desktop wallpaper. Omar's
// reasoning, and it is the right one: seeing the wallpaper through the lock
// spends it, so unlocking reveals nothing. It is its own picture, set here and
// nowhere else, and unlocking is then a change of scene rather than the same
// image losing a panel.
//
// Because that picture is chosen rather than inherited, it is barely blurred.
// Blur was doing two jobs before -- making white text legible over an arbitrary
// wallpaper, and signalling "not your session" -- and neither survives contact
// with an image picked on purpose: an anonymised smear could have been any
// file. Legibility comes from the scrim instead, which darkens the band the
// text sits in and leaves the rest of the picture alone.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "root:/theme"

Item {
    id: root

    // Driven by the host: the text being typed, and what PAM last said about
    // it. Held here rather than owned here so the probe can fake a failure
    // without a PAM conversation, and so the real host can keep the password
    // out of any property a QML inspector would show.
    property alias password: input.text
    property bool busy: false
    property string status: ""
    property bool statusIsError: false

    // Both set by the probe only. A probe window deliberately takes no keyboard
    // focus -- it must not swallow the keystrokes of whoever is using the
    // machine -- so the field can never look focused there unless it is told to.
    property bool acceptInput: true
    property bool forceFocusRing: false

    property bool capsLock: false

    // Any key at all, so the host can start watching the Caps Lock LED while
    // somebody is demonstrably at the keyboard.
    signal activity

    signal submitted

    // The field is disabled while PAM is thinking, and a disabled item loses
    // active focus. Without putting it back, the first failed attempt would
    // leave a lock screen that silently ignores the keyboard -- which looks
    // exactly like the machine having hung, on the one screen where that is
    // least welcome.
    onBusyChanged: if (!root.busy)
        root.grabField()

    function grabField() {
        if (root.acceptInput)
            input.forceActiveFocus();
    }

    // -----------------------------------------------------------------
    // Background
    // -----------------------------------------------------------------

    // The lock screen's own picture. An absolute path, and the only place it is
    // set -- nothing reads hyprpaper.conf here, which is the whole point.
    property string wallpaper: ""

    // Softening, not concealment. Zero is legitimate; single digits take the
    // digital edge off a sharp render without turning it into wallpaper soup.
    property real blurAmount: 0

    // The output's scale factor, so the picture can be decoded at its real
    // pixel size. Handed in rather than read from a Screen attached property,
    // which is not available on these surfaces.
    property real pixelRatio: 1

    // How hard the scrim pulls down the region the text sits in.
    property real scrimStrength: 0.55

    // "center" or "corner". Centre is the better composition in the abstract and
    // the worse one over most pictures: every candidate wallpaper here has its
    // subject dead centre, so a centred card lands on somebody's chest. Corner
    // puts the whole column in the bottom-left and leaves the picture its middle.
    property string placement: "center"
    readonly property bool centred: root.placement === "center"

    // Flat ground for the moment before the image decodes, for the case where
    // the file has gone missing, and for the instant before the first frame.
    // A session lock surface must never be transparent: there is nothing behind
    // it, and a hole in it is a hole through the lock.
    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    Image {
        id: paper

        anchors.fill: parent
        source: root.wallpaper ? `file://${root.wallpaper}` : ""
        fillMode: Image.PreserveAspectCrop

        // Decoded at the size it is actually drawn at, in PHYSICAL pixels.
        // Without a cap the full-resolution image is held in memory on every
        // output at once, and one of these candidates is 8K -- but capping at
        // the logical size is worse than not capping at all on a scaled output:
        // DP-3 is 3840x2160 at scale 2, so QML's width/height report 1920x1080
        // and an uncorrected sourceSize would decode to 1920 and let the
        // compositor stretch it back to 3840. The picture would be soft on
        // exactly the screen chosen for having the resolution to show it.
        sourceSize.width: root.width * root.pixelRatio
        sourceSize.height: root.height * root.pixelRatio

        cache: false
        asynchronous: true

        // Drawn directly when there is no blur to apply. MultiEffect always
        // costs an offscreen texture pass, which is not worth paying for a
        // no-op on three outputs.
        visible: root.blurAmount <= 0 && status === Image.Ready
    }

    MultiEffect {
        anchors.fill: parent
        source: paper
        visible: root.blurAmount > 0 && paper.status === Image.Ready

        blurEnabled: true
        blur: 1.0
        blurMax: Math.round(root.blurAmount)
    }

    // The scrim. A band rather than a flat wash: full-strength across the middle
    // where the clock and the card are, falling away to almost nothing at top
    // and bottom so the picture keeps its corners and its highlights. A flat
    // 40% dim over the whole surface was what made the old background read as
    // "wallpaper with something over it" rather than as a composition.
    Rectangle {
        anchors.fill: parent

        visible: root.centred

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, root.scrimStrength * 0.35)
            }
            GradientStop {
                position: 0.3
                color: Qt.rgba(0, 0, 0, root.scrimStrength * 0.92)
            }
            GradientStop {
                position: 0.62
                color: Qt.rgba(0, 0, 0, root.scrimStrength)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, root.scrimStrength * 0.45)
            }
        }
    }

    // Corner placement needs the opposite shape of scrim: weight in one corner
    // instead of a band across the middle, so the subject of the picture -- which
    // in every one of these is centred and is the reason the picture was picked --
    // keeps its own light. Two gradients multiplied by being stacked, which
    // pools the darkness into the bottom-left without either one having to be
    // strong enough to flatten the image on its own.
    Rectangle {
        anchors.fill: parent
        visible: !root.centred

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "transparent"
            }
            GradientStop {
                position: 0.45
                color: Qt.rgba(0, 0, 0, root.scrimStrength * 0.28)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, root.scrimStrength * 1.15)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.centred

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, root.scrimStrength * 0.85)
            }
            GradientStop {
                position: 0.42
                color: Qt.rgba(0, 0, 0, root.scrimStrength * 0.18)
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
    }

    // -----------------------------------------------------------------
    // Foreground
    // -----------------------------------------------------------------

    // Sized off the surface rather than fixed, because this has to look
    // deliberate on the 3440x1440 and on both 4K panels at scale 2, which are
    // 1920x1080 as far as QML is concerned.
    readonly property int clockSize: Math.round(Math.max(72, Math.min(150, root.height * 0.095)))

    // Tied to the clock rather than to the screen, so the two always look like
    // one object. A fixed 420 was 12% of the width on the 3440x1440 and 22% of
    // it on a 4K panel at scale 2 -- the same card, reading as restrained on one
    // output and as a chunky dialog on the next.
    readonly property int cardWidth: Math.round(root.clockSize * 3.05)

    // Inset for corner placement. Generous: tucked tight into the corner it
    // reads as an overlay that has slipped, rather than as a composition.
    readonly property int inset: Math.round(Math.max(56, Math.min(140, root.width * 0.035)))

    Column {
        spacing: 0

        // Centre placement centres the whole column; corner placement pins it
        // to the bottom-left and lets the children left-align themselves by
        // simply not anchoring. Assigning `undefined` to an anchor clears it,
        // which is what makes one Column serve both.
        anchors.horizontalCenter: root.centred ? parent.horizontalCenter : undefined
        anchors.verticalCenter: root.centred ? parent.verticalCenter : undefined
        anchors.left: root.centred ? undefined : parent.left
        anchors.bottom: root.centred ? undefined : parent.bottom
        anchors.leftMargin: root.inset
        anchors.bottomMargin: root.inset

        Text {
            anchors.horizontalCenter: root.centred ? parent.horizontalCenter : undefined

            text: clock.time
            color: Theme.text
            font.family: Theme.textFont
            font.pixelSize: root.clockSize

            // Thin, and tracked out a little. At this size the regular weight
            // reads as a heading rather than as a clock.
            font.weight: Font.Light
            font.letterSpacing: root.clockSize * 0.02
        }

        Text {
            anchors.horizontalCenter: root.centred ? parent.horizontalCenter : undefined

            text: clock.date
            color: Theme.text
            opacity: 0.62
            font.family: Theme.textFont
            font.pixelSize: Math.round(root.clockSize * 0.155)
            font.weight: Font.Normal
            font.letterSpacing: 2.2

            bottomPadding: Math.round(root.clockSize * 0.55)
        }

        // The card. Same treatment as the bar's popouts -- Theme.panel over a
        // hairline border -- so the lock screen reads as part of the same shell
        // rather than as a separate program, which is what it used to be.
        Rectangle {
            id: card

            anchors.horizontalCenter: root.centred ? parent.horizontalCenter : undefined

            width: root.cardWidth
            height: cardBody.implicitHeight + 44
            radius: Theme.panelRadius

            color: Theme.panel
            border.width: 1
            border.color: Theme.panelBorder

            Column {
                id: cardBody

                anchors.centerIn: parent
                width: parent.width - 44
                spacing: 18

                // Avatar and name. A padlock rather than a photograph: there is
                // one user on this machine, so the circle is not identifying
                // anybody -- it is saying what state the session is in.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Rectangle {
                        width: 40
                        height: 40
                        radius: width / 2
                        color: Theme.surfaceStrong
                        opacity: 0.9

                        Text {
                            anchors.centerIn: parent
                            text: Icons.lock
                            color: Theme.text
                            font.family: Theme.iconFont
                            font.pixelSize: 16
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: Quickshell.env("USER") || "omar"
                        color: Theme.text
                        font.family: Theme.textFont
                        font.pixelSize: 19
                        font.weight: Font.Medium
                    }
                }

                // The field.
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 10

                    // Darker than the card, so it reads as a well rather than a
                    // second panel.
                    color: Qt.rgba(0, 0, 0, 0.28)

                    border.width: 1
                    border.color: root.statusIsError ? Theme.danger : ((input.activeFocus || root.forceFocusRing) ? Theme.surface : Theme.panelBorder)

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Theme.animation
                        }
                    }

                    TextInput {
                        id: input

                        anchors.fill: parent
                        anchors.margins: 12

                        enabled: root.acceptInput && !root.busy
                        focus: root.acceptInput

                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        passwordMaskDelay: 0

                        color: Theme.text
                        font.family: Theme.textFont
                        font.pixelSize: 16
                        // Real dots, spaced. The default run of bullets at this
                        // size looks like one smear.
                        font.letterSpacing: 4

                        // Selection is meaningless in a masked field and only
                        // gives a way to leak the length by dragging.
                        selectByMouse: false

                        onAccepted: root.submitted()

                        // Fires for keys that produce no character too, which
                        // is what lets pressing Caps Lock itself wake the watch.
                        Keys.onPressed: event => {
                            root.activity();
                            event.accepted = false;
                        }

                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            visible: input.text === "" && !root.busy
                            text: "Password"
                            color: Theme.text
                            opacity: 0.35
                            font.family: Theme.textFont
                            font.pixelSize: 15
                        }
                    }

                    // Inside the field, not a row of its own. A warning that
                    // appears and disappears between the field and the status
                    // line would change the card's height and shift the field
                    // out from under the pointer -- the same reason the status
                    // line is always present. The dots are centred, so the
                    // right-hand end is free.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        visible: root.capsLock

                        width: caps.implicitWidth + 14
                        height: 20
                        radius: 5

                        color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.18)
                        border.width: 1
                        border.color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.55)

                        Text {
                            id: caps

                            anchors.centerIn: parent

                            // Words rather than a glyph. Every arrow-ish
                            // codepoint that could stand for this reads as
                            // something else at 10px, and the whole point is
                            // that it is unmissable at a glance.
                            text: "CAPS"
                            color: Theme.warning
                            font.family: Theme.textFont
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }
                    }
                }

                // One line, always present so the card does not change height
                // when a message arrives -- a card that grows on a failed
                // attempt shifts the field out from under the pointer.
                Text {
                    width: parent.width
                    height: 16

                    horizontalAlignment: Text.AlignHCenter

                    text: root.busy ? "Checking…" : root.status
                    color: root.statusIsError ? Theme.danger : Theme.text
                    opacity: root.statusIsError ? 1 : 0.5

                    font.family: Theme.textFont
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Local clock. Re-armed to land on each minute boundary rather than run at
    // 1Hz: there are no seconds on the display, so a per-second timer would
    // wake the shell sixty times an hour to redraw the same two digits -- and
    // this one runs while the machine is locked and otherwise idle, which is
    // exactly when it should not be keeping anything busy.
    QtObject {
        id: clock

        property string time: ""
        property string date: ""

        function update() {
            const now = new Date();
            time = Qt.formatDateTime(now, "HH:mm");
            date = Qt.formatDateTime(now, "dddd, d MMMM").toUpperCase();
        }
    }

    // Set imperatively, not as a binding: `new Date()` is not a reactive
    // dependency, so an `interval:` binding would be evaluated once at load and
    // then keep that first offset forever.
    function retime() {
        clock.update();

        const now = new Date();
        // Plus a little, so clock drift can never leave it firing a hair before
        // the boundary and showing the previous minute for another whole one.
        tick.interval = Math.max(250, (60 - now.getSeconds()) * 1000 - now.getMilliseconds() + 50);
        tick.restart();
    }

    Timer {
        id: tick

        repeat: false
        onTriggered: root.retime()
    }

    Component.onCompleted: {
        root.retime();
        root.grabField();
    }
}
