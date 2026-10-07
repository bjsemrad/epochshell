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
}
