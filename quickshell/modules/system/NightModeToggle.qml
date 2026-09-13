import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Night mode, in the bar drawer.
//
// It follows the same rule as the idle inhibitor beside it: shown only while the screen is
// actually being warmed. A screen that has gone orange is worth explaining, and clicking hands it
// back -- but an icon saying the screen is normal earns no room on the bar, open drawer or not.
// Turning night mode on is the system menu's job.
//
// That menu reads the same service this does, so the row and this icon always agree.
BarIcon {
    id: root
    // Overridden where it is placed, which decides when the alert shows.
    visible: S.NightLight.connected && S.NightLight.enabled
    mouseEnabled: true
    iconText: S.NightLight.icon
    iconColor: T.Config.orange

    function performLeftClickAction() {
        S.NightLight.toggle();
    }
}
