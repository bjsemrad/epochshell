import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.theme as T
import qs.popups
import qs.modules
import qs.modules.audio
import qs.modules.compositor
import qs.commonwidgets
import qs.services as S

Scope {
    id: bar
    property string time

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData
            WlrLayershell.layer: WlrLayer.Top
            anchors {
                top: true
                left: true
                right: true
            }
            // The window stays transparent and a Rectangle paints the ground: a window's own color
            // ignores opacity.
            color: "transparent"

            implicitHeight: T.Config.barBottom

            mask: barWindow.pillMode ? pillMask : barMask
            Region {
                id: barMask
                item: barArea
            }
            Region {
                id: pillMask
                item: pill
            }

            BackgroundEffect.blurRegion: !T.Config.barBlur ? null : barWindow.pillMode ? pillBlur : barBlur
            Region {
                id: barBlur
                item: barArea
                radius: barArea.radius
            }
            Region {
                id: pillBlur
                item: pill
                radius: pill.radius
            }

            Rectangle {
                id: barArea
                x: T.Config.barSideGap
                y: T.Config.barTopGap
                width: parent.width - T.Config.barSideGap * 2
                height: T.Config.barHeight
                radius: T.Config.barFloating ? T.Config.popupRadius : 0
                antialiasing: true
                color: barWindow.pillMode ? "transparent" : T.Config.barBackground
            }

            readonly property bool centered: T.Config.barCentered
            readonly property bool pillMode: centered && !T.Config.barSpanFull
            readonly property var hangPanels: centered ? pillPanels : panelTracker
            readonly property int pillPadding: T.Config.barModuleSpacing
            readonly property int groupGap: T.Config.barModuleSpacing
            readonly property real centeredContentWidth: (leftSide.width > 0 ? leftSide.width + groupGap : 0)
                + centerSide.width + groupGap + rightSide.width
            readonly property real centeredContentX: pill.x + Math.round((pill.width - centeredContentWidth) / 2)

            readonly property bool osdReady: panelTracker.openness <= 0 && pillPanels.openness <= 0
                && !(S.PopupManager.launcher && S.PopupManager.launcher._visible)
            Component.onCompleted: S.OsdService.registerBar(modelData.name, barWindow)
            Component.onDestruction: S.OsdService.unregisterBar(modelData.name, barWindow)
            readonly property bool launcherHere: T.Config.barIsLedge && S.PopupManager.launcher !== null
                && S.PopupManager.launcher.ledgeMode === true && S.PopupManager.launcher._visible
                && S.PopupManager.launcher.screenName === modelData.name
            readonly property bool osdHere: S.OsdService.visible && S.OsdService.inBar && S.OsdService.screenName === modelData.name
            readonly property real osdWidth: {
                if (barWindow.centered) return Ui.osdWidth;
                const half = Math.min(barWindow.width / 2 - (leftSide.x + leftSide.width) - Ui.osdClearance,
                    rightSide.x - barWindow.width / 2 - Ui.osdClearance);
                return Math.max(Ui.osdMinWidth, Math.min(Ui.osdWidth, Math.floor(half * 2)));
            }

            BarPanels { id: pillPanels }
            BarPanels { id: panelTracker }

            Rectangle {
                id: pill
                readonly property real natural: Math.max(barWindow.centeredContentWidth + barWindow.pillPadding * 2,
                    barWindow.osdHere ? Ui.osdWidth + barWindow.pillPadding * 2 : 0,
                    barWindow.launcherHere ? S.PopupManager.launcher.panelWidth : 0)
                visible: barWindow.pillMode
                x: Math.round((barWindow.width - width) / 2)
                y: T.Config.barTopGap
                width: pillPanels.widthAround(natural, T.Config.popupRadius)
                height: T.Config.barHeight
                radius: T.Config.popupRadius
                antialiasing: true
                color: T.Config.barIsLedge ? "transparent" : T.Config.barBackground
                border.width: !T.Config.barIsLedge && T.Config.panelOutline === "bar" && pillPanels.openness > 0 ? 1 : 0
                border.color: Qt.rgba(T.Config.outline.r, T.Config.outline.g, T.Config.outline.b, pillPanels.openness)
            }

            AttachedSurface {
                id: ledge
                visible: T.Config.barIsLedge && barWindow.pillMode
                x: pill.x - flare
                y: 0
                width: pill.width + flare * 2
                height: T.Config.barHeight
                fillColor: T.Config.barBackground
                radius: ledge.joined ? 0 : T.Config.popupRadius
                flare: T.Config.popupRadius
                readonly property bool joined: pillPanels.leadingJoin === "snap" || barWindow.launcherHere
                outlineOpacity: joined ? (T.Config.panelOutline !== "none" ? (barWindow.launcherHere ? 1 : pillPanels.openness) : 0)
                    : T.Config.panelOutline === "bar" ? pillPanels.openness : 0
                outlineBottom: !joined
                outlineFade: joined && T.Config.panelOutline === "fade" ? flare : 0
            }

            Rectangle {
                visible: T.Config.barIsLedge && (pillPanels.leadingJoin === "snap" || barWindow.launcherHere)
                x: pill.x + T.Config.popupPadding
                y: T.Config.barHeight - 1
                width: pill.width - T.Config.popupPadding * 2
                height: 1
                color: Ui.alpha(T.Config.surfaceText, Ui.hairlineAlpha)
            }

            Item {
                id: pillBody
                readonly property real naturalWidth: pill.natural
                width: pillPanels.targetWidth(pill.natural, T.Config.popupRadius)
                x: Math.round((barWindow.width - width) / 2)
                y: T.Config.barTopGap
                height: T.Config.barHeight
            }

            Rectangle {
                visible: !barWindow.centered && T.Config.panelOutline === "bar" && opacity > 0
                opacity: panelTracker.openness
                x: barArea.x + barArea.radius
                y: T.Config.barBottom - 1
                width: barArea.width - barArea.radius * 2
                height: 1
                color: T.Config.outline
            }

            Rectangle {
                visible: barWindow.centered && leftSide.width > 0 && !barWindow.osdHere
                x: Math.round(centerSide.x - (barWindow.groupGap + width) / 2)
                y: T.Config.barTopGap + Math.round((T.Config.barHeight - height) / 2)
                width: 1
                height: Math.round(T.Config.barHeight * Ui.separatorHeight)
                color: Ui.alpha(T.Config.surfaceText, Ui.separatorAlpha)
            }
            Rectangle {
                visible: barWindow.centered && rightSide.width > 0 && !barWindow.osdHere
                x: Math.round(centerSide.x + centerSide.width + (barWindow.groupGap - width) / 2)
                y: T.Config.barTopGap + Math.round((T.Config.barHeight - height) / 2)
                width: 1
                height: Math.round(T.Config.barHeight * Ui.separatorHeight)
                color: Ui.alpha(T.Config.surfaceText, Ui.separatorAlpha)
            }

            // Belt and braces with the backend's logind inhibitor: a Wayland idle-inhibit also
            // stops the compositor reporting idle.
            IdleInhibitor {
                window: barWindow
                enabled: S.StayAwake.enabled
            }

            RowLayout {
                id: leftSide
                visible: !(barWindow.osdHere && barWindow.centered)
                spacing: T.Config.barModuleSpacing
                readonly property var barPanels: barWindow.hangPanels
                readonly property Item barPill: barWindow.centered ? pillBody : null
                readonly property Item barStrip: barArea
                // Placed by x rather than anchors: an anchor removed at runtime leaves the item
                // where it was until a binding re-evaluates.
                x: barWindow.centered ? barWindow.centeredContentX : barArea.x + T.Config.barModuleSpacing

                anchors {
                    top: barArea.top
                    bottom: barArea.bottom
                }

                children: [
                    ApplicationLauncher {},
                    MediaIndicator {
                        id: mediaIndicator
                        popup: mediaPanel
                    }
                ]
            }

            Flickable {
                id: centerSide
                visible: !barWindow.osdHere
                readonly property var barPanels: barWindow.hangPanels
                readonly property Item barPill: barWindow.centered ? pillBody : null
                readonly property Item barStrip: barArea
                x: barWindow.centered ? barWindow.centeredContentX + (leftSide.width > 0 ? leftSide.width + barWindow.groupGap : 0)
                    : Math.round((parent.width - width) / 2)
                width: Math.min(centerContent.implicitWidth, parent.width * T.Config.workspaceStripMaxWidthRatio)
                contentWidth: centerContent.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width

                anchors {
                    top: barArea.top
                    bottom: barArea.bottom
                }

                RowLayout {
                    id: centerContent
                    height: parent.height
                    spacing: T.Config.barModuleSpacing

                    Workspaces {}
                }
            }

            RowLayout {
                id: rightSide
                visible: !(barWindow.osdHere && barWindow.centered)
                spacing: Math.max(Ui.spaceS, Math.round(T.Config.barModuleSpacing / 2))
                readonly property var barPanels: barWindow.hangPanels
                readonly property Item barPill: barWindow.centered ? pillBody : null
                readonly property Item barStrip: barArea
                x: barWindow.centered ? centerSide.x + centerSide.width + barWindow.groupGap
                    : barArea.x + barArea.width - width - T.Config.barModuleSpacing
                Layout.alignment: Qt.AlignVCenter

                anchors {
                    top: barArea.top
                    bottom: barArea.bottom
                }

                IndividualBarRight {}

                ClickableClock {
                    id: clock
                    visible: !T.Config.barCompact
                    Layout.alignment: Qt.AlignVCenter
                    popup: calendarPanel
                }
            }

            OsdDisplay {
                visible: barWindow.osdHere
                width: barWindow.osdWidth
                height: T.Config.barHeight
                x: Math.round((barWindow.width - width) / 2)
                y: T.Config.barTopGap
            }

            CalendarPanel {
                id: calendarPanel
                trigger: clock
            }

            MediaPanel {
                id: mediaPanel
                trigger: mediaIndicator
            }
        }
    }
}
