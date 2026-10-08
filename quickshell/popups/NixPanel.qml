import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.modules.nix
import qs.theme as T
import qs.services as S

// The flake update panel: what is pinned, what could move, and the two commands that act on it.
//
// Nothing here changes a system on its own. "Update" and each host's "Rebuild" open a terminal
// running a command the user configured, so what happens next is visible and interruptible rather
// than a silent rebuild started by a panel.
HoverPopupWindow {
    id: nixPopup
    trigger: trigger
    popupWidth: T.Config.nixPopupWidth

    onVisibleChanged: {
        if (visible) {
            S.NixUpdates.refresh();
            S.PopupManager.closeOthers(nixPopup);
        }
    }

    Component.onDestruction: S.PopupManager.unregister(nixPopup)
    Component.onCompleted: S.PopupManager.register(nixPopup, "nix")

    // Header
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: T.Config.settingsHeaderHeight
        spacing: T.Config.layoutMarginSmall

        Text {
            text: "Nix"
            color: T.Config.surfaceText
            font.pixelSize: T.Config.fontSizeLarge
            font.bold: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // Where the flake stands, as a card: lit when something can move. A problem -- no flake, the
    // daemon unreachable, a failed check -- takes the card over in red, since then it is the news.
    readonly property string problem: {
        if (S.NixUpdates.backendError.length > 0) return S.NixUpdates.backendError;
        if (!S.NixUpdates.configured) return "No flake configured (set nix_flake)";
        if (!S.NixUpdates.available) return S.NixUpdates.reason;
        if (S.NixUpdates.error.length > 0) return S.NixUpdates.error;
        return "";
    }

    StatusCard {
        icon: S.NixUpdates.icon
        active: S.NixUpdates.hasUpdates
        problem: nixPopup.problem.length > 0
        title: {
            if (nixPopup.problem.length > 0) return nixPopup.problem;
            if (S.NixUpdates.checking) return "Checking every input…";
            if (S.NixUpdates.status.length > 0) return S.NixUpdates.status;
            if (S.NixUpdates.checkedAt === 0) return "Not checked yet";
            if (S.NixUpdates.updates === 0) return "Everything is current";
            return S.NixUpdates.updates === 1 ? "1 input can be updated" : S.NixUpdates.updates + " inputs can be updated";
        }
        subtitle: {
            if (!S.NixUpdates.available) return "";
            const parts = [];
            if (S.NixUpdates.checkedAt > 0) parts.push("checked " + S.NixUpdates.ago(S.NixUpdates.checkedAt) + " ago");
            if (S.NixUpdates.lockedAt > 0) parts.push("locked " + S.NixUpdates.ago(S.NixUpdates.lockedAt) + " ago");
            return parts.join(" · ");
        }
        detail: S.NixUpdates.configured ? S.NixUpdates.flake : ""
    }

    ComponentSplitter {
        visible: S.NixUpdates.movable.length > 0
    }

    // What could move. Inputs that are already current are left out: a wall of unchanged names
    // buries the answer the panel exists to give.
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: S.NixUpdates.movable.length > 0

        SectionLabel {
            text: "Can be updated"
        }

        Repeater {
            model: S.NixUpdates.movable

            delegate: NixInput {
                required property var modelData
                name: String(modelData.name || "")
                source: String(modelData.source || "")
                currentRev: String(modelData.current_rev || "")
                latestRev: String(modelData.latest_rev || "")
            }
        }
    }

    ComponentSplitter {}

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        SystemAction {
            icon: "󰑐"
            description: S.NixUpdates.checking ? "Checking..." : "Check for updates"
            function onClick() {
                S.NixUpdates.check();
            }
        }

        SystemAction {
            icon: "󰚰"
            description: "Update flake"
            visible: S.NixUpdates.updateCommand.length > 0
            function onClick() {
                S.PopupManager.closeAll();
                S.NixUpdates.update();
            }
        }
    }

    ComponentSplitter {
        visible: nixPopup.rebuildable.length > 0
    }

    // Every host in the flake shares one lock, so there is nothing per-host to report about
    // updates. What is per host is the command that rebuilds it, which is why they appear here
    // and not next to the inputs. A host with no configured command is left out rather than
    // offered as a button that cannot do anything.
    readonly property var rebuildable: S.NixUpdates.hosts.filter(host => String(host.rebuild || "").length > 0)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: nixPopup.rebuildable.length > 0

        SectionLabel {
            text: "Hosts"
        }

        Repeater {
            model: nixPopup.rebuildable

            delegate: SystemAction {
                required property var modelData
                icon: "󰒋"
                description: "Rebuild " + String(modelData.name || "")
                function onClick() {
                    S.PopupManager.closeAll();
                    S.NixUpdates.rebuild(String(modelData.name || ""));
                }
            }
        }
    }

    ComponentSpacer { bottomMargin: 6; Layout.preferredHeight: 1 }
}
