import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.commonwidgets
import qs.services as S

ColumnLayout {
    id: page

    property bool showBack: false
    property bool showHeader: true
    signal back()

    Layout.fillWidth: true
    spacing: 0

    property string username: ""
    property string armed: ""

    function focusFirst() {
        lockRow.forceActiveFocus();
    }

    onVisibleChanged: if (!visible) armed = ""

    Process {
        command: ["whoami"]
        running: true
        stdout: SplitParser {
            onRead: data => page.username = data.trim()
        }
    }
    Process { id: sleepProcess; command: ["systemctl", "suspend"] }
    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: poweroffProcess; command: ["systemctl", "poweroff"] }
    Process { id: logoutProcess; command: ["sh", "/home/" + page.username + "/.config/wmscripts/logout.sh"] }

    function confirm(name, process) {
        if (page.armed === name) {
            page.armed = "";
            process.running = true;
        } else {
            page.armed = name;
        }
    }

    PageHeader {
        visible: page.showHeader
        showBack: page.showBack
        title: "power"
        onBack: page.back()
    }

    ListRow {
        id: lockRow
        icon: "󰌾"
        value: "lock"
        onClicked: {
            S.PopupManager.closeAll();
            S.Lock.lock();
        }
    }
    ListRow {
        icon: "󰤄"
        value: "sleep"
        onClicked: sleepProcess.running = true
    }
    ListRow {
        icon: "󰜉"
        value: "restart"
        status: page.armed === "restart" ? "enter to confirm" : ""
        statusColor: Ui.danger
        onClicked: page.confirm("restart", rebootProcess)
    }
    ListRow {
        icon: "⏻"
        value: "shut down"
        status: page.armed === "poweroff" ? "enter to confirm" : ""
        statusColor: Ui.danger
        onClicked: page.confirm("poweroff", poweroffProcess)
    }
    ListRow {
        icon: "󰗽"
        value: "log out"
        status: page.armed === "logout" ? "enter to confirm" : ""
        statusColor: Ui.danger
        onClicked: page.confirm("logout", logoutProcess)
    }
}
