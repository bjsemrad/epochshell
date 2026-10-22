import QtQuick
import QtQuick.Layouts
import qs.commonwidgets
import qs.services as S

// The battery and the power profile as a spec sheet, then the stay-awake switch. The profile is
// read here, not set: the power profile service reports it and has no way to change it.
ColumnLayout {
    id: page

    property bool showBack: false
    signal back()

    Layout.fillWidth: true
    spacing: 0

    ReadoutHeader {
        showBack: page.showBack
        title: S.BatteryService.hasBattery ? "battery" : "power"
        status: S.BatteryService.hasBattery ? Math.round(S.BatteryService.percentage) + "%" : ""
        active: S.BatteryService.charging
        onBack: page.back()
    }

    ReadoutKeyRow {
        visible: S.BatteryService.hasBattery
        key: "charge"
        ReadoutGauge {
            segments: 20
            interactive: false
            value: S.BatteryService.percentage / 100
        }
    }
    ReadoutKeyRow {
        visible: S.BatteryService.hasBattery && S.BatteryService.stateText().length > 0
        key: "state"
        text: S.BatteryService.stateText().toLowerCase()
    }

    ReadoutKeyRow {
        visible: S.PowerProfile.available
        key: "profile"
        text: S.PowerProfile.profileLabel.toLowerCase()
        textColor: S.PowerProfile.profile === "performance" ? Readout.accent : Readout.value
    }
    ReadoutKeyRow {
        visible: S.PowerProfile.available && S.PowerProfile.governor.length > 0
        key: "governor"
        text: S.PowerProfile.governor
    }
    ReadoutKeyRow {
        visible: S.PowerProfile.available && S.PowerProfile.energyPreference.length > 0
        key: "epp"
        text: S.PowerProfile.energyPreference
    }
    ReadoutKeyRow {
        visible: S.PowerProfile.available && S.PowerProfile.turbo !== null
        key: "turbo"
        text: S.PowerProfile.turbo === true ? "enabled" : "disabled"
    }
    ReadoutKeyRow {
        visible: S.PowerProfile.available
        key: "managed by"
        text: S.PowerProfile.manager.length > 0 ? S.PowerProfile.manager : "nothing"
    }
    ReadoutKeyRow {
        visible: S.SystemInfo.batteryHealth > 0
        key: "health"
        text: S.SystemInfo.batteryHealth + "%" + (S.SystemInfo.batteryCycles > 0 ? " · " + S.SystemInfo.batteryCycles + " cycles" : "")
    }

    ReadoutDivider { visible: S.StayAwake.available }

    ReadoutRow {
        visible: S.StayAwake.available
        icon: S.StayAwake.icon
        value: "stay awake"
        detail: S.StayAwake.enabled ? "held for " + S.StayAwake.held : ""
        active: S.StayAwake.enabled
        toggleable: true
        onToggled: S.StayAwake.set(!S.StayAwake.enabled)
    }
}
