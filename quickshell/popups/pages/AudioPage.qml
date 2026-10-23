import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.commonwidgets
import qs.services as S

ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker {
        objects: [page.sink, page.source].filter(node => node !== null)
    }

    function isBluetooth(node) {
        return String(node.name || "").indexOf("bluez") !== -1;
    }

    PageHeader {
        showBack: page.showBack
        title: "sound"
        status: page.sink && page.sink.audio && page.sink.audio.muted ? "muted" : ""
        active: page.sink !== null && page.sink.audio !== null && !page.sink.audio.muted
        hasSwitch: page.sink !== null
        checked: active
        onToggled: if (page.sink && page.sink.audio) page.sink.audio.muted = !page.sink.audio.muted
        onBack: page.back()
    }

    KeyRow {
        key: "volume"
        LevelSlider {
            trackWidth: 200
            value: page.sink && page.sink.audio ? page.sink.audio.volume : 0
            muted: page.sink !== null && page.sink.audio !== null && page.sink.audio.muted
            onMoved: v => { if (page.sink && page.sink.audio) page.sink.audio.volume = v; }
        }
    }

    SectionHeader { text: "output" }
    Repeater {
        model: Pipewire.nodes.values.filter(node => node.isSink && node.audio && node.description && !node.isStream)
        delegate: ListRow {
            required property var modelData
            readonly property bool inUse: page.sink !== null && modelData.id === page.sink.id
            icon: page.isBluetooth(modelData) ? "󰂰" : "󰓃"
            iconColor: inUse ? Ui.accent : Ui.detail
            value: modelData.description
            status: inUse ? "active" : page.isBluetooth(modelData) ? "bt" : ""
            active: inUse
            current: inUse
            hoverStatus: inUse ? "" : "use"
            onClicked: S.AudioService.setDefault(modelData.id)
        }
    }

    KeyRow {
        Layout.topMargin: 8
        key: "mic"
        LevelSlider {
            trackWidth: 200
            value: page.source && page.source.audio ? page.source.audio.volume : 0
            muted: page.source !== null && page.source.audio !== null && page.source.audio.muted
            onMoved: v => { if (page.source && page.source.audio) page.source.audio.volume = v; }
        }
    }

    SectionHeader { text: "input" }
    Repeater {
        model: Pipewire.nodes.values.filter(node => !node.isSink && node.audio && node.description && !node.isStream)
        delegate: ListRow {
            required property var modelData
            readonly property bool inUse: page.source !== null && modelData.id === page.source.id
            icon: "󰍬"
            iconColor: inUse ? Ui.accent : Ui.detail
            value: modelData.description
            status: inUse ? "active" : ""
            active: inUse
            current: inUse
            hoverStatus: inUse ? "" : "use"
            onClicked: S.AudioService.setDefault(modelData.id)
        }
    }

    Divider {}

    ListRow {
        icon: "󰒓"
        value: "sound settings"
        onClicked: S.AudioService.openSettings()
    }
}
