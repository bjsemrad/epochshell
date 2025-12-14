pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isHyprland: false
    property bool isNiri: false

    Component.onCompleted: {
        detectCompositor();
    }

    function detectCompositor() {
        const hyprlandSignature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE");
        const niriSocket = Quickshell.env("NIRI_SOCKET");

        if (niriSocket && niriSocket.length > 0) {
            isHyprland = false;
            isNiri = true;
        } else if (hyprlandSignature && hyprlandSignature.length > 0) {
            isHyprland = true;
            isNiri = false;
        }
    }

    function logout() {
        //TODO
    }
}
