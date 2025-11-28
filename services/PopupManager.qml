pragma Singleton
import QtQuick

QtObject {
    property var openPopups: []

    function register(popup) {
        if (openPopups.indexOf(popup) === -1){
            openPopups.push(popup)
        }
    }

    function closeOthers(except) {
        for (let p of openPopups) {
            if (p !== except && p.visible) {
                p.visible = false
            }
        }
    }
}
