import QtQuick

// The panels opened from one bar, and how far open the most-open of them is -- which the bar's
// bottom-edge outline fades in with, so the bar and an open panel are outlined as one shape.
//
// Panels find this by walking up from their trigger to whichever bar item carries it as
// `barPanels`, and `attach` themselves on first opening. Never detached: a shut panel's reveal is
// 0, so it counts for nothing, and a bar's panels live as long as the bar does.
QtObject {
    property var panels: []

    function attach(panel) {
        if (panels.indexOf(panel) === -1) panels = panels.concat([panel]);
    }

    readonly property real openness: {
        let most = 0;
        for (const panel of panels)
            most = Math.max(most, panel.reveal);
        return most;
    }

    // For the island style: how wide an island of `natural` width has to be for every open panel
    // to hang from it with `margin` to spare at each end -- so a panel's flares always land on the
    // island's bottom edge, clear of its rounded corners. It grows as a panel opens and shrinks as
    // it closes, so a panel wider than the island widens it rather than overhanging it.
    function widthAround(natural, margin) {
        let width = natural;
        for (const panel of panels) {
            const needed = panel.width + margin * 2;
            if (needed > natural)
                width = Math.max(width, natural + (needed - natural) * panel.reveal);
        }
        return width;
    }
}
