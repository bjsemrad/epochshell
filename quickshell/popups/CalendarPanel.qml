import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S
import qs.theme as T

HoverPopupWindow {
    id: popup

    popupWidth: Ui.calendarWidth

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    onOpenChanged: if (open) goToToday()

    function firstVisibleDate() {
        const first = new Date(viewYear, viewMonth, 1);
        return new Date(viewYear, viewMonth, 1 - first.getDay());
    }
    function cellDate(index) {
        const start = firstVisibleDate();
        return new Date(start.getFullYear(), start.getMonth(), start.getDate() + index);
    }
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }
    function moveMonth(delta) {
        const next = new Date(viewYear, viewMonth + delta, 1);
        viewYear = next.getFullYear();
        viewMonth = next.getMonth();
    }
    function goToToday() {
        today = new Date();
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    Component.onDestruction: S.PopupManager.unregister(popup)
    Component.onCompleted: S.PopupManager.register(popup, "calendar")
    onVisibleChanged: if (visible) S.PopupManager.closeOthers(popup)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Keys.onEscapePressed: popup.hidePanel()

        PageHeader {
            title: Qt.formatDate(popup.today, "dddd d MMMM").toLowerCase()
            status: popup.viewYear === popup.today.getFullYear() && popup.viewMonth === popup.today.getMonth() ? "" : "today"
            switchable: true
            onStatusClicked: popup.goToToday()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Ui.spaceS
            Layout.bottomMargin: Ui.spaceS
            spacing: 0

            component Arrow: Text {
                id: arrow
                property int by: 1
                Layout.preferredWidth: Ui.iconColumn
                horizontalAlignment: Text.AlignHCenter
                color: arrowMouse.containsMouse ? Ui.value : Ui.detail
                font.pixelSize: Ui.chevronSize
                font.family: Ui.font
                MouseArea {
                    id: arrowMouse
                    anchors.fill: parent
                    anchors.margins: -Ui.hitSlopSmall
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.moveMonth(arrow.by)
                }
            }

            Arrow { text: "‹"; by: -1 }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(popup.viewYear, popup.viewMonth, 1), "MMMM yyyy").toLowerCase()
                color: Ui.value
                font.pixelSize: Ui.valueSize
                font.family: Ui.font
            }
            Arrow { text: "›"; by: 1 }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Ui.spaceM
            columns: 7
            rowSpacing: 2
            columnSpacing: 0

            Repeater {
                model: ["s", "m", "t", "w", "t", "f", "s"]
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Ui.key
                    font.pixelSize: Ui.detailSize
                    font.family: Ui.font
                }
            }

            Repeater {
                model: 42
                delegate: Item {
                    required property int index
                    readonly property date day: popup.cellDate(index)
                    readonly property bool inMonth: day.getMonth() === popup.viewMonth
                    readonly property bool isToday: popup.sameDay(day, popup.today)
                    Layout.fillWidth: true
                    implicitHeight: Ui.rowHeight

                    Text {
                        id: number
                        anchors.centerIn: parent
                        text: parent.day.getDate()
                        color: parent.isToday ? Ui.value : parent.inMonth ? Ui.value : Ui.segmentOff
                        font.pixelSize: Ui.valueSize
                        font.family: Ui.font
                        font.bold: parent.isToday
                    }
                    Rectangle {
                        visible: parent.isToday
                        anchors.top: number.bottom
                        anchors.horizontalCenter: number.horizontalCenter
                        width: number.width + Ui.spaceS
                        height: Ui.tick
                        color: Ui.accent
                    }
                }
            }
        }
    }
}
