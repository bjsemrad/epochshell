pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property color accent: blue
    property color accentLightShade: Qt.rgba(Qt.color(accent).r, Qt.color(accent).g, Qt.color(accent).b, 0.10)
    property color inactive: surfaceTextInactive
    property color active: surfaceText
    property color activeSelection: Qt.rgba(Qt.color(surfaceVariant).r, Qt.color(surfaceVariant).g, Qt.color(surfaceVariant).b, 0.25)

    property color background: "#101418"
    property color surface: "#101418"
    property color surfaceText: "#a0a8b7"
    property color surfaceTextInactive: "#758799"
    property color surfaceContainer: "#1d2024"
    property color outline: "#8c9199"
    property color surfaceVariant: "#42474e"
    property color surfaceContainerHigh: "#272a2f"
    property color surfaceContainerHighest: "#32353a"
    property color primaryText: "#000000"

    // property color primary: "#42a5f5"
    // property color primaryContainer: "#0d47a1" //blue
    // property color secondary: "#8ab4f8" //blue
    // property color surfaceVariantText: "#c2c7cf"
    // property color surfaceTint: "#8ab4f8"
    // property color backgroundText: "#e0e2e8"

    // ───────────────────────────────────────────────
    //  ACCENT COLORS
    // ───────────────────────────────────────────────
    //
    property color purple: "#bf68d9"
    property color green: "#8ebd6b"
    property color orange: "#cc9057"
    property color blue: "#4fa6ed"
    property color yellow: "#e2b86b"
    property color cyan: "#48b0bd"
    property color red: "#e55561"
    property color bg_blue: "#61afef"
    property color bg_yellow: "#e8c88c"

    /* Misc */
    property string fontFamily: "JetBrainsMono Nerd Font Propo"

    property int networkPopupWidth: 400
    property int tailscalePopupWidth: 600
    property int bluetoothPopupWidth: 400
    property int audioPopupWidth: 550
    property int systemTrayPopupWidth: 300
    property int systemPopupWidth: 300
    property int batteryPopupWidth: 250

    property int tailscalePeersFontSize: 14

    property int selectedBorderWidth: 1
    property int panelBottomMargin: 5

    property bool showIndividualIcons: true
}
