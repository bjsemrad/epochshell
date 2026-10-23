import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S

ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    PageHeader {
        showBack: page.showBack
        title: S.BatteryService.hasBattery ? "battery" : "power"
        status: S.BatteryService.hasBattery ? Math.round(S.BatteryService.percentage) + "%" : ""
        active: S.BatteryService.charging
        onBack: page.back()
    }

    KeyRow {
        visible: S.BatteryService.hasBattery
        key: "charge"
        Gauge {
            segments: 20
            value: S.BatteryService.percentage / 100
        }
    }
    KeyRow {
        visible: S.BatteryService.hasBattery && S.BatteryService.stateText().length > 0
        key: "state"
        text: S.BatteryService.stateText().toLowerCase()
    }

    KeyRow {
        visible: S.PowerProfile.available
        key: "profile"
        text: S.PowerProfile.profileLabel.toLowerCase()
        textColor: S.PowerProfile.profile === "performance" ? Ui.accent : Ui.value
    }
    KeyRow {
        visible: S.PowerProfile.available && S.PowerProfile.governor.length > 0
        key: "governor"
        text: S.PowerProfile.governor
    }
    KeyRow {
        visible: S.PowerProfile.available && S.PowerProfile.energyPreference.length > 0
        key: "epp"
        text: S.PowerProfile.energyPreference
    }
    KeyRow {
        visible: S.PowerProfile.available && S.PowerProfile.turbo !== null
        key: "turbo"
        text: S.PowerProfile.turbo === true ? "enabled" : "disabled"
    }
    KeyRow {
        visible: S.PowerProfile.available
        key: "managed by"
        text: S.PowerProfile.manager.length > 0 ? S.PowerProfile.manager : "nothing"
    }
    KeyRow {
        visible: S.SystemInfo.batteryHealth > 0
        key: "health"
        text: S.SystemInfo.batteryHealth + "%" + (S.SystemInfo.batteryCycles > 0 ? " · " + S.SystemInfo.batteryCycles + " cycles" : "")
    }

    Divider { visible: S.StayAwake.available }

    ListRow {
        visible: S.StayAwake.available
        icon: S.StayAwake.icon
        value: "stay awake"
        detail: S.StayAwake.enabled ? "held for " + S.StayAwake.held : ""
        active: S.StayAwake.enabled
        toggleable: true
        onToggled: S.StayAwake.set(!S.StayAwake.enabled)
    }
}
