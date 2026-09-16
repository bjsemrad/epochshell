import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.theme as T
import qs.popups
import qs.modules
import qs.modules.audio
import qs.modules.compositor
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
            implicitHeight: T.Config.barHeight

            // First child, so it sits behind everything else the bar draws.
            Rectangle {
                anchors.fill: parent
                color: T.Config.barBackground
            }

            // Stay awake, at the compositor's level. The backend holds a logind inhibitor, which
            // is what hypridle and systemd watch; this is the belt to that pair of braces, because
            // a Wayland idle-inhibit stops the compositor reporting idle at all -- and it has to
            // live here, since the protocol inhibits against a surface and the daemon has none.
            IdleInhibitor {
                window: barWindow
                enabled: S.StayAwake.enabled
            }

            Flickable {
                id: leftSide
                width: Math.min(leftContent.implicitWidth, parent.width * T.Config.workspaceStripMaxWidthRatio)
                contentWidth: leftContent.implicitWidth
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentWidth > width
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }

                RowLayout {
                    id: leftContent
                    height: parent.height
                    spacing: T.Config.barModuleSpacing

                    BarFill {}
                    ApplicationLauncher {}
                    Workspaces {}
                    BarFill {}
                }
            }

            RowLayout {
                id: centerSide
                spacing: T.Config.barModuleSpacing

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    centerIn: parent
                }
                readonly property int available: parent.width

                implicitWidth: available
                children: [
                    BarFill {},
                    MediaIndicator {
                        id: mediaIndicator
                        popup: mediaPanel
                    },
                    ClickableClock {
                        id: clock
                        popup: calendarPanel
                    },
                    Weather {
                        id: weather
                        popup: weatherPanel
                    },
                    BarFill {}
                ]
            }

            RowLayout {
                id: rightSide
                spacing: T.Config.barModuleSpacing
                Layout.alignment: Qt.AlignVCenter

                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                    rightMargin: T.Config.barModuleSpacing
                }

                IndividualBarRight {}
            }

            CalendarPanel {
                id: calendarPanel
                trigger: clock
            }

            WeatherPanel {
                id: weatherPanel
                trigger: weather
            }

            MediaPanel {
                id: mediaPanel
                trigger: mediaIndicator
            }
        }
    }
}
