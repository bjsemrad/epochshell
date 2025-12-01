import "../commonwidgets"

BarIconPopup {
    id: root
    mouseEnabled: true
    hoverEnabled: false
    iconText: "󰂯"
            // TODO: Have this based on the connectivity and the battery etc status
            // {
            //     if (s >= 75) return "󰤨"
            //     if (s >= 50) return "󰤢"
            //     if (s >= 25) return "󰤟"
            //     return "󰤟"
            // }
}
