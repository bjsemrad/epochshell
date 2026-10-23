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

    // --- Spacing -------------------------------------------------------------------------------
    readonly property int spaceXS: 3
    readonly property int spaceS: 4
    readonly property int spaceWorkspace: 5
    readonly property int spaceM: 6
    readonly property int spaceL: 8
    readonly property int spaceXL: 10
    readonly property int space2XL: 12
    readonly property int space3XL: 14
    readonly property int space4XL: 16
    // How far a control's click area reaches past what is drawn.
    readonly property int hitSlop: 6
    readonly property int hitSlopSmall: 4
    readonly property int chevronSlop: 8

    // --- Rows, headers, sections ---------------------------------------------------------------
    readonly property int headerHeight: rowHeight + 4
    readonly property int iconButtonSize: rowHeight + 4
    readonly property int chevronColumn: 22
    readonly property int rowHoverInset: 10
    readonly property int tickClearance: 10
    readonly property int detailMinWidth: 72
    readonly property int sectionRuleGap: 8
    readonly property int sectionLabelHeight: 28
    readonly property int panelListMaxHeight: 420
    readonly property int notificationBodyLines: 4
    readonly property int dotSize: 7
    readonly property int swatchSize: 8
    readonly property int badgeGap: 3
    readonly property real trayFallbackScale: 0.6

    // --- Panels ----------------------------------------------------------------------------------
    readonly property int panelWidth: 480
    readonly property int panelWidthWide: 500
    readonly property int dashboardWidth: 520
    readonly property int calendarWidth: 380
    readonly property int settingsWidth: 520
    readonly property int screenMarginV: 80
    readonly property int floatingGap: 5
    // A panel narrower than the ledge by more than this many corner radii hangs instead of snapping.
    readonly property int ledgeHangCorners: 4
    readonly property real solidOpacity: 0.99
    readonly property real revealFadeRate: 1.5

    // --- Controls --------------------------------------------------------------------------------
    readonly property int switchWidth: 34
    readonly property int switchHeight: 18
    readonly property int switchRadius: 4
    readonly property int switchKnob: 12
    readonly property int switchKnobInset: 3
    readonly property int switchKnobRadius: 3
    readonly property real switchOffAlpha: 0.18
    readonly property real switchKnobOffAlpha: 0.6

    readonly property real sliderStep: 0.05
    readonly property real sliderFineStep: 0.01
    readonly property int sliderTrack: 160
    readonly property int sliderTrackWide: 200
    readonly property int sliderTrackCompact: 110
    readonly property int sliderTrackTiny: 90
    readonly property int sliderHandle: 3
    readonly property int sliderHandleHover: 4
    readonly property int sliderHandleHeight: 14
    readonly property real sliderTrackAlpha: 0.15
    readonly property real sliderTrackHoverAlpha: 0.25
    readonly property real sliderFillAlpha: 0.85
    readonly property real sliderMutedAlpha: 0.35

    readonly property int gaugeSegments: 10
    readonly property int batterySegments: 20
    readonly property int stepperMax: 10
    readonly property int iconLimitMax: 6
    readonly property int topGapMax: 24
    readonly property int sideGapMax: 48

    readonly property int buttonPadX: 16
    readonly property int buttonPadY: 8
    readonly property real buttonHoverAlpha: 0.14

    // --- Shared alphas ---------------------------------------------------------------------------
    readonly property real detailFloor: 0.62
    readonly property real keyFloor: 0.58
    readonly property real mutedFloor: 0.55
    readonly property real disabledAlpha: 0.35
    readonly property real unselectedAlpha: 0.7
    readonly property real hairlineAlpha: 0.10
    readonly property real separatorAlpha: 0.18
    readonly property real separatorHeight: 0.45
    readonly property real scrimAlpha: 0.6
    readonly property real backdropAlpha: 0.25

    // --- Contrast --------------------------------------------------------------------------------
    readonly property real contrastValue: 7
    readonly property real contrastText: 4.5
    readonly property real contrastKey: 3
    readonly property real contrastStep: 0.1

    // --- Motion ----------------------------------------------------------------------------------
    readonly property int drawerSlideMs: 300
    readonly property int drawerCollapseDelay: 120
    readonly property int revealMs: 260
    readonly property int fadeMs: 240
    readonly property int wallpaperFadeMs: 450
    readonly property int pulseMs: 700
    readonly property real pulseLowAlpha: 0.35
    readonly property int tooltipDelay: 500
    readonly property int hoverOpenDelay: 250
    readonly property int hoverCloseDelay: 120
    readonly property int pageSettleMs: 400
    readonly property int launcherAnimateDelay: 100
    readonly property int previewDelay: 120
    // Shake on a wrong password: offsets and the time each step takes.
    readonly property var shakeSmall: [-8, 8, 0]
    readonly property var shakeSmallMs: [35, 50, 55]
    readonly property var shakeLarge: [-10, 10, -6, 4, 0]
    readonly property var shakeLargeMs: [45, 70, 60, 50, 40]

    // --- OSD -------------------------------------------------------------------------------------
    readonly property int osdWidth: 340
    readonly property int osdMinWidth: 220
    readonly property int osdHeight: 46
    readonly property int osdClearance: 12
    readonly property int osdTopGap: 8
    readonly property int osdTopNoBar: 50
    readonly property int osdSegmentHeight: 10
    readonly property int osdLabelWidth: 44
    readonly property int osdPollMs: 250
    readonly property int osdMediaMs: 1600

    // --- Toasts ----------------------------------------------------------------------------------
    readonly property int toastWidth: 340
    readonly property int toastPadding: 12
    readonly property int toastIconColumn: 22
    readonly property int toastIconSize: 18
    readonly property int toastBodyLines: 3
    readonly property int toastImageMaxHeight: 120
    readonly property int toastCloseColumn: 14
    readonly property real toastHoverMix: 0.6
    readonly property int actionPadX: 10
    readonly property int actionPadY: 6

    // --- Launcher --------------------------------------------------------------------------------
    readonly property int launcherWidth: 560
    readonly property int launcherKeybindsWidth: 760
    readonly property int launcherSplitWidth: 1100
    readonly property int launcherMaxHeight: 620
    readonly property real launcherScreenFraction: 0.6
    readonly property real launcherTop: 0.18
    readonly property real launcherListFraction: 0.46
    readonly property int launcherPromptHeight: 44
    readonly property int launcherInset: 22
    readonly property int appIconSource: 44
    readonly property int calcSize: valueSize + 10
    readonly property real nameFraction: 0.55
    readonly property real keybindNameFraction: 0.4
    readonly property int keycapPadX: 8
    readonly property int keycapPadY: 4
    readonly property int keycapRadius: 3
    readonly property real keycapBorderAlpha: 0.25

    // --- Appearance strip ------------------------------------------------------------------------
    readonly property int stripHeight: 168
    readonly property real stripGridFraction: 0.45
    readonly property int stripMargin: 20
    readonly property int stripHeaderHeight: 26
    readonly property int stripControlHeight: 24
    readonly property int stripTabGap: 18
    readonly property int thumbWidth: 120
    readonly property int thumbHeight: 68
    readonly property int thumbLabel: 22
    readonly property int gridCellWidth: 130
    readonly property int gridCellHeight: 100
    readonly property int specimenHeight: 78
    readonly property int specimenRadius: 4
    readonly property int specimenInset: 10
    readonly property real specimenLedgeWidth: 0.6
    readonly property int specimenLedgeHeight: 12
    readonly property int specimenLine1Y: 26
    readonly property int specimenLine2Y: 36
    readonly property real specimenLineWidth: 0.7
    readonly property int specimenLineHeight: 4

    // --- Polkit ----------------------------------------------------------------------------------
    readonly property int dialogWidth: 440
    readonly property int dialogMinWidth: 240
    readonly property int dialogTextPad: 48
    readonly property int dialogPadV: 32
    readonly property int dialogScreenMargin: 40
    readonly property int polkitPromptHeight: 48
    readonly property int fingerprintSize: 28
    readonly property int polkitCloseDelay: 300
    readonly property int polkitErrorMs: 1200

    // --- Workspaces ------------------------------------------------------------------------------
    readonly property int workspaceFrameRadius: 20
    readonly property int workspaceHoverRadius: 10
    readonly property int pillInsetV: 14
    readonly property int cellPad: 10
    readonly property int cellMinPad: 4
    readonly property int cellMaxWidth: 56
    readonly property int fullColumnWidth: 64
    readonly property int mediaTitleMax: 160
    readonly property int mediaButtonMaxWidth: 220
    readonly property int stackCountSize: Math.max(8, T.Config.fontSizeSubtext - 2)
    readonly property real windowUnfocusedAlpha: 0.35
    readonly property real workspaceEmptyAlpha: 0.6
    readonly property real windowDimAlpha: 0.45
    readonly property real iconQuietAlpha: 0.6
    readonly property real cellDimAlpha: 0.7
    readonly property real columnBarAlpha: 0.20
    readonly property real titleAlpha: 0.45

    // --- Lock screen -----------------------------------------------------------------------------
    readonly property int lockWallpaperScale: 4
    readonly property int lockBlur: 48
    readonly property real lockDesaturate: -0.15
    readonly property real lockDim: 0.45
    readonly property real lockZoom: 1.03
    readonly property int lockFadeMs: 220
    readonly property int lockClockBottom: 40
    readonly property int lockClockSize: 96
    readonly property int lockMeridiemSize: 24
    readonly property real lockMeridiemAlpha: 0.7
    readonly property real lockDateAlpha: 0.75
    readonly property int lockPromptTop: 24
    readonly property real lockStatusLineHeight: 1.6
    readonly property int lockCornerMargin: 32
    readonly property real lockFooterAlpha: 0.65
    readonly property real lockFooterValueAlpha: 0.85
    readonly property int lockFieldWidth: 320
    readonly property int lockFieldHeight: 46
    readonly property real lockFieldAlpha: 0.55
    readonly property real lockHintAlpha: 0.55
    readonly property real lockGlyphAlpha: 0.6
    readonly property int lockGlyphSize: T.Config.fontSizeNormal + 6
    readonly property int lockMaxDots: 20
    readonly property int busyDots: 3
    readonly property int busyStaggerMs: 150
    readonly property int busyPulseMs: 300
    readonly property real busyLowAlpha: 0.25

    // --- Signal and level thresholds (percent) ---------------------------------------------------
    readonly property int signalStrong: 75
    readonly property int signalFair: 50
    readonly property int signalWeak: 25

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
    readonly property real valueAlpha: alphaFor(1, contrastValue)
    readonly property real detailAlpha: alphaFor(detailFloor, contrastText)
    readonly property real keyAlpha: alphaFor(keyFloor, contrastKey)
    readonly property real mutedAlpha: alphaFor(mutedFloor, contrastKey)

    function reportContrast() {
        const raised = [];
        if (detailAlpha > detailFloor + 0.001) raised.push("detail to " + detailAlpha.toFixed(2));
        if (keyAlpha > keyFloor + 0.001) raised.push("key to " + keyAlpha.toFixed(2));
        if (mutedAlpha > mutedFloor + 0.001) raised.push("muted to " + mutedAlpha.toFixed(2));
        const valueRatio = contrast(over(T.Config.surfaceText, 1), T.Config.background);
        if (valueRatio < contrastValue) raised.push("value only reaches " + valueRatio.toFixed(1) + ":1");
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
