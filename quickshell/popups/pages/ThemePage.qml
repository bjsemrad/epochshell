import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.theme as T

ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    onVisibleChanged: if (!visible) T.Config.endPreview()

    TextMetrics {
        id: longest
        font.family: Ui.font
        font.pixelSize: Ui.valueSize
        text: T.Config.availableThemes.reduce((a, b) => (b.length > a.length ? b : a), "")
    }
    readonly property real nameWidth: Math.ceil(longest.width) + Ui.space2XL

    PageHeader {
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
            delegate: ListRow {
                id: themeRow
                required property string modelData
                readonly property bool isCurrent: modelData === T.Config.themeName
                icon: isCurrent ? "󰄬" : ""
                value: modelData
                valueWidth: page.nameWidth
                active: isCurrent
                current: isCurrent
                status: isCurrent ? "current" : ""
                hoverStatus: isCurrent ? "" : "keep"
                onClicked: T.Config.selectTheme(modelData)

                Row {
                    spacing: 2
                    Repeater {
                        model: T.Config.swatchKeys
                        delegate: Rectangle {
                            required property string modelData
                            width: Ui.swatchSize
                            height: Ui.swatchSize
                            color: T.Config.themeColor(themeRow.modelData, modelData)
                        }
                    }
                }

                onLitChanged: if (lit) T.Config.previewTheme(themeRow.modelData)
            }
        }
    }
}
