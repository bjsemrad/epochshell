import QtQuick
import qs.commonwidgets
import Quickshell
import qs.services as S

Scope {
    id: root

    function show() {
        S.OsdService.show({
            kind: "media",
            icon: S.AudioService.osdIcon,
            text: S.AudioService.osdMessage
        }, Ui.osdMediaMs);
    }

    Connections {
        target: S.AudioService
        function onOsdVisibleChanged() {
            if (S.AudioService.osdVisible) root.show();
        }
        function onOsdMessageChanged() {
            if (S.AudioService.osdVisible) root.show();
        }
        function onOsdIconChanged() {
            if (S.AudioService.osdVisible) root.show();
        }
    }
}
