import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.theme as T

Rectangle {
    Layout.fillWidth: true
    Layout.bottomMargin: bottomMargin
    color: "transparent"

    property int bottomMargin: T.Config.panelBottomMarginMedium
}
