import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: homeAssistantPopup
    trigger: trigger
    popupWidth: T.Config.homeAssistantPopupWidth

    onVisibleChanged: {
        if (visible) {
            S.PopupManager.closeOthers(homeAssistantPopup);
            S.HomeAssistant.refresh();
        }
    }

    Component.onDestruction: S.PopupManager.unregister(homeAssistantPopup)
    Component.onCompleted: S.PopupManager.register(homeAssistantPopup, "homeassistant")

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: T.Config.settingsHeaderHeight
        spacing: T.Config.layoutMarginSmall

        Text {
            text: "Home Assistant"
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            font.bold: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        PanelHeaderIcon {
            iconText: "󰑓"
            function onClick() {
                S.HomeAssistant.refresh();
            }
        }
    }

    ComponentSplitter {}

    Text {
        Layout.fillWidth: true
        text: S.HomeAssistant.statusText
        color: S.HomeAssistant.connected ? T.Config.inactive : T.Config.orange
        font.pixelSize: T.Config.fontSizeSubtext
        elide: Text.ElideRight
    }

    Text {
        visible: !S.HomeAssistant.configured
        Layout.fillWidth: true
        text: "Create ~/.config/epochshell-hass.json with baseUrl, token, and favorites."
        color: T.Config.inactive
        font.pixelSize: T.Config.fontSizeSubtext
        wrapMode: Text.WordWrap
    }

    ListView {
        id: entityList
        visible: S.HomeAssistant.rows.count > 0
        Layout.fillWidth: true
        implicitHeight: Math.min(contentHeight, Screen.height * 0.55)
        clip: true
        model: S.HomeAssistant.rows
        spacing: T.Config.popupLayoutSpacing
        boundsBehavior: Flickable.StopAtBounds

        // An entity, in the shared row look. One that is on is lit, like a dashboard tile; clicking a
        // controllable one toggles it -- or, for a scene or a script, runs it.
        delegate: ListRow {
            id: row
            required property string entityId
            required property string name
            required property string state
            required property string icon
            required property bool controllable

            readonly property bool runnable: row.entityId.indexOf("scene.") === 0 || row.entityId.indexOf("script.") === 0

            width: entityList.width - 12
            icon: row.icon
            title: row.name
            subtitle: row.runnable ? "Click to run" : row.state
            active: row.state === "on"
            clickable: row.controllable && !S.HomeAssistant.loading
            onClicked: S.HomeAssistant.toggleEntity(row.entityId)
        }
        ScrollBar.vertical: ScrollBar {
            policy: entityList.contentHeight > entityList.height ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 3
                radius: 3
                antialiasing: true
                color: T.Config.surfaceText
                opacity: 0.7
            }
        }
    }

    ComponentSpacer { bottomMargin: 6 }
}
