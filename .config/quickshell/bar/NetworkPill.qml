// Network state.
//
// Quickshell 0.3 talks to NetworkManager directly, so unlike waybar this needs
// no polling and no shelling out to nmcli to find out what is connected.

import QtQuick
import Quickshell
import Quickshell.Networking
import "root:/theme"
import "root:/components"

Pill {
    id: root

    // First connected device wins: the wired link when it is up, wifi
    // otherwise. Preferring wired matches how the machine actually routes.
    readonly property var device: {
        const devices = Networking.devices.values;
        return devices.find(d => d.connected && d.type === DeviceType.Wired) || devices.find(d => d.connected) || null;
    }

    readonly property bool wireless: root.device !== null && root.device.type === DeviceType.Wifi

    readonly property var network: root.device && root.device.networks ? root.device.networks.values.find(n => n.connected) : null

    readonly property string label: {
        if (!root.device)
            return "Offline";
        if (root.wireless)
            return root.network ? `${Math.round(root.network.signalStrength)}%` : "Wi-Fi";
        return root.device.name;
    }

    onClicked: Quickshell.execDetached(["alacritty", "--class", "dotfiles-floating", "-e", "nmtui"])

    BarIcon {
        text: root.wireless ? Icons.wifi : Icons.ethernet
        opacity: root.device ? 1.0 : 0.5
    }

    BarText {
        text: root.label
    }
}
