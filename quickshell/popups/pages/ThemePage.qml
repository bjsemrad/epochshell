import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.theme as T

// The themes as rows, each with a strip of its colours; the current one marked. Hovering one tries
// it on, as the theme overlay does, and clicking keeps it.
ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    onVisibleChanged: if (!visible) T.Config.endPreview()

    // The widest theme name, measured in the rows' own font.
    TextMetrics {
        id: longest
        font.family: Readout.font
        font.pixelSize: Readout.valueSize
        text: T.Config.availableThemes.reduce((a, b) => (b.length > a.length ? b : a), "")
    }
    readonly property real nameWidth: Math.ceil(longest.width) + 12

    ReadoutHeader {
        showBack: page.showBack
        title: "theme"
        status: T.Config.themeName
        onBack: page.back()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        HoverHandler {
            onHoveredChanged: if (!hovered) T.Config.endPreview()
        }

        Repeater {
            model: T.Config.availableThemes
            delegate: ReadoutRow {
                id: themeRow
                required property string modelData
                readonly property bool current: modelData === T.Config.themeName
                icon: current ? "󰄬" : ""
                value: modelData
                // The longest theme name, so every row's colours line up in one column.
                valueWidth: page.nameWidth
                active: current
                status: current ? "current" : ""
                hoverStatus: current ? "" : "keep"
                onClicked: T.Config.selectTheme(modelData)

                Row {
                    spacing: 2
                    Repeater {
                        model: T.Config.swatchKeys
                        delegate: Rectangle {
                            required property string modelData
                            width: 8
                            height: 8
                            color: T.Config.themeColor(themeRow.modelData, modelData)
                        }
                    }
                }

                // Hovered (or focused from the keyboard): try it on.
                onLitChanged: if (lit) T.Config.previewTheme(themeRow.modelData)
            }
        }
    }
}
