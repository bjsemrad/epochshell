import QtQuick
import QtQuick.Layouts
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
            // The window itself is transparent and the ground is painted by a Rectangle inside it,
            // which is how every panel in this shell does it -- and the reason the panels' opacity
            // slider worked while the bar's did not.
            //
            // A Wayland surface's opaque region is decided when the surface is created. A window
            // created with an opaque colour stays marked opaque, so lowering the alpha of
            // `PanelWindow.color` afterwards changes the colour and nothing else: the compositor
            // goes on compositing it as solid. Painting the ground as ordinary content sidesteps
            // that entirely, because the surface is transparent from the start and the alpha lives
            // in a Rectangle that can change whenever it likes.
            color: "transparent"

            // Floating, the window takes the gap above the bar too, so the space it reserves
            // ends where the bar does.
            implicitHeight: T.Config.barBottom

            // Clicks on the bar, or in the islands style on the islands only: the screen showing
            // between them is the desktop's, not the bar's.
            mask: barWindow.islands ? islandsMask : barMask
            Region {
                id: barMask
                item: barArea
            }
            Region {
                id: islandsMask
                Region { item: leftIsland }
                Region { item: centerIsland }
                Region { item: rightIsland }
            }

            // Blur behind the bar while it is see-through (T.Config.barBlur), in its own shape:
            // the strip with its corners, or each island.
            BackgroundEffect.blurRegion: !T.Config.barBlur ? null : barWindow.islands ? islandsBlur : barBlur
            Region {
                id: barBlur
                item: barArea
                radius: barArea.radius
            }
            Region {
                id: islandsBlur
                Region { item: leftIsland; radius: leftIsland.radius }
                Region { item: centerIsland; radius: centerIsland.radius }
                Region { item: rightIsland; radius: rightIsland.radius }
            }

            // First child, so it sits behind everything else the bar draws.
            Rectangle {
                id: barArea
                // Floating, held in from the screen's top and sides with its corners rounded; the
                // gaps around it are outside the input mask, so clicks there reach the desktop.
                x: T.Config.barSideGap
                y: T.Config.barTopGap
                width: parent.width - T.Config.barSideGap * 2
                height: T.Config.barHeight
                radius: T.Config.barFloating ? T.Config.popupRadius : 0
                antialiasing: true
                // In the islands style the ground is the islands, and the strip is only the frame
                // they are laid out in.
                color: barWindow.islands ? "transparent" : T.Config.barBackground
            }

            // --- Islands -----------------------------------------------------------------------
            //
            // The floating bar in three pieces -- left, centre and right, each as wide as what it
            // holds -- with the desktop between them. A panel hangs from its own island, kept
            // within that island's flat bottom edge; one wider than its island widens it to carry
            // the panel (BarPanels), away from the screen's edge: the left island to the right, the
            // right island to the left, the centre one both ways.
            readonly property bool islands: T.Config.barIslands
            // Between an island's ends and what it holds.
            readonly property int islandPadding: T.Config.barModuleSpacing

            component Island: Rectangle {
                // The panels opened from this island.
                required property var tracker
                // As wide as what it holds; the drawn width follows a panel as it opens.
                required property real natural
                readonly property real targetWidth: tracker.targetWidth(natural, T.Config.popupRadius)
                visible: barWindow.islands
                y: T.Config.barTopGap
                width: tracker.widthAround(natural, T.Config.popupRadius)
                height: T.Config.barHeight
                radius: T.Config.popupRadius
                antialiasing: true
                color: T.Config.barBackground
                // With a panel open and the bar outline asked for, the island is outlined, and the
                // panel outlines the rest of the shape.
                border.width: T.Config.panelOutline === "bar" && tracker.openness > 0 ? 1 : 0
                border.color: Qt.rgba(T.Config.outline.r, T.Config.outline.g, T.Config.outline.b, tracker.openness)
            }

            // Where a panel anchors to its island: the island at the width it is growing to, so a
            // panel is placed once, for where the island will be, rather than chasing it.
            component IslandBody: Item {
                y: T.Config.barTopGap
                height: T.Config.barHeight
            }

            BarPanels { id: leftPanels }
            BarPanels { id: centerPanels }
            BarPanels { id: rightPanels }
            // The full and floating bars' panels.
            BarPanels { id: panelTracker }

            Island {
                id: leftIsland
                tracker: leftPanels
                natural: leftSide.width + barWindow.islandPadding * 2
                x: T.Config.barSideGap
            }
            IslandBody {
                id: leftIslandBody
                x: leftIsland.x
                width: leftIsland.targetWidth
            }

            Island {
                id: centerIsland
                tracker: centerPanels
                natural: centerSide.width + barWindow.islandPadding * 2
                x: Math.round((barWindow.width - width) / 2)
            }
            IslandBody {
                id: centerIslandBody
                x: Math.round((barWindow.width - width) / 2)
                width: centerIsland.targetWidth
            }

            Island {
                id: rightIsland
                tracker: rightPanels
                natural: rightSide.width + barWindow.islandPadding * 2
                x: barWindow.width - T.Config.barSideGap - width
            }
            IslandBody {
                id: rightIslandBody
                x: barWindow.width - T.Config.barSideGap - width
                width: rightIsland.targetWidth
            }

            // With a panel open, an outline along the bar's bottom edge. The panel draws the rest
            // -- round its flares, sides and bottom -- so the bar and the panel are outlined as one
            // shape. The panel covers this line where it hangs, since it overlaps the bar by a
            // pixel.
            Rectangle {
                visible: !barWindow.islands && T.Config.panelOutline === "bar" && opacity > 0
                opacity: panelTracker.openness
                x: barArea.x + barArea.radius
                y: T.Config.barBottom - 1
                width: barArea.width - barArea.radius * 2
                height: 1
                color: T.Config.outline
            }

            // Stay awake, at the compositor's level. The backend holds a logind inhibitor, which
            // is what hypridle and systemd watch; this is the belt to that pair of braces, because
            // a Wayland idle-inhibit stops the compositor reporting idle at all -- and it has to
            // live here, since the protocol inhibits against a surface and the daemon has none.
            IdleInhibitor {
                window: barWindow
                enabled: S.StayAwake.enabled
            }

            // Left: the launcher and what is playing.
            RowLayout {
                id: leftSide
                spacing: T.Config.barModuleSpacing
                // Found by panels opened from in here; see HoverPopupWindow.
                readonly property var barPanels: barWindow.islands ? leftPanels : panelTracker
                readonly property Item barIsland: barWindow.islands ? leftIslandBody : null
                readonly property Item barStrip: barArea
                // Placed by x rather than anchors, in every style. An anchor removed at runtime
                // leaves the item where the anchor put it -- an x binding underneath does not take
                // over until something it reads changes -- so switching style after startup, as
                // reading config.toml does, left the groups where the first style put them.
                x: barWindow.islands ? leftIsland.x + barWindow.islandPadding : barArea.x + T.Config.barModuleSpacing

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

            // Centre: the workspaces, the thing glanced at most, where the eye lands. A strip of
            // many workspaces is capped at a share of the bar and scrolls rather than pushing into
            // the groups either side.
            Flickable {
                id: centerSide
                readonly property var barPanels: barWindow.islands ? centerPanels : panelTracker
                readonly property Item barIsland: barWindow.islands ? centerIslandBody : null
                readonly property Item barStrip: barArea
                x: Math.round((parent.width - width) / 2)
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
                // The drawer's own spacing between its icons (IndividualBarRight), so the clock
                // after them sits at the same distance as one icon from the next rather than
                // standing off as a group of its own.
                spacing: Math.max(4, Math.round(T.Config.barModuleSpacing / 2))
                readonly property var barPanels: barWindow.islands ? rightPanels : panelTracker
                readonly property Item barIsland: barWindow.islands ? rightIslandBody : null
                readonly property Item barStrip: barArea
                x: barWindow.islands ? rightIsland.x + rightIsland.width - width - barWindow.islandPadding
                    : barArea.x + barArea.width - width - T.Config.barModuleSpacing
                Layout.alignment: Qt.AlignVCenter

                anchors {
                    top: barArea.top
                    bottom: barArea.bottom
                }

                IndividualBarRight {}

                // The time at the far right, after the system icons, where most desktops keep it.
                ClickableClock {
                    id: clock
                    Layout.alignment: Qt.AlignVCenter
                    popup: calendarPanel
                }
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
