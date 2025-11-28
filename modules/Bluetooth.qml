import "../commonwidgets"

BarIconPopup {
    id: root
    mouseEnabled: true
    iconText: "󰂯"
            // TODO: Have this based on the connectivity and the battery etc status
            // {
            //     const s = S.NetworkMonitor.strength
            //
            //     if (!S.NetworkMonitor.connected) return "󰤭"
            //     if (s >= 75) return "󰤨"
            //     if (s >= 50) return "󰤢"
            //     if (s >= 25) return "󰤟"
            //     return "󰤟"
            // }
}
