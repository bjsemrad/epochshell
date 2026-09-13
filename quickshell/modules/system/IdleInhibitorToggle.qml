import qs.commonwidgets
import qs.services as S
import qs.theme as T

// The idle inhibitor, in the bar drawer.
//
// It follows the rule Tailscale and LocalSend use for their alerts, minus their second half:
// shown while it is actually holding the machine awake, and not otherwise. A machine that will
// not sleep is worth seeing, and clicking lets it sleep again -- but an icon saying everything is
// normal earns no room on the bar, open drawer or not. Turning it on is the system menu's job,
// and the battery panel's on a laptop.
//
// The struck-through "zZ" is the only glyph this needs: it is never drawn while the machine is
// free to sleep.
BarIcon {
    id: root
    // Overridden where it is placed, which decides when the alert shows.
    visible: S.StayAwake.connected && S.StayAwake.enabled
    mouseEnabled: true
    iconText: "󰒳"
    iconColor: T.Config.accent

    function performLeftClickAction() {
        S.StayAwake.toggle();
    }
}
