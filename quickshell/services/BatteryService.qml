pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: batteryService

    property real percentage: 0
    property bool charging: false

    property bool hasBattery: {
        for (let dev of UPower.devices.values) {
            if (dev.isPresent && dev.isLaptopBattery) {
                return true;
            }
        }
        return false;
    }

    function batteryIcon() {
        let pct = Math.round(batteryService.percentage);
        if (pct > 95)
            return batteryService.charging ? "󰂋" : "󰁹";
        if (pct > 55)
            return batteryService.charging ? "󰢞" : "󰂀";
        if (pct > 45)
            return batteryService.charging ? "󰂈" : "󰁽";
        if (pct > 20)
            return batteryService.charging ? "󰂆" : "󰁻";
        return batteryService.charging ? "󰢜" : "󰁺";
    }

    // What the battery is doing, in words. By its state rather than only charging-or-not: plugged
    // in and full, or held below a charge limit, there is no time to count down, and the old
    // "Remaining: " was left with nothing after it.
    function stateText() {
        const dev = UPower.displayDevice;
        if (!dev) return "";
        switch (dev.state) {
        case UPowerDeviceState.Charging: {
            const t = timeToString(dev.timeToFull);
            return t.length > 0 ? "Full in " + t : "Charging";
        }
        case UPowerDeviceState.Discharging: {
            const t = timeToString(dev.timeToEmpty);
            return t.length > 0 ? t + " remaining" : "On battery";
        }
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.PendingCharge:
            return "Plugged in, not charging";
        default:
            return "";
        }
    }

    // "1 h 20 m", "45 m", "2 h"; empty when there is no time to tell.
    function timeToString(input) {
        const time = secondsToHMS(input);
        const parts = [];
        if (time.hours > 0) parts.push(time.hours + " h");
        if (time.minutes > 0) parts.push(time.minutes + " m");
        return parts.join(" ");
    }

    function secondsToHMS(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        return {
            hours: h,
            minutes: m,
            seconds: s
        };
    }

    function computePercentage(pct) {
        return pct * 100;
    }

    Component.onCompleted: {
        if (UPower.displayDevice) {
            percentage = computePercentage(UPower.displayDevice.percentage);
            charging = (UPower.displayDevice.state === UPowerDeviceState.Charging);
        }
    }

    Connections {
        target: UPower.displayDevice

        function onPercentageChanged() {
            let pct = UPower.displayDevice ? UPower.displayDevice.percentage : 0;
            batteryService.percentage = computePercentage(pct);
        }

        function onStateChanged() {
            batteryService.charging = (UPower.displayDevice.state === UPowerDeviceState.Charging);
        }
    }
}
