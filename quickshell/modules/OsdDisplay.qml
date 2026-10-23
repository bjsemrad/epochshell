import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

Item {
    id: osd

    implicitWidth: Ui.osdWidth
    implicitHeight: T.Config.barHeight

    readonly property bool continuous: S.OsdService.kind === "volume" || S.OsdService.kind === "brightness"
    readonly property bool discrete: S.OsdService.kind === "kbd"
    readonly property bool media: S.OsdService.kind === "media"

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Ui.space4XL
        anchors.rightMargin: Ui.space4XL
        spacing: Ui.space2XL

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: S.OsdService.icon
            color: S.OsdService.muted ? T.Config.red : T.Config.accent
            font.pixelSize: Ui.iconSize
            font.family: Ui.font
        }

        Item {
            visible: osd.continuous
            Layout.fillWidth: true
            Layout.fillHeight: true
            LevelSlider {
                anchors.verticalCenter: parent.verticalCenter
                interactive: false
                showLabel: false
                trackWidth: parent.width
                value: S.OsdService.value
                muted: S.OsdService.muted
            }
        }

        Item {
            visible: osd.discrete
            Layout.fillWidth: true
            Layout.fillHeight: true
            Gauge {
                anchors.verticalCenter: parent.verticalCenter
                showLabel: false
                segments: Math.max(1, S.OsdService.steps)
                segmentHeight: Ui.osdSegmentHeight
                filled: Ui.value
                value: S.OsdService.value
            }
        }

        Text {
            visible: osd.media
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            textFormat: Text.StyledText
            text: {
                const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;");
                const detail = S.OsdService.detail.length > 0
                    ? "<font color=\"" + Ui.detail + "\"> · " + esc(S.OsdService.detail) + "</font>" : "";
                return esc(S.OsdService.text) + detail;
            }
            color: Ui.value
            font.pixelSize: Ui.detailSize
            font.family: Ui.font
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            visible: !osd.media
            Layout.preferredWidth: Ui.osdLabelWidth
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: S.OsdService.label
            color: S.OsdService.muted ? Ui.detail : Ui.value
            font.pixelSize: Ui.detailSize
            font.family: Ui.font
        }
    }
}
