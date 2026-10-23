import QtQuick

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

    function targetWidth(natural, margin) {
        let width = natural;
        for (const panel of panels) {
            if (counts(panel) && panel.open && widens(panel))
                width = Math.max(width, needs(panel, margin));
        }
        return width;
    }

    function widens(panel) {
        return !panel.ledgeJoin || panel.ledgeJoin === "snap";
    }
    function needs(panel, margin) {
        return panel.ledgeJoin === "snap" ? panel.width : panel.width + margin * 2;
    }

    readonly property var leading: {
        let best = null;
        for (const panel of panels) {
            if (counts(panel) && panel.reveal > 0 && (best === null || panel.reveal > best.reveal)) best = panel;
        }
        return best;
    }
    readonly property string leadingJoin: leading && leading.ledgeJoin ? leading.ledgeJoin : ""

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
