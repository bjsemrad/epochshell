import QtQuick

// The panels opened from one bar, and how far open the most-open of them is -- which the bar's
// bottom-edge outline fades in with, so the bar and an open panel are outlined as one shape.
//
// Panels find this by walking up from their trigger to whichever bar item carries it as
// `barPanels`, and `attach` themselves on first opening. Never detached, but only counted while
// they are still there and still attached: a shut panel's reveal is 0, so it counts for nothing,
// and one that has since gone floating (panelStyle changed after it first opened) -- or gone
// altogether, as the panel design switched -- must not go on widening the bar or outlining it.
QtObject {
    property var panels: []

    function attach(panel) {
        if (panels.indexOf(panel) === -1) panels = panels.concat([panel]);
    }

    function counts(panel) {
        return panel !== null && panel !== undefined && panel.attached === true;
    }

    readonly property real openness: {
        let most = 0;
        for (const panel of panels) {
            if (counts(panel)) most = Math.max(most, panel.reveal);
        }
        return most;
    }

    // For the centered bar: the width its pill (an island, below) of `natural` width grows to while
    // its panels are open -- enough for each to hang from it with `margin` to spare at each end, so
    // a panel's flares always land on the pill's flat bottom edge, clear of its rounded corners.
    // Counts a panel from the moment it is opened, so a panel is placed for the pill it will hang
    // from.
    function targetWidth(natural, margin) {
        let width = natural;
        for (const panel of panels) {
            if (counts(panel) && panel.open && widens(panel))
                width = Math.max(width, needs(panel, margin));
        }
        return width;
    }

    // Under the centered ledge only a snapped panel widens it, and to the panel's own width (the
    // sides run straight on down); a hanging one leaves it as it is (see
    // HoverPopupWindow.ledgeJoin). Anywhere else every panel can.
    function widens(panel) {
        return !panel.ledgeJoin || panel.ledgeJoin === "snap";
    }
    function needs(panel, margin) {
        return panel.ledgeJoin === "snap" ? panel.width : panel.width + margin * 2;
    }

    // The most-open panel, and how it joins the ledge: the bar draws its half of the join from
    // these.
    readonly property var leading: {
        let best = null;
        for (const panel of panels) {
            if (counts(panel) && panel.reveal > 0 && (best === null || panel.reveal > best.reveal)) best = panel;
        }
        return best;
    }
    readonly property string leadingJoin: leading && leading.ledgeJoin ? leading.ledgeJoin : ""

    // The width drawn: the island grows towards targetWidth as a panel opens, rather than jumping,
    // and drops back at once as it closes.
    function widthAround(natural, margin) {
        let width = natural;
        for (const panel of panels) {
            if (!counts(panel) || !widens(panel)) continue;
            const needed = needs(panel, margin);
            if (needed > natural)
                width = Math.max(width, natural + (needed - natural) * panel.reveal);
        }
        return width;
    }
}
