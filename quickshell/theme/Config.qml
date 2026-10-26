pragma Singleton
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/epochshell"
    readonly property string configPath: configDir + "/config.toml"

    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/epochshell"
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/epochshell"
    readonly property string userThemeDir: dataDir + "/themes"
    readonly property string bundledThemeDir: Quickshell.shellRoot + "/theme/themes"
    readonly property string selectionPath: stateDir + "/theme"

    readonly property string settingsPath: stateDir + "/settings.toml"
    readonly property string defaultThemeName: "matte-black"

    property string themeName: defaultThemeName
    readonly property string themePath: themeName === "" ? "" : (themeFromUserDir ? userThemeDir : bundledThemeDir) + "/" + themeName + ".toml"
    property bool themeLoaded: false
    readonly property var availableThemes: themeScan.names

    property string selectedThemeName: ""
    property string configThemeName: defaultThemeName

    property string pendingSelection: ""
    property string previousSelection: ""
    property string committedThemeName: ""

    property string previewThemeName: ""

    property string parentThemeName: ""
    readonly property string parentThemePath: parentThemeName === "" ? "" : (parentFromUserDir ? userThemeDir : bundledThemeDir) + "/" + parentThemeName + ".toml"
    property bool parentFromUserDir: true
    onParentThemeNameChanged: parentFromUserDir = true

    property string configText: ""
    property string themeText: ""
    property string parentThemeText: ""
    property string settingsText: ""

    // FileView answers whether a file exists only by loading it, so the bundled dir is tried after
    // a failed load.
    property bool themeFromUserDir: true
    onThemeNameChanged: themeFromUserDir = true
    readonly property var colorKeys: ["accent", "accentLightShade", "inactive", "active", "activeSelection", "background", "surface", "surfaceVariant", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "surfaceText", "outline", "purple", "green", "orange", "blue", "yellow", "cyan", "red", "bg_blue", "bg_yellow"]
    readonly property var boolKeys: ["hideInactiveWorkspaces", "workspaceIcons", "blur", "barLedge", "workspaceShowTitle"]
    readonly property var realKeys: ["workspaceStripMaxWidthRatio", "barOpacity", "panelOpacity", "popupOpacity"]
    readonly property var stringKeys: ["fontFamily", "barStyle", "panelOutline", "panelStyle", "statusStyle", "workspaceStyle", "workspaceHomes", "workspaceIconColor", "polkitPhrase", "launcherStyle", "barSpan"]
    readonly property string themeKey: "theme"
    readonly property string extendsKey: "extends"
    readonly property var intKeys: ["popupPadding", "popupRadius", "popupLayoutSpacing", "barIconSize", "barClockSize", "barModuleSpacing", "barIconTextSpacing", "barModuleHorizontalPadding", "barModuleVerticalPadding", "barFloatingGap", "barFloatingSideGap", "workspaceIconLimit", "workspaceMinimapMaxWidth", "polkitMaxAttempts", "widthPaddingSmall", "layoutMarginSmall", "fontSizeNormal", "fontSizeMedium", "fontSizeLarge", "fontSizeXLarge", "fontSizeSubtext", "cardRadius", "cardHeight", "barHeight", "switchHeight", "switchWidth", "switchKnobSize", "switchKnobRadius"]

    property color accent: blue
    property color accentLightShade: Qt.rgba(Qt.color(accent).r, Qt.color(accent).g, Qt.color(accent).b, 0.10)
    property color inactive: Qt.rgba(Qt.color(surfaceText).r, Qt.color(surfaceText).g, Qt.color(surfaceText).b, 0.75)
    property color active: surfaceText
    property color activeSelection: surfaceContainerHigh

    property color background: "#0e1013"
    property color surface: "#1f2329"
    property color surfaceVariant: "#323641"
    property color surfaceContainer: "#1f2329"
    property color surfaceContainerHigh: "#282c34"
    property color surfaceContainerHighest: "#30363f"
    property color surfaceText: "#a0a8b7"
    property color outline: "#8c9199"

    property color purple: "#bf68d9"
    property color green: "#8ebd6b"
    property color orange: "#cc9057"
    property color blue: "#4fa6ed"
    property color yellow: "#e2b86b"
    property color cyan: "#48b0bd"
    property color red: "#e55561"
    property color bg_blue: "#61afef"
    property color bg_yellow: "#e8c88c"

    /* Misc */
    property string fontFamily: "JetBrainsMono Nerd Font Propo"

    readonly property string defaultBarStyle: Quickshell.env("EPOCHSHELL_BAR_STYLE") || "full"
    property string barStyle: defaultBarStyle

    property int barFloatingGap: 4
    property int barFloatingSideGap: 10
    readonly property bool barCentered: barStyle === "centered"
    property bool barLedge: true
    property string barSpan: "pill"
    readonly property bool barSpanFull: barCentered && barSpan === "full"
    readonly property bool barIsLedge: barCentered && (barLedge || barSpanFull)
    readonly property bool barCompact: settledStatusStyle === "dashboard"
    readonly property bool barFloating: barStyle === "floating" || (barCentered && !barSpanFull)
    readonly property int barTopGap: barFloating && !barIsLedge ? barFloatingGap : 0
    readonly property int barSideGap: barFloating ? barFloatingSideGap : 0
    readonly property int barBottom: barTopGap + barHeight

    property string panelOutline: "fade"

    property string panelStyle: "attached"

    property string statusStyle: "individual"

    // rebuild() resets every setting to its default before re-applying the files; read directly,
    // the bar tore down the capsule and an open dashboard in that instant. So the bar reads this,
    // settled a turn later.
    property string settledStatusStyle: statusStyle
    onStatusStyleChanged: structureSettle.restart()
    Timer {
        id: structureSettle
        interval: 0
        onTriggered: root.settledStatusStyle = root.statusStyle
    }

    property string workspaceStyle: "minimap"

    property int workspaceIconLimit: 2

    property bool workspaceShowTitle: false

    property string workspaceIconColor: "color"
    readonly property bool workspaceIconsMono: workspaceIconColor === "mono"

    property int polkitMaxAttempts: 3

    // A phrase only the real polkit dialog shows, so a fake prompt cannot reproduce it. Never
    // logged.
    property string polkitPhrase: ""

    property string launcherStyle: "attached"

    property int workspaceMinimapMaxWidth: 160

    property string workspaceHomes: ""
    readonly property int barSmallIconSize: Math.max(10, barIconSize - 2)
    readonly property var workspaceHomeList: {
        const homes = [];
        for (const pair of workspaceHomes.split(",")) {
            const at = pair.lastIndexOf(":");
            if (at <= 0) continue;
            const app = pair.slice(0, at).trim().toLowerCase();
            const workspace = pair.slice(at + 1).trim();
            if (app.length > 0 && workspace.length > 0) homes.push({ app: app, workspace: workspace });
        }
        return homes;
    }
    function workspaceHomeFor(appId) {
        const id = String(appId || "").toLowerCase();
        if (id.length === 0) return "";
        for (const home of workspaceHomeList) {
            if (id === home.app) return home.workspace;
        }
        for (const home of workspaceHomeList) {
            if (id.indexOf(home.app) !== -1) return home.workspace;
        }
        return "";
    }

    property int popupPadding: 10
    property int popupRadius: 10
    property int popupLayoutSpacing: 8

    readonly property int defaultBarIconSize: 15
    property int barIconSize: defaultBarIconSize
    property int barClockSize: barIconSize
    property int barModuleSpacing: 8
    property int barIconTextSpacing: 5
    property int barModuleHorizontalPadding: widthPaddingSmall
    property int barModuleVerticalPadding: popupPadding

    property int widthPaddingSmall: 14

    property int layoutMarginSmall: 5

    property int fontSizeNormal: 14
    property int fontSizeMedium: 16

    property int fontSizeLarge: 18
    property int fontSizeXLarge: 24
    property int fontSizeSubtext: 11

    property int cardRadius: 10
    property int cardHeight: 50

    readonly property int defaultBarHeight: 32
    property int barHeight: defaultBarHeight

    property int switchHeight: 42
    property int switchWidth: 24
    property int switchKnobSize: 20
    property int switchKnobRadius: 10

    property bool hideInactiveWorkspaces: true
    property bool workspaceIcons: true

    property bool blur: true
    readonly property bool barBlur: blur && barOpacity < 0.99
    readonly property bool panelBlur: blur && panelOpacity < 0.99
    readonly property bool popupBlur: blur && popupOpacity < 0.99
    property real workspaceStripMaxWidthRatio: 0.45

    property real barOpacity: 1.0
    property real panelOpacity: 1.0
    property real popupOpacity: 1.0

    readonly property color barBackground: Qt.rgba(background.r, background.g, background.b, barOpacity)
    readonly property color panelBackground: Qt.rgba(background.r, background.g, background.b, panelOpacity)
    readonly property color popupBackground: Qt.rgba(background.r, background.g, background.b, popupOpacity)

    function tint(c) {
        const w = surfaceText;
        const b = background;
        const span = (w.r - b.r) + (w.g - b.g) + (w.b - b.b);
        const strength = span === 0 ? 0.1
            : Math.max(0, Math.min(1, ((c.r - b.r) + (c.g - b.g) + (c.b - b.b)) / span));
        return Qt.rgba(w.r, w.g, w.b, strength * c.a);
    }

    function onBar(c) {
        return barOpacity >= 0.99 ? c : tint(c);
    }

    function onPanel(c) {
        return panelOpacity >= 0.99 ? c : tint(c);
    }

    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onLoaded: root.acceptConfig(text())
        onLoadFailed: root.acceptConfig("")
        onFileChanged: reload()
    }

    FileView {
        id: themeFile
        path: root.themePath
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.themeLoaded = true;
            root.committedThemeName = root.themeName;
            root.themeText = text();
            const parent = root.readExtends(root.themeText);
            if (parent === "")
                root.parentThemeText = "";
            root.parentThemeName = parent;
            if (root.pendingSelection !== "" && root.pendingSelection === root.themeName) {
                root.pendingSelection = "";
                selectionWriter.setText(root.themeName + "\n");
            }
            root.rebuild();
        }

        onLoadFailed: {
            // The reload is needed: re-pointing `path` after a failed load does not start another
            // one.
            if (root.themeFromUserDir) {
                root.themeFromUserDir = false;
                Qt.callLater(themeFile.reload);
                return;
            }

            if (root.previewThemeName !== "") {
                console.warn("EpochShell theme not found:", root.themeName, "-- ending preview");
                root.endPreview();
                return;
            }

            if (root.pendingSelection !== "" && root.committedThemeName !== "") {
                console.warn("EpochShell theme not found:", root.themeName, "-- staying on", root.committedThemeName);
                root.pendingSelection = "";
                root.selectedThemeName = root.previousSelection;
                root.resolveTheme();
                return;
            }

            root.themeLoaded = false;
            root.themeText = "";
            if (root.themeName !== "") {
                console.warn("Unknown EpochShell theme:", root.themeName, "-- known:", root.availableThemes.join(", ") || "none");
            }
            root.rebuild();
        }

        onFileChanged: reload()
    }

    FileView {
        id: parentFile
        path: root.parentThemePath
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.parentThemeText = text();
            root.rebuild();
        }

        onLoadFailed: {
            if (root.parentFromUserDir) {
                root.parentFromUserDir = false;
                Qt.callLater(parentFile.reload);
                return;
            }
            root.parentThemeText = "";
            if (root.parentThemeName !== "") {
                console.warn("EpochShell theme", root.themeName, "extends unknown theme:", root.parentThemeName);
            }
            root.rebuild();
        }

        onFileChanged: reload()
    }

    Process {
        id: themeScan
        property var names: []
        property var palettes: ({})
        command: ["sh", "-c", "for f in '" + root.userThemeDir + "'/*.toml '" + root.bundledThemeDir + "'/*.toml; do " + "[ -e \"$f\" ] || continue; " + "echo \"@@theme $(basename \"$f\" .toml)\"; cat \"$f\"; done"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.applyThemeScan(text)
        }
    }

    readonly property var swatchKeys: ["surfaceText", "accent", "green", "red"]

    function applyThemeScan(raw) {
        const names = [];
        const palettes = {};
        const parents = {};
        const lines = String(raw || "").split("\n");
        let current = "";

        for (let i = 0; i < lines.length; i++) {
            const rawLine = lines[i];

            if (rawLine.startsWith("@@theme ")) {
                const name = rawLine.slice(8).trim();
                current = (name === "" || palettes[name] !== undefined) ? "" : name;
                if (current !== "") {
                    names.push(current);
                    palettes[current] = {};
                }
                continue;
            }

            if (current === "")
                continue;

            const line = root.stripTomlComment(rawLine);
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;

            const key = line.slice(0, eq).trim();

            if (key === root.extendsKey) {
                parents[current] = String(root.parseTomlValue(line.slice(eq + 1))).trim();
                continue;
            }

            if (root.colorKeys.indexOf(key) === -1)
                continue;
            palettes[current][key] = String(root.parseTomlValue(line.slice(eq + 1)));
        }

        // After the loop: the directory is walked alphabetically, so a parent may be read after its
        // child.
        for (const name in parents) {
            const parent = palettes[parents[name]];
            if (!parent || parents[name] === name)
                continue;
            const merged = {};
            for (const key in parent)
                merged[key] = parent[key];
            for (const key in palettes[name])
                merged[key] = palettes[name][key];
            palettes[name] = merged;
        }

        names.sort();
        themeScan.names = names;
        themeScan.palettes = palettes;
    }

    function themeColor(name, key) {
        const palette = themeScan.palettes[name];
        const value = palette && palette[key];
        return (typeof value === "string" && value.length > 0) ? value : root[key];
    }

    function stripTomlComment(line) {
        let quoted = false;
        let escaped = false;
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (escaped) {
                escaped = false;
                continue;
            }
            if (c === "\\") {
                escaped = true;
                continue;
            }
            if (c === '"')
                quoted = !quoted;
            if (c === "#" && !quoted)
                return line.slice(0, i).trim();
        }
        return line.trim();
    }

    function parseTomlValue(raw) {
        const value = raw.trim();
        if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
            return value.slice(1, -1);
        }
        if (value === "true")
            return true;
        if (value === "false")
            return false;
        const numberValue = Number(value);
        if (!Number.isNaN(numberValue))
            return numberValue;
        return value;
    }

    function resetDefaults() {
        purple = "#bf68d9";
        green = "#8ebd6b";
        orange = "#cc9057";
        blue = "#4fa6ed";
        yellow = "#e2b86b";
        cyan = "#48b0bd";
        red = "#e55561";
        bg_blue = "#61afef";
        bg_yellow = "#e8c88c";

        accent = blue;
        background = "#0e1013";
        surface = "#1f2329";
        surfaceVariant = "#323641";
        surfaceContainer = "#1f2329";
        surfaceContainerHigh = "#282c34";
        surfaceContainerHighest = "#30363f";
        surfaceText = "#a0a8b7";
        outline = "#8c9199";

        fontFamily = "JetBrainsMono Nerd Font Propo";
        barStyle = defaultBarStyle;
        panelOutline = "fade";
        panelStyle = "attached";
        statusStyle = "individual";
        workspaceStyle = "minimap";
        barLedge = true;
        barSpan = "pill";
        workspaceIconLimit = 2;
        workspaceShowTitle = false;
        workspaceIconColor = "color";
        workspaceMinimapMaxWidth = 160;
        polkitMaxAttempts = 3;
        polkitPhrase = "";
        launcherStyle = "attached";
        workspaceHomes = "";
        popupPadding = 10;
        popupRadius = 10;
        popupLayoutSpacing = 8;
        barIconSize = defaultBarIconSize;
        widthPaddingSmall = 14;
        layoutMarginSmall = 5;
        fontSizeNormal = 14;
        fontSizeMedium = 16;
        fontSizeLarge = 18;
        fontSizeXLarge = 24;
        fontSizeSubtext = 11;
        cardRadius = 10;
        cardHeight = 50;
        barHeight = defaultBarHeight;
        barFloatingGap = 4;
        barFloatingSideGap = 10;
        switchHeight = 42;
        switchWidth = 24;
        switchKnobSize = 20;
        switchKnobRadius = 10;
        hideInactiveWorkspaces = true;
        workspaceIcons = true;
        blur = true;
        workspaceStripMaxWidthRatio = 0.45;
        barOpacity = 1.0;
        panelOpacity = 1.0;
        popupOpacity = 1.0;

        updateDerived({});
    }

    function updateDerived(overridden) {
        if (!overridden.accentLightShade)
            accentLightShade = Qt.rgba(Qt.color(accent).r, Qt.color(accent).g, Qt.color(accent).b, 0.10);
        if (!overridden.inactive)
            inactive = Qt.rgba(Qt.color(surfaceText).r, Qt.color(surfaceText).g, Qt.color(surfaceText).b, 0.75);
        if (!overridden.active)
            active = surfaceText;
        if (!overridden.activeSelection)
            activeSelection = surfaceContainerHigh;
        if (!overridden.barClockSize)
            barClockSize = barIconSize;
        if (!overridden.barModuleHorizontalPadding)
            barModuleHorizontalPadding = widthPaddingSmall;
        if (!overridden.barModuleVerticalPadding)
            barModuleVerticalPadding = popupPadding;
    }

    function applyOverride(key, value, overridden) {
        if (colorKeys.indexOf(key) === -1 && boolKeys.indexOf(key) === -1 && realKeys.indexOf(key) === -1 && stringKeys.indexOf(key) === -1 && intKeys.indexOf(key) === -1) {
            console.warn("Unknown EpochShell config key:", key);
            return;
        }

        try {
            if (colorKeys.indexOf(key) !== -1)
                root[key] = Qt.color(String(value));
            else if (boolKeys.indexOf(key) !== -1)
                root[key] = !!value;
            else if (realKeys.indexOf(key) !== -1)
                root[key] = Number(value);
            else if (stringKeys.indexOf(key) !== -1)
                root[key] = String(value);
            else {
                const n = Number(value);
                if (isNaN(n))
                    throw "expected number";
                root[key] = Math.round(n);
            }
            overridden[key] = true;
        } catch (e) {
            // The polkit phrase is never logged, even when it fails to parse.
            console.warn("Invalid EpochShell config value for", key + ":", key === "polkitPhrase" ? "(hidden)" : value, e);
        }
    }

    function applyText(raw, overridden) {
        const lines = String(raw || "").split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            if (!line || (line.startsWith("[") && line.endsWith("]")))
                continue;

            const eq = line.indexOf("=");
            if (eq < 0)
                continue;

            const key = line.slice(0, eq).trim();
            if (key === root.themeKey || key === root.extendsKey)
                continue;

            const value = root.parseTomlValue(line.slice(eq + 1));
            root.applyOverride(key, value, overridden);
        }
    }

    function readThemeName(raw) {
        const lines = String(raw || "").split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            if (line.slice(0, eq).trim() !== root.themeKey)
                continue;
            return String(root.parseTomlValue(line.slice(eq + 1))).trim();
        }

        return root.defaultThemeName;
    }

    function readExtends(raw) {
        const lines = String(raw || "").split("\n");

        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            if (line.slice(0, eq).trim() !== root.extendsKey)
                continue;
            const parent = String(root.parseTomlValue(line.slice(eq + 1))).trim();
            // A theme naming itself would load itself forever.
            return parent === root.themeName ? "" : parent;
        }

        return "";
    }

    function acceptConfig(raw) {
        root.configText = String(raw || "");
        root.configThemeName = root.readThemeName(root.configText);
        root.resolveTheme();
        root.rebuild();
    }

    function resolveTheme() {
        root.themeName = root.previewThemeName !== "" ? root.previewThemeName : root.selectedThemeName !== "" ? root.selectedThemeName : root.configThemeName;
    }

    function previewTheme(name) {
        const wanted = String(name || "").trim();
        if (wanted === "" || wanted === root.previewThemeName)
            return false;
        root.previewThemeName = wanted;
        root.resolveTheme();
        return true;
    }

    function endPreview() {
        if (root.previewThemeName === "")
            return false;
        root.previewThemeName = "";
        root.resolveTheme();
        return true;
    }

    // Rebuilt from scratch every time, so removing a line from either file restores what it
    // covered.
    function rebuild() {
        themeScan.running = true;
        root.resetDefaults();
        const overridden = {};
        root.applyText(root.parentThemeText, overridden);
        root.applyText(root.themeText, overridden);
        root.applyText(root.configText, overridden);
        root.applyText(root.settingsText, overridden);
        root.updateDerived(overridden);
    }

    function selectTheme(name) {
        const wanted = String(name || "").trim();
        if (wanted === "")
            return false;
        if (root.availableThemes.length > 0 && root.availableThemes.indexOf(wanted) === -1)
            return false;

        // Already loaded (previewed or current): onLoaded will not fire again, so commit now.
        if (wanted === root.committedThemeName) {
            root.previewThemeName = "";
            root.pendingSelection = "";
            root.previousSelection = root.selectedThemeName;
            root.selectedThemeName = wanted;
            root.resolveTheme();
            selectionWriter.setText(wanted + "\n");
            return true;
        }

        root.previewThemeName = "";
        root.previousSelection = root.selectedThemeName;
        root.pendingSelection = wanted;
        root.selectedThemeName = wanted;
        root.resolveTheme();
        return true;
    }

    function clearThemeSelection() {
        root.previousSelection = root.selectedThemeName;
        root.pendingSelection = "";
        root.selectedThemeName = "";
        root.resolveTheme();
        selectionWriter.setText("\n");
        return true;
    }

    function setSetting(key, value) {
        const name = String(key || "").trim();
        if (name === "")
            return false;

        const values = {};
        const lines = root.settingsText.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = root.stripTomlComment(lines[i]);
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            values[line.slice(0, eq).trim()] = line.slice(eq + 1).trim();
        }

        values[name] = typeof value === "string" ? ('"' + value + '"') : String(value);

        const out = ["# Written by EpochShell. Settings changed from a control in the shell land", "# here, and win over both the selected theme and config.toml.", ""];
        for (const k in values)
            out.push(k + " = " + values[k]);
        settingsWriter.setText(out.join("\n") + "\n");
        return true;
    }

    FileView {
        path: root.settingsPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.settingsText = text();
            root.rebuild();
        }
        onLoadFailed: {
            root.settingsText = "";
            root.rebuild();
        }
        onFileChanged: reload()
    }

    FileView {
        id: settingsWriter
        path: root.settingsPath
        printErrors: false
        atomicWrites: true
    }

    FileView {
        id: selectionFile
        path: root.selectionPath
        watchChanges: true
        printErrors: false

        onLoaded: {
            root.selectedThemeName = String(text()).trim();
            root.resolveTheme();
        }

        onLoadFailed: {
            root.selectedThemeName = "";
            root.resolveTheme();
        }

        onFileChanged: reload()
    }

    // Written through a second, unwatched view: writing through the watched one fights its own
    // change notification.
    Process {
        id: stateDirMaker
        command: ["mkdir", "-p", root.stateDir]
        running: true
    }

    FileView {
        id: selectionWriter
        path: root.selectionPath
        printErrors: false
        atomicWrites: true
    }
}
