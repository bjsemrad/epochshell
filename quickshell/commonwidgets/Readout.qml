pragma Singleton
import QtQuick
import Quickshell
import qs.theme as T

// The Readout design's tokens: one place for every size and colour the panels use, all derived
// from T.Config so every theme works.
Singleton {
    readonly property int rowHeight: 36
    // The icon column, and the glyphs in it: the Nerd Font icons the shell already uses.
    readonly property int iconColumn: 26
    readonly property int iconSize: T.Config.barIconSize + 1
    // Key rows: the key's column.
    readonly property int keyColumn: 130

    readonly property string font: T.Config.fontFamily
    // Generous: mono at the usual body sizes reads small.
    readonly property int valueSize: T.Config.fontSizeNormal + 4
    readonly property int detailSize: T.Config.fontSizeSubtext + 3
    // ‹ and ›, wherever they are: big enough to see and to hit.
    readonly property int chevronSize: valueSize + 8

    readonly property color value: T.Config.surfaceText
    readonly property color detail: alpha(T.Config.surfaceText, 0.45)
    readonly property color key: alpha(T.Config.inactive, 0.65)
    readonly property color accent: T.Config.accent
    readonly property color danger: T.Config.red
    // The only fill a row ever has: hover, and keyboard focus, which looks the same.
    readonly property color hover: T.Config.onPanel(T.Config.surfaceContainer)
    readonly property int hoverRadius: 3
    readonly property color divider: alpha(T.Config.surfaceText, 0.08)
    // What's on: a tick, inset on a row's left edge or under an icon.
    readonly property int tick: 2

    // Gauges: segments, filled and empty.
    readonly property int segmentWidth: 6
    readonly property int segmentHeight: 8
    readonly property int segmentGap: 2
    readonly property color segmentOn: alpha(T.Config.surfaceText, 0.75)
    readonly property color segmentOff: alpha(T.Config.surfaceText, 0.15)

    // Whether the keyboard is driving the panels: set by a key press in a row, cleared when the
    // pointer moves over one. Keyboard focus is only drawn while it is set -- a panel that puts
    // the focus on its first row as it opens (the power page) would otherwise show that row lit
    // as if hovered, before any key was pressed.
    property bool keyboardActive: false

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
}
