pragma Singleton
import QtQuick
import Quickshell
import qs.theme as T

Singleton {
    readonly property int rowHeight: 36
    readonly property int iconColumn: 26
    readonly property int iconSize: T.Config.barIconSize + 1
    readonly property int keyColumn: 130

    readonly property string font: T.Config.fontFamily
    readonly property int valueSize: T.Config.fontSizeNormal + 4
    readonly property int detailSize: T.Config.fontSizeSubtext + 3
    readonly property int chevronSize: valueSize + 8

    readonly property color value: alpha(T.Config.surfaceText, valueAlpha)
    readonly property color detail: alpha(T.Config.surfaceText, detailAlpha)
    readonly property color key: alpha(T.Config.surfaceText, keyAlpha)
    readonly property color muted: alpha(T.Config.surfaceText, mutedAlpha)
    readonly property color accent: T.Config.accent
    readonly property color danger: T.Config.red
    readonly property color hover: T.Config.onPanel(T.Config.surfaceContainer)
    readonly property int hoverRadius: 3
    readonly property color divider: alpha(T.Config.surfaceText, 0.08)
    readonly property int tick: 3

    readonly property int segmentWidth: 6
    readonly property int segmentHeight: 8
    readonly property int segmentGap: 2
    readonly property color segmentOn: alpha(T.Config.surfaceText, 0.75)
    readonly property color segmentOff: alpha(T.Config.surfaceText, 0.15)

    // Keyboard focus is only drawn while the keyboard is driving; a pointer move over a row clears
    // it.
    property bool keyboardActive: false

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Each text role's alpha is raised until it meets its contrast ratio against the theme's
    // background.

    function luminance(c) {
        const lin = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    }
    function over(c, a) {
        const g = T.Config.background;
        return Qt.rgba(c.r * a + g.r * (1 - a), c.g * a + g.g * (1 - a), c.b * a + g.b * (1 - a), 1);
    }
    function contrast(a, b) {
        const la = luminance(a);
        const lb = luminance(b);
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }
    function alphaFor(start, ratio) {
        for (let a = start; a < 1; a += 0.02) {
            if (contrast(over(T.Config.surfaceText, a), T.Config.background) >= ratio) return a;
        }
        return 1;
    }
    readonly property real valueAlpha: alphaFor(1, 7)
    readonly property real detailAlpha: alphaFor(0.62, 4.5)
    readonly property real keyAlpha: alphaFor(0.58, 3)
    readonly property real mutedAlpha: alphaFor(0.55, 3)

    function reportContrast() {
        const raised = [];
        if (detailAlpha > 0.62 + 0.001) raised.push("detail to " + detailAlpha.toFixed(2));
        if (keyAlpha > 0.58 + 0.001) raised.push("key to " + keyAlpha.toFixed(2));
        if (mutedAlpha > 0.55 + 0.001) raised.push("muted to " + mutedAlpha.toFixed(2));
        const valueRatio = contrast(over(T.Config.surfaceText, 1), T.Config.background);
        if (valueRatio < 7) raised.push("value only reaches " + valueRatio.toFixed(1) + ":1");
        console.info("panel contrast (" + T.Config.themeName + "): " + (raised.length > 0 ? "raised " + raised.join(", ") : "every role passes"));
    }
    Component.onCompleted: reportContrast()
    Connections {
        target: T.Config
        function onThemeNameChanged() {
            Qt.callLater(reportContrast);
        }
    }
}
