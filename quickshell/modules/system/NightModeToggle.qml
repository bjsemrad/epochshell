import qs.commonwidgets
import qs.services as S
import qs.theme as T

// Night mode, in the bar drawer.
//
// It follows the same rule as the idle inhibitor beside it: on show whenever the screen is
// actually being warmed, and otherwise only while the drawer is open. A screen that has gone
// orange is worth explaining with the drawer shut, and the control is worth reaching for when the
// evening starts -- but an icon that says "the screen is normal" earns no room on a collapsed bar.
//
// The system menu carries the same switch, the way the battery panel carries the idle
// inhibitor's; both read the service, so this and that row always say the same thing.
//
// The moon stays the glyph either way -- it is what night mode is called everywhere else -- and
// colour says whether it is on, warm while the screen is warmed and muted when it is not.
BarIcon {
    id: root
    // Overridden where it is placed, which decides when an alert shows.
    visible: S.NightLight.connected && S.NightLight.available
    mouseEnabled: true
    iconText: S.NightLight.icon
    iconColor: S.NightLight.enabled ? T.Config.orange : T.Config.outline

    function performLeftClickAction() {
        S.NightLight.toggle();
    }
}
