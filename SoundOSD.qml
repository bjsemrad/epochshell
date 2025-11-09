import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import "./theme" as T
Scope {
	id: root

	// Bind the pipewire node so its volume will be tracked
	PwObjectTracker {
		objects: [ Pipewire.defaultAudioSink ]
	}

	Connections {
		target: Pipewire.defaultAudioSink?.audio

		function onVolumeChanged() {
			if (!root.initialized) {
				root.initialized = true
		            return
			}
			root.shouldShowOsd = true;
			hideTimer.restart();
		}


		function onMutedChanged() {
			let audio = Pipewire.defaultAudioSink.audio
		        let muted = audio.muted ?? false

		        if (!root.initialized) {
		            root.initialized = true
		            root.lastMuted = muted
		            return
		        }
	
			if (muted !== lastMuted) {
		            root.lastMuted = muted
		            root.shouldShowOsd = true
		            hideTimer.restart()
			 }
		 }
	}

	property bool shouldShowOsd: false
	property bool initialized: false
	property bool lastMuted: false


	Timer {
		id: hideTimer
		interval: 1000
		onTriggered: root.shouldShowOsd = false
	}

	// The OSD window will be created and destroyed based on shouldShowOsd.
	// PanelWindow.visible could be set instead of using a loader, but using
	// a loader will reduce the memory overhead when the window isn't open.
	LazyLoader {
		active: root.shouldShowOsd

		PanelWindow {
			// Since the panel's screen is unset, it will be picked by the compositor
			// when the window is created. Most compositors pick the current active monitor.

			anchors {
				// right: true
				top: true
			}
			margins {
				// right: 50
				top:50
			}
			exclusiveZone: 0

			implicitWidth: 400
			implicitHeight: 75
			color: "transparent"

			// An empty click mask prevents the window from blocking mouse events.
			mask: Region {}

			Rectangle {
				anchors.fill: parent
				radius: 10
				color: T.Config.osdBg
				RowLayout {
					anchors {
						fill: parent
						leftMargin: 10
						rightMargin: 15
					}

					IconImage {
 					   implicitSize: 30

					    source: Pipewire.defaultAudioSink.audio.muted
					        ? Quickshell.iconPath("audio-volume-muted-symbolic")
					        : Quickshell.iconPath("audio-volume-high-symbolic")
					}

					Rectangle {
						// Stretches to fill all left-over space
						Layout.fillWidth: true

						implicitHeight: 10
						radius: 20
						color: "#50ffffff"

						Rectangle {
							anchors {
								left: parent.left
								top: parent.top
								bottom: parent.bottom
							}

							implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
							radius: parent.radius
						}
					}
				}
			}
		}
	}
}
