// The wallpaper effect picker: a Picker over ~/.config/hypr/effects/wallpaper.

import QtQuick
import Quickshell
import "root:/theme"
import "root:/services"
import "root:/components"

Picker {
    id: root

    open: WallpaperEffects.open
    placeholder: "Wallpaper effect"
    model: WallpaperEffects.results

    // Narrower and shorter than the launcher: fifteen one-word names, so the
    // panel has no reason to take up half the screen.
    panelWidth: 420
    maxHeight: 400

    footer: `Currently ${WallpaperEffects.current}`

    onQueryChanged: WallpaperEffects.query = root.query

    onDismissed: WallpaperEffects.hide()

    onAccepted: index => {
        const name = WallpaperEffects.results[index];
        WallpaperEffects.hide();
        WallpaperEffects.apply(name);
    }

    delegate: EffectRow {
        required property var modelData
        required property int index

        name: modelData
        current: modelData === WallpaperEffects.current
        width: ListView.view.width
        selected: ListView.isCurrentItem

        onActivated: root.accepted(index)
        onHovered: ListView.view.currentIndex = index
    }
}
