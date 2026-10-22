import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Home Assistant in the Readout design: each favourite a row -- its icon, its name, its state --
// and a click toggles what can be toggled or runs a scene or script.
HoverPopupWindow {
    id: panel

    popupWidth: 440

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "homeassistant")

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(panel);
            S.HomeAssistant.refresh();
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        ReadoutHeader {
            title: "home assistant"
            status: S.HomeAssistant.loading ? "loading…" : "refresh"
            switchable: !S.HomeAssistant.loading
            onStatusClicked: S.HomeAssistant.refresh()
        }
        ReadoutText {
            text: S.HomeAssistant.configured ? S.HomeAssistant.statusText.toLowerCase()
                : "create ~/.config/epochshell-hass.json with baseUrl, token and favorites"
        }

        Flickable {
            visible: S.HomeAssistant.rows.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(entities.implicitHeight, 420)
            contentWidth: width
            contentHeight: entities.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: entities
                width: parent.width
                spacing: 0

                Repeater {
                    model: S.HomeAssistant.rows
                    delegate: ReadoutRow {
                        // The roles through `model`: two of them, icon and state, are names a row
                        // already has (its glyph, and every Item's states machinery).
                        required property var model
                        readonly property string entityId: model.entityId
                        readonly property string entityState: String(model.state || "")
                        readonly property bool runnable: entityId.indexOf("scene.") === 0 || entityId.indexOf("script.") === 0
                        icon: model.icon
                        value: model.name
                        // What can be switched shows a switch; a scene or script runs; anything
                        // else reports its state, in words other than on and off.
                        readonly property bool switchable: model.controllable && !runnable
                        status: runnable ? "run" : switchable ? "" : entityState === "on" ? "active" : entityState === "off" ? "idle" : entityState.toLowerCase()
                        active: entityState === "on"
                        toggleable: switchable
                        interactive: model.controllable && !S.HomeAssistant.loading
                        onToggled: S.HomeAssistant.toggleEntity(entityId)
                        onClicked: S.HomeAssistant.toggleEntity(entityId)
                    }
                }
            }
        }
    }
}
