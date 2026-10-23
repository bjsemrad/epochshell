import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: panel

    popupWidth: 500

    Component.onDestruction: S.PopupManager.unregister(panel)
    Component.onCompleted: S.PopupManager.register(panel, "nix")

    onVisibleChanged: {
        if (visible) {
            S.NixUpdates.refresh();
            S.PopupManager.closeOthers(panel);
        }
    }

    readonly property string problem: {
        if (S.NixUpdates.backendError.length > 0) return S.NixUpdates.backendError;
        if (!S.NixUpdates.configured) return "no flake configured (set nix_flake)";
        if (!S.NixUpdates.available) return S.NixUpdates.reason;
        if (S.NixUpdates.error.length > 0) return S.NixUpdates.error;
        return "";
    }
    readonly property var rebuildable: S.NixUpdates.hosts.filter(host => String(host.rebuild || "").length > 0)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: panel.hidePanel()

        PageHeader {
            title: "nix"
            status: S.NixUpdates.checking ? "checking…" : S.NixUpdates.hasUpdates ? "update" : S.NixUpdates.checkedAt > 0 ? "current" : ""
            active: S.NixUpdates.hasUpdates
        }
        KeyRow {
            visible: S.NixUpdates.configured
            key: "flake"
            text: S.NixUpdates.flake
        }
        KeyRow {
            visible: S.NixUpdates.checkedAt > 0
            key: "checked"
            text: S.NixUpdates.ago(S.NixUpdates.checkedAt) + " ago"
        }
        KeyRow {
            visible: S.NixUpdates.lockedAt > 0
            key: "locked"
            text: S.NixUpdates.ago(S.NixUpdates.lockedAt) + " ago"
        }
        Note {
            visible: text.length > 0
            text: (panel.problem || S.NixUpdates.status).toLowerCase()
        }

        SectionHeader {
            visible: S.NixUpdates.movable.length > 0
            text: "inputs"
        }
        Repeater {
            model: S.NixUpdates.movable
            delegate: ListRow {
                required property var modelData
                icon: "󰏗"
                value: String(modelData.name || "")
                detail: S.NixUpdates.shortRev(String(modelData.current_rev || "")) + " → " + S.NixUpdates.shortRev(String(modelData.latest_rev || ""))
                status: "behind"
                active: true
                interactive: false
            }
        }

        Divider {}

        ListRow {
            icon: "󰑐"
            value: S.NixUpdates.checking ? "checking…" : "check"
            interactive: !S.NixUpdates.checking
            onClicked: S.NixUpdates.check()
        }
        ListRow {
            visible: S.NixUpdates.updateCommand.length > 0
            icon: "󰚰"
            value: "update"
            active: S.NixUpdates.hasUpdates
            onClicked: {
                S.PopupManager.closeAll();
                S.NixUpdates.update();
            }
        }
        Repeater {
            model: panel.rebuildable
            delegate: ListRow {
                required property var modelData
                icon: "󰒋"
                value: "rebuild " + String(modelData.name || "")
                onClicked: {
                    S.PopupManager.closeAll();
                    S.NixUpdates.rebuild(String(modelData.name || ""));
                }
            }
        }
    }
}
